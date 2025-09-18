/**
 * FunnelEvent.swift
 * Growth App Analytics Event Models
 *
 * Comprehensive event taxonomy for paywall conversion funnel tracking
 * and user behavior analysis across the subscription journey.
 */

import Foundation
import UIKit
import Charts

// MARK: - Type Dependencies
// PaywallContext is defined in ../PaywallContext.swift
// RevenueSource and AnyCodable are defined in ./AnalyticsModels.swift
// These types must be in the same module (Growth target) for visibility

// MARK: - Funnel Step Tracking

/// Detailed funnel steps for conversion tracking
public enum FunnelStep: String, CaseIterable, Codable, Equatable, Plottable {
    public var primitivePlottable: String {
        return self.rawValue
    }
    case paywallImpression = "paywall_impression"
    case featureHighlightView = "feature_highlight_view"
    case pricingOptionView = "pricing_option_view"
    case pricingOptionSelected = "pricing_option_selected"
    case purchaseInitiated = "purchase_initiated"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseCancelled = "purchase_cancelled"
    case paywallDismissed = "paywall_dismissed"
    case exitIntentDetected = "exit_intent_detected"
    case retentionOfferShown = "retention_offer_shown"
    case retentionOfferAccepted = "retention_offer_accepted"
    case retentionOfferDeclined = "retention_offer_declined"
    case socialProofViewed = "social_proof_viewed"
    case featureDetailViewed = "feature_detail_viewed"
    case restorePurchaseAttempted = "restore_purchase_attempted"
    case restorePurchaseCompleted = "restore_purchase_completed"
    
    /// Display name for analytics dashboards
    public var displayName: String {
        switch self {
        case .paywallImpression: return "Paywall Impression"
        case .featureHighlightView: return "Feature Highlight Viewed"
        case .pricingOptionView: return "Pricing Options Viewed"
        case .pricingOptionSelected: return "Pricing Option Selected"
        case .purchaseInitiated: return "Purchase Initiated"
        case .purchaseCompleted: return "Purchase Completed"
        case .purchaseFailed: return "Purchase Failed"
        case .purchaseCancelled: return "Purchase Cancelled"
        case .paywallDismissed: return "Paywall Dismissed"
        case .exitIntentDetected: return "Exit Intent Detected"
        case .retentionOfferShown: return "Retention Offer Shown"
        case .retentionOfferAccepted: return "Retention Offer Accepted"
        case .retentionOfferDeclined: return "Retention Offer Declined"
        case .socialProofViewed: return "Social Proof Viewed"
        case .featureDetailViewed: return "Feature Detail Viewed"
        case .restorePurchaseAttempted: return "Restore Purchase Attempted"
        case .restorePurchaseCompleted: return "Restore Purchase Completed"
        }
    }
    
    /// Funnel position for conversion analysis
    public var funnelPosition: Int {
        switch self {
        case .paywallImpression: return 1
        case .featureHighlightView: return 2
        case .pricingOptionView: return 3
        case .pricingOptionSelected: return 4
        case .purchaseInitiated: return 5
        case .purchaseCompleted: return 6
        case .purchaseFailed, .purchaseCancelled: return 6
        case .paywallDismissed, .exitIntentDetected: return 99 // Exit events
        case .retentionOfferShown: return 7
        case .retentionOfferAccepted: return 8
        case .retentionOfferDeclined: return 8
        case .socialProofViewed, .featureDetailViewed: return 2 // Engagement events
        case .restorePurchaseAttempted, .restorePurchaseCompleted: return 5 // Alternative path
        }
    }
}

// MARK: - Conversion Events

/// Specific conversion events for revenue tracking
public enum ConversionEvent: String, CaseIterable, Codable {
    case subscriptionPurchased = "subscription_purchased"
    case subscriptionRestored = "subscription_restored"
    case subscriptionUpgraded = "subscription_upgraded"
    case subscriptionDowngraded = "subscription_downgraded"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionRefunded = "subscription_refunded"
    case trialStarted = "trial_started"
    case trialConverted = "trial_converted"
    case trialExpired = "trial_expired"
    case featureGateInteraction = "feature_gate_interaction"
    
    /// Revenue impact indicator
    public var revenueImpact: RevenueImpact {
        switch self {
        case .subscriptionPurchased, .subscriptionRestored, .trialConverted:
            return .positive
        case .subscriptionUpgraded:
            return .increase
        case .subscriptionDowngraded:
            return .decrease
        case .subscriptionCancelled, .subscriptionRefunded, .trialExpired:
            return .negative
        case .trialStarted, .featureGateInteraction:
            return .neutral
        }
    }
}

