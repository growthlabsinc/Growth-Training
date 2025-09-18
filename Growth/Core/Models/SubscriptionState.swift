//
//  SubscriptionState.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation

/// Unified subscription state model representing the complete subscription status
/// This is the single source of truth for subscription state across the app
public struct SubscriptionState: Codable, Equatable {
    
    // MARK: - Subscription Status
    
    public enum Status: String, Codable {
        case none = "none"
        case active = "active"
        case expired = "expired"
        case pending = "pending"
        case grace = "grace" // Grace period after failed renewal
        case cancelled = "cancelled" // Cancelled but still active until expiration
    }
    
    // MARK: - Validation Source
    
    public enum ValidationSource: String, Codable {
        case local = "local"
        case server = "server"
        case cached = "cached"
        case unknown = "unknown"
    }
    
    // MARK: - Properties
    
    /// Current subscription tier
    public let tier: SubscriptionTier
    
    /// Current subscription status
    public let status: Status
    
    /// Subscription expiration date (nil for lifetime or no subscription)
    public let expirationDate: Date?
    
    /// Original purchase date
    public let purchaseDate: Date?
    
    /// Whether user is in trial period
    public let isTrialActive: Bool
    
    /// Trial expiration date if in trial
    public let trialExpirationDate: Date?
    
    /// Whether auto-renewal is enabled
    public let autoRenewalEnabled: Bool
    
    /// Last time the state was updated
    public let lastUpdated: Date
    
    /// Source of the validation
    public let validationSource: ValidationSource
    
    /// Product ID of current subscription
    public let productId: String?
    
    /// Transaction ID for tracking
    public let transactionId: String?
    
    /// Cancellation date if cancelled
    public let cancellationDate: Date?
    
    /// Grace period end date if in grace period
    public let gracePeriodEndDate: Date?
    
    // MARK: - Computed Properties
    
    /// Whether the subscription grants access to features
    public var hasActiveAccess: Bool {
        switch status {
        case .active, .grace:
            return true
        case .cancelled:
            // Still has access until expiration
            if let expirationDate = expirationDate {
                return Date() < expirationDate
            }
            return false
        default:
            return false
        }
    }
    
    /// Whether the subscription needs renewal attention
    public var needsRenewalAttention: Bool {
        status == .grace || (status == .cancelled && hasActiveAccess)
    }
    
    /// Days remaining in subscription
    public var daysRemaining: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
    
    /// Whether state data is stale and needs refresh
    public var isStale: Bool {
        let staleThreshold: TimeInterval = 15 * 60 // 15 minutes
        return Date().timeIntervalSince(lastUpdated) > staleThreshold
    }
    
    // MARK: - Initialization
    
    public init(
        tier: SubscriptionTier = .none,
        status: Status = .none,
        expirationDate: Date? = nil,
        purchaseDate: Date? = nil,
        isTrialActive: Bool = false,
        trialExpirationDate: Date? = nil,
        autoRenewalEnabled: Bool = false,
        lastUpdated: Date = Date(),
        validationSource: ValidationSource = .unknown,
        productId: String? = nil,
        transactionId: String? = nil,
        cancellationDate: Date? = nil,
        gracePeriodEndDate: Date? = nil
    ) {
        self.tier = tier
        self.status = status
        self.expirationDate = expirationDate
        self.purchaseDate = purchaseDate
        self.isTrialActive = isTrialActive
        self.trialExpirationDate = trialExpirationDate
        self.autoRenewalEnabled = autoRenewalEnabled
        self.lastUpdated = lastUpdated
        self.validationSource = validationSource
        self.productId = productId
        self.transactionId = transactionId
        self.cancellationDate = cancellationDate
        self.gracePeriodEndDate = gracePeriodEndDate
    }
    
    // MARK: - Factory Methods
    
    /// Creates a default non-subscribed state
    public static var nonSubscribed: SubscriptionState {
        SubscriptionState()
    }
    
    /// Creates an active subscription state
    public static func active(
        tier: SubscriptionTier,
        expirationDate: Date,
        productId: String,
        autoRenewalEnabled: Bool = true
    ) -> SubscriptionState {
        SubscriptionState(
            tier: tier,
            status: .active,
            expirationDate: expirationDate,
            purchaseDate: Date(),
            autoRenewalEnabled: autoRenewalEnabled,
            validationSource: .local,
            productId: productId
        )
    }
    
    /// Creates a trial state
    public static func trial(
        tier: SubscriptionTier,
        trialExpirationDate: Date,
        productId: String
    ) -> SubscriptionState {
        SubscriptionState(
            tier: tier,
            status: .active,
            expirationDate: trialExpirationDate,
            isTrialActive: true,
            trialExpirationDate: trialExpirationDate,
            autoRenewalEnabled: true,
            validationSource: .local,
            productId: productId
        )
    }
    
    // MARK: - State Updates
    
    /// Creates a new state with updated validation source and timestamp
    public func validated(from source: ValidationSource) -> SubscriptionState {
        SubscriptionState(
            tier: tier,
            status: status,
            expirationDate: expirationDate,
            purchaseDate: purchaseDate,
            isTrialActive: isTrialActive,
            trialExpirationDate: trialExpirationDate,
            autoRenewalEnabled: autoRenewalEnabled,
            lastUpdated: Date(),
            validationSource: source,
            productId: productId,
            transactionId: transactionId,
            cancellationDate: cancellationDate,
            gracePeriodEndDate: gracePeriodEndDate
        )
    }
    
    /// Creates an expired state from current state
    public func expired() -> SubscriptionState {
        SubscriptionState(
            tier: .none,
            status: .expired,
            expirationDate: expirationDate,
            purchaseDate: purchaseDate,
            isTrialActive: false,
            trialExpirationDate: trialExpirationDate,
            autoRenewalEnabled: false,
            lastUpdated: Date(),
            validationSource: validationSource,
            productId: productId,
            transactionId: transactionId,
            cancellationDate: cancellationDate,
            gracePeriodEndDate: nil
        )
    }
}

// MARK: - Persistence

extension SubscriptionState {
    
    private static let persistenceKey = "com.growth.subscriptionState"
    
    /// Saves state to UserDefaults
    public func persist() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.persistenceKey)
        }
    }
    
    /// Loads state from UserDefaults
    public static func loadPersisted() -> SubscriptionState? {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let state = try? JSONDecoder().decode(SubscriptionState.self, from: data) else {
            return nil
        }
        return state
    }
    
    /// Clears persisted state
    public static func clearPersisted() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }
}

// MARK: - Debug

extension SubscriptionState: CustomStringConvertible {
    public var description: String {
        """
        SubscriptionState:
        - Tier: \(tier.rawValue)
        - Status: \(status.rawValue)
        - Has Access: \(hasActiveAccess)
        - Expires: \(expirationDate?.formatted() ?? "Never")
        - Trial: \(isTrialActive)
        - Auto-Renew: \(autoRenewalEnabled)
        - Source: \(validationSource.rawValue)
        - Last Updated: \(lastUpdated.formatted())
        """
    }
}