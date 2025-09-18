/**
 * SimplifiedEntitlementManager.swift  
 * Growth App Simplified Entitlement Management
 *
 * Based on RevenueCat demo pattern using @AppStorage for simple boolean flags
 * Replaces complex entitlement tracking with App Group shared preferences
 */

import SwiftUI

@MainActor
public class SimplifiedEntitlementManager: ObservableObject {
    
    // MARK: - App Group UserDefaults
    static let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod")!
    
    // MARK: - Entitlement Flags
    @AppStorage("hasPremium", store: userDefaults)
    public var hasPremium: Bool = false
    
    @AppStorage("hasLifetime", store: userDefaults) 
    public var hasLifetime: Bool = false
    
    // MARK: - Convenience Properties
    public var hasAnyPremiumAccess: Bool {
        return hasPremium || hasLifetime
    }
    
    public var subscriptionTier: SubscriptionTier {
        return hasAnyPremiumAccess ? .premium : .none
    }
    
    // MARK: - Initializer
    public init() {
        // Default initializer - @AppStorage properties are automatically initialized
    }
    
    // MARK: - Methods
    public func reset() {
        hasPremium = false
        hasLifetime = false
        print("🧹 Entitlements reset")
    }
    
    public func debugPrint() {
        print("📱 Current Entitlements:")
        print("   - Premium: \(hasPremium)")
        print("   - Lifetime: \(hasLifetime)")
        print("   - Any Access: \(hasAnyPremiumAccess)")
    }
}

// MARK: - Subscription Tier Mapping
extension SimplifiedEntitlementManager {
    
    /// Updates entitlements based on purchased product IDs
    public func updateFromPurchasedProducts(_ purchasedIDs: Set<String>) {
        let oldHasPremium = hasPremium
        
        // Check for any active premium subscription
        hasPremium = !purchasedIDs.isEmpty
        
        // Log changes
        if oldHasPremium != hasPremium {
            print("📱 Premium access changed: \(hasPremium ? "Granted" : "Revoked")")
        }
    }
}

// MARK: - EntitlementProvider Bridge
extension SimplifiedEntitlementManager {
    /// Get an EntitlementProvider that can be used in non-MainActor contexts
    nonisolated public var asEntitlementProvider: EntitlementProvider {
        return EntitlementManagerBridge()
    }
}

/// Bridge to provide nonisolated access to entitlements
private struct EntitlementManagerBridge: EntitlementProvider {
    private let userDefaults: UserDefaults
    
    init() {
        self.userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") ?? UserDefaults.standard
    }
    
    public var hasPremium: Bool {
        return userDefaults.bool(forKey: "hasPremium")
    }
}