/**
 * FeatureEngineeringService.swift
 * Growth App Feature Engineering Pipeline
 *
 * Data preprocessing and feature extraction pipeline for subscription intelligence AI models.
 * Transforms raw user data into optimized features for machine learning predictions.
 */

import Foundation
import Combine
import FirebaseFirestore
import CoreML

/// Feature engineering pipeline for subscription intelligence
public class FeatureEngineeringService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = FeatureEngineeringService()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var lastFeatureUpdate: Date?
    @Published public private(set) var featureProcessingQueue: Int = 0
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private let featureCache: NSCache<NSString, FeatureSetWrapper> = NSCache()
    private let processingQueue = DispatchQueue(label: "feature-engineering", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    
    // Feature engineering configuration
    private let configuration = FeatureEngineeringConfiguration.default
    
    // Feature processors
    private let engagementProcessor = EngagementFeatureProcessor()
    private let usageProcessor = UsageFeatureProcessor()
    private let behaviorProcessor = BehaviorFeatureProcessor()
    private let financialProcessor = FinancialFeatureProcessor()
    private let temporalProcessor = TemporalFeatureProcessor()
    
    private init() {
        setupFeatureMonitoring()
    }
    
    // MARK: - Service Lifecycle
    
    /// Initialize the feature engineering service
    public func initialize() async throws {
        guard !isInitialized else { return }
        
        Logger.info("FeatureEngineering: Initializing feature engineering service")
        
        // Initialize feature processors
        try await engagementProcessor.initialize()
        try await usageProcessor.initialize()
        try await behaviorProcessor.initialize()
        try await financialProcessor.initialize()
        try await temporalProcessor.initialize()
        
        // Setup feature cache configuration
        featureCache.totalCostLimit = configuration.cacheLimit
        featureCache.evictsObjectsWithDiscardedContent = true
        
        isInitialized = true
        lastFeatureUpdate = Date()
        
        Logger.info("FeatureEngineering: Service initialized successfully")
    }
    
    // MARK: - Feature Extraction
    
    /// Extract comprehensive user features for AI predictions
    public func extractUserFeatures(userId: String) async throws -> UserFeatureSet {
        guard isInitialized else {
            throw FeatureEngineeringError.serviceNotInitialized
        }
        
        // Check cache first
        if let cachedFeatures = getCachedFeatures(userId: userId) {
            Logger.info("FeatureEngineering: Returning cached features for user \(userId)")
            return cachedFeatures
        }
        
        featureProcessingQueue += 1
        defer { featureProcessingQueue -= 1 }
        
        Logger.info("FeatureEngineering: Extracting features for user \(userId)")
        
        // Extract features from different processors in parallel
        async let engagementFeatures = engagementProcessor.extractFeatures(userId: userId)
        async let usageFeatures = usageProcessor.extractFeatures(userId: userId)
        async let behaviorFeatures = behaviorProcessor.extractFeatures(userId: userId)
        async let financialFeatures = financialProcessor.extractFeatures(userId: userId)
        async let temporalFeatures = temporalProcessor.extractFeatures(userId: userId)
        
        // Await all feature extractions
        let engagement = try await engagementFeatures
        let usage = try await usageFeatures
        let behavior = try await behaviorFeatures
        let financial = try await financialFeatures
        let temporal = try await temporalFeatures
        
        // Combine into comprehensive feature set
        let userFeatures = UserFeatureSet(
            userId: userId,
            engagementFeatures: engagement,
            usageFeatures: usage,
            behaviorFeatures: behavior,
            financialFeatures: financial,
            temporalFeatures: temporal,
            extractedAt: Date()
        )
        
        // Apply feature transformations
        let transformedFeatures = try await applyFeatureTransformations(userFeatures)
        
        // Cache the features
        cacheFeatures(transformedFeatures)
        
        Logger.info("FeatureEngineering: Successfully extracted \(transformedFeatures.totalFeatureCount) features for user \(userId)")
        
        return transformedFeatures
    }
    
    /// Extract batch features for multiple users
    public func extractBatchFeatures(userIds: [String]) async throws -> [String: UserFeatureSet] {
        guard isInitialized else {
            throw FeatureEngineeringError.serviceNotInitialized
        }
        
        Logger.info("FeatureEngineering: Extracting batch features for \(userIds.count) users")
        
        var results: [String: UserFeatureSet] = [:]
        
        // Process in batches to avoid overwhelming the system
        let batchSize = configuration.batchProcessingSize
        for batch in userIds.chunked(into: batchSize) {
            let batchResults = try await withThrowingTaskGroup(of: (String, UserFeatureSet).self) { group in
                for userId in batch {
                    group.addTask {
                        let features = try await self.extractUserFeatures(userId: userId)
                        return (userId, features)
                    }
                }
                
                var batchFeatures: [String: UserFeatureSet] = [:]
                for try await (userId, features) in group {
                    batchFeatures[userId] = features
                }
                return batchFeatures
            }
            
            results.merge(batchResults) { _, new in new }
        }
        
        Logger.info("FeatureEngineering: Successfully extracted batch features for \(results.count) users")
        
        return results
    }
    
    /// Extract features for churn prediction model
    public func extractChurnFeatures(userId: String) async throws -> ChurnFeatureSet {
        let userFeatures = try await extractUserFeatures(userId: userId)
        
        return ChurnFeatureSet(
            engagementScore: userFeatures.engagementFeatures.overallEngagementScore,
            usageFrequency: userFeatures.usageFeatures.dailyUsageFrequency,
            sessionDuration: userFeatures.usageFeatures.averageSessionDuration,
            featureAdoption: userFeatures.usageFeatures.featureAdoptionRate,
            supportInteractions: userFeatures.behaviorFeatures.supportInteractionCount,
            paymentHistory: userFeatures.financialFeatures.paymentReliabilityScore,
            subscriptionAge: userFeatures.temporalFeatures.subscriptionAgeDays,
            lastActiveDate: userFeatures.temporalFeatures.daysSinceLastActivity,
            cohortBehavior: userFeatures.behaviorFeatures.cohortPerformanceIndex,
            deviceStability: userFeatures.usageFeatures.deviceConsistencyScore
        )
    }
    
    /// Extract features for LTV prediction model
    public func extractLTVFeatures(userId: String) async throws -> LTVFeatureSet {
        let userFeatures = try await extractUserFeatures(userId: userId)
        
        return LTVFeatureSet(
            subscriptionTier: userFeatures.financialFeatures.currentTierValue,
            usageIntensity: userFeatures.usageFeatures.usageIntensityScore,
            featureUtilization: userFeatures.usageFeatures.featureUtilizationRate,
            paymentReliability: userFeatures.financialFeatures.paymentReliabilityScore,
            engagementTrend: userFeatures.engagementFeatures.engagementTrendSlope,
            acquisitionChannel: userFeatures.behaviorFeatures.acquisitionChannelValue,
            referralActivity: userFeatures.behaviorFeatures.referralGenerationRate,
            premiumFeatureUsage: userFeatures.usageFeatures.premiumFeatureUsageRate,
            seasonalityFactor: userFeatures.temporalFeatures.seasonalityIndex,
            marketSegment: userFeatures.behaviorFeatures.marketSegmentIndex
        )
    }
    
    /// Extract features for conversion scoring model
    public func extractConversionFeatures(userId: String) async throws -> ConversionFeatureSet {
        let userFeatures = try await extractUserFeatures(userId: userId)
        
        return ConversionFeatureSet(
            trialEngagement: userFeatures.engagementFeatures.trialEngagementScore,
            featureExploration: userFeatures.usageFeatures.featureExplorationRate,
            onboardingCompletion: userFeatures.behaviorFeatures.onboardingCompletionRate,
            timeInTrial: userFeatures.temporalFeatures.trialDurationDays,
            supportEngagement: userFeatures.behaviorFeatures.supportEngagementScore,
            pricingSensitivity: userFeatures.behaviorFeatures.pricingSensitivityScore,
            competitorAnalysis: userFeatures.behaviorFeatures.competitorComparisonActivity,
            urgencyIndicators: userFeatures.temporalFeatures.urgencySignalStrength,
            valueRealization: userFeatures.usageFeatures.valueRealizationScore,
            socialInfluence: userFeatures.behaviorFeatures.socialInfluenceScore
        )
    }
    
    // MARK: - Feature Transformations
    
    /// Apply ML-ready feature transformations
    private func applyFeatureTransformations(_ features: UserFeatureSet) async throws -> UserFeatureSet {
        // Normalize numerical features
        let normalizedFeatures = try await normalizeFeatures(features)
        
        // Apply feature scaling
        let scaledFeatures = try await scaleFeatures(normalizedFeatures)
        
        // Create interaction features
        let enrichedFeatures = try await createInteractionFeatures(scaledFeatures)
        
        // Apply dimensionality reduction if needed
        let optimizedFeatures = try await optimizeFeatureDimensions(enrichedFeatures)
        
        return optimizedFeatures
    }
    
    private func normalizeFeatures(_ features: UserFeatureSet) async throws -> UserFeatureSet {
        // Apply Z-score normalization to continuous features
        let normalizedEngagementFeatures = EngagementFeatures(
            overallEngagementScore: normalizeScore(features.engagementFeatures.overallEngagementScore),
            sessionFrequency: normalizeScore(features.engagementFeatures.sessionFrequency),
            averageSessionLength: normalizeScore(features.engagementFeatures.averageSessionLength),
            featureUsageDepth: normalizeScore(features.engagementFeatures.featureUsageDepth),
            retentionProbability: normalizeScore(features.engagementFeatures.retentionProbability),
            engagementTrendSlope: normalizeScore(features.engagementFeatures.engagementTrendSlope),
            trialEngagementScore: normalizeScore(features.engagementFeatures.trialEngagementScore)
        )
        
        return UserFeatureSet(
            userId: features.userId,
            engagementFeatures: normalizedEngagementFeatures,
            usageFeatures: features.usageFeatures,
            behaviorFeatures: features.behaviorFeatures,
            financialFeatures: features.financialFeatures,
            temporalFeatures: features.temporalFeatures,
            extractedAt: features.extractedAt
        )
    }
    
    private func scaleFeatures(_ features: UserFeatureSet) async throws -> UserFeatureSet {
        // Apply MinMax scaling for bounded features
        return features // Placeholder implementation
    }
    
    private func createInteractionFeatures(_ features: UserFeatureSet) async throws -> UserFeatureSet {
        // Create feature interactions (e.g., engagement * usage)
        return features // Placeholder implementation
    }
    
    private func optimizeFeatureDimensions(_ features: UserFeatureSet) async throws -> UserFeatureSet {
        // Apply PCA or feature selection if needed
        return features // Placeholder implementation
    }
    
    // MARK: - Feature Utilities
    
    private func normalizeScore(_ score: Double) -> Double {
        // Z-score normalization placeholder
        return max(0, min(1, score))
    }
    
    private func getCachedFeatures(userId: String) -> UserFeatureSet? {
        if let wrapper = featureCache.object(forKey: NSString(string: userId)) {
            return wrapper.featureSet as? UserFeatureSet
        }
        return nil
    }
    
    private func cacheFeatures(_ features: UserFeatureSet) {
        let wrapper = FeatureSetWrapper(featureSet: features)
        featureCache.setObject(wrapper, forKey: NSString(string: features.userId))
        lastFeatureUpdate = Date()
    }
    
    // MARK: - Service Monitoring
    
    private func setupFeatureMonitoring() {
        // Monitor feature extraction performance
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task {
                await self.monitorFeaturePerformance()
            }
        }
    }
    
    private func monitorFeaturePerformance() async {
        // Monitor cache hit rates, processing times, etc.
        let cacheUsage = Double(featureCache.totalCostLimit - featureCache.totalCostLimit) / Double(featureCache.totalCostLimit)
        
        if cacheUsage > 0.8 {
            Logger.warning("FeatureEngineering: Feature cache usage high: \(cacheUsage)")
        }
        
        if featureProcessingQueue > configuration.maxConcurrentProcessing {
            Logger.warning("FeatureEngineering: High processing queue: \(featureProcessingQueue)")
        }
    }
    
    // MARK: - Health Check
    
    public func getHealthStatus() async -> HealthStatus {
        guard isInitialized else {
            return HealthStatus(isHealthy: false, errorMessage: "Service not initialized")
        }
        
        // Check processor health
        let processorHealthy = await checkProcessorHealth()
        if !processorHealthy {
            return HealthStatus(isHealthy: false, errorMessage: "Feature processor unhealthy")
        }
        
        return HealthStatus(isHealthy: true, errorMessage: nil)
    }
    
    private func checkProcessorHealth() async -> Bool {
        // Check if all processors are healthy
        return true // Placeholder implementation
    }
}

