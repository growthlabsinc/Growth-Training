/**
 * AdvancedTrialModels.swift
 * Growth App Advanced Trial Models
 *
 * Comprehensive models for advanced trial management including
 * personalized trials, trial optimization, and conversion tracking.
 */

import Foundation

// MARK: - Core Trial Models

/// Trial experience tracking comprehensive trial journey
public struct TrialExperience: Codable {
    public let id: String
    public let userId: String
    public let trialType: TrialType
    public let configuration: TrialConfiguration
    public let startDate: Date
    public var expectedEndDate: Date
    public var actualEndDate: Date?
    public var status: TrialStatus
    public var extensions: [TrialExtension]
    public let personalizationFactors: [PersonalizationFactor]
    public var conversionDate: Date?
    public var cancellationDate: Date?
    public var conversionDetails: TrialConversion?
    public var cancellationDetails: TrialCancellation?
    
    public var totalTrialDuration: TimeInterval {
        let endDate = actualEndDate ?? expectedEndDate
        return endDate.timeIntervalSince(startDate)
    }
    
    public init(
        userId: String,
        trialType: TrialType,
        configuration: TrialConfiguration,
        startDate: Date,
        expectedEndDate: Date,
        status: TrialStatus,
        personalizationFactors: [PersonalizationFactor]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.trialType = trialType
        self.configuration = configuration
        self.startDate = startDate
        self.expectedEndDate = expectedEndDate
        self.status = status
        self.extensions = []
        self.personalizationFactors = personalizationFactors
    }
}

/// Types of trial experiences
public enum TrialType: String, CaseIterable, Codable {
    case standard = "standard"
    case extended = "extended"
    case featureSpecific = "feature_specific"
    case freemium = "freemium"
    case gradualUnlock = "gradual_unlock"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard Trial"
        case .extended: return "Extended Trial"
        case .featureSpecific: return "Feature Trial"
        case .freemium: return "Freemium Trial"
        case .gradualUnlock: return "Gradual Unlock Trial"
        }
    }
}

/// Trial status tracking
public enum TrialStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case active = "active"
    case converted = "converted"
    case cancelled = "cancelled"
    case expired = "expired"
    case suspended = "suspended"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .converted: return "Converted"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        case .suspended: return "Suspended"
        }
    }
}

/// Trial configuration for different trial types
public struct TrialConfiguration: Codable {
    public let duration: TimeInterval
    public let targetTier: SubscriptionTier
    public let features: [FeatureType]
    public var focusFeatures: [FeatureType]
    public let restrictions: [TrialRestriction]
    public let checkpoints: [TrialCheckpoint]
    
    public init(
        duration: TimeInterval,
        targetTier: SubscriptionTier,
        features: [FeatureType],
        focusFeatures: [FeatureType] = [],
        restrictions: [TrialRestriction] = [],
        checkpoints: [TrialCheckpoint] = []
    ) {
        self.duration = duration
        self.targetTier = targetTier
        self.features = features
        self.focusFeatures = focusFeatures
        self.restrictions = restrictions
        self.checkpoints = checkpoints
    }
}

/// Trial restrictions and limitations
public struct TrialRestriction: Codable {
    public let type: RestrictionType
    public let limit: Int
    public let description: String
    
    public enum RestrictionType: String, CaseIterable, Codable {
        case sessionLimit = "session_limit"
        case featureUsageLimit = "feature_usage_limit"
        case exportLimit = "export_limit"
        case dataLimit = "data_limit"
    }
}

/// Trial checkpoints for engagement tracking
public struct TrialCheckpoint: Codable {
    public let day: Int
    public let requiredActions: [CheckpointAction]
    public let rewards: [CheckpointReward]
    public var completed: Bool
    public var completionDate: Date?
    
    public enum CheckpointAction: String, CaseIterable, Codable {
        case completeOnboarding = "complete_onboarding"
        case useFeature = "use_feature"
        case createSession = "create_session"
        case inviteFriend = "invite_friend"
        case provideFeedback = "provide_feedback"
    }
    
    public enum CheckpointReward: String, CaseIterable, Codable {
        case extraTrialDays = "extra_trial_days"
        case premiumFeatureUnlock = "premium_feature_unlock"
        case discount = "discount"
        case badge = "badge"
    }
}

// MARK: - Trial Extension Models

/// Trial extension record
public struct TrialExtension: Codable {
    public let id: String
    public let trialId: String
    public let extensionDays: Int
    public let reason: TrialExtensionReason
    public let originalEndDate: Date
    public let newEndDate: Date
    public let grantedDate: Date
    
