/**
 * SubscriptionProduct.swift
 * Growth App Subscription Product Configuration
 *
 * Defines the App Store Connect subscription product configuration
 * and provides mapping between App Store product IDs and subscription tiers.
 * Updated for Story 23.4 2-tier subscription model.
 */

import Foundation
import StoreKit

// MARK: - Subscription Product Configuration

/// Represents a configured App Store Connect subscription product
public struct SubscriptionProduct: Codable, Identifiable, Hashable {
    public let id: String // App Store Product ID
    public let tier: SubscriptionTier
    public let duration: SubscriptionDuration
    public let priceCents: Int
    public let displayName: String
    public let description: String
    public let localizedTitle: String
    public let localizedDescription: String
    public let hasTrialOffer: Bool // Whether this product includes a free trial
    
    /// Initialize from App Store Connect configuration
    public init(
        productID: String,
        tier: SubscriptionTier,
        duration: SubscriptionDuration,
        priceCents: Int,
        displayName: String,
        description: String,
        localizedTitle: String,
        localizedDescription: String,
        hasTrialOffer: Bool = false
    ) {
        self.id = productID
        self.tier = tier
        self.duration = duration
        self.priceCents = priceCents
        self.displayName = displayName
        self.description = description
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.hasTrialOffer = hasTrialOffer
    }
    
    /// Convenience init from duration (uses new product ID structure)
    public init(duration: SubscriptionDuration) {
        self.id = duration.productId
        self.tier = .premium // All paid subscriptions are premium
        self.duration = duration
        self.priceCents = duration.priceCents
        self.displayName = "Growth Premium (\(duration.displayName))"
        self.description = "Premium access to all features"
        self.localizedTitle = "Growth Premium (\(duration.displayName))"
        self.localizedDescription = "Premium access to all features including AI Coach, custom routines, and advanced analytics"
        self.hasTrialOffer = duration == .yearly // Only annual plan has trial
    }
    
    /// Get formatted price string
    public var formattedPrice: String {
        return String(format: "$%.2f", Double(priceCents) / 100.0)
    }
    
    /// Check if this product offers savings compared to weekly
    public var savingsPercentage: Int {
        let weeklyPriceCents = SubscriptionDuration.weekly.priceCents
        let weeklyEquivalent: Int
        
        switch duration {
        case .weekly:
            return 0
        case .quarterly:
            weeklyEquivalent = weeklyPriceCents * 13 // ~3 months
        case .yearly:
            weeklyEquivalent = weeklyPriceCents * 52 // ~12 months
        }
        
        let savings = Double(weeklyEquivalent - priceCents) / Double(weeklyEquivalent)
        return max(0, Int(savings * 100))
    }
}

// Note: SubscriptionDuration is now defined in SubscriptionTier.swift

// MARK: - Product ID Constants

/// App Store Connect product identifiers - Only 3 products as configured
public enum SubscriptionProductIDs {
    // Premium tier - the only tier with actual products in App Store Connect
    public static let premiumWeekly = "com.growthlabs.growthmethod.subscription.premium.weekly"
    public static let premiumQuarterly = "com.growthlabs.growthmethod.subscription.premium.quarterly"
    public static let premiumYearly = "com.growthlabs.growthmethod.subscription.premium.yearly"
    
    // Aliases for backward compatibility
    public static let monthly = "com.growthlabs.growthmethod.premium.monthly"
    public static let quarterly = premiumQuarterly
    public static let annual = premiumYearly
    public static let all: Set<String> = [premiumWeekly, premiumQuarterly, premiumYearly]
    
    /// All available product IDs - only 3 as per App Store Connect
    public static let allProductIDs: Set<String> = [
        premiumWeekly,
        premiumQuarterly,
        premiumYearly
    ]
    
    /// Map product ID to duration
    public static func duration(for productId: String) -> SubscriptionDuration? {
        if productId.contains("monthly") {
            return .quarterly  // Map monthly to quarterly since monthly doesn't exist
        } else if productId.contains("yearly") || productId.contains("annual") {
            return .yearly
        } else if productId.contains("weekly") {
            return .weekly
        } else if productId.contains("quarterly") {
            return .quarterly
        }
        return nil
    }
    
    /// Map product ID to tier
    public static func tier(for productId: String) -> SubscriptionTier {
        // All paid subscriptions are premium tier
        if allProductIDs.contains(productId) {
            return .premium
        }
        return .none
    }
    
    /// Check if a product ID is a subscription
    public static func isSubscription(_ productId: String) -> Bool {
        return allProductIDs.contains(productId) || all.contains(productId)
    }
}

// MARK: - Subscription Product Catalog

/// Central catalog of all available subscription products
public struct SubscriptionProductCatalog {
    
