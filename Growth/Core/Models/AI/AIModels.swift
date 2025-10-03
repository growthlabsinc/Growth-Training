/**
 * AIModels.swift
 * Growth App AI-Powered Subscription Intelligence Models
 *
 * Comprehensive data models for AI-powered subscription intelligence including
 * predictions, insights, business intelligence, and optimization recommendations.
 */

import Foundation

// MARK: - Core AI Models

/// System health status for AI services
public enum AISystemHealth: Equatable {
    case initializing
    case healthy
    case warning(String)
    case error(String)
    
    public var displayName: String {
        switch self {
        case .initializing: return "Initializing"
        case .healthy: return "Healthy"
        case .warning(let message): return "Warning: \(message)"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    public var isHealthy: Bool {
        switch self {
        case .healthy: return true
        default: return false
        }
    }
}

/// AI configuration settings
public struct AIConfiguration {
    public let monitoringInterval: TimeInterval
    public let predictionCacheTime: TimeInterval
    public let batchProcessingSize: Int
    public let maxConcurrentPredictions: Int
    
    public static let `default` = AIConfiguration(
        monitoringInterval: 300, // 5 minutes
        predictionCacheTime: 600, // 10 minutes
        batchProcessingSize: 20,
        maxConcurrentPredictions: 10
    )
}

// MARK: - Individual Prediction Types

/// Churn prediction for a user
public struct ChurnPrediction: Codable {
    public let userId: String
    public let probability: Double
    public let riskLevel: RiskLevel
    public let confidence: Double
    public let factors: [String]
    public let predictedDate: Date?
    
    public enum RiskLevel: String, Codable {
        case low, medium, high, critical
    }
}

/// Lifetime value prediction
public struct LTVPrediction: Codable {
    public let userId: String
    public let predictedValue: Double
    public let confidence: Double
    public let confidenceIntervalLower: Double
    public let confidenceIntervalUpper: Double
    public let timeHorizon: Int // months
    
    public var confidenceInterval: (lower: Double, upper: Double) {
        return (lower: confidenceIntervalLower, upper: confidenceIntervalUpper)
    }
    
    public init(userId: String, predictedValue: Double, confidence: Double, 
                confidenceInterval: (lower: Double, upper: Double), timeHorizon: Int) {
        self.userId = userId
        self.predictedValue = predictedValue
        self.confidence = confidence
        self.confidenceIntervalLower = confidenceInterval.lower
        self.confidenceIntervalUpper = confidenceInterval.upper
        self.timeHorizon = timeHorizon
    }
}

/// Conversion prediction
public struct ConversionPrediction: Codable {
    public let userId: String
    public let probability: Double
    public let confidence: Double
    public let optimalTiming: Date?
    public let recommendedActions: [String]
}

/// Pricing prediction
public struct PricingPrediction: Codable {
    public let userId: String
    public let optimalPrice: Double
    public let elasticity: Double
    public let confidence: Double
    public let priceRangeMin: Double
    public let priceRangeMax: Double
    
    public var priceRange: (min: Double, max: Double) {
        return (min: priceRangeMin, max: priceRangeMax)
    }
    
    public init(userId: String, optimalPrice: Double, elasticity: Double, 
                confidence: Double, priceRange: (min: Double, max: Double)) {
        self.userId = userId
        self.optimalPrice = optimalPrice
        self.elasticity = elasticity
        self.confidence = confidence
        self.priceRangeMin = priceRange.min
        self.priceRangeMax = priceRange.max
    }
}

/// Segmentation prediction
public struct SegmentationPrediction: Codable {
    public let userId: String
    public let segment: String
    public let confidence: Double
    public let characteristics: [String: Any]
    
    public init(userId: String, segment: String, confidence: Double, characteristics: [String: Any] = [:]) {
        self.userId = userId
        self.segment = segment
        self.confidence = confidence
        self.characteristics = characteristics
    }
    
    enum CodingKeys: String, CodingKey {
        case userId, segment, confidence, characteristics
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        segment = try container.decode(String.self, forKey: .segment)
        confidence = try container.decode(Double.self, forKey: .confidence)
        characteristics = [:] // Simplified for compilation
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(segment, forKey: .segment)
        try container.encode(confidence, forKey: .confidence)
    }
}

/// Attribution breakdown
public struct AttributionBreakdown: Codable {
    public let channel: String
    public let value: Double
    public let percentage: Double
}

/// Performance thresholds for AI models
public struct PerformanceThresholds {
    public let minimumAccuracy: Double
    public let healthyAccuracy: Double
    public let maxDataDrift: Double
    public let minimumDailyPredictions: Int
    
    public static let `default` = PerformanceThresholds(
        minimumAccuracy: 0.75,
        healthyAccuracy: 0.85,
        maxDataDrift: 0.2,
        minimumDailyPredictions: 50
    )
}

/// AI-related errors
public enum AIError: Error, LocalizedError {
    case engineNotInitialized
    case modelLoadingFailed(String)
    case initializationFailed(String)
    case predictionFailed(String)
    case optimizationFailed(String)
    case scenarioAnalysisFailed(String)
    case dataProcessingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "AI engine not initialized"
        case .modelLoadingFailed(let error):
            return "Model loading failed: \(error)"
        case .initializationFailed(let error):
            return "AI engine initialization failed: \(error)"
        case .predictionFailed(let error):
            return "Prediction failed: \(error)"
        case .optimizationFailed(let error):
            return "Optimization failed: \(error)"
        case .scenarioAnalysisFailed(let error):
            return "Scenario analysis failed: \(error)"
        case .dataProcessingFailed(let error):
            return "Data processing failed: \(error)"
        }
    }
}