    public init(
        trialId: String,
        extensionDays: Int,
        reason: TrialExtensionReason,
        originalEndDate: Date,
        newEndDate: Date,
        grantedDate: Date
    ) {
        self.id = UUID().uuidString
        self.trialId = trialId
        self.extensionDays = extensionDays
        self.reason = reason
        self.originalEndDate = originalEndDate
        self.newEndDate = newEndDate
        self.grantedDate = grantedDate
    }
}

/// Reasons for trial extension
public enum TrialExtensionReason: String, CaseIterable, Codable {
    case userRequest = "user_request"
    case lowEngagement = "low_engagement"
    case technicalIssue = "technical_issue"
    case retentionOffer = "retention_offer"
    case checkpointReward = "checkpoint_reward"
    case specialPromotion = "special_promotion"
    
    public var displayName: String {
        switch self {
        case .userRequest: return "User Request"
        case .lowEngagement: return "Low Engagement"
        case .technicalIssue: return "Technical Issue"
        case .retentionOffer: return "Retention Offer"
        case .checkpointReward: return "Checkpoint Reward"
        case .specialPromotion: return "Special Promotion"
        }
    }
}

// MARK: - Trial Conversion Models

/// Trial conversion tracking
public struct TrialConversion: Codable {
    public let id: String
    public let trialId: String
    public let fromTier: SubscriptionTier
    public let toTier: SubscriptionTier
    public let conversionDate: Date
    public let trialDurationUsed: TimeInterval
    public let conversionValue: Double
    public let conversionChannel: ConversionChannel
    public let influencingFactors: [ConversionFactor]
    
    public init(
        trialId: String,
        fromTier: SubscriptionTier,
        toTier: SubscriptionTier,
        conversionDate: Date,
        trialDurationUsed: TimeInterval,
        conversionValue: Double,
        conversionChannel: ConversionChannel,
        influencingFactors: [ConversionFactor] = []
    ) {
        self.id = UUID().uuidString
        self.trialId = trialId
        self.fromTier = fromTier
        self.toTier = toTier
        self.conversionDate = conversionDate
        self.trialDurationUsed = trialDurationUsed
        self.conversionValue = conversionValue
        self.conversionChannel = conversionChannel
        self.influencingFactors = influencingFactors
    }
}

/// Conversion channels
public enum ConversionChannel: String, CaseIterable, Codable {
    case inApp = "in_app"
    case email = "email"
    case push = "push"
    case webOffer = "web_offer"
    case supportChat = "support_chat"
    
    public var displayName: String {
        switch self {
        case .inApp: return "In-App"
        case .email: return "Email"
        case .push: return "Push Notification"
        case .webOffer: return "Web Offer"
        case .supportChat: return "Support Chat"
        }
    }
}

/// Factors influencing conversion
public enum ConversionFactor: String, CaseIterable, Codable {
    case highEngagement = "high_engagement"
    case featureUsage = "feature_usage"
    case timelyOffer = "timely_offer"
    case socialProof = "social_proof"
    case limitedTime = "limited_time"
    case personalizedDiscount = "personalized_discount"
    case supportInteraction = "support_interaction"
    
    public var displayName: String {
        switch self {
        case .highEngagement: return "High Engagement"
        case .featureUsage: return "Feature Usage"
        case .timelyOffer: return "Timely Offer"
        case .socialProof: return "Social Proof"
        case .limitedTime: return "Limited Time"
        case .personalizedDiscount: return "Personalized Discount"
        case .supportInteraction: return "Support Interaction"
        }
    }
}

// MARK: - Trial Cancellation Models

/// Trial cancellation tracking
public struct TrialCancellation: Codable {
    public let id: String
    public let trialId: String
    public let reason: TrialCancellationReason
    public let cancellationDate: Date
    public let trialDurationUsed: TimeInterval
    public let feedback: String?
    public let retentionOfferPresented: Bool
    public let retentionOfferAccepted: Bool
    
    public init(
        trialId: String,
        reason: TrialCancellationReason,
        cancellationDate: Date,
        trialDurationUsed: TimeInterval,
        feedback: String? = nil,
        retentionOfferPresented: Bool = false,
        retentionOfferAccepted: Bool = false
    ) {
        self.id = UUID().uuidString
        self.trialId = trialId
        self.reason = reason
        self.cancellationDate = cancellationDate
        self.trialDurationUsed = trialDurationUsed
        self.feedback = feedback
        self.retentionOfferPresented = retentionOfferPresented
        self.retentionOfferAccepted = retentionOfferAccepted
    }
}

