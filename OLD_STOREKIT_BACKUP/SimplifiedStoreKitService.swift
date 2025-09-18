/**
 * SimplifiedStoreKitService.swift
 * Migration Bridge for Gradual Rollout
 * 
 * This service acts as a bridge between the old complex architecture and the new
 * simplified approach, allowing for gradual migration with feature flags.
 */

import SwiftUI
import StoreKit
import Combine

/// Feature flag for enabling simplified StoreKit implementation
public struct StoreKitFeatureFlags {
    /// Check if simplified implementation is enabled
    public static var useSimplifiedImplementation: Bool {
        #if DEBUG
        // Always use simplified in debug for testing
        return UserDefaults.standard.bool(forKey: "use_simplified_storekit") || true
        #else
        // Production: controlled by remote config or user defaults
        return UserDefaults.standard.bool(forKey: "use_simplified_storekit")
        #endif
    }
    
    /// Enable simplified implementation
    public static func enableSimplified() {
        UserDefaults.standard.set(true, forKey: "use_simplified_storekit")
    }
    
    /// Disable simplified implementation (rollback)
    public static func disableSimplified() {
        UserDefaults.standard.set(false, forKey: "use_simplified_storekit")
    }
}

/// Unified service that routes to either old or new implementation
@MainActor
public final class SimplifiedStoreKitService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = SimplifiedStoreKitService()
    
    // MARK: - Published Properties (Compatible with existing UI)
    
    @Published public var hasActiveSubscription: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var products: [Product] = []
    
    // MARK: - Implementation Selection
    
    private let simplePurchaseManager: SimplePurchaseManager
    private let simpleEntitlementManager: SimpleEntitlementManager
    private let legacyPurchaseManager: PurchaseManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize simple implementation
        simpleEntitlementManager = SimpleEntitlementManager.shared
        simplePurchaseManager = SimplePurchaseManager(entitlementManager: simpleEntitlementManager)
        
        // Initialize legacy if needed
        if !StoreKitFeatureFlags.useSimplifiedImplementation {
            legacyPurchaseManager = PurchaseManager.shared
        } else {
            legacyPurchaseManager = nil
        }
        
        setupBindings()
        
        Logger.info("🚀 StoreKit Service initialized with \(StoreKitFeatureFlags.useSimplifiedImplementation ? "SIMPLIFIED" : "LEGACY") implementation")
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            // Bind to simple implementation
            simplePurchaseManager.$purchasedProductIDs
                .map { !$0.isEmpty }
                .assign(to: &$hasActiveSubscription)
            
            simplePurchaseManager.$isLoading
                .assign(to: &$isLoading)
            
            simplePurchaseManager.$products
                .assign(to: &$products)
        } else {
            // Bind to legacy implementation
            legacyPurchaseManager?.$isPurchasing
                .map { $0 }
                .assign(to: &$isLoading)
        }
    }
    
    // MARK: - Public API (Compatible with existing code)
    
    /// Purchase a product
    public func purchase(productID: String) async -> Bool {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            return await simplePurchaseManager.purchase(productID: productID)
        } else {
            do {
                let result = await legacyPurchaseManager?.purchase(productID: productID) ?? .failed(.unknownError)
                switch result {
                case .success:
                    return true
                default:
                    return false
                }
            }
        }
    }
    
    /// Restore purchases
    public func restorePurchases() async {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            await simplePurchaseManager.restorePurchases()
        } else {
            _ = await legacyPurchaseManager?.restorePurchases()
        }
    }
    
    /// Check if user has access to a feature
    public func hasAccess(to feature: FeatureType) -> Bool {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            return simpleEntitlementManager.hasAccess(to: feature)
        } else {
            return FeatureGateService.shared.hasAccessBool(to: feature)
        }
    }
    
    /// Get current subscription tier
    public var currentTier: SubscriptionTier {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            return simpleEntitlementManager.hasPremium ? .premium : .none
        } else {
            return SubscriptionStateManager.shared.currentTier
        }
    }
    
    /// Refresh subscription state
    public func refreshState() async {
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            await simplePurchaseManager.updatePurchasedProducts()
        } else {
            await SubscriptionStateManager.shared.refreshState()
        }
    }
    
    // MARK: - Migration Helpers
    
    /// Migrate from old to new implementation
    public func migrateToSimplified() async {
        Logger.info("🔄 Starting migration to simplified StoreKit implementation...")
        
        // Enable feature flag
        StoreKitFeatureFlags.enableSimplified()
        
        // Refresh state with new implementation
        await simplePurchaseManager.loadProducts()
        await simplePurchaseManager.updatePurchasedProducts()
        
        Logger.info("✅ Migration to simplified implementation complete")
    }
    
    /// Rollback to legacy implementation
    public func rollbackToLegacy() {
        Logger.info("⏪ Rolling back to legacy StoreKit implementation...")
        
        // Disable feature flag
        StoreKitFeatureFlags.disableSimplified()
        
        // Re-setup bindings
        setupBindings()
        
        Logger.info("✅ Rollback to legacy implementation complete")
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    public func debugPrintState() {
        print("""
        📱 StoreKit Service State:
        - Implementation: \(StoreKitFeatureFlags.useSimplifiedImplementation ? "SIMPLIFIED" : "LEGACY")
        - Has Subscription: \(hasActiveSubscription)
        - Products Loaded: \(products.count)
        - Is Loading: \(isLoading)
        """)
        
        if StoreKitFeatureFlags.useSimplifiedImplementation {
            simpleEntitlementManager.debugPrintState()
        }
    }
    #endif
}