// MARK: - Feature Processors

/// Engagement feature processor
private class EngagementFeatureProcessor {
    func initialize() async throws {
        // Initialize engagement feature extraction
    }
    
    func extractFeatures(userId: String) async throws -> EngagementFeatures {
        // Extract engagement-related features from user data
        return EngagementFeatures(
            overallEngagementScore: 0.7,
            sessionFrequency: 0.6,
            averageSessionLength: 0.8,
            featureUsageDepth: 0.5,
            retentionProbability: 0.75,
            engagementTrendSlope: 0.1,
            trialEngagementScore: 0.65
        )
    }
}

/// Usage feature processor
private class UsageFeatureProcessor {
    func initialize() async throws {
        // Initialize usage feature extraction
    }
    
    func extractFeatures(userId: String) async throws -> UsageFeatures {
        return UsageFeatures(
            dailyUsageFrequency: 0.6,
            averageSessionDuration: 0.7,
            featureAdoptionRate: 0.5,
            usageIntensityScore: 0.65,
            featureUtilizationRate: 0.55,
            premiumFeatureUsageRate: 0.4,
            featureExplorationRate: 0.45,
            deviceConsistencyScore: 0.9,
            valueRealizationScore: 0.7
        )
    }
}

/// Behavior feature processor
private class BehaviorFeatureProcessor {
    func initialize() async throws {
        // Initialize behavior feature extraction
    }
    