/// Trial cancellation reasons
public enum TrialCancellationReason: String, CaseIterable, Codable {
    case tooExpensive = "too_expensive"
    case notEnoughValue = "not_enough_value"
    case foundAlternative = "found_alternative"
    case technicalIssues = "technical_issues"
    case needMoreTime = "need_more_time"
    case privacyConcerns = "privacy_concerns"
    case changedMind = "changed_mind"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .tooExpensive: return "Too Expensive"
        case .notEnoughValue: return "Not Enough Value"
        case .foundAlternative: return "Found Alternative"
        case .technicalIssues: return "Technical Issues"
        case .needMoreTime: return "Need More Time"
        case .privacyConcerns: return "Privacy Concerns"
        case .changedMind: return "Changed Mind"
        case .other: return "Other"
        }
    }
}

// MARK: - User Profile and Personalization

/// User trial profile for personalization
public struct UserTrialProfile {
    public let engagementLevel: EngagementLevel
    public let expectedUsageLevel: UsageLevel
    public let primaryFeatureInterest: FeatureType?
    public let acquisitionSource: AcquisitionSource?
    public let demographicData: DemographicData?
    public let behaviorPatterns: [BehaviorPattern]
    
    public init(
        engagementLevel: EngagementLevel,
        expectedUsageLevel: UsageLevel,
        primaryFeatureInterest: FeatureType? = nil,
        acquisitionSource: AcquisitionSource? = nil,
        demographicData: DemographicData? = nil,
        behaviorPatterns: [BehaviorPattern] = []
    ) {
        self.engagementLevel = engagementLevel
        self.expectedUsageLevel = expectedUsageLevel
        self.primaryFeatureInterest = primaryFeatureInterest
        self.acquisitionSource = acquisitionSource
        self.demographicData = demographicData
        self.behaviorPatterns = behaviorPatterns
    }
}

/// User engagement levels
public enum EngagementLevel: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Engagement"
        case .moderate: return "Moderate Engagement"
        case .high: return "High Engagement"
        }
    }
}

/// Expected usage levels
public enum UsageLevel: String, CaseIterable, Codable {
    case light = "light"
    case moderate = "moderate"
    case heavy = "heavy"
    
    public var displayName: String {
        switch self {
        case .light: return "Light Usage"
        case .moderate: return "Moderate Usage"
        case .heavy: return "Heavy Usage"
        }
    }
}

/// User acquisition sources
public enum AcquisitionSource: String, CaseIterable, Codable {
    case organic = "organic"
    case socialMedia = "social_media"
    case searchAds = "search_ads"
    case referral = "referral"
    case contentMarketing = "content_marketing"
    case influencer = "influencer"
    case appStore = "app_store"
    
    public var displayName: String {
        switch self {
        case .organic: return "Organic"
        case .socialMedia: return "Social Media"
        case .searchAds: return "Search Ads"
        case .referral: return "Referral"
        case .contentMarketing: return "Content Marketing"
        case .influencer: return "Influencer"
        case .appStore: return "App Store"
        }
    }
}

/// Demographic data for personalization
public struct DemographicData {
    public let ageGroup: AgeGroup?
    public let region: String?
    public let deviceType: DeviceType?
    public let timeZone: TimeZone?
}

/// User behavior patterns
public enum BehaviorPattern: String, CaseIterable, Codable {
    case earlyAdopter = "early_adopter"
    case priceConscious = "price_conscious"
    case featureExplorer = "feature_explorer"
    case goalOriented = "goal_oriented"
    case socialUser = "social_user"
    case privacyFocused = "privacy_focused"
    
    public var displayName: String {
        switch self {
        case .earlyAdopter: return "Early Adopter"
        case .priceConscious: return "Price Conscious"
        case .featureExplorer: return "Feature Explorer"
        case .goalOriented: return "Goal Oriented"
        case .socialUser: return "Social User"
        case .privacyFocused: return "Privacy Focused"
        }
    }
}

/// Personalization factors applied to trials
public enum PersonalizationFactor: CaseIterable, Codable {
    case engagementLevel(EngagementLevel)
    case usageLevel(UsageLevel)
    case featureInterest(FeatureType)
    case acquisitionSource(AcquisitionSource)
    case timeOfDay(Int)
    case deviceType(DeviceType)
    