// MARK: - User AI Insights

/// Comprehensive AI insights for a user
public struct UserAIInsights {
    public let userId: String
    public let churnPrediction: ChurnPrediction
    public let ltvPrediction: LTVPrediction
    public let conversionScore: ConversionPrediction
    public let optimalPricing: PricingPrediction
    public let userSegment: SegmentationPrediction
    public let generatedAt: Date
    public let confidenceLevel: Double
    
    /// Risk assessment summary
    public var riskAssessment: RiskAssessment {
        return RiskAssessment(
            churnRisk: churnPrediction.riskLevel,
            conversionPotential: conversionScore.probability > 0.7 ? .high : conversionScore.probability > 0.4 ? .medium : .low,
            valueScore: ltvPrediction.predictedValue,
            overallRisk: calculateOverallRisk()
        )
    }
    
    private func calculateOverallRisk() -> RiskLevel {
        if churnPrediction.probability > 0.7 {
            return .high
        } else if churnPrediction.probability > 0.4 {
            return .medium
        } else {
            return .low
        }
    }
}

/// Risk assessment for users
public struct RiskAssessment {
    public let churnRisk: ChurnPrediction.RiskLevel
    public let conversionPotential: PotentialLevel
    public let valueScore: Double
    public let overallRisk: RiskLevel
}

/// Risk levels
public enum RiskLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Potential levels
public enum PotentialLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

// MARK: - Business Intelligence

/// Comprehensive business intelligence dashboard data
public struct BusinessIntelligence {
    public let churnAnalysis: ChurnAnalysis
    public let revenueForecasting: RevenueForecasting
    public let conversionOptimization: ConversionOptimization
    public let segmentInsights: SegmentInsights
    public let marketIntelligence: MarketIntelligence
    public let recommendations: [BusinessRecommendation]
    public let generatedAt: Date
    public let dataFreshness: DataFreshness
}

/// Churn analysis results
public struct ChurnAnalysis {
    public let currentChurnRate: Double
    public let predictedChurnRate: Double
    public let trendDirection: TrendDirection
    public let riskSegments: [RiskSegment]
    public let interventionOpportunities: [InterventionOpportunity]
    public let forecastAccuracy: Double
}

/// Revenue forecasting results
public struct RevenueForecasting {
    public let currentMRR: Double
    public let predictedMRR: Double
    public let revenueGrowthRate: Double
    public let seasonalityFactors: [SeasonalityFactor]
    public let confidenceIntervals: [ConfidenceInterval]
    public let scenarioProjections: [RevenueScenario]
}

/// Conversion optimization analysis
public struct ConversionOptimization {
    public let currentConversionRate: Double
    public let predictedConversionRate: Double
    public let optimizationOpportunities: [ConversionOpportunity]
    public let segmentPerformance: [SegmentConversionMetrics]
    public let recommendedActions: [ConversionAction]
}

/// User segment insights
public struct SegmentInsights {
    public let segments: [UserSegment]
    public let segmentPerformance: [SegmentPerformanceMetrics]
    public let migrationPatterns: [MigrationPattern]
    public let valueDistribution: [SegmentValueMetrics]
    public let growthOpportunities: [GrowthOpportunity]
}

/// Market intelligence data
public struct MarketIntelligence {
    public let marketTrends: [MarketTrend]
    public let competitivePositioning: CompetitivePositioning
    public let pricingBenchmarks: [PricingBenchmark]
    public let opportunityAreas: [MarketOpportunity]
    public let threatAssessment: [CompetitiveThreat]
}

/// Business recommendations
public struct BusinessRecommendation {
    public let title: String
    public let description: String
    public let priority: RecommendationPriority
    public let expectedImpact: Double
    public let implementationEffort: ImplementationEffort
    public let timeframe: Timeframe
    public let category: RecommendationCategory
}

