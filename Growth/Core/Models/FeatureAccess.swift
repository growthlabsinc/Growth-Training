/**
 * FeatureAccess.swift
 * Simplified Feature Access Model for StoreKit 2
 * 
 * Lightweight feature access model to support legacy code during transition.
 */

import Foundation
import SwiftUI

// MARK: - Entitlement Provider Protocol

/// Protocol for checking premium entitlements
/// This avoids direct dependency on SimplifiedEntitlementManager
public protocol EntitlementProvider {
    var hasPremium: Bool { get }
}

/// Default entitlement provider that checks UserDefaults directly
/// This can be used in non-MainActor contexts
public class DefaultEntitlementProvider: EntitlementProvider {
    private let userDefaults: UserDefaults
    
    public init() {
        self.userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") ?? UserDefaults.standard
    }
    
    public var hasPremium: Bool {
        return userDefaults.bool(forKey: "hasPremium")
    }
}

/// Simplified feature access status
public enum FeatureAccess {
    case granted
    case denied(reason: DenialReason)
    case limited(usage: FeatureUsage)
    
    /// Whether access is granted
    public var isGranted: Bool {
        switch self {
        case .granted:
            return true
        case .denied, .limited:
            return false
        }
    }
    
    /// Whether this is a limited access (e.g., trial or usage-limited)
    public var isLimited: Bool {
        switch self {
        case .limited:
            return true
        default:
            return false
        }
    }
}

/// Reason for denial
public enum DenialReason: String, Equatable {
    case noSubscription = "no_subscription"
    case insufficientTier = "insufficient_tier"
    case trialExpired = "trial_expired"
    case usageLimitReached = "usage_limit_reached"
    case featureNotAvailable = "feature_not_available"
    
    public var localizedDescription: String {
        switch self {
        case .noSubscription:
            return "Premium subscription required"
        case .insufficientTier:
            return "Upgrade your subscription to access this feature"
        case .trialExpired:
            return "Your trial has expired"
        case .usageLimitReached:
            return "You've reached the usage limit for this feature"
        case .featureNotAvailable:
            return "This feature is not available"
        }
    }
    
    public var suggestedAction: String {
        switch self {
        case .noSubscription:
            return "Get Premium"
        case .insufficientTier:
            return "Upgrade Plan"
        case .trialExpired:
            return "Subscribe Now"
        case .usageLimitReached:
            return "Upgrade for Unlimited"
        case .featureNotAvailable:
            return "Learn More"
        }
    }
}

/// Feature usage information
public struct FeatureUsage: Equatable {
    public let feature: String  // Using String instead of FeatureType to avoid dependency
    public let currentUsage: Int
    public let maxUsage: Int
    public let resetDate: Date?
    public let isPermanent: Bool  // Whether the usage limit is permanent or resets
    
    public init(
        feature: String,
        currentUsage: Int,
        maxUsage: Int,
        resetDate: Date? = nil,
        isPermanent: Bool = false
    ) {
        self.feature = feature
        self.currentUsage = currentUsage
        self.maxUsage = maxUsage
        self.resetDate = resetDate
        self.isPermanent = isPermanent
    }
    
    public var isAtLimit: Bool {
        return currentUsage >= maxUsage
    }
    
    public var remaining: Int {
        return max(0, maxUsage - currentUsage)
    }
    
    public var usagePercentage: Double {
        guard maxUsage > 0 else { return 0 }
        return Double(currentUsage) / Double(maxUsage)
    }
    
    public var usageMessage: String {
        if isAtLimit {
            return "You've reached the limit for this feature"
        } else if usagePercentage > 0.8 {
            return "You have \(remaining) uses remaining"
        } else if usagePercentage > 0.5 {
            return "\(currentUsage) of \(maxUsage) uses"
        } else {
            return ""
        }
    }
}

// MARK: - Equatable Conformance

extension FeatureAccess: Equatable {
    public static func == (lhs: FeatureAccess, rhs: FeatureAccess) -> Bool {
        switch (lhs, rhs) {
        case (.granted, .granted):
            return true
        case (.denied(let reason1), .denied(let reason2)):
            return reason1 == reason2
        case (.limited(let usage1), .limited(let usage2)):
            return usage1 == usage2  // FeatureUsage already has Equatable
        default:
            return false
        }
    }
}

// MARK: - Bridge to SimplifiedEntitlementManager

extension FeatureAccess {
    /// Create FeatureAccess from feature name with entitlement provider
    /// This is the proper way to check feature access with dependency injection
    public static func from(feature: String, using provider: EntitlementProvider) -> FeatureAccess {
        // All premium features require premium subscription in the simplified model
        if provider.hasPremium {
            return .granted
        } else {
            return .denied(reason: .noSubscription)
        }
    }
    
    /// Create FeatureAccess from feature enum with entitlement provider
    /// Note: Requires FeatureType to be in scope
    public static func from<T>(feature: T, using provider: EntitlementProvider) -> FeatureAccess where T: RawRepresentable, T.RawValue == String {
        return from(feature: feature.rawValue, using: provider)
    }
    
    /// Create FeatureAccess from feature name using default entitlement checking
    /// This is a convenience method for property wrappers and annotations
    /// In production, this would connect to a shared entitlement manager instance
    public static func from(feature: String) -> FeatureAccess {
        // For property wrappers that can't receive dependency injection,
        // we need to check entitlements through a different mechanism
        // This could use UserDefaults directly or a shared singleton
        let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") ?? UserDefaults.standard
        let hasPremium = userDefaults.bool(forKey: "hasPremium")
        
        return hasPremium ? .granted : .denied(reason: .noSubscription)
    }
}