    public var rawValue: String {
        switch self {
        case .engagementLevel(let level): return "engagement_\(level.rawValue)"
        case .usageLevel(let level): return "usage_\(level.rawValue)"
        case .featureInterest(let feature): return "feature_\(feature.rawValue)"
        case .acquisitionSource(let source): return "source_\(source.rawValue)"
        case .timeOfDay(let hour): return "time_\(hour)"
        case .deviceType(let device): return "device_\(device.rawValue)"
        }
    }
    
    public static var allCases: [PersonalizationFactor] {
        return [
            .engagementLevel(.low),
            .engagementLevel(.moderate),
            .engagementLevel(.high),
            .usageLevel(.light),
            .usageLevel(.moderate),
            .usageLevel(.heavy)
        ]
    }
}

// MARK: - Trial Recommendations

/// Trial recommendation based on user analysis
public struct TrialRecommendation {
    public let type: TrialType
    public let duration: TimeInterval
    public let targetTier: SubscriptionTier
    public let expectedConversionRate: Double
    public let personalizationScore: Double
    public let features: [FeatureType]
    public let reasoning: String
    
    public var durationDays: Int {
        return Int(duration / (24 * 60 * 60))
    }
}

/// Trial feature sets for different trial types
public enum TrialFeatureSet {
    case standard
    case premium
    case focused(on: FeatureType)
    
    public var features: [FeatureType] {
        switch self {
        case .standard:
            return [.quickTimer, .advancedAnalytics, .customRoutines]
        case .premium:
            return FeatureType.allCases
        case .focused(let feature):
            return [feature] + relatedFeatures(to: feature)
        }
    }
    
    private func relatedFeatures(to feature: FeatureType) -> [FeatureType] {
        switch feature {
        case .quickTimer:
            return [.customRoutines, .advancedTimer]
        case .advancedAnalytics:
            return [.progressTracking, .expertInsights]
        case .aiCoach:
            return [.expertInsights, .goalSetting]
        default:
            return []
        }
    }
}

// MARK: - Trial Analytics and Optimization

/// Trial performance metrics
public struct TrialPerformanceMetrics {
    public let timeRange: DateRange
    public let totalTrials: Int
    public let conversions: Int
    public let conversionRate: Double
    public let averageTrialDuration: TimeInterval
    public let averageTimeToConversion: TimeInterval
    public let totalRevenue: Double
    public let averageRevenuePerTrial: Double
    public let performanceByType: [TrialType: Double]
    public let performanceByDuration: [Int: Double] // Days to conversion rate
    public let topPersonalizationFactors: [PersonalizationFactor]
}

/// Trial progress tracking
public struct TrialProgress {
    public let daysUsed: Int
    public let featuresExplored: [FeatureType]
    public let engagementScore: Double
    public let conversionLikelihood: Double
}

/// Trial optimization opportunities
public struct TrialOptimization {
    public let type: OptimizationType
    public let description: String
    public let expectedImpact: Double
    public let implementation: OptimizationImplementation
    
    public enum OptimizationType: String, CaseIterable {
        case extendDuration = "extend_duration"
        case addFeatures = "add_features"
        case sendReminder = "send_reminder"
        case offerDiscount = "offer_discount"
        case scheduleCheckIn = "schedule_check_in"
    }
    
    public enum OptimizationImplementation {
        case automatic
        case userPrompt
        case delayed(TimeInterval)
    }
}

/// User behavior analysis for trials
public struct UserBehaviorAnalysis {
    public let primaryFeatureInterest: FeatureType?
    public let valueScore: Double
    public let engagementPattern: EngagementPattern
    
    public enum EngagementPattern {
        case declining
        case stable
        case increasing
        case moderate
    }
}

/// Conversion probability predictions
public struct ConversionProbability {
    public let standard: Double
    public let featureSpecific: Double
    public let extended: Double
}

// MARK: - Trial Configurations

/// Trial configurations for different types
public struct TrialConfigurations {
    public let standardTrialDuration: TimeInterval
    public let extendedTrialDuration: TimeInterval
    public let featureTrialDuration: TimeInterval
    
    public static let `default` = TrialConfigurations(
        standardTrialDuration: 14 * 24 * 60 * 60, // 14 days
        extendedTrialDuration: 30 * 24 * 60 * 60, // 30 days
        featureTrialDuration: 7 * 24 * 60 * 60    // 7 days
    )
    
