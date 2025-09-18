/**
 * EntitlementManager.swift
 * Growth App Entitlement Management
 *
 * Manages subscription entitlements and shares them with app extensions
 * via App Groups for widgets, watch apps, and other extensions.
 */

import Foundation
import SwiftUI
import StoreKit

/// Manages subscription entitlements and shares them across app and extensions
@available(iOS 15.0, *)
@MainActor
class EntitlementManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether user has any active subscription
    @Published var hasActiveSubscription: Bool = false
    
    /// Whether user has Premium subscription
    @Published var hasPremium: Bool = false
    
    /// Current subscription tier
    @Published var currentTier: SubscriptionTier = .none
    
    /// Set of purchased product IDs
    @Published var purchasedProductIDs: Set<String> = []
    
    /// Subscription expiration date if available
    @Published var expirationDate: Date?
    
    // MARK: - App Group Storage
    
    /// Shared UserDefaults for App Group
    static let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.identifier)
    
    // MARK: - Storage Keys
    
    private enum StorageKeys {
        static let hasActiveSubscription = "com.growthlabs.growthmethod.hasActiveSubscription"
        static let hasPremium = "com.growthlabs.growthmethod.hasPremium"
        static let currentTier = "com.growthlabs.growthmethod.currentTier"
        static let purchasedProductIDs = "com.growthlabs.growthmethod.purchasedProductIDs"
        static let expirationDate = "com.growthlabs.growthmethod.expirationDate"
        static let lastUpdated = "com.growthlabs.growthmethod.entitlements.lastUpdated"
    }
    
    // MARK: - Singleton
    
    static let shared = EntitlementManager()
    
    private init() {
        loadStoredEntitlements()
    }
    
    // MARK: - Public Methods
    
    /// Update entitlements based on current transactions
    func updateEntitlements(from transactions: [StoreKit.Transaction]) async {
        Logger.info("EntitlementManager: Updating entitlements from \(transactions.count) transactions")
        
        // Clear existing entitlements
        purchasedProductIDs.removeAll()
        
        // Track highest tier and latest expiration
        var highestTier: SubscriptionTier = .none
        var latestExpiration: Date?
        
        for transaction in transactions {
            // Skip revoked transactions
            if transaction.revocationDate != nil {
                Logger.info("EntitlementManager: Skipping revoked transaction: \(transaction.productID)")
                continue
            }
            
            // Add to purchased products
            purchasedProductIDs.insert(transaction.productID)
            
            // Determine tier for this product
            let tier = SubscriptionProductIDs.tier(for: transaction.productID)
            if tier.hierarchyLevel > highestTier.hierarchyLevel {
                highestTier = tier
            }
            
            // Track expiration date
            if let expiration = transaction.expirationDate {
                if latestExpiration == nil || expiration > latestExpiration! {
                    latestExpiration = expiration
                }
            }
        }
        
        // Update published properties
        currentTier = highestTier
        hasActiveSubscription = !purchasedProductIDs.isEmpty
        hasPremium = highestTier == .premium
        expirationDate = latestExpiration
        
        // Store to App Group
        persistEntitlements()
        
        Logger.info("EntitlementManager: Updated - Tier: \(highestTier.displayName), Active: \(hasActiveSubscription)")
    }
    
    /// Update entitlements using Transaction.currentEntitlements
    func refreshEntitlements() async {
        Logger.info("EntitlementManager: Refreshing entitlements from currentEntitlements")
        
        var verifiedTransactions: [StoreKit.Transaction] = []
        
        // Get all current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                verifiedTransactions.append(transaction)
            } catch {
                Logger.error("EntitlementManager: Failed to verify transaction: \(error)")
            }
        }
        
        // Update entitlements with verified transactions
        await updateEntitlements(from: verifiedTransactions)
    }
    
    /// Check if user has access to a specific feature
    func hasAccess(to feature: PremiumFeatureType) -> Bool {
        // All premium features require premium subscription
        return hasPremium
    }
    
    /// Clear all entitlements (for logout)
    func clearEntitlements() {
        hasActiveSubscription = false
        hasPremium = false
        currentTier = .none
        purchasedProductIDs.removeAll()
        expirationDate = nil
        
        clearStoredEntitlements()
    }
    
    // MARK: - Private Methods
    
    /// Persist entitlements to App Group UserDefaults
    private func persistEntitlements() {
        guard let defaults = Self.sharedDefaults else {
            Logger.error("EntitlementManager: Unable to access App Group UserDefaults")
            return
        }
        
        defaults.set(hasActiveSubscription, forKey: StorageKeys.hasActiveSubscription)
        defaults.set(hasPremium, forKey: StorageKeys.hasPremium)
        defaults.set(currentTier.rawValue, forKey: StorageKeys.currentTier)
        defaults.set(Array(purchasedProductIDs), forKey: StorageKeys.purchasedProductIDs)
        defaults.set(expirationDate, forKey: StorageKeys.expirationDate)
        defaults.set(Date(), forKey: StorageKeys.lastUpdated)
        
        defaults.synchronize()
        
        Logger.info("EntitlementManager: Persisted entitlements to App Group")
    }
    
    /// Load stored entitlements from App Group UserDefaults
    private func loadStoredEntitlements() {
        guard let defaults = Self.sharedDefaults else {
            Logger.error("EntitlementManager: Unable to access App Group UserDefaults")
            return
        }
        
        hasActiveSubscription = defaults.bool(forKey: StorageKeys.hasActiveSubscription)
        hasPremium = defaults.bool(forKey: StorageKeys.hasPremium)
        
        if let tierRawValue = defaults.string(forKey: StorageKeys.currentTier) {
            currentTier = SubscriptionTier(rawValue: tierRawValue) ?? .none
        }
        
        if let productIDArray = defaults.array(forKey: StorageKeys.purchasedProductIDs) as? [String] {
            purchasedProductIDs = Set(productIDArray)
        }
        
        expirationDate = defaults.object(forKey: StorageKeys.expirationDate) as? Date
        
        Logger.info("EntitlementManager: Loaded stored entitlements - Tier: \(currentTier.displayName)")
    }
    
    /// Clear stored entitlements from App Group UserDefaults
    private func clearStoredEntitlements() {
        guard let defaults = Self.sharedDefaults else { return }
        
        defaults.removeObject(forKey: StorageKeys.hasActiveSubscription)
        defaults.removeObject(forKey: StorageKeys.hasPremium)
        defaults.removeObject(forKey: StorageKeys.currentTier)
        defaults.removeObject(forKey: StorageKeys.purchasedProductIDs)
        defaults.removeObject(forKey: StorageKeys.expirationDate)
        defaults.removeObject(forKey: StorageKeys.lastUpdated)
        
        defaults.synchronize()
    }
    
    /// Verify transaction authenticity
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TransactionVerificationError()
        case .verified(let safe):
            return safe
        }
    }
}