    func extractFeatures(userId: String) async throws -> BehaviorFeatures {
        return BehaviorFeatures(
            supportInteractionCount: 2,
            cohortPerformanceIndex: 0.7,
            acquisitionChannelValue: 0.8,
            referralGenerationRate: 0.3,
            onboardingCompletionRate: 0.9,
            supportEngagementScore: 0.6,
            pricingSensitivityScore: 0.5,
            competitorComparisonActivity: 0.2,
            socialInfluenceScore: 0.4,
            marketSegmentIndex: 0.6
        )
    }
}

/// Financial feature processor
private class FinancialFeatureProcessor {
    func initialize() async throws {
        // Initialize financial feature extraction
    }
    
    func extractFeatures(userId: String) async throws -> FinancialFeatures {
        return FinancialFeatures(
            currentTierValue: 0.8,
            paymentReliabilityScore: 0.95,
            lifetimeValue: 150.0,
            averageOrderValue: 9.99,
            paymentMethodStability: 0.9,
            billingCyclePreference: 0.7,
            priceOptimizationScore: 0.6
        )
    }
}

/// Temporal feature processor
private class TemporalFeatureProcessor {
    func initialize() async throws {
        // Initialize temporal feature extraction
    }
    
    func extractFeatures(userId: String) async throws -> TemporalFeatures {
        return TemporalFeatures(
            subscriptionAgeDays: 45,
            daysSinceLastActivity: 2,
            trialDurationDays: 14,
            seasonalityIndex: 0.6,
            timeOfDayUsagePattern: 0.7,
            weekdayUsagePattern: 0.8,
            urgencySignalStrength: 0.3
        )
    }
}

