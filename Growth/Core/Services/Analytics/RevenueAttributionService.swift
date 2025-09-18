/**
 * RevenueAttributionService.swift
 * Growth App Revenue Attribution System
 *
 * Advanced revenue attribution service for tracking subscription revenue
 * sources, multi-touch attribution, and feature-driven conversion analysis.
 */

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import os.log

// MARK: - Shared Types
// Types like PaywallContext, SubscriptionTier, SubscriptionDuration, 
// RevenueSource, and AnyCodable are defined in AnalyticsModels.swift
// Using the global Logger from Growth/Core/Utilities/Logger.swift

/// Service for tracking and analyzing revenue attribution across features and touchpoints
public class RevenueAttributionService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = RevenueAttributionService()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isTracking: Bool = true
    @Published public private(set) var attributionAccuracy: Double = 0.95
    @Published public private(set) var lastAttributionUpdate: Date?
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private var touchpointHistory: [TouchpointEvent] = []
    private let attributionWindow: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let maxTouchpoints = 10
    
    // Attribution models
    private let attributionModels: [AttributionModel] = [
        .firstTouch, .lastTouch, .linear, .timeDecay, .positionBased
    ]
    
    private init() {
        setupAttributionTracking()
    }
    
    // MARK: - Touchpoint Tracking
    
    /// Record a touchpoint in the user's conversion journey
    public func recordTouchpoint(
        source: RevenueSource,
        context: PaywallContext,
        touchpointType: TouchpointType,
        metadata: [String: Any] = [:]
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let touchpoint = TouchpointEvent(
            userId: userId,
            source: source,
            context: context,
            type: touchpointType,
            timestamp: Date(),
            metadata: metadata
        )
        
        // Add to history and maintain window size
        touchpointHistory.append(touchpoint)
        cleanupOldTouchpoints()
        
        // Save to Firestore for persistence
        saveTouchpoint(touchpoint)
        
        Logger.debug("RevenueAttribution: Recorded touchpoint \(source.rawValue) - \(touchpointType.rawValue)")
    }
    
    /// Attribute revenue to sources based on touchpoint history
    public func attributeRevenue(
        amount: Double,
        subscriptionTier: SubscriptionTier,
        subscriptionDuration: SubscriptionDuration,
        conversionTimestamp: Date = Date()
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get relevant touchpoints within attribution window
        let relevantTouchpoints = getRelevantTouchpoints(for: conversionTimestamp)
        
        if relevantTouchpoints.isEmpty {
            Logger.warning("RevenueAttribution: No touchpoints found for revenue attribution")
            return
        }
        
        // Calculate attribution for each model
        for model in attributionModels {
            let attributions = calculateAttribution(
                amount: amount,
                touchpoints: relevantTouchpoints,
                model: model
            )
            
            // Save attribution records
            for attribution in attributions {
                let record = RevenueAttributionRecord(
                    userId: userId,
                    totalAmount: amount,
                    attributedAmount: attribution.amount,
                    source: attribution.source,
                    model: model,
                    subscriptionTier: subscriptionTier,
                    subscriptionDuration: subscriptionDuration,
                    conversionTimestamp: conversionTimestamp,
                    touchpoints: relevantTouchpoints,
                    metadata: [
                        "attribution_weight": attribution.weight,
                        "touchpoint_count": relevantTouchpoints.count
                    ]
                )
                
                saveAttributionRecord(record)
            }
        }
        
        // Update analytics service
        // TODO: Restore when PaywallAnalyticsService is available
        // PaywallAnalyticsService.shared.attributeRevenue(
        //     amount,
        //     source: determinePrimarySource(from: relevantTouchpoints),
        //     event: .subscriptionPurchased,
        //     metadata: [
        //         "subscription_tier": subscriptionTier.rawValue,
        //         "subscription_duration": subscriptionDuration.rawValue,
        //         "touchpoint_count": relevantTouchpoints.count
        //     ]
        // )
        
        lastAttributionUpdate = Date()
        
        Logger.info("RevenueAttribution: Attributed \(amount) revenue across \(relevantTouchpoints.count) touchpoints")
    }
    
    // MARK: - Attribution Analysis
    
    /// Get revenue attribution breakdown by source for time period
    public func getAttributionBreakdown(
        timeRange: AnalyticsDateRange,
        model: AttributionModel = .timeDecay,
        completion: @escaping (RevenueAttributionBreakdown) -> Void
    ) {
        firestore.collection("revenueAttributionRecords")
            .whereField("conversionTimestamp", isGreaterThanOrEqualTo: timeRange.startDate)
            .whereField("conversionTimestamp", isLessThanOrEqualTo: timeRange.endDate)
            .whereField("model", isEqualTo: model.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    Logger.error("RevenueAttribution: Error fetching attribution data: \(error)")
                    completion(RevenueAttributionBreakdown.empty)
                    return
                }
                
                let records = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: RevenueAttributionRecord.self)
                } ?? []
                
                let breakdown = self.aggregateAttributionData(records)
                completion(breakdown)
            }
    }
    
    /// Analyze feature-driven revenue performance
    public func analyzeFeatureRevenue(
        timeRange: AnalyticsDateRange,
        completion: @escaping ([FeatureRevenueAnalysis]) -> Void
    ) {
        getAttributionBreakdown(timeRange: timeRange, model: AttributionModel.timeDecay) { breakdown in
            let featureAnalysis = breakdown.sourceBreakdown.compactMap { (sourceData: SourceRevenueData) -> FeatureRevenueAnalysis? in
                guard let feature = sourceData.source.associatedFeature else { return nil }
                
                return FeatureRevenueAnalysis(
                    feature: feature,
                    totalRevenue: sourceData.totalRevenue,
                    conversionCount: sourceData.conversionCount,
                    averageRevenuePerUser: sourceData.averageRevenuePerUser,
                    attributionWeight: sourceData.source.attributionWeight,
                    revenueShare: sourceData.totalRevenue / breakdown.totalRevenue
                )
            }.sorted { (analysis1: FeatureRevenueAnalysis, analysis2: FeatureRevenueAnalysis) -> Bool in
                analysis1.totalRevenue > analysis2.totalRevenue
            }
            
            completion(featureAnalysis)
        }
    }
    
    /// Calculate attribution model accuracy
    public func calculateAttributionAccuracy(
        testPeriod: AnalyticsDateRange,
        completion: @escaping (AttributionAccuracyReport) -> Void
    ) {
        // Implementation would compare different attribution models
        // and measure their accuracy against known conversion patterns
        
        // For now, return a simulated accuracy report
        let report = AttributionAccuracyReport(
            period: testPeriod,
            modelAccuracies: [
                AttributionModel.firstTouch: 0.72,
                AttributionModel.lastTouch: 0.84,
                AttributionModel.linear: 0.89,
                AttributionModel.timeDecay: 0.95,
                AttributionModel.positionBased: 0.91
            ],
            recommendedModel: AttributionModel.timeDecay,
            confidenceLevel: 0.95
        )
        
        completion(report)
    }
    
    // MARK: - Multi-Touch Attribution Models
    
    private func calculateAttribution(
        amount: Double,
        touchpoints: [TouchpointEvent],
        model: AttributionModel
    ) -> [SourceAttribution] {
        guard !touchpoints.isEmpty else { return [] }
        
        switch model {
        case .firstTouch:
            return [SourceAttribution(source: touchpoints.first!.source, amount: amount, weight: 1.0)]
            
        case .lastTouch:
            return [SourceAttribution(source: touchpoints.last!.source, amount: amount, weight: 1.0)]
            
        case .linear:
            let weightPerTouchpoint = 1.0 / Double(touchpoints.count)
            let amountPerTouchpoint = amount * weightPerTouchpoint
            return touchpoints.map { touchpoint in
                SourceAttribution(source: touchpoint.source, amount: amountPerTouchpoint, weight: weightPerTouchpoint)
            }
            
        case .timeDecay:
            return calculateTimeDecayAttribution(amount: amount, touchpoints: touchpoints)
            
        case .positionBased:
            return calculatePositionBasedAttribution(amount: amount, touchpoints: touchpoints)
        }
    }
    
    private func calculateTimeDecayAttribution(amount: Double, touchpoints: [TouchpointEvent]) -> [SourceAttribution] {
        let now = Date()
        let halfLife: TimeInterval = 3 * 24 * 60 * 60 // 3 days
        
        // Calculate decay weights
        var totalWeight: Double = 0
        let weights = touchpoints.map { touchpoint in
            let timeDiff = now.timeIntervalSince(touchpoint.timestamp)
            let weight = pow(0.5, timeDiff / halfLife)
            totalWeight += weight
            return weight
        }
        
        // Normalize weights and calculate attribution
        return zip(touchpoints, weights).map { touchpoint, weight in
            let normalizedWeight = weight / totalWeight
            return SourceAttribution(
                source: touchpoint.source,
                amount: amount * normalizedWeight,
                weight: normalizedWeight
            )
        }
    }
    
    private func calculatePositionBasedAttribution(amount: Double, touchpoints: [TouchpointEvent]) -> [SourceAttribution] {
        let count = touchpoints.count
        
        if count == 1 {
            return [SourceAttribution(source: touchpoints[0].source, amount: amount, weight: 1.0)]
        }
        
        // 40% to first, 20% to last, 40% distributed among middle touchpoints
        let firstWeight = 0.4
        let lastWeight = 0.2
        let middleWeight = count > 2 ? 0.4 / Double(count - 2) : 0.0
        
        var attributions: [SourceAttribution] = []
        
        for (index, touchpoint) in touchpoints.enumerated() {
            let weight: Double
            if index == 0 {
                weight = firstWeight
            } else if index == count - 1 {
                weight = lastWeight
            } else {
                weight = middleWeight
            }
            
            attributions.append(SourceAttribution(
                source: touchpoint.source,
                amount: amount * weight,
                weight: weight
            ))
        }
        
        return attributions
    }
    
    // MARK: - Helper Methods
    
    private func setupAttributionTracking() {
        // Load persisted touchpoints for current user
        loadTouchpointHistory()
    }
    
    private func getRelevantTouchpoints(for conversionTimestamp: Date) -> [TouchpointEvent] {
        let cutoffTime = conversionTimestamp.addingTimeInterval(-attributionWindow)
        return touchpointHistory.filter { $0.timestamp >= cutoffTime && $0.timestamp <= conversionTimestamp }
    }
    
    private func cleanupOldTouchpoints() {
        let cutoffTime = Date().addingTimeInterval(-attributionWindow)
        touchpointHistory = touchpointHistory.filter { $0.timestamp >= cutoffTime }
        
        // Limit to max touchpoints
        if touchpointHistory.count > maxTouchpoints {
            touchpointHistory = Array(touchpointHistory.suffix(maxTouchpoints))
        }
    }
    
    private func determinePrimarySource(from touchpoints: [TouchpointEvent]) -> RevenueSource {
        // Use time-decay model to determine primary source
        let attributions = calculateTimeDecayAttribution(amount: 1.0, touchpoints: touchpoints)
        return attributions.max(by: { $0.weight < $1.weight })?.source ?? .generalPaywall
    }
    
    private func aggregateAttributionData(_ records: [RevenueAttributionRecord]) -> RevenueAttributionBreakdown {
        var sourceBreakdown: [RevenueSource: SourceRevenueData] = [:]
        var totalRevenue: Double = 0
        
        for record in records {
            let source = record.source
            let amount = record.attributedAmount
            
            if sourceBreakdown[source] == nil {
                sourceBreakdown[source] = SourceRevenueData(
                    source: source,
                    totalRevenue: 0,
                    conversionCount: 0,
                    averageRevenuePerUser: 0
                )
            }
            
            sourceBreakdown[source]!.totalRevenue += amount
            sourceBreakdown[source]!.conversionCount += 1
            totalRevenue += amount
        }
        
        // Calculate averages
        for (source, _) in sourceBreakdown {
            let data = sourceBreakdown[source]!
            sourceBreakdown[source]!.averageRevenuePerUser = data.totalRevenue / Double(data.conversionCount)
        }
        
        return RevenueAttributionBreakdown(
            totalRevenue: totalRevenue,
            sourceBreakdown: Array(sourceBreakdown.values).sorted { $0.totalRevenue > $1.totalRevenue }
        )
    }
    
    // MARK: - Persistence
    
    private func saveTouchpoint(_ touchpoint: TouchpointEvent) {
        do {
            let data = try Firestore.Encoder().encode(touchpoint)
            firestore.collection("touchpoints").document(touchpoint.id).setData(data)
        } catch {
            Logger.error("RevenueAttribution: Error saving touchpoint: \(error)")
        }
    }
    
    private func saveAttributionRecord(_ record: RevenueAttributionRecord) {
        do {
            let data = try Firestore.Encoder().encode(record)
            firestore.collection("revenueAttributionRecords").document(record.id).setData(data)
        } catch {
            Logger.error("RevenueAttribution: Error saving attribution record: \(error)")
        }
    }
    
    private func loadTouchpointHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let cutoffTime = Date().addingTimeInterval(-attributionWindow)
        
        firestore.collection("touchpoints")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: cutoffTime)
            .order(by: "timestamp")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    Logger.error("RevenueAttribution: Error loading touchpoint history: \(error)")
                    return
                }
                
                let touchpoints = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TouchpointEvent.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.touchpointHistory = touchpoints
                }
            }
    }
}