    /// All configured subscription products matching App Store Connect - Only 3 products
    public static let products: [SubscriptionProduct] = [
        // Premium Weekly
        SubscriptionProduct(
            productID: SubscriptionProductIDs.premiumWeekly,
            tier: .premium,
            duration: .weekly,
            priceCents: 499,  // $4.99
            displayName: "Growth Premium - Weekly",
            description: "Unlock all premium features. Billed weekly.",
            localizedTitle: "Growth Premium - Weekly",
            localizedDescription: "Unlock all premium features including AI Coach, custom routines, and advanced analytics. Automatically renews weekly.",
            hasTrialOffer: false
        ),
        
        // Premium Quarterly
        SubscriptionProduct(
            productID: SubscriptionProductIDs.premiumQuarterly,
            tier: .premium,
            duration: .quarterly,
            priceCents: 2999,  // $29.99
            displayName: "Growth Premium - 3 Months",
            description: "Save 40% with quarterly billing",
            localizedTitle: "Growth Premium - 3 Months",
            localizedDescription: "Get 3 months of unlimited access to all premium features. Best value for regular users. Automatically renews every 3 months.",
            hasTrialOffer: false
        ),
        
        // Premium Yearly
        SubscriptionProduct(
            productID: SubscriptionProductIDs.premiumYearly,
            tier: .premium,
            duration: .yearly,
            priceCents: 4999,  // $49.99
            displayName: "Growth Premium - Annual",
            description: "Best value - Save 75%",
            localizedTitle: "Growth Premium - Annual",
            localizedDescription: "12 months of unlimited premium access. Includes 7-day free trial. Automatically renews yearly.",
            hasTrialOffer: true
        )
    ]
    
    /// Get product by tier and duration
    public static func product(for tier: SubscriptionTier, duration: SubscriptionDuration) -> SubscriptionProduct? {
        return products.first { $0.tier == tier && $0.duration == duration }
    }
    
    /// Get product by product ID
    public static func product(for productId: String) -> SubscriptionProduct? {
        return products.first { $0.id == productId }
    }
    
    /// Get all products for a specific tier
    public static func products(for tier: SubscriptionTier) -> [SubscriptionProduct] {
        return products.filter { $0.tier == tier }
    }
    
    /// Get all premium products (new system only has premium)
    public static var premiumProducts: [SubscriptionProduct] {
        return products(for: .premium)
    }
    
    /// Get products with trial offers
    public static var productsWithTrials: [SubscriptionProduct] {
        return products.filter { $0.hasTrialOffer }
    }
    
    /// Check if a specific duration has trial offer
    public static func hasTrialOffer(for duration: SubscriptionDuration) -> Bool {
        return product(for: .premium, duration: duration)?.hasTrialOffer ?? false
    }
    
    /// Validate that all products have valid configurations
    public static func validateCatalog() -> Bool {
        // Ensure we have exactly 3 products
        guard products.count == 3 else {
            return false
        }
        
        for product in products {
            // Check product ID format
            guard product.id.contains("com.growthlabs.growthmethod.subscription.premium") else {
                return false
            }
            
            // Check price is positive
            guard product.priceCents > 0 else {
                return false
            }
            
            // Check display names are not empty
            guard !product.displayName.isEmpty && !product.description.isEmpty else {
                return false
            }
        }
        
        // Verify we have one of each duration
        let durations = Set(products.map { $0.duration })
        guard durations == Set(SubscriptionDuration.allCases) else {
            return false
        }
        
        return true
    }
}

// MARK: - Migration Support

/// Support for migrating from old subscription system
public struct SubscriptionMigration {
    
    /// Map old product IDs to new system - Maps to the 3 actual products
    public static func migrateProductId(_ oldProductId: String) -> String? {
        switch oldProductId {
        case "com.growthlabs.growthmethod.basic_monthly",
             "com.growthlabs.growthmethod.subscription.basic.monthly":
            return SubscriptionProductIDs.premiumWeekly  // Map basic monthly to weekly
        case "com.growthlabs.growthmethod.basic_yearly",
             "com.growthlabs.growthmethod.subscription.basic.yearly":
            return SubscriptionProductIDs.premiumYearly
        case "com.growthlabs.growthmethod.premium_monthly",
             "com.growthlabs.growthmethod.subscription.premium.monthly",
             "com.growthlabs.growthmethod.elite_monthly",
             "com.growthlabs.growthmethod.subscription.elite.monthly":
            return SubscriptionProductIDs.premiumQuarterly  // Map all monthly to quarterly
        case "com.growthlabs.growthmethod.premium_yearly",
             "com.growthlabs.growthmethod.subscription.premium.yearly",
             "com.growthlabs.growthmethod.elite_yearly",
             "com.growthlabs.growthmethod.subscription.elite.yearly":
            return SubscriptionProductIDs.premiumYearly
        default:
            return nil
        }
    }
    
    /// Map old tiers to new system
    public static func migrateTier(_ oldTierString: String) -> SubscriptionTier {
        switch oldTierString.lowercased() {
        case "basic", "premium", "elite":
            return .premium
        default:
            return .none
        }
    }
}