/// Error for transaction verification failures
private struct TransactionVerificationError: LocalizedError {
    var errorDescription: String? { "Transaction verification failed" }
}

// MARK: - Premium Features Enum

public enum PremiumFeatureType {
    case unlimitedSessions
    case advancedAnalytics
    case aiCoach
    case customRoutines
    case exportData
    case prioritySupport
}

// MARK: - Extension for Widget/Watch Access

@available(iOS 15.0, *)
extension EntitlementManager {
    
    /// Static method for extensions to check entitlements without full initialization
    static func checkEntitlement(for feature: PremiumFeatureType) -> Bool {
        guard let defaults = sharedDefaults else { return false }
        
        // All premium features require premium subscription
        return defaults.bool(forKey: StorageKeys.hasPremium)
    }
    
    /// Get current tier from shared storage (for extensions)
    static func getCurrentTier() -> SubscriptionTier {
        guard let defaults = sharedDefaults,
              let tierRawValue = defaults.string(forKey: StorageKeys.currentTier) else {
            return .none
        }
        
        return SubscriptionTier(rawValue: tierRawValue) ?? .none
    }
    
    /// Check if subscription is expired (for extensions)
    static func isSubscriptionExpired() -> Bool {
        guard let defaults = sharedDefaults,
              let expirationDate = defaults.object(forKey: StorageKeys.expirationDate) as? Date else {
            return true
        }
        
        return expirationDate < Date()
    }
}