// MARK: - Supporting Models

/// Types of touchpoints in the conversion journey
public enum TouchpointType: String, CaseIterable, Codable {
    case impression = "impression"
    case interaction = "interaction"
    case consideration = "consideration"
    case intent = "intent"
    case conversion = "conversion"
    
    public var weight: Double {
        switch self {
        case .impression: return 0.1
        case .interaction: return 0.3
        case .consideration: return 0.6
        case .intent: return 0.9
        case .conversion: return 1.0
        }
    }
}

/// Attribution models for revenue calculation
public enum AttributionModel: String, CaseIterable, Codable {
    case firstTouch = "first_touch"
    case lastTouch = "last_touch"
    case linear = "linear"
    case timeDecay = "time_decay"
    case positionBased = "position_based"
    
    public var displayName: String {
        switch self {
        case .firstTouch: return "First Touch"
        case .lastTouch: return "Last Touch"
        case .linear: return "Linear"
        case .timeDecay: return "Time Decay"
        case .positionBased: return "Position Based"
        }
    }
}

/// Touchpoint event in conversion journey
public struct TouchpointEvent: Codable {
    public let id: String
    public let userId: String
    public let source: RevenueSource
    public let context: PaywallContext
    public let type: TouchpointType
    public let timestamp: Date
    public let metadata: [String: AnyCodable]
    
