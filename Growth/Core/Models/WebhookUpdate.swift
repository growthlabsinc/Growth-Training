//
//  WebhookUpdate.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation

/// Webhook event types from App Store Server Notifications
public enum WebhookEventType: String, Codable {
    case purchased = "INITIAL_BUY"
    case renewed = "DID_RENEW"
    case cancelled = "CANCEL"
    case expired = "EXPIRED"
    case refunded = "REFUND"
    case gracePeriod = "GRACE_PERIOD"
    case billingRetry = "DID_FAIL_TO_RENEW"
    case revoked = "REVOKE"
    case priceIncrease = "PRICE_INCREASE_CONSENT"
    case offerRedeemed = "OFFER_REDEEMED"
}

/// Subscription status from webhook
public enum WebhookSubscriptionStatus: String, Codable {
    case active = "active"
    case expired = "expired"
    case billingRetry = "billing_retry"
    case gracePeriod = "grace_period"
    case revoked = "revoked"
}

/// Update received from App Store Server Notifications webhook
public struct WebhookUpdate: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Unique transaction ID
    public let transactionId: String
    
    /// Original transaction ID (for renewals)
    public let originalTransactionId: String?
    
    /// Subscription status
    public let subscriptionStatus: WebhookSubscriptionStatus
    
    /// Expiration date if applicable
    public let expirationDate: Date?
    
    /// Event type that triggered the webhook
    public let eventType: WebhookEventType
    
    /// Bundle ID of the app
    public let bundleId: String
    
    /// Product ID of the subscription
    public let productId: String?
    
    /// Purchase date
    public let purchaseDate: Date?
    
    /// Whether subscription is in trial
    public let isTrialActive: Bool
    
    /// Trial expiration date if in trial
    public let trialExpirationDate: Date?
    
    /// Auto-renewal status
    public let autoRenewalEnabled: Bool
    
    /// Cancellation date if cancelled
    public let cancellationDate: Date?
    
    /// Grace period end date if applicable
    public let gracePeriodEndDate: Date?
    
    /// Timestamp when webhook was received
    public let receivedAt: Date
    
    /// Environment (production/sandbox)
    public let environment: String
    
    // MARK: - Computed Properties
    
    /// Whether the update represents an active subscription
    public var isActive: Bool {
        switch subscriptionStatus {
        case .active, .gracePeriod:
            return true
        case .billingRetry:
            // Still active during billing retry
            if let expirationDate = expirationDate {
                return Date() < expirationDate
            }
            return false
        default:
            return false
        }
    }
    
    /// Whether the update requires user attention
    public var requiresUserAttention: Bool {
        switch subscriptionStatus {
        case .billingRetry, .gracePeriod:
            return true
        case .expired, .revoked:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    
    public init(
        transactionId: String,
        originalTransactionId: String? = nil,
        subscriptionStatus: WebhookSubscriptionStatus,
        expirationDate: Date? = nil,
        eventType: WebhookEventType,
        bundleId: String,
        productId: String? = nil,
        purchaseDate: Date? = nil,
        isTrialActive: Bool = false,
        trialExpirationDate: Date? = nil,
        autoRenewalEnabled: Bool = true,
        cancellationDate: Date? = nil,
        gracePeriodEndDate: Date? = nil,
        receivedAt: Date = Date(),
        environment: String = "production"
    ) {
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.subscriptionStatus = subscriptionStatus
        self.expirationDate = expirationDate
        self.eventType = eventType
        self.bundleId = bundleId
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.isTrialActive = isTrialActive
        self.trialExpirationDate = trialExpirationDate
        self.autoRenewalEnabled = autoRenewalEnabled
        self.cancellationDate = cancellationDate
        self.gracePeriodEndDate = gracePeriodEndDate
        self.receivedAt = receivedAt
        self.environment = environment
    }
}

// MARK: - Firestore Integration

extension WebhookUpdate {
    
    /// Creates a webhook update from Firestore data
    public static func from(firestoreData: [String: Any]) -> WebhookUpdate? {
        guard let transactionId = firestoreData["transactionId"] as? String,
              let statusString = firestoreData["subscriptionStatus"] as? String,
              let status = WebhookSubscriptionStatus(rawValue: statusString),
              let eventTypeString = firestoreData["eventType"] as? String,
              let eventType = WebhookEventType(rawValue: eventTypeString),
              let bundleId = firestoreData["bundleId"] as? String else {
            return nil
        }
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        
        var expirationDate: Date?
        if let expirationString = firestoreData["expirationDate"] as? String {
            expirationDate = dateFormatter.date(from: expirationString)
        }
        
        var purchaseDate: Date?
        if let purchaseString = firestoreData["purchaseDate"] as? String {
            purchaseDate = dateFormatter.date(from: purchaseString)
        }
        
        var trialExpirationDate: Date?
        if let trialString = firestoreData["trialExpirationDate"] as? String {
            trialExpirationDate = dateFormatter.date(from: trialString)
        }
        
        var cancellationDate: Date?
        if let cancelString = firestoreData["cancellationDate"] as? String {
            cancellationDate = dateFormatter.date(from: cancelString)
        }
        
        var gracePeriodEndDate: Date?
        if let graceString = firestoreData["gracePeriodEndDate"] as? String {
            gracePeriodEndDate = dateFormatter.date(from: graceString)
        }
        
        var receivedAt = Date()
        if let receivedString = firestoreData["receivedAt"] as? String {
            receivedAt = dateFormatter.date(from: receivedString) ?? Date()
        }
        
        return WebhookUpdate(
            transactionId: transactionId,
            originalTransactionId: firestoreData["originalTransactionId"] as? String,
            subscriptionStatus: status,
            expirationDate: expirationDate,
            eventType: eventType,
            bundleId: bundleId,
            productId: firestoreData["productId"] as? String,
            purchaseDate: purchaseDate,
            isTrialActive: firestoreData["isTrialActive"] as? Bool ?? false,
            trialExpirationDate: trialExpirationDate,
            autoRenewalEnabled: firestoreData["autoRenewalEnabled"] as? Bool ?? true,
            cancellationDate: cancellationDate,
            gracePeriodEndDate: gracePeriodEndDate,
            receivedAt: receivedAt,
            environment: firestoreData["environment"] as? String ?? "production"
        )
    }
    
    /// Converts webhook update to Firestore data
    public func toFirestoreData() -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        var data: [String: Any] = [
            "transactionId": transactionId,
            "subscriptionStatus": subscriptionStatus.rawValue,
            "eventType": eventType.rawValue,
            "bundleId": bundleId,
            "isTrialActive": isTrialActive,
            "autoRenewalEnabled": autoRenewalEnabled,
            "receivedAt": dateFormatter.string(from: receivedAt),
            "environment": environment
        ]
        
        // Add optional fields
        if let originalTransactionId = originalTransactionId {
            data["originalTransactionId"] = originalTransactionId
        }
        
        if let productId = productId {
            data["productId"] = productId
        }
        
        if let expirationDate = expirationDate {
            data["expirationDate"] = dateFormatter.string(from: expirationDate)
        }
        
        if let purchaseDate = purchaseDate {
            data["purchaseDate"] = dateFormatter.string(from: purchaseDate)
        }
        
        if let trialExpirationDate = trialExpirationDate {
            data["trialExpirationDate"] = dateFormatter.string(from: trialExpirationDate)
        }
        
        if let cancellationDate = cancellationDate {
            data["cancellationDate"] = dateFormatter.string(from: cancellationDate)
        }
        
        if let gracePeriodEndDate = gracePeriodEndDate {
            data["gracePeriodEndDate"] = dateFormatter.string(from: gracePeriodEndDate)
        }
        
        return data
    }
}

// MARK: - Debug

extension WebhookUpdate: CustomStringConvertible {
    public var description: String {
        """
        WebhookUpdate:
        - Event: \(eventType.rawValue)
        - Status: \(subscriptionStatus.rawValue)
        - Transaction: \(transactionId)
        - Product: \(productId ?? "unknown")
        - Active: \(isActive)
        - Expires: \(expirationDate?.formatted() ?? "never")
        - Environment: \(environment)
        """
    }
}