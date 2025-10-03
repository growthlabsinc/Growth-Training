/**
 * ChurnPreventionModels.swift
 * Growth App Churn Prevention Models
 *
 * Comprehensive models for churn risk assessment, retention interventions,
 * personalized offers, and winback campaigns.
 */

import Foundation

// MARK: - Churn Risk Models

/// Comprehensive churn risk score for a user
public struct ChurnRiskScore: Codable {
    public let id: String
    public let userId: String
    public let overallRisk: Double // 0.0 to 1.0
    public let behaviorRisk: Double
    public let subscriptionRisk: Double
    public let engagementRisk: Double
    public let paymentRisk: Double
    public let mlPrediction: Double
    public let riskCategory: ChurnRiskCategory
    public let calculationDate: Date
    public let contributingFactors: [ChurnRiskFactor]
    
    public init(
        userId: String,
        overallRisk: Double,
        behaviorRisk: Double,
        subscriptionRisk: Double,
        engagementRisk: Double,
        paymentRisk: Double,
        mlPrediction: Double,
        riskCategory: ChurnRiskCategory,
        calculationDate: Date,
        contributingFactors: [ChurnRiskFactor]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.overallRisk = overallRisk
        self.behaviorRisk = behaviorRisk
        self.subscriptionRisk = subscriptionRisk
        self.engagementRisk = engagementRisk
        self.paymentRisk = paymentRisk
        self.mlPrediction = mlPrediction
        self.riskCategory = riskCategory
        self.calculationDate = calculationDate
        self.contributingFactors = contributingFactors
    }
}

/// Churn risk categories
public enum ChurnRiskCategory: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Individual risk factors contributing to churn
public enum ChurnRiskFactor: String, CaseIterable, Codable {
    case lowUsage = "low_usage"
    case subscriptionIssues = "subscription_issues"
    case lowEngagement = "low_engagement"
    case paymentProblems = "payment_problems"
    
    public var displayName: String {
        switch self {
        case .lowUsage: return "Low App Usage"
        case .subscriptionIssues: return "Subscription Issues"
        case .lowEngagement: return "Low Engagement"
        case .paymentProblems: return "Payment Problems"
        }
    }
    
    public var weight: Double {
        switch self {
        case .lowUsage: return 0.3
        case .subscriptionIssues: return 0.25
        case .lowEngagement: return 0.2
        case .paymentProblems: return 0.25
        }
    }
}

// MARK: - Data Collection Models

/// User behavior data for risk assessment
public struct UserBehaviorData {
    public let dailySessionCount: Double
    public let averageSessionDuration: TimeInterval
    public let featureEngagementScore: Double
    public let supportTicketCount: Int
    public let activityDeclineRate: Double
}

/// Subscription-related data for risk assessment
public struct SubscriptionData {
    public let subscriptionAge: TimeInterval
    public let previousCancellationAttempts: Int
    public let downgradeCount: Int
    public let failedPaymentCount: Int
    public let featureUtilizationRate: Double
}

/// User engagement data for risk assessment
public struct EngagementData {
    public let emailOpenRate: Double
    public let pushNotificationClickRate: Double
    public let inAppEngagementScore: Double
    public let communityParticipationScore: Double
}

/// Payment-related data for risk assessment
public struct PaymentData {
    public let paymentMethodExpiringWithinDays: Int
    public let failedPaymentCount: Int
    public let refundRequestCount: Int
    public let averagePaymentDelay: TimeInterval
}

// MARK: - Risk Configuration Models

/// Configuration for churn risk factors and thresholds
public struct ChurnRiskFactors {
    public let lowUsageThreshold: Double
    public let shortSessionThreshold: TimeInterval
    public let lowEngagementThreshold: Double
    public let highSupportTicketThreshold: Int
    public let activityDeclineThreshold: Double
    public let newSubscriberWindow: TimeInterval
    public let underutilizationThreshold: Double
    public let lowEmailEngagementThreshold: Double
    public let lowPushEngagementThreshold: Double
    public let lowInAppEngagementThreshold: Double
    public let lowCommunityEngagementThreshold: Double
    public let paymentDelayThreshold: TimeInterval
    public let riskWeights: RiskWeights
    
    public static let `default` = ChurnRiskFactors(
        lowUsageThreshold: 2.0, // sessions per day
        shortSessionThreshold: 300, // 5 minutes
        lowEngagementThreshold: 0.3,
        highSupportTicketThreshold: 3,
        activityDeclineThreshold: 0.3,
        newSubscriberWindow: 30 * 24 * 60 * 60, // 30 days
        underutilizationThreshold: 0.4,
        lowEmailEngagementThreshold: 0.2,
        lowPushEngagementThreshold: 0.1,
        lowInAppEngagementThreshold: 0.4,
        lowCommunityEngagementThreshold: 0.1,
        paymentDelayThreshold: 24 * 60 * 60, // 24 hours
        riskWeights: RiskWeights.default
    )
}

