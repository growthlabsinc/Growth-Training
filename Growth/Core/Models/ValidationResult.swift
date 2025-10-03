//
//  ValidationResult.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation

/// Result of subscription validation with source tracking
public struct ValidationResult: Codable, Equatable {
    
    // MARK: - Validation Source
    
    public enum ValidationSource: String, Codable {
        case local = "local"        // Validated locally via StoreKit
        case server = "server"      // Validated with Apple servers
        case cached = "cached"      // Retrieved from cache
        case webhook = "webhook"    // Updated via webhook
    }
    
    // MARK: - Properties
    
    /// The validated subscription state
    public let state: SubscriptionState
    
    /// Source of the validation
    public let source: ValidationSource
    
    /// Timestamp of validation
    public let timestamp: Date
    
    /// Server receipt hash for verification
    public let serverReceiptHash: String?
    
    /// Number of validation attempts made
    public let validationAttempts: Int
    
    /// Error message if validation failed
    public let error: String?
    
    /// Whether validation succeeded
    public var isValid: Bool {
        error == nil && state.hasActiveAccess
    }
    
    /// Whether result is from server validation
    public var isServerValidated: Bool {
        source == .server || source == .webhook
    }
    
    /// Whether result is stale and needs refresh
    public var isStale: Bool {
        let staleThreshold: TimeInterval = 60 * 60 // 1 hour for server results
        let cacheThreshold: TimeInterval = 15 * 60 // 15 minutes for cached results
        
        let threshold = source == .cached ? cacheThreshold : staleThreshold
        return Date().timeIntervalSince(timestamp) > threshold
    }
    
    // MARK: - Initialization
    
    public init(
        state: SubscriptionState,
        source: ValidationSource,
        timestamp: Date = Date(),
        serverReceiptHash: String? = nil,
        validationAttempts: Int = 1,
        error: String? = nil
    ) {
        self.state = state
        self.source = source
        self.timestamp = timestamp
        self.serverReceiptHash = serverReceiptHash
        self.validationAttempts = validationAttempts
        self.error = error
    }
    
    // MARK: - Factory Methods
    
    /// Creates a successful validation result
    public static func success(
        state: SubscriptionState,
        source: ValidationSource,
        receiptHash: String? = nil
    ) -> ValidationResult {
        ValidationResult(
            state: state,
            source: source,
            serverReceiptHash: receiptHash
        )
    }
    
    /// Creates a failed validation result
    public static func failure(
        error: String,
        source: ValidationSource = .local
    ) -> ValidationResult {
        ValidationResult(
            state: .nonSubscribed,
            source: source,
            error: error
        )
    }
    
    /// Creates a cached validation result
    public static func cached(from original: ValidationResult) -> ValidationResult {
        ValidationResult(
            state: original.state,
            source: .cached,
            timestamp: original.timestamp,
            serverReceiptHash: original.serverReceiptHash,
            validationAttempts: original.validationAttempts
        )
    }
}

// MARK: - Persistence

extension ValidationResult {
    
    private static let cacheKey = "com.growth.validationResultCache"
    
    /// Caches the validation result
    public func cache() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.cacheKey)
        }
    }
    
    /// Loads cached validation result
    public static func loadCached() -> ValidationResult? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let result = try? JSONDecoder().decode(ValidationResult.self, from: data) else {
            return nil
        }
        
        // Don't return stale cached results
        if result.isStale {
            clearCache()
            return nil
        }
        
        // Convert to cached source
        return .cached(from: result)
    }
    
    /// Clears cached validation result
    public static func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}

// MARK: - Debug

extension ValidationResult: CustomStringConvertible {
    public var description: String {
        """
        ValidationResult:
        - Valid: \(isValid)
        - Source: \(source.rawValue)
        - Timestamp: \(timestamp.formatted())
        - Attempts: \(validationAttempts)
        - Error: \(error ?? "none")
        - State: \(state.tier.rawValue) - \(state.status.rawValue)
        """
    }
}