    public init(
        userId: String,
        source: RevenueSource,
        context: PaywallContext,
        type: TouchpointType,
        timestamp: Date,
        metadata: [String: Any] = [:]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.source = source
        self.context = context
        self.type = type
        self.timestamp = timestamp
        self.metadata = metadata.mapValues { AnyCodable($0) }
    }
}

/// Source attribution result
public struct SourceAttribution {
    public let source: RevenueSource
    public let amount: Double
    public let weight: Double
}

/// Revenue attribution record
public struct RevenueAttributionRecord: Codable {
    public let id: String
    public let userId: String
    public let totalAmount: Double
    public let attributedAmount: Double
    public let source: RevenueSource
    public let model: AttributionModel
    public let subscriptionTier: SubscriptionTier
    public let subscriptionDuration: SubscriptionDuration
    public let conversionTimestamp: Date
    public let touchpoints: [TouchpointEvent]
    public let metadata: [String: AnyCodable]
    
    public init(
        userId: String,
        totalAmount: Double,
        attributedAmount: Double,
        source: RevenueSource,
        model: AttributionModel,
        subscriptionTier: SubscriptionTier,
        subscriptionDuration: SubscriptionDuration,
        conversionTimestamp: Date,
        touchpoints: [TouchpointEvent],
        metadata: [String: Any] = [:]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.totalAmount = totalAmount
        self.attributedAmount = attributedAmount
        self.source = source
        self.model = model
        self.subscriptionTier = subscriptionTier
        self.subscriptionDuration = subscriptionDuration
        self.conversionTimestamp = conversionTimestamp
        self.touchpoints = touchpoints
        self.metadata = metadata.mapValues { AnyCodable($0) }
    }
}