/// Weights for combining different risk factors
public struct RiskWeights {
    public let behavior: Double
    public let subscription: Double
    public let engagement: Double
    public let payment: Double
    public let mlPrediction: Double
    
    public static let `default` = RiskWeights(
        behavior: 0.25,
        subscription: 0.25,
        engagement: 0.2,
        payment: 0.15,
        mlPrediction: 0.15
    )
}

/// Thresholds for triggering interventions
public struct InterventionThresholds {
    public let minimumRiskForIntervention: Double
    public let criticalRiskThreshold: Double
    public let earlyWarningThreshold: Double
    public let maxInterventionsPerUser: Int
    public let interventionCooldownPeriod: TimeInterval
    
    public static let `default` = InterventionThresholds(
        minimumRiskForIntervention: 0.4,
        criticalRiskThreshold: 0.7,
        earlyWarningThreshold: 0.3,
        maxInterventionsPerUser: 3,
        interventionCooldownPeriod: 7 * 24 * 60 * 60 // 7 days
    )
}

// MARK: - Retention Intervention Models

/// Retention intervention strategies
public enum InterventionStrategy: String, CaseIterable, Codable {
    case featureEducation = "feature_education"
    case personalizedDiscount = "personalized_discount"
    case premiumSupport = "premium_support"
    case paymentAssistance = "payment_assistance"
    case communityInvitation = "community_invitation"
    case trialExtension = "trial_extension"
    case downgradePrevention = "downgrade_prevention"
    case pauseOffer = "pause_offer"
    
    public var displayName: String {
        switch self {
        case .featureEducation: return "Feature Education"
        case .personalizedDiscount: return "Personalized Discount"
        case .premiumSupport: return "Premium Support"
        case .paymentAssistance: return "Payment Assistance"
        case .communityInvitation: return "Community Invitation"
        case .trialExtension: return "Trial Extension"
        case .downgradePrevention: return "Downgrade Prevention"
        case .pauseOffer: return "Pause Offer"
        }
    }
}

/// Retention intervention record
public struct RetentionIntervention: Codable {
    public let id: String
    public let userId: String
    public let strategy: InterventionStrategy
    public let triggerRiskScore: Double
    public let createdDate: Date
    public var status: InterventionStatus
    public var completedDate: Date?
    public var effectivenessScore: Double?
    
    public init(
        userId: String,
        strategy: InterventionStrategy,
        triggerRiskScore: Double,
        createdDate: Date,
        status: InterventionStatus
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.strategy = strategy
        self.triggerRiskScore = triggerRiskScore
        self.createdDate = createdDate
        self.status = status
    }
}

/// Status of retention interventions
public enum InterventionStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Personalized Offer Models

/// Personalized retention offer
public struct PersonalizedOffer: Codable {
    public let id: String
    public let userId: String
    public let offerType: OfferType
    public let discountPercentage: Int?
    public let discountAmount: Double?
    public let freeTrialDays: Int?
    public let validUntil: Date
    public let personalizedMessage: String
    public let createdDate: Date
    public var status: OfferStatus
    public var acceptedDate: Date?
    
    public init(
        userId: String,
        offerType: OfferType,
        discountPercentage: Int? = nil,
        discountAmount: Double? = nil,
        freeTrialDays: Int? = nil,
        validUntil: Date,
        personalizedMessage: String,
        createdDate: Date
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.offerType = offerType
        self.discountPercentage = discountPercentage
        self.discountAmount = discountAmount
        self.freeTrialDays = freeTrialDays
        self.validUntil = validUntil
        self.personalizedMessage = personalizedMessage
        self.createdDate = createdDate
        self.status = .pending
    }
}

/// Types of personalized offers
public enum OfferType: String, CaseIterable, Codable {
    case percentageDiscount = "percentage_discount"
    case fixedAmountDiscount = "fixed_amount_discount"
    case freeTrialExtension = "free_trial_extension"
    case featureUnlock = "feature_unlock"
    case subscriptionPause = "subscription_pause"
    
    public var displayName: String {
        switch self {
        case .percentageDiscount: return "Percentage Discount"
        case .fixedAmountDiscount: return "Fixed Amount Discount"
        case .freeTrialExtension: return "Free Trial Extension"
        case .featureUnlock: return "Feature Unlock"
        case .subscriptionPause: return "Subscription Pause"
        }
    }
}

/// Status of personalized offers
public enum OfferStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case presented = "presented"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .presented: return "Presented"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Winback Campaign Models

/// Winback campaign for cancelled subscribers
public struct WinbackCampaign: Codable {
    public let id: String
    public let userId: String
    public let cancellationReason: CancellationReason
    public let strategy: WinbackStrategy
    public let createdDate: Date
    public var status: CampaignStatus
    public var completedDate: Date?
    public var successfulReactivation: Bool?
    
    public init(
        userId: String,
        cancellationReason: CancellationReason,
        strategy: WinbackStrategy,
        createdDate: Date,
        status: CampaignStatus
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.cancellationReason = cancellationReason
        self.strategy = strategy
        self.createdDate = createdDate
        self.status = status
    }
}

