/**
 * ExperimentModels.swift
 * Growth App A/B Testing Models
 *
 * Comprehensive model definitions for the advanced A/B testing framework,
 * including experiments, variants, results, and statistical analysis.
 */

import Foundation

// MARK: - Core Experiment Models

/// Reason for stopping an experiment
public enum StopReason: String, Codable {
    case completed = "completed"
    case earlyStop = "early_stop"
    case userStopped = "user_stopped"
    case error = "error"
}

/// A/B testing experiment configuration and data
public struct Experiment: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let type: ExperimentType
    public let variants: [ExperimentVariant]
    public let trafficAllocation: Double // 0.0 to 1.0
    public let targetMetric: String
    public let minimumDetectableEffect: Double
    public let startDate: Date
    public let endDate: Date
    public var status: ExperimentStatus
    public let createdBy: String
    
    // Runtime properties
    public var actualStartDate: Date?
    public var actualEndDate: Date?
    public var stopReason: StopReason?
    public var results: ExperimentResults?
    
    public init(
        id: String,
        name: String,
        description: String,
        type: ExperimentType,
        variants: [ExperimentVariant],
        trafficAllocation: Double,
        targetMetric: String,
        minimumDetectableEffect: Double,
        startDate: Date,
        endDate: Date,
        status: ExperimentStatus,
        createdBy: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.variants = variants
        self.trafficAllocation = trafficAllocation
        self.targetMetric = targetMetric
        self.minimumDetectableEffect = minimumDetectableEffect
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.createdBy = createdBy
    }
}

/// Experiment status lifecycle
public enum ExperimentStatus: String, Codable, CaseIterable {
    case created = "created"
    case running = "running"
    case stopped = "stopped"
    case paused = "paused"
    case completed = "completed"
    