// MARK: - Optimization Models

/// Optimization recommendation
public struct OptimizationRecommendation {
    public let type: OptimizationType
    public let title: String
    public let description: String
    public let expectedImpact: Double
    public let confidence: Double
    public let implementation: OptimizationImplementation
    public let timeframe: Timeframe
    public let metrics: [String]
}

/// Types of optimizations
public enum OptimizationType: String, CaseIterable {
    case pricing = "pricing"
    case trialOptimization = "trial_optimization"
    case retentionIntervention = "retention_intervention"
    case featureOptimization = "feature_optimization"
    case segmentTargeting = "segment_targeting"
    case conversionFunnel = "conversion_funnel"
}

/// Optimization implementation approaches
public enum OptimizationImplementation: String, CaseIterable {
    case automatic = "automatic"
    case userPrompt = "user_prompt"
    case manualReview = "manual_review"
}

// MARK: - Scenario Analysis

/// Business scenario for analysis
public struct BusinessScenario {
    public let id: String
    public let name: String
    public let description: String
    public let parameters: [String: Any]
    public let assumptions: [String]
}

/// Scenario analysis result
public struct ScenarioAnalysis {
    public let scenarios: [ScenarioResult]
    public let baselineMetrics: BaselineMetrics
    public let comparisonMatrix: ComparisonMatrix
    public let recommendations: [ScenarioRecommendation]
    public let generatedAt: Date
}

/// Individual scenario result
public struct ScenarioResult {
    public let scenario: BusinessScenario
    public let projectedMetrics: ProjectedMetrics
    public let riskFactors: [RiskFactor]
    public let probability: Double
}

/// Baseline metrics for comparison
public struct BaselineMetrics {
    public let currentMRR: Double = 0
    public let currentChurnRate: Double = 0
    public let currentConversionRate: Double = 0
    public let currentLTV: Double = 0
}

/// Comparison matrix for scenarios
public struct ComparisonMatrix {
    public let scenarios: [ScenarioResult]
    // Matrix comparison logic would be implemented here
}

/// Scenario recommendation
public struct ScenarioRecommendation {
    public let scenario: BusinessScenario
    public let recommendation: String
    public let reasoning: String
    public let confidence: Double
}

// MARK: - Supporting Models

/// Trend direction

/// Risk segment
public struct RiskSegment {
    public let name: String
    public let userCount: Int
    public let riskScore: Double
    public let characteristics: [String]
}

/// Intervention opportunity
public struct InterventionOpportunity {
    public let type: String
    public let targetSegment: String
    public let expectedImpact: Double
    public let recommendation: String
}

/// Seasonality factor
public struct SeasonalityFactor {
    public let period: String
    public let factor: Double
    public let confidence: Double
}

/// Confidence interval
public struct ConfidenceInterval {
    public let lower: Double
    public let upper: Double
    public let confidence: Double
}

/// Revenue scenario
public struct RevenueScenario {
    public let name: String
    public let projectedMRR: Double
    public let probability: Double
}

/// Conversion opportunity
public struct ConversionOpportunity {
    public let segment: String
    public let currentRate: Double
    public let potentialRate: Double
    public let userCount: Int
}

/// Segment conversion metrics
public struct SegmentConversionMetrics {
    public let segment: String
    public let conversionRate: Double
    public let averageTimeToConvert: TimeInterval
    public let dropoffStages: [String]
}

/// Conversion action
public struct ConversionAction {
    public let action: String
    public let targetSegment: String
    public let expectedLift: Double
    public let effort: ImplementationEffort
}

/// User segment
public struct UserSegment {
    public let id: String
    public let name: String
    public let userCount: Int
    public let characteristics: [String]
    public let averageLTV: Double
}

/// Segment performance metrics
public struct SegmentPerformanceMetrics {
    public let segment: String
    public let revenue: Double
    public let churnRate: Double
    public let conversionRate: Double
    public let growth: Double
}

/// Migration pattern
public struct MigrationPattern {
    public let fromSegment: String
    public let toSegment: String
    public let migrationRate: Double
    public let triggers: [String]
}

/// Segment value metrics
public struct SegmentValueMetrics {
    public let segment: String
    public let totalValue: Double
    public let averageValue: Double
    public let valueGrowth: Double
}

/// Growth opportunity
public struct GrowthOpportunity {
    public let segment: String
    public let opportunity: String
    public let potentialValue: Double
    public let probability: Double
}

/// Market trend
public struct MarketTrend {
    public let name: String
    public let direction: TrendDirection
    public let impact: Double
    public let timeframe: String
}