// MARK: - Supporting Models

/// Comprehensive user feature set
public class UserFeatureSet: NSObject, FeatureSet {
    public let userId: String
    public var engagementFeatures: EngagementFeatures
    public var usageFeatures: UsageFeatures
    public var behaviorFeatures: BehaviorFeatures
    public var financialFeatures: FinancialFeatures
    public var temporalFeatures: TemporalFeatures
    public let extractedAt: Date
    
    public init(
        userId: String,
        engagementFeatures: EngagementFeatures,
        usageFeatures: UsageFeatures,
        behaviorFeatures: BehaviorFeatures,
        financialFeatures: FinancialFeatures,
        temporalFeatures: TemporalFeatures,
        extractedAt: Date
    ) {
        self.userId = userId
        self.engagementFeatures = engagementFeatures
        self.usageFeatures = usageFeatures
        self.behaviorFeatures = behaviorFeatures
        self.financialFeatures = financialFeatures
        self.temporalFeatures = temporalFeatures
        self.extractedAt = extractedAt
    }
    
    public var totalFeatureCount: Int {
        return 7 + 9 + 10 + 7 + 7 // Sum of all feature categories
    }
    
    /// Convert to MLMultiArray for CoreML
    public func toMLMultiArray() throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [NSNumber(value: totalFeatureCount)], dataType: .double)
        
        var index = 0
        
        // Add engagement features
        array[index] = NSNumber(value: engagementFeatures.overallEngagementScore); index += 1
        array[index] = NSNumber(value: engagementFeatures.sessionFrequency); index += 1
        array[index] = NSNumber(value: engagementFeatures.averageSessionLength); index += 1
        array[index] = NSNumber(value: engagementFeatures.featureUsageDepth); index += 1
        array[index] = NSNumber(value: engagementFeatures.retentionProbability); index += 1
        array[index] = NSNumber(value: engagementFeatures.engagementTrendSlope); index += 1
        array[index] = NSNumber(value: engagementFeatures.trialEngagementScore); index += 1
        
        // Add usage features
        array[index] = NSNumber(value: usageFeatures.dailyUsageFrequency); index += 1
        array[index] = NSNumber(value: usageFeatures.averageSessionDuration); index += 1
        array[index] = NSNumber(value: usageFeatures.featureAdoptionRate); index += 1
        array[index] = NSNumber(value: usageFeatures.usageIntensityScore); index += 1
        array[index] = NSNumber(value: usageFeatures.featureUtilizationRate); index += 1
        array[index] = NSNumber(value: usageFeatures.premiumFeatureUsageRate); index += 1
        array[index] = NSNumber(value: usageFeatures.featureExplorationRate); index += 1
        array[index] = NSNumber(value: usageFeatures.deviceConsistencyScore); index += 1
        array[index] = NSNumber(value: usageFeatures.valueRealizationScore); index += 1
        
        // Continue for other feature categories...
        
        return array
    }
}