/// Winback strategies for different scenarios
public enum WinbackStrategy: String, CaseIterable, Codable {
    case personalizedDiscount = "personalized_discount"
    case featureHighlight = "feature_highlight"
    case premiumSupport = "premium_support"
    case communityInvitation = "community_invitation"
    case trialOffer = "trial_offer"
    case generalDiscount = "general_discount"
    case pauseOffer = "pause_offer"
    
    public var displayName: String {
        switch self {
        case .personalizedDiscount: return "Personalized Discount"
        case .featureHighlight: return "Feature Highlight"
        case .premiumSupport: return "Premium Support"
        case .communityInvitation: return "Community Invitation"
        case .trialOffer: return "Trial Offer"
        case .generalDiscount: return "General Discount"
        case .pauseOffer: return "Pause Offer"
        }
    }
}

/// Campaign status
public enum CampaignStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - User Analysis Models

/// User preferences for personalization
public struct UserPreferences {
    public let preferredFeatures: [FeatureType]
    public let communicationPreferences: CommunicationChannel
    public let offerPreferences: OfferPreference
}

/// Communication channels for interventions
public enum CommunicationChannel: String, CaseIterable, Codable {
    case email = "email"
    case push = "push"
    case inApp = "in_app"
    case sms = "sms"
}

/// User's preference for types of offers
public enum OfferPreference: String, CaseIterable, Codable {
    case discount = "discount"
    case trialExtension = "trial_extension"
    case featureUnlock = "feature_unlock"
    case pause = "pause"
}

/// Price sensitivity categories
public enum PriceSensitivity: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Price Sensitivity"
        case .moderate: return "Moderate Price Sensitivity"
        case .high: return "High Price Sensitivity"
        }
    }
}

/// Feature usage analysis
public struct FeatureUsageAnalysis {
    public let mostUsedFeatures: [FeatureType]
    public let leastUsedFeatures: [FeatureType]
    public let usagePatterns: [UsagePattern]
}

/// Usage patterns for feature analysis
public struct UsagePattern {
    public let feature: FeatureType
    public let frequency: UsageFrequency
    public let timeOfDay: [Int] // Hours of day when used
    public let sessionLength: TimeInterval
}

/// Feature usage frequency
public enum UsageFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case rarely = "rarely"
    case never = "never"
}

// MARK: - Cohort Analysis Models

/// Churn analysis for user cohorts
public struct CohortChurnAnalysis {
    public let cohort: UserCohort
    public let sampleSize: Int
    public let averageRiskScore: Double
    public let riskDistribution: [ChurnRiskCategory: Int]
    public let topRiskFactors: [ChurnRiskFactor]
    public let recommendedActions: [RecommendedAction]
}

/// Recommended actions for cohort management
public struct RecommendedAction {
    public let action: InterventionStrategy
    public let priority: ActionPriority
    public let estimatedImpact: Double
    public let description: String
}

/// Priority levels for recommended actions
public enum ActionPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Machine Learning Models

/// Placeholder for churn risk ML model
public protocol ChurnRiskModel {
    func predict(behavior: Double, subscription: Double, engagement: Double, payment: Double) -> Double
}

/// Placeholder for retention optimization ML model
public protocol RetentionModel {
    func recommendStrategy(riskScore: ChurnRiskScore, userProfile: UserProfile) -> InterventionStrategy
}

/// User profile for ML model input
public struct UserProfile {
    public let subscriptionTier: SubscriptionTier
    public let subscriptionAge: TimeInterval
    public let usagePatterns: FeatureUsageAnalysis
    public let preferences: UserPreferences
    public let demographics: Demographics?
}

/// User demographics for enhanced personalization
public struct Demographics {
    public let ageGroup: AgeGroup?
    public let region: String?
    public let deviceType: DeviceType?
}

/// Age groups for demographic analysis
public enum AgeGroup: String, CaseIterable, Codable {
    case gen_z = "gen_z"       // 18-24
    case millennial = "millennial"  // 25-40
    case gen_x = "gen_x"       // 41-56
    case boomer = "boomer"     // 57+
}

/// Device types for usage analysis
public enum DeviceType: String, CaseIterable, Codable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case appleWatch = "apple_watch"
    case mac = "mac"
}

// MARK: - Error Models

/// Churn prevention system errors
public enum ChurnError: Error, LocalizedError {
    case userNotAuthenticated
    case calculationFailed(String)
    case dataRetrievalFailed(String)
    case interventionFailed(String)
    case modelNotAvailable
    case insufficientData
    
    public var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .calculationFailed(let message):
            return "Risk calculation failed: \(message)"
        case .dataRetrievalFailed(let message):
            return "Data retrieval failed: \(message)"
        case .interventionFailed(let message):
            return "Intervention failed: \(message)"
        case .modelNotAvailable:
            return "ML model not available"
        case .insufficientData:
            return "Insufficient data for analysis"
        }
    }
}