    public func configuration(for type: TrialType) -> TrialConfiguration {
        switch type {
        case .standard:
            return TrialConfiguration(
                duration: standardTrialDuration,
                targetTier: .premium,
                features: TrialFeatureSet.standard.features
            )
        case .extended:
            return TrialConfiguration(
                duration: extendedTrialDuration,
                targetTier: .premium,
                features: TrialFeatureSet.premium.features
            )
        case .featureSpecific:
            return TrialConfiguration(
                duration: featureTrialDuration,
                targetTier: .premium,
                features: TrialFeatureSet.standard.features
            )
        case .freemium:
            return TrialConfiguration(
                duration: .greatestFiniteMagnitude, // Unlimited
                targetTier: .premium,
                features: [.quickTimer], // Limited features
                restrictions: [
                    TrialRestriction(
                        type: .sessionLimit,
                        limit: 5,
                        description: "5 sessions per day"
                    )
                ]
            )
        case .gradualUnlock:
            return TrialConfiguration(
                duration: standardTrialDuration,
                targetTier: .premium,
                features: TrialFeatureSet.standard.features,
                checkpoints: [
                    TrialCheckpoint(
                        day: 3,
                        requiredActions: [.completeOnboarding],
                        rewards: [.premiumFeatureUnlock],
                        completed: false
                    ),
                    TrialCheckpoint(
                        day: 7,
                        requiredActions: [.useFeature],
                        rewards: [.extraTrialDays],
                        completed: false
                    )
                ]
            )
        }
    }
}

// MARK: - Retention Offers

/// Retention offer for trial users
public struct RetentionOffer {
    public let id: String
    public let type: RetentionOfferType
    public let discountPercentage: Int?
    public let extensionDays: Int?
    public let validForDays: Int
    public let message: String
    public let createdDate: Date
    
    public init(
        type: RetentionOfferType,
        discountPercentage: Int? = nil,
        extensionDays: Int? = nil,
        validForDays: Int,
        message: String
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.discountPercentage = discountPercentage
        self.extensionDays = extensionDays
        self.validForDays = validForDays
        self.message = message
        self.createdDate = Date()
    }
}

/// Types of retention offers
public enum RetentionOfferType: String, CaseIterable, Codable {
    case discount = "discount"
    case trialExtension = "trial_extension"
    case featureUnlock = "feature_unlock"
    case premiumSupport = "premium_support"
    
    public var displayName: String {
        switch self {
        case .discount: return "Discount Offer"
        case .trialExtension: return "Trial Extension"
        case .featureUnlock: return "Feature Unlock"
        case .premiumSupport: return "Premium Support"
        }
    }
}

// MARK: - Trial Record (Historical)

/// Historical trial record for analytics
public struct TrialRecord {
    public let id: String
    public let trialType: TrialType
    public let startDate: Date
    public let endDate: Date?
    public let status: TrialStatus
    public let conversionValue: Double?
    
    public init(from experience: TrialExperience) {
        self.id = experience.id
        self.trialType = experience.trialType
        self.startDate = experience.startDate
        self.endDate = experience.actualEndDate
        self.status = experience.status
        self.conversionValue = experience.conversionDetails?.conversionValue
    }
}

// MARK: - Error Models

/// Trial-specific errors
public enum TrialError: Error, LocalizedError {
    case userNotAuthenticated
    case notEligible
    case noActiveTrial
    case trialNotActive
    case initializationFailed(String)
    case extensionFailed(String)
    case conversionFailed(String)
    case cancellationFailed(String)
    case purchaseFailed(String)
    case storeKitError(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .notEligible:
            return "User not eligible for trial"
        case .noActiveTrial:
            return "No active trial found"
        case .trialNotActive:
            return "Trial is not active"
        case .initializationFailed(let message):
            return "Trial initialization failed: \(message)"
        case .extensionFailed(let message):
            return "Trial extension failed: \(message)"
        case .conversionFailed(let message):
            return "Trial conversion failed: \(message)"
        case .cancellationFailed(let message):
            return "Trial cancellation failed: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .storeKitError(let message):
            return "StoreKit error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}

// MARK: - Extensions for Codable Support

extension PersonalizationFactor {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if rawValue.hasPrefix("engagement_") {
            let levelString = String(rawValue.dropFirst("engagement_".count))
            if let level = EngagementLevel(rawValue: levelString) {
                self = .engagementLevel(level)
                return
            }
        }
        
        // Add other cases as needed
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid PersonalizationFactor")
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}