/// Revenue impact classification
public enum RevenueImpact: String, Codable {
    case positive = "positive"     // New revenue
    case increase = "increase"     // Revenue increase
    case decrease = "decrease"     // Revenue decrease
    case negative = "negative"     // Revenue loss
    case neutral = "neutral"       // No immediate impact
}

// MARK: - User Cohorts

/// User segmentation for cohort analysis
public enum UserCohort: String, CaseIterable, Codable {
    case newUser = "new_user"
    case returningFreeUser = "returning_free_user"
    case trialUser = "trial_user"
    case expiredSubscriber = "expired_subscriber"
    case activePowerUser = "active_power_user"
    case cancelledSubscriber = "cancelled_subscriber"
    case reactivatedUser = "reactivated_user"
    
    /// Display name for analytics
    public var displayName: String {
        switch self {
        case .newUser: return "New User"
        case .returningFreeUser: return "Returning Free User"
        case .trialUser: return "Trial User"
        case .expiredSubscriber: return "Expired Subscriber"
        case .activePowerUser: return "Active Power User"
        case .cancelledSubscriber: return "Cancelled Subscriber"
        case .reactivatedUser: return "Reactivated User"
        }
    }
    
    /// Expected conversion rate range for benchmarking
    public var expectedConversionRange: ClosedRange<Double> {
        switch self {
        case .newUser: return 0.02...0.05          // 2-5%
        case .returningFreeUser: return 0.03...0.08 // 3-8%
        case .trialUser: return 0.15...0.35         // 15-35%
        case .expiredSubscriber: return 0.05...0.15  // 5-15%
        case .activePowerUser: return 0.08...0.20    // 8-20%
        case .cancelledSubscriber: return 0.01...0.05 // 1-5%
        case .reactivatedUser: return 0.10...0.25    // 10-25%
        }
    }
}

// MARK: - Revenue Attribution
// RevenueSource is defined in AnalyticsModels.swift

// MARK: - Funnel Event Data Model

/// Comprehensive funnel event for analytics tracking
public struct FunnelEvent {
    public let id: String
    public let userId: String
    public let sessionId: String
    public let step: FunnelStep
    public let timestamp: Date
    
    // Context information
    public let paywallContext: PaywallContext
    public let userCohort: UserCohort
    public let revenueSource: RevenueSource
    
    // Experiment assignments
    public let experimentAssignments: [String: String]
    
    // Device and app information
    public let deviceInfo: DeviceInfo
    public let appVersion: String
    
    // Event-specific metadata
    public let metadata: [String: AnyCodable]
    
    public init(
        userId: String,
        sessionId: String,
        step: FunnelStep,
        paywallContext: PaywallContext,
        userCohort: UserCohort,
        revenueSource: RevenueSource,
        experimentAssignments: [String: String] = [:],
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.sessionId = sessionId
        self.step = step
        self.timestamp = Date()
        self.paywallContext = paywallContext
        self.userCohort = userCohort
        self.revenueSource = revenueSource
        self.experimentAssignments = experimentAssignments
        self.deviceInfo = DeviceInfo.current
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        self.metadata = metadata
    }
}

// MARK: - Device Information

/// Device information for analytics segmentation
public struct DeviceInfo: Codable {
    public let platform: String
    public let osVersion: String
    public let deviceModel: String
    public let screenSize: CGSize
    public let locale: String
    public let timezone: String
    
    public static var current: DeviceInfo {
        return DeviceInfo(
            platform: "ios",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model,
            screenSize: UIScreen.main.bounds.size,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }
}

// MARK: - Type-safe Any wrapper for Codable metadata
// AnyCodable is defined in AnalyticsModels.swift

// MARK: - Codable Conformance

extension FunnelEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, userId, sessionId, step, timestamp
        case paywallContext, userCohort, revenueSource
        case experimentAssignments, deviceInfo, appVersion, metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        step = try container.decode(FunnelStep.self, forKey: .step)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode PaywallContext directly since it's Codable
        paywallContext = try container.decode(PaywallContext.self, forKey: .paywallContext)
        
        userCohort = try container.decode(UserCohort.self, forKey: .userCohort)
        revenueSource = try container.decode(RevenueSource.self, forKey: .revenueSource)
        experimentAssignments = try container.decode([String: String].self, forKey: .experimentAssignments)
        deviceInfo = try container.decode(DeviceInfo.self, forKey: .deviceInfo)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(step, forKey: .step)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode PaywallContext directly since it's Codable
        try container.encode(paywallContext, forKey: .paywallContext)
        
        try container.encode(userCohort, forKey: .userCohort)
        try container.encode(revenueSource, forKey: .revenueSource)
        try container.encode(experimentAssignments, forKey: .experimentAssignments)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(metadata, forKey: .metadata)
    }
}

// PaywallContext extensions moved to PaywallContext.swift to avoid duplication