/// Competitive positioning
public struct CompetitivePositioning {
    public let position: String = "strong"
    public let strengths: [String] = []
    public let weaknesses: [String] = []
    public let opportunities: [String] = []
    public let threats: [String] = []
}

/// Pricing benchmark
public struct PricingBenchmark {
    public let competitor: String
    public let product: String
    public let price: Double
    public let features: [String]
}

/// Market opportunity
public struct MarketOpportunity {
    public let area: String
    public let size: Double
    public let competition: String
    public let barriers: [String]
}

/// Competitive threat
public struct CompetitiveThreat {
    public let competitor: String
    public let threat: String
    public let severity: String
    public let mitigation: String
}

/// Data freshness indicator
public struct DataFreshness {
    public let lastUpdate: Date
    public let stalenessMinutes: Int
    public let isStale: Bool
}

/// Projected metrics
public struct ProjectedMetrics {
    public let revenue: Double = 0
    public let churnRate: Double = 0
    public let conversionRate: Double = 0
    public let userGrowth: Double = 0
}

/// Risk factor
public struct RiskFactor {
    public let factor: String
    public let probability: Double
    public let impact: String
}

// MARK: - Enums

/// Recommendation priority
public enum RecommendationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Implementation effort
public enum ImplementationEffort: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Timeframe
public enum Timeframe: String, CaseIterable {
    case immediate = "immediate"
    case shortTerm = "short_term"
    case mediumTerm = "medium_term"
    case longTerm = "long_term"
}

/// Recommendation category
public enum RecommendationCategory: String, CaseIterable {
    case revenue = "revenue"
    case retention = "retention"
    case acquisition = "acquisition"
    case engagement = "engagement"
    case pricing = "pricing"
    case product = "product"
}

// MARK: - Placeholder Data Models

/// Placeholder structures for data pipeline

/// Churn predictions batch result
public struct ChurnPredictions {
    public let predictions: [ChurnPrediction]
    public let averagePrediction: Double
    public let confidence: Double
    
    public init(predictions: [ChurnPrediction]) {
        self.predictions = predictions
        self.averagePrediction = predictions.map { $0.probability }.reduce(0, +) / Double(predictions.count)
        self.confidence = predictions.map { $0.confidence }.reduce(0, +) / Double(predictions.count)
    }
}

/// LTV predictions batch result
public struct LTVPredictions {
    public let predictions: [LTVPrediction]
    public let projectedMRR: Double
    public let confidenceIntervals: [ConfidenceInterval]
    
    public init(predictions: [LTVPrediction]) {
        self.predictions = predictions
        self.projectedMRR = predictions.map { $0.predictedValue }.reduce(0, +) / 12 // Monthly from annual
        self.confidenceIntervals = predictions.map { prediction in
            ConfidenceInterval(
                lower: prediction.confidenceIntervalLower,
                upper: prediction.confidenceIntervalUpper,
                confidence: prediction.confidence
            )
        }
    }
}

/// Conversion predictions batch result
public struct ConversionPredictions {
    public let predictions: [ConversionPrediction]
    public let averagePrediction: Double
    
    public init(predictions: [ConversionPrediction]) {
        self.predictions = predictions
        self.averagePrediction = predictions.map { $0.probability }.reduce(0, +) / Double(predictions.count)
    }
}

/// Segment predictions batch result
public struct SegmentPredictions {
    public let predictions: [SegmentationPrediction]
    public let segments: [UserSegment]
    
    public init(predictions: [SegmentationPrediction]) {
        self.predictions = predictions
        self.segments = [] // Would be populated with actual segments
    }
}

/// Revenue data for analysis
public struct RevenueData {
    public let currentMRR: Double
    public let historicalMRR: [Double]
    public let timeRange: DateRange
}

/// Market data for intelligence
public struct MarketData {
    public let trends: [MarketTrend]
    public let size: Double
    public let growth: Double
}

/// Competitive data for analysis
public struct CompetitiveData {
    public let competitors: [String]
    public let marketShare: [String: Double]
    public let pricing: [PricingBenchmark]
}

/// Trial analysis result
public struct TrialAnalysis {
    public let optimalTrialLength: Int = 14
    public let currentAverageLength: Int = 14
    public let expectedImpactFromLengthChange: Double = 0.15
    public let lengthOptimizationConfidence: Double = 0.8
}

/// Churn risk data
public struct ChurnRisk {
    public let userId: String
    public let riskScore: Double
    public let factors: [String]
}

/// Feature analysis result
public struct FeatureAnalysis {
    public let recommendations: [FeatureRecommendation] = []
}

/// Feature recommendation
public struct FeatureRecommendation {
    public let title: String = ""
    public let description: String = ""
    public let expectedImpact: Double = 0
    public let confidence: Double = 0
    public let trackingMetrics: [String] = []
}