    public var displayName: String {
        switch self {
        case .created: return "Created"
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

/// Types of experiments supported
public enum ExperimentType: String, Codable, CaseIterable {
    case headerMessaging = "header_messaging"
    case ctaButtonText = "cta_button_text"
    case pricingDisplay = "pricing_display"
    case featureHighlights = "feature_highlights"
    case socialProofPlacement = "social_proof_placement"
    case exitIntentTiming = "exit_intent_timing"
    case discountStrategy = "discount_strategy"
    case onboardingFlow = "onboarding_flow"
    case paywallLayout = "paywall_layout"
    
    public var displayName: String {
        switch self {
        case .headerMessaging: return "Header Messaging"
        case .ctaButtonText: return "CTA Button Text"
        case .pricingDisplay: return "Pricing Display"
        case .featureHighlights: return "Feature Highlights"
        case .socialProofPlacement: return "Social Proof Placement"
        case .exitIntentTiming: return "Exit Intent Timing"
        case .discountStrategy: return "Discount Strategy"
        case .onboardingFlow: return "Onboarding Flow"
        case .paywallLayout: return "Paywall Layout"
        }
    }
}

/// Individual experiment variant
public struct ExperimentVariant: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let isControl: Bool
    public let splitRatio: Double // Percentage of traffic for this variant
    public let configuration: [String: AnyCodable] // Variant-specific settings
    
    public init(
        id: String,
        name: String,
        description: String,
        isControl: Bool,
        splitRatio: Double,
        configuration: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isControl = isControl
        self.splitRatio = splitRatio
        self.configuration = configuration
    }
}

/// Experiment configuration for creation
public struct ExperimentConfig {
    public let name: String
    public let description: String
    public let type: ExperimentType
    public let variants: [ExperimentVariant]
    public let trafficAllocation: Double
    public let targetMetric: String
    public let minimumDetectableEffect: Double
    public let startDate: Date
    public let endDate: Date
    
    public init(
        name: String,
        description: String,
        type: ExperimentType,
        variants: [ExperimentVariant],
        trafficAllocation: Double,
        targetMetric: String,
        minimumDetectableEffect: Double,
        startDate: Date,
        endDate: Date
    ) {
        self.name = name
        self.description = description
        self.type = type
        self.variants = variants
        self.trafficAllocation = trafficAllocation
        self.targetMetric = targetMetric
        self.minimumDetectableEffect = minimumDetectableEffect
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Statistical Analysis Models

/// Statistical significance test result
public struct StatisticalTest {
    public let isSignificant: Bool
    public let pValue: Double
    public let effect: Double // Effect size (relative improvement)
    public let confidenceInterval: (Double, Double)
    
    public init(
        isSignificant: Bool,
        pValue: Double,
        effect: Double,
        confidenceInterval: (Double, Double)
    ) {
        self.isSignificant = isSignificant
        self.pValue = pValue
        self.effect = effect
        self.confidenceInterval = confidenceInterval
    }
}

/// Statistical significance analysis result
public enum SignificanceResult {
    case significant(winner: ExperimentVariant, results: [SignificantVariant])
    case inconclusive(reason: String)
    
    public var isSignificant: Bool {
        switch self {
        case .significant: return true
        case .inconclusive: return false
        }
    }
    
    public var winningVariant: ExperimentVariant? {
        switch self {
        case .significant(let winner, _): return winner
        case .inconclusive: return nil
        }
    }
    
    public var effect: Double {
        switch self {
        case .significant(_, let results): return results.first?.effect ?? 0
        case .inconclusive: return 0
        }
    }
}

/// Significant variant result
public struct SignificantVariant {
    public let variant: ExperimentVariant
    public let pValue: Double
    public let confidenceInterval: (Double, Double)
    public let effect: Double
    
    public init(
        variant: ExperimentVariant,
        pValue: Double,
        confidenceInterval: (Double, Double),
        effect: Double
    ) {
        self.variant = variant
        self.pValue = pValue
        self.confidenceInterval = confidenceInterval
        self.effect = effect
    }
}

/// Variant performance results
public struct VariantResults {
    public let variant: ExperimentVariant
    public let sampleSize: Int
    public let conversions: Double
    public let conversionRate: Double
    public let averageOrderValue: Double
    
    public init(
        variant: ExperimentVariant,
        sampleSize: Int,
        conversions: Double,
        conversionRate: Double,
        averageOrderValue: Double
    ) {
        self.variant = variant
        self.sampleSize = sampleSize
        self.conversions = conversions
        self.conversionRate = conversionRate
        self.averageOrderValue = averageOrderValue
    }
}

/// Comprehensive experiment results
public struct ExperimentResults: Codable {
    public let experimentId: String
    public let status: ExperimentStatus
    public let significance: SignificanceResult
    public let variantResults: [VariantResults]
    public let duration: TimeInterval
    public let totalSampleSize: Int
    public let conclusionReached: Bool
    
    public init(
        experimentId: String,
        status: ExperimentStatus,
        significance: SignificanceResult,
        variantResults: [VariantResults],
        duration: TimeInterval,
        totalSampleSize: Int,
        conclusionReached: Bool
    ) {
        self.experimentId = experimentId
        self.status = status
        self.significance = significance
        self.variantResults = variantResults
        self.duration = duration
        self.totalSampleSize = totalSampleSize
        self.conclusionReached = conclusionReached
    }
}

// MARK: - User Assignment Models

/// User assignment to experiment variant
public struct UserAssignment: Codable {
    public let userId: String
    public let experimentId: String
    public let variant: ExperimentVariant
    public let assignedAt: Date
    
    public init(
        userId: String,
        experimentId: String,
        variant: ExperimentVariant,
        assignedAt: Date
    ) {
        self.userId = userId
        self.experimentId = experimentId
        self.variant = variant
        self.assignedAt = assignedAt
    }
}

/// Experiment conversion tracking
public struct ExperimentConversion: Codable {
    public let id: String
    public let experimentId: String
    public let userId: String
    public let variant: ExperimentVariant
    public let conversionValue: Double
    public let timestamp: Date
    public let metadata: [String: AnyCodable]
    
    public init(
        experimentId: String,
        userId: String,
        variant: ExperimentVariant,
        conversionValue: Double,
        timestamp: Date,
        metadata: [String: Any] = [:]
    ) {
        self.id = UUID().uuidString
        self.experimentId = experimentId
        self.userId = userId
        self.variant = variant
        self.conversionValue = conversionValue
        self.timestamp = timestamp
        self.metadata = metadata.mapValues { AnyCodable($0) }
    }
}

// MARK: - Codable Extensions for SignificanceResult

extension SignificanceResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case winner
        case results
        case reason
    }
    
    private enum ResultType: String, Codable {
        case significant
        case inconclusive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ResultType.self, forKey: .type)
        
        switch type {
        case .significant:
            let winner = try container.decode(ExperimentVariant.self, forKey: .winner)
            let results = try container.decode([SignificantVariant].self, forKey: .results)
            self = .significant(winner: winner, results: results)
        case .inconclusive:
            let reason = try container.decode(String.self, forKey: .reason)
            self = .inconclusive(reason: reason)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .significant(let winner, let results):
            try container.encode(ResultType.significant, forKey: .type)
            try container.encode(winner, forKey: .winner)
            try container.encode(results, forKey: .results)
        case .inconclusive(let reason):
            try container.encode(ResultType.inconclusive, forKey: .type)
            try container.encode(reason, forKey: .reason)
        }
    }
}

extension SignificantVariant: Codable {
    private enum CodingKeys: String, CodingKey {
        case variant
        case pValue
        case confidenceIntervalLower
        case confidenceIntervalUpper
        case effect
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variant = try container.decode(ExperimentVariant.self, forKey: .variant)
        pValue = try container.decode(Double.self, forKey: .pValue)
        let lower = try container.decode(Double.self, forKey: .confidenceIntervalLower)
        let upper = try container.decode(Double.self, forKey: .confidenceIntervalUpper)
        confidenceInterval = (lower, upper)
        effect = try container.decode(Double.self, forKey: .effect)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(variant, forKey: .variant)
        try container.encode(pValue, forKey: .pValue)
        try container.encode(confidenceInterval.0, forKey: .confidenceIntervalLower)
        try container.encode(confidenceInterval.1, forKey: .confidenceIntervalUpper)
        try container.encode(effect, forKey: .effect)
    }
}

extension VariantResults: Codable {
    private enum CodingKeys: String, CodingKey {
        case variant
        case sampleSize
        case conversions
        case conversionRate
        case averageOrderValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variant = try container.decode(ExperimentVariant.self, forKey: .variant)
        sampleSize = try container.decode(Int.self, forKey: .sampleSize)
        conversions = try container.decode(Double.self, forKey: .conversions)
        conversionRate = try container.decode(Double.self, forKey: .conversionRate)
        averageOrderValue = try container.decode(Double.self, forKey: .averageOrderValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(variant, forKey: .variant)
        try container.encode(sampleSize, forKey: .sampleSize)
        try container.encode(conversions, forKey: .conversions)
        try container.encode(conversionRate, forKey: .conversionRate)
        try container.encode(averageOrderValue, forKey: .averageOrderValue)
    }
}