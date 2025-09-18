/**
 * AnalyticsModels.swift
 * Growth App Analytics Models
 *
 * Shared models and data structures for analytics and metrics reporting.
 */

import Foundation

// MARK: - Date Range Models

/// Date range for analytics queries
public struct AnalyticsDateRange {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public static func lastNDays(_ days: Int) -> AnalyticsDateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return AnalyticsDateRange(startDate: startDate, endDate: endDate)
    }
    
    public static func thisMonth() -> AnalyticsDateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return AnalyticsDateRange(startDate: startOfMonth, endDate: now)
    }
}

// MARK: - Trend Direction

/// Trend direction for metrics
public enum TrendDirection: String, CaseIterable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
    
    public var iconName: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    public var color: String {
        switch self {
        case .increasing: return "green"
        case .decreasing: return "red"
        case .stable: return "gray"
        }
    }
}

// MARK: - Subscription Types
// Note: PaywallContext is defined in Growth/Core/Models/PaywallContext.swift
// Note: SubscriptionTier and SubscriptionDuration are defined in Growth/Core/Models/SubscriptionTier.swift

// MARK: - Revenue Source

/// Revenue source tracking for attribution - comprehensive list
public enum RevenueSource: String, CaseIterable, Codable, Equatable {
    // Feature gates
    case featureGateAICoach = "feature_gate_ai_coach"
    case featureGateCustomRoutines = "feature_gate_custom_routines"
    case featureGateProgressTracking = "feature_gate_progress_tracking"
    case featureGateAdvancedAnalytics = "feature_gate_advanced_analytics"
    case featureGateLiveActivities = "feature_gate_live_activities"
    
    // Paywall contexts
    case generalPaywall = "general_paywall"
    case onboardingPaywall = "onboarding_paywall"
    case featurePaywall = "feature_paywall"
    case settingsPaywall = "settings_paywall"
    case exitIntentPaywall = "exit_intent_paywall"
    case sessionLimitPaywall = "session_limit_paywall"
    
    // User actions
    case settingsUpgrade = "settings_upgrade"
    case onboardingFlow = "onboarding_flow"
    case sessionCompletion = "session_completion"
    case directPurchase = "direct_purchase"
    case reactivation = "reactivation"
    case upgrade = "upgrade"
    
    // External triggers
    case pushNotification = "push_notification"
    case appLaunch = "app_launch"
    case marketingCampaign = "marketing_campaign"
    
    /// Feature associated with this revenue source
    public var associatedFeature: String? {
        switch self {
        case .featureGateAICoach: return "aiCoach"
        case .featureGateCustomRoutines: return "customRoutines"
        case .featureGateProgressTracking: return "progressTracking"
        case .featureGateAdvancedAnalytics: return "advancedAnalytics"
        case .featureGateLiveActivities: return "liveActivities"
        case .featurePaywall: return "premium_features"
        case .sessionLimitPaywall: return "unlimited_sessions"
        case .upgrade: return "plan_upgrade"
        default: return nil
        }
    }
    
    /// Attribution weight for multi-touch attribution
    public var attributionWeight: Double {
        switch self {
        case .featureGateAICoach, .featureGateCustomRoutines: 
            return 1.0  // Direct feature desire
        case .featureGateProgressTracking, .featureGateAdvancedAnalytics: 
            return 0.8  // Strong intent
        case .sessionCompletion: 
            return 0.9  // High engagement moment
        case .onboardingFlow, .onboardingPaywall: 
            return 0.7  // Early adoption
        case .settingsUpgrade, .settingsPaywall: 
            return 0.6  // Considered decision
        case .exitIntentPaywall: 
            return 0.8  // Recovery moment
        case .reactivation: 
            return 1.1  // Win-back
        case .upgrade: 
            return 1.3  // Expansion revenue
        case .generalPaywall, .appLaunch: 
            return 0.4  // Broad exposure
        case .pushNotification, .marketingCampaign: 
            return 0.3  // External trigger
        default: 
            return 0.5
        }
    }
}

// MARK: - Type-Erased Codable

/// Type-erased Codable container for metadata
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init<T>(_ value: T?) {
        self.value = value ?? NSNull()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else if container.decodeNil() {
            self.value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case let v as [String: AnyCodable]:
            try container.encode(v)
        case let v as [AnyCodable]:
            try container.encode(v)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}