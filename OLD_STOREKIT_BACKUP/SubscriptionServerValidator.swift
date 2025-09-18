//
//  SubscriptionServerValidator.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFunctions
import UIKit

/// Service for validating subscriptions with Apple servers via Firebase Functions
@available(iOS 15.0, *)
@MainActor
public final class SubscriptionServerValidator: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = SubscriptionServerValidator()
    
    // MARK: - Properties
    
    private let functions: Functions
    private let networkMonitor = NetworkReachability.shared
    private let validationQueue = DispatchQueue(label: "com.growth.subscription.server.validation", qos: .userInitiated)
    
    // Retry configuration
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 2.0
    private let maxRetryDelay: TimeInterval = 60.0
    
    // Circuit breaker configuration
    private var failureCount = 0
    private let failureThreshold = 5
    private var circuitBreakerOpenUntil: Date?
    private let circuitBreakerResetTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    private init() {
        // Configure functions for the current environment
        if let region = ProcessInfo.processInfo.environment["FIREBASE_FUNCTIONS_REGION"] {
            functions = Functions.functions(region: region)
        } else {
            functions = Functions.functions()
        }
    }
    
    // MARK: - Public Methods
    
    /// Validates a subscription receipt with Apple servers
    /// - Parameters:
    ///   - receiptData: Base64 encoded receipt data
    ///   - forceRefresh: Force refresh bypassing cache
    /// - Returns: Server validation result
    public func validateReceipt(_ receiptData: String, forceRefresh: Bool = false) async throws -> ValidationResult {
        // Check circuit breaker
        if isCircuitBreakerOpen() {
            throw ValidationError.serverUnavailable
        }
        
        // Check network connectivity
        guard networkMonitor.isConnected else {
            throw ValidationError.noNetwork
        }
        
        // Validate with retry logic
        return try await withExponentialBackoff(maxRetries: maxRetries) { [weak self] attempt in
            guard let self = self else {
                return ValidationResult.failure(error: "Service unavailable", source: .server)
            }
            return try await self.performValidation(receiptData: receiptData, forceRefresh: forceRefresh)
        }
    }
    
    /// Processes a webhook update from App Store Server Notifications
    /// - Parameter update: Webhook update data
    /// - Returns: Updated subscription state
    public func processWebhookUpdate(_ update: WebhookUpdate) async throws -> SubscriptionState {
        // Map webhook event to subscription state
        let status = mapWebhookEventToStatus(update.eventType)
        let tier = update.subscriptionStatus == .active ? 
            SubscriptionTier.from(productId: update.productId ?? "") : .none
        
        return SubscriptionState(
            tier: tier,
            status: status,
            expirationDate: update.expirationDate,
            purchaseDate: update.purchaseDate,
            isTrialActive: update.isTrialActive,
            trialExpirationDate: update.trialExpirationDate,
            autoRenewalEnabled: update.autoRenewalEnabled,
            lastUpdated: Date(),
            validationSource: .server,
            productId: update.productId,
            transactionId: update.transactionId
        )
    }
    
    // MARK: - Private Methods
    
    private func performValidation(receiptData: String, forceRefresh: Bool) async throws -> ValidationResult {
        do {
            // Call Firebase Function
            let callable = functions.httpsCallable("validateSubscriptionReceipt")
            let result = try await callable.call(["receiptData": receiptData, "forceRefresh": forceRefresh])
            
            // Parse response
            guard let data = result.data as? [String: Any] else {
                throw ValidationError.invalidResponse
            }
            
            let validationResult = try parseValidationResponse(data)
            
            // Reset circuit breaker on success
            resetCircuitBreaker()
            
            return validationResult
            
        } catch {
            // Increment failure count
            recordFailure()
            
            // Map Firebase errors to validation errors
            if let nsError = error as NSError?, nsError.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: nsError.code)
                switch code {
                case .unauthenticated:
                    throw ValidationError.unauthenticated
                case .invalidArgument:
                    throw ValidationError.invalidReceipt
                case .unavailable:
                    throw ValidationError.serverUnavailable
                default:
                    throw ValidationError.serverError(error.localizedDescription)
                }
            }
            
            throw ValidationError.serverError(error.localizedDescription)
        }
    }
    
    private func parseValidationResponse(_ data: [String: Any]) throws -> ValidationResult {
        guard let isValid = data["isValid"] as? Bool,
              let tierString = data["tier"] as? String,
              let _ = data["timestamp"] as? String else {
            throw ValidationError.invalidResponse
        }
        
        let tier = SubscriptionTier(rawValue: tierString) ?? .none
        let expirationDateString = data["expirationDate"] as? String
        let transactionId = data["transactionId"] as? String
        
        var expirationDate: Date?
        if let dateString = expirationDateString {
            let formatter = ISO8601DateFormatter()
            expirationDate = formatter.date(from: dateString)
        }
        
        if isValid {
            let state = SubscriptionState(
                tier: tier,
                status: .active,
                expirationDate: expirationDate,
                purchaseDate: Date(),
                isTrialActive: false,
                trialExpirationDate: nil,
                autoRenewalEnabled: true,
                lastUpdated: Date(),
                validationSource: .server,
                productId: nil,
                transactionId: transactionId
            )
            
            return ValidationResult(
                state: state,
                source: .server,
                timestamp: Date(),
                serverReceiptHash: transactionId,
                validationAttempts: 1,
                error: nil
            )
        } else {
            let errorMessage = data["error"] as? String
            return ValidationResult(
                state: .nonSubscribed,
                source: .server,
                timestamp: Date(),
                serverReceiptHash: nil,
                validationAttempts: 1,
                error: errorMessage
            )
        }
    }
    
    // MARK: - Circuit Breaker
    
    private func isCircuitBreakerOpen() -> Bool {
        if let openUntil = circuitBreakerOpenUntil {
            if Date() < openUntil {
                return true
            } else {
                // Reset circuit breaker after timeout
                resetCircuitBreaker()
                return false
            }
        }
        return false
    }
    
    private func recordFailure() {
        failureCount += 1
        if failureCount >= failureThreshold {
            // Open circuit breaker
            circuitBreakerOpenUntil = Date().addingTimeInterval(circuitBreakerResetTime)
            Logger.info("🔴 Circuit breaker opened until: \(circuitBreakerOpenUntil!)")
        }
    }
    
    private func resetCircuitBreaker() {
        failureCount = 0
        circuitBreakerOpenUntil = nil
    }
    
    // MARK: - Retry Logic
    
    private func withExponentialBackoff<T>(
        maxRetries: Int,
        operation: @escaping (Int) async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation(attempt)
            } catch {
                lastError = error
                
                // Don't retry for certain errors
                if case ValidationError.unauthenticated = error {
                    throw error
                }
                if case ValidationError.invalidReceipt = error {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = min(baseRetryDelay * pow(2.0, Double(attempt)), maxRetryDelay)
                
                Logger.info("🔄 Retry attempt \(attempt + 1) after \(delay)s delay")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? ValidationError.serverUnavailable
    }
    
    // MARK: - Helper Methods
    
    private func mapWebhookEventToStatus(_ eventType: WebhookEventType) -> SubscriptionState.Status {
        switch eventType {
        case .purchased, .renewed, .offerRedeemed:
            return .active
        case .expired:
            return .expired
        case .cancelled:
            return .cancelled
        case .refunded, .revoked:
            return .none
        case .gracePeriod:
            return .grace
        case .billingRetry:
            return .pending
        case .priceIncrease:
            // Price increase consent doesn't change status, keep current
            return .active
        }
    }
}

// MARK: - Error Types

extension SubscriptionServerValidator {
    public enum ValidationError: LocalizedError {
        case noNetwork
        case serverUnavailable
        case unauthenticated
        case invalidReceipt
        case invalidResponse
        case serverError(String)
        
        public var errorDescription: String? {
            switch self {
            case .noNetwork:
                return "No network connection available"
            case .serverUnavailable:
                return "Validation server is temporarily unavailable"
            case .unauthenticated:
                return "User authentication required"
            case .invalidReceipt:
                return "Invalid receipt data"
            case .invalidResponse:
                return "Invalid server response"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }
}

// MARK: - Network Reachability

/// Simple network reachability monitor
@available(iOS 15.0, *)
@MainActor
public final class NetworkReachability: ObservableObject {
    static let shared = NetworkReachability()
    
    @Published public private(set) var isConnected: Bool = true
    
    private init() {
        // In production, use NWPathMonitor for real network monitoring
        // For now, assume connected
    }
}