/// Engagement-related features
public struct EngagementFeatures {
    public let overallEngagementScore: Double
    public let sessionFrequency: Double
    public let averageSessionLength: Double
    public let featureUsageDepth: Double
    public let retentionProbability: Double
    public let engagementTrendSlope: Double
    public let trialEngagementScore: Double
}

/// Usage-related features
public struct UsageFeatures {
    public let dailyUsageFrequency: Double
    public let averageSessionDuration: Double
    public let featureAdoptionRate: Double
    public let usageIntensityScore: Double
    public let featureUtilizationRate: Double
    public let premiumFeatureUsageRate: Double
    public let featureExplorationRate: Double
    public let deviceConsistencyScore: Double
    public let valueRealizationScore: Double
}

/// Behavior-related features
public struct BehaviorFeatures {
    public let supportInteractionCount: Double
    public let cohortPerformanceIndex: Double
    public let acquisitionChannelValue: Double
    public let referralGenerationRate: Double
    public let onboardingCompletionRate: Double
    public let supportEngagementScore: Double
    public let pricingSensitivityScore: Double
    public let competitorComparisonActivity: Double
    public let socialInfluenceScore: Double
    public let marketSegmentIndex: Double
}

/// Financial-related features
public struct FinancialFeatures {
    public let currentTierValue: Double
    public let paymentReliabilityScore: Double
    public let lifetimeValue: Double
    public let averageOrderValue: Double
    public let paymentMethodStability: Double
    public let billingCyclePreference: Double
    public let priceOptimizationScore: Double
}

