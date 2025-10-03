/**
 * SubscriptionTier.swift
 * Growth App Subscription Tier Definitions
 *
 * Defines the subscription tier enumeration and associated feature access levels
 * for the Growth app subscription system.
 */

import Foundation

// MARK: - Subscription Tier Enumeration

/// Represents the available subscription tiers in the Growth app
public enum SubscriptionTier: String, CaseIterable, Codable {
    case none = "none"
    case premium = "premium" // Single premium tier for all paid features
    
    /// Display name for the subscription tier
    public var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .premium:
            return "Premium"
        }
    }
    
    /// Tier hierarchy level for upgrade/downgrade logic
    public var hierarchyLevel: Int {
        switch self {
        case .none:
            return 0
        case .premium:
            return 1
        }
    }
    
    /// Priority level for comparison (alias for hierarchyLevel)
    public var priority: Int {
        hierarchyLevel
    }
    
    /// Available subscription durations and pricing
    public var availableSubscriptions: [SubscriptionDuration] {
        switch self {
        case .none:
            return []
        case .premium:
            return SubscriptionDuration.allCases
        }
    }
    
    /// Feature entitlements for this tier
    public var entitlements: FeatureEntitlements {
        switch self {
        case .none:
            return FeatureEntitlements(
                availableFeatures: [.quickTimer, .articles]
            )
        case .premium:
            return FeatureEntitlements(
                availableFeatures: Set(FeatureType.allCases) // All features
            )
        }
    }
    
    /// Check if this tier can upgrade to another tier
    public func canUpgradeTo(_ targetTier: SubscriptionTier) -> Bool {
        return targetTier.hierarchyLevel > self.hierarchyLevel
    }
    
    /// Check if this tier can downgrade to another tier
    public func canDowngradeTo(_ targetTier: SubscriptionTier) -> Bool {
        return targetTier.hierarchyLevel < self.hierarchyLevel
    }
    
    /// Creates a SubscriptionTier from a product ID
    public static func from(productId: String) -> SubscriptionTier {
        // Map product IDs to tiers based on the subscription specification
        switch productId {
        case "com.growthlabs.growthmethod.subscription.premium.weekly",
             "com.growthlabs.growthmethod.subscription.premium.quarterly",
             "com.growthlabs.growthmethod.subscription.premium.yearly":
            return .premium
            
        default:
            return .none
        }
    }
}

// MARK: - Subscription Duration

/// Available subscription duration options
public enum SubscriptionDuration: String, CaseIterable, Codable {
    case weekly = "weekly"
    case quarterly = "quarterly" 
    case yearly = "yearly"
    
    /// Display name for the duration
    public var displayName: String {
        switch self {
        case .weekly: return "1 Week"
        case .quarterly: return "3 Months"
        case .yearly: return "12 Months"
        }
    }
    
    /// Price in USD (hardcoded for display, but StoreKit will provide actual prices)
    public var price: String {
        switch self {
        case .weekly: return "$4.99"    // Updated to match App Store Connect
        case .quarterly: return "$29.99" // Updated to match App Store Connect
        case .yearly: return "$49.99"   // Updated to match App Store Connect
        }
    }
    
    /// Price in cents for StoreKit (hardcoded for reference, but StoreKit will provide actual prices)
    public var priceCents: Int {
        switch self {
        case .weekly: return 499     // Updated to match App Store Connect
        case .quarterly: return 2999 // Updated to match App Store Connect
        case .yearly: return 4999    // Updated to match App Store Connect
        }
    }
    
    /// Product ID for App Store Connect
    public var productId: String {
        return "com.growthlabs.growthmethod.subscription.premium.\(rawValue)"
    }
}

// MARK: - Feature Entitlements

/// Defines the specific feature access permissions for each subscription tier
public struct FeatureEntitlements: Codable, Equatable {
    public let availableFeatures: Set<FeatureType>
    
    public init(availableFeatures: Set<FeatureType>) {
        self.availableFeatures = availableFeatures
    }
    
    /// Check if a specific feature is available for this entitlement
    public func hasFeature(_ feature: FeatureType) -> Bool {
        return availableFeatures.contains(feature)
    }
}

// MARK: - Supporting Enumerations

/// Available feature types for entitlement checking
public enum FeatureType: String, CaseIterable, Codable, Hashable {
    // Free Features
    case quickTimer = "quick_timer"
    case articles = "articles"
    
    // Premium Features (All paid tiers)
    case customRoutines = "custom_routines"
    case advancedTimer = "advanced_timer"
    case progressTracking = "progress_tracking"
    case advancedAnalytics = "advanced_analytics"
    case goalSetting = "goal_setting"
    case aiCoach = "ai_coach"
    case liveActivities = "live_activities"
    case prioritySupport = "priority_support"
    case unlimitedBackup = "unlimited_backup"
    case advancedCustomization = "advanced_customization"
    case expertInsights = "expert_insights"
    case premiumContent = "premium_content"
    
    /// Display name for the feature
    public var displayName: String {
        switch self {
        case .quickTimer: return "Quick Timer"
        case .articles: return "Articles"
        case .customRoutines: return "Custom Routines"
        case .advancedTimer: return "Advanced Timer"
        case .progressTracking: return "Progress Tracking"
        case .advancedAnalytics: return "Advanced Analytics"
        case .goalSetting: return "Goal Setting"
        case .aiCoach: return "AI Coach"
        case .liveActivities: return "Live Activities"
        case .prioritySupport: return "Priority Support"
        case .unlimitedBackup: return "Unlimited Backup"
        case .advancedCustomization: return "Advanced Customization"
        case .expertInsights: return "Expert Insights"
        case .premiumContent: return "Premium Content"
        }
    }
    
    /// Whether this feature is available in the free tier
    public var isFreeFeature: Bool {
        switch self {
        case .quickTimer, .articles:
            return true
        default:
            return false
        }
    }
}