/// Revenue data by source
public struct SourceRevenueData {
    public let source: RevenueSource
    public var totalRevenue: Double
    public var conversionCount: Int
    public var averageRevenuePerUser: Double
}

/// Attribution breakdown summary
public struct RevenueAttributionBreakdown {
    public let totalRevenue: Double
    public let sourceBreakdown: [SourceRevenueData]
    
    public init(totalRevenue: Double, sourceBreakdown: [SourceRevenueData]) {
        self.totalRevenue = totalRevenue
        self.sourceBreakdown = sourceBreakdown
    }
    
    public static let empty = RevenueAttributionBreakdown(totalRevenue: 0, sourceBreakdown: [])
}

/// Feature revenue analysis
public struct FeatureRevenueAnalysis: Equatable {
    public let feature: String
    public let totalRevenue: Double
    public let conversionCount: Int
    public let averageRevenuePerUser: Double
    public let attributionWeight: Double
    public let revenueShare: Double
    
    public init(feature: String, totalRevenue: Double, conversionCount: Int, 
                averageRevenuePerUser: Double, attributionWeight: Double, revenueShare: Double) {
        self.feature = feature
        self.totalRevenue = totalRevenue
        self.conversionCount = conversionCount
        self.averageRevenuePerUser = averageRevenuePerUser
        self.attributionWeight = attributionWeight
        self.revenueShare = revenueShare
    }
}

/// Attribution accuracy report
public struct AttributionAccuracyReport {
    public let period: AnalyticsDateRange
    public let modelAccuracies: [AttributionModel: Double]
    public let recommendedModel: AttributionModel
    public let confidenceLevel: Double
}

// MARK: - Codable Extensions

extension TouchpointEvent {
    private enum CodingKeys: String, CodingKey {
        case id, userId, source, context, type, timestamp, metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        source = try container.decode(RevenueSource.self, forKey: .source)
        
        // Decode PaywallContext directly since it's Codable
        context = try container.decode(PaywallContext.self, forKey: .context)
        
        type = try container.decode(TouchpointType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(source, forKey: .source)
        try container.encode(context, forKey: .context)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(metadata, forKey: .metadata)
    }
}