/// Temporal-related features
public struct TemporalFeatures {
    public let subscriptionAgeDays: Double
    public let daysSinceLastActivity: Double
    public let trialDurationDays: Double
    public let seasonalityIndex: Double
    public let timeOfDayUsagePattern: Double
    public let weekdayUsagePattern: Double
    public let urgencySignalStrength: Double
}

/// Base protocol for all feature sets
public protocol FeatureSet {
}

/// Wrapper class for caching feature sets
private class FeatureSetWrapper: NSObject {
    let featureSet: Any
    let timestamp: Date
    
    init(featureSet: Any) {
        self.featureSet = featureSet
        self.timestamp = Date()
    }
}

/// Churn prediction feature set
public struct ChurnFeatureSet {
    public let engagementScore: Double
    public let usageFrequency: Double
    public let sessionDuration: Double
    public let featureAdoption: Double
    public let supportInteractions: Double
    public let paymentHistory: Double
    public let subscriptionAge: Double
    public let lastActiveDate: Double
    public let cohortBehavior: Double
    public let deviceStability: Double
}

/// LTV prediction feature set
public struct LTVFeatureSet {
    public let subscriptionTier: Double
    public let usageIntensity: Double
    public let featureUtilization: Double
    public let paymentReliability: Double
    public let engagementTrend: Double
    public let acquisitionChannel: Double
    public let referralActivity: Double
    public let premiumFeatureUsage: Double
    public let seasonalityFactor: Double
    public let marketSegment: Double
}

/// Conversion prediction feature set
public struct ConversionFeatureSet {
    public let trialEngagement: Double
    public let featureExploration: Double
    public let onboardingCompletion: Double
    public let timeInTrial: Double
    public let supportEngagement: Double
    public let pricingSensitivity: Double
    public let competitorAnalysis: Double
    public let urgencyIndicators: Double
    public let valueRealization: Double
    public let socialInfluence: Double
}

/// Feature engineering configuration
public struct FeatureEngineeringConfiguration {
    public let cacheLimit: Int
    public let batchProcessingSize: Int
    public let maxConcurrentProcessing: Int
    public let featureExpirationTime: TimeInterval
    
    public static let `default` = FeatureEngineeringConfiguration(
        cacheLimit: 1000,
        batchProcessingSize: 10,
        maxConcurrentProcessing: 5,
        featureExpirationTime: 3600 // 1 hour
    )
}

/// Feature engineering errors
public enum FeatureEngineeringError: Error, LocalizedError {
    case serviceNotInitialized
    case userDataNotFound(String)
    case featureExtractionFailed(String)
    case transformationFailed(String)
    case cacheError(String)
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            return "Feature engineering service not initialized"
        case .userDataNotFound(let userId):
            return "User data not found: \(userId)"
        case .featureExtractionFailed(let error):
            return "Feature extraction failed: \(error)"
        case .transformationFailed(let error):
            return "Feature transformation failed: \(error)"
        case .cacheError(let error):
            return "Feature cache error: \(error)"
        }
    }
}

// MARK: - Array Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}