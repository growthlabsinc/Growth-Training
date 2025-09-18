/**
 * MetricsDashboardViewModel.swift
 * Growth App Metrics Dashboard
 *
 * Real-time analytics dashboard for paywall conversion tracking,
 * revenue metrics, and A/B testing results with stakeholder reporting.
 */

import Foundation
import Combine
import FirebaseFirestore
import os.log

private let logger = os.Logger(subsystem: "com.growthlabs.growthmethod", category: "MetricsDashboard")

// Note: Using SignificanceResult from ExperimentModels.swift
// All analytics types are now properly available from the Analytics module files

/// ViewModel for real-time metrics dashboard
@MainActor
public class MetricsDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var conversionMetrics: ConversionMetrics = ConversionMetrics.empty
    @Published public var revenueMetrics: RevenueMetrics = RevenueMetrics.empty
    @Published public var activeExperiments: [ExperimentSummary] = []
    @Published public var cohortAnalysis: CohortAnalysis = CohortAnalysis.empty
    @Published public var isLoading: Bool = false
    @Published public var lastUpdateTime: Date?
    @Published public var selectedTimeRange: AnalyticsTimeRange = .last7Days
    
    // Error handling
    @Published public var errorState: AnalyticsError?
    @Published public var isRetrying: Bool = false
    @Published public var networkStatus: NetworkStatus = .connected
    
    // MARK: - Private Properties
    
    private let analyticsService = PaywallAnalyticsService.shared
    private let experimentService = PaywallExperimentService.shared  
    private let revenueService = RevenueAttributionService.shared
    private var cancellables = Set<AnyCancellable>()
    private let firestore = Firestore.firestore()
    
    // Real-time update configuration
    private let updateInterval: TimeInterval = 30 // 30 seconds
    private var updateTimer: Timer?
    
    // Cache for performance
    private var metricsCache: [String: Any] = [:]
    private var lastCacheUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute
    
    // Error handling and retry logic
    private let maxRetryAttempts = 3
    private var retryAttempts: [String: Int] = [:]
    private let retryDelay: TimeInterval = 2.0
    
    public init() {
        setupRealTimeUpdates()
        refreshAllMetrics()
    }
    
    // MARK: - Public Methods
    
    /// Refresh all dashboard metrics with error handling
    public func refreshAllMetrics() {
        Task {
            isLoading = true
            errorState = nil
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.refreshConversionMetrics() }
                group.addTask { await self.refreshRevenueMetrics() }
                group.addTask { await self.refreshActiveExperiments() }
                group.addTask { await self.refreshCohortAnalysis() }
            }
            
            await MainActor.run {
                self.lastUpdateTime = Date()
                self.isLoading = false
                
                // Check if all metrics loaded successfully
                if self.conversionMetrics == ConversionMetrics.empty &&
                   self.revenueMetrics == RevenueMetrics.empty {
                    self.errorState = .dataLoadingFailed
                }
            }
        }
    }
    
    /// Update selected time range and refresh metrics
    public func updateTimeRange(_ range: AnalyticsTimeRange) {
        selectedTimeRange = range
        invalidateCache()
        refreshAllMetrics()
    }
    
    /// Export comprehensive metrics report
    public func exportMetricsReport(format: ExportFormat) -> URL? {
        let report = createMetricsReport()
        
        switch format {
        case .csv:
            return exportAsCSV(report)
        case .json:
            return exportAsJSON(report)
        case .pdf:
            return exportAsPDF(report)
        }
    }
    
    /// Generate stakeholder summary email
    public func generateStakeholderSummary() -> StakeholderSummary {
        return StakeholderSummary(
            period: selectedTimeRange.dateRange,
            overallConversionRate: conversionMetrics.overallConversionRate,
            totalRevenue: revenueMetrics.totalRevenue,
            topPerformingFeature: revenueMetrics.topRevenueSource,
            activeExperimentCount: activeExperiments.count,
            significantExperiments: activeExperiments.filter { $0.hasSignificantResults },
            cohortInsights: cohortAnalysis.keyInsights,
            recommendations: generateRecommendations()
        )
    }
    
    // MARK: - Private Methods
    
    private func getFeatureDisplayName(_ feature: String) -> String {
        switch feature {
        case "aiCoach": return "AI Coach"
        case "customRoutines": return "Custom Routines"
        case "progressTracking": return "Progress Tracking"
        case "advancedAnalytics": return "Advanced Analytics"
        case "liveActivities": return "Live Activities"
        case "allMethods": return "All Methods"
        default: return feature.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func mapRevenueSourceToFeature(_ source: String) -> String? {
        switch source {
        case "feature_gate_ai_coach", "featureGateAICoach": return "aiCoach"
        case "feature_gate_custom_routines", "featureGateCustomRoutines": return "customRoutines"
        case "feature_gate_progress_tracking", "featureGateProgressTracking": return "progressTracking"
        case "feature_gate_advanced_analytics", "featureGateAdvancedAnalytics": return "advancedAnalytics"
        case "feature_gate_live_activities", "featureGateLiveActivities": return "liveActivities"
        default: return nil
        }
    }
    
    private func setupRealTimeUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            Task { @MainActor in
                if !self.isLoading {
                    self.refreshAllMetrics()
                }
            }
        }
    }
    
    private func refreshConversionMetrics() async {
        await MainActor.run {
            isLoading = true
        }
        
        let cacheKey = "conversion_metrics_\(selectedTimeRange.rawValue)"
        if let cached = getCachedValue(for: cacheKey) as? ConversionMetrics {
            await MainActor.run {
                conversionMetrics = cached
            }
            return
        }
        
        // Fetch conversion funnel data
        let dateRange = selectedTimeRange.dateRange
        
        // Fetch data concurrently
        async let impressions = getFunnelStepCount("paywallImpression", dateRange: dateRange)
        async let purchases = getFunnelStepCount("purchaseCompleted", dateRange: dateRange)
        async let funnelData = getFunnelBreakdown(dateRange: dateRange)
        async let conversionsBySource = getConversionRatesBySource(dateRange: dateRange)
        async let avgTimeToConversion = getAverageTimeToConversion(dateRange: dateRange)
        async let exitIntentRecovery = getExitIntentRecoveryRate(dateRange: dateRange)
        
        let impressionCount = await impressions
        let purchaseCount = await purchases
        let overallRate = impressionCount > 0 ? Double(purchaseCount) / Double(impressionCount) : 0.0
        
        let metrics = ConversionMetrics(
            overallConversionRate: overallRate,
            totalImpressions: await impressions,
            totalPurchases: await purchases,
            funnelBreakdown: await funnelData,
            conversionRatesBySource: await conversionsBySource,
            averageTimeToConversion: await avgTimeToConversion,
            exitIntentRecoveryRate: await exitIntentRecovery
        )
        
        self.conversionMetrics = metrics
        self.setCachedValue(metrics, for: cacheKey)
    }
    
    private func refreshRevenueMetrics() async {
        let cacheKey = "revenue_metrics_\(selectedTimeRange.rawValue)"
        if let cached = getCachedValue(for: cacheKey) as? RevenueMetrics {
            revenueMetrics = cached
            return
        }
        
        let dateRange = selectedTimeRange.dateRange
        
        // Use RevenueAttributionService for comprehensive data
        let attributionBreakdown = await getAttributionBreakdown(dateRange: dateRange)
        let featureRevenues = await getFeatureRevenueAnalysis(dateRange: dateRange)
        
        let metrics = RevenueMetrics(
            totalRevenue: attributionBreakdown.totalRevenue,
            revenuePerVisitor: conversionMetrics.totalImpressions > 0 ? 
                attributionBreakdown.totalRevenue / Double(conversionMetrics.totalImpressions) : 0,
            topRevenueSource: attributionBreakdown.sourceBreakdown.first?.source ?? "generalPaywall",
            revenueByFeature: featureRevenues,
            revenueGrowthRate: await calculateRevenueGrowthRate(dateRange: dateRange),
            averageRevenuePerUser: await getAverageRevenuePerUser(dateRange: dateRange)
        )
        
        revenueMetrics = metrics
        setCachedValue(metrics, for: cacheKey)
    }
    
    private func refreshActiveExperiments() async {
        let experiments = experimentService.activeExperiments
        
        var summaries: [ExperimentSummary] = []
        
        for experiment in experiments {
            let significance = experimentService.calculateStatisticalSignificance(experiment)
            let results = await getExperimentResults(experiment.id)
            
            let summary = ExperimentSummary(
                id: experiment.id,
                name: experiment.name,
                status: experiment.status,
                startDate: experiment.actualStartDate ?? experiment.startDate,
                sampleSize: results?.totalSampleSize ?? 0,
                hasSignificantResults: significance.isSignificant,
                winningVariant: significance.winningVariant?.name,
                conversionLift: significance.effect
            )
            
            summaries.append(summary)
        }
        
        activeExperiments = summaries
    }
    
    private func refreshCohortAnalysis() async {
        let cacheKey = "cohort_analysis_\(selectedTimeRange.rawValue)"
        if let cached = getCachedValue(for: cacheKey) as? CohortAnalysis {
            await MainActor.run {
                cohortAnalysis = cached
            }
            return
        }
        
        let dateRange = selectedTimeRange.dateRange
        let cohortData = await getCohortPerformanceData(dateRange: dateRange)
        
        let analysis = CohortAnalysis(
            cohortPerformance: cohortData,
            acquisitionChannelBreakdown: await getAcquisitionChannelData(dateRange: dateRange),
            retentionRates: await getRetentionRatesByCohort(dateRange: dateRange),
            lifetimeValueProjections: await getLTVProjections(dateRange: dateRange),
            keyInsights: generateCohortInsights(from: cohortData)
        )
        
        await MainActor.run {
            cohortAnalysis = analysis
        }
        setCachedValue(analysis, for: cacheKey)
    }
    
    // MARK: - Data Fetching Methods
    
    private func getFunnelStepCount(_ step: String, dateRange: AnalyticsDateRange) async -> Int {
        return await withErrorHandling(operation: "getFunnelStepCount_\(step)") {
            let query = self.firestore.collection("analytics_events")
                .whereField("eventType", isEqualTo: step)
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.count
        } ?? 0
    }
    
    private func getFunnelBreakdown(dateRange: AnalyticsDateRange) async -> [String: Int] {
        return await withErrorHandling(operation: "getFunnelBreakdown") {
            var breakdown: [String: Int] = [:]
            
            let allSteps = ["paywallImpression", "featureHighlightView", "pricingOptionView", "purchaseInitiated", "purchaseCompleted"]
            
            await withTaskGroup(of: (String, Int).self) { group in
                for step in allSteps {
                    group.addTask {
                        let count = await self.getFunnelStepCount(step, dateRange: dateRange)
                        return (step, count)
                    }
                }
                
                for await (step, count) in group {
                    breakdown[step] = count
                }
            }
            
            return breakdown
        } ?? [:]
    }
    
    private func getConversionRatesBySource(dateRange: AnalyticsDateRange) async -> [String: Double] {
        return await withErrorHandling(operation: "getConversionRatesBySource") {
            var conversionRates: [String: Double] = [:]
            
            let sources = ["featureGateAICoach", "featureGateCustomRoutines", "sessionCompletion", "onboardingFlow", "settingsUpgrade"]
            
            for source in sources {
                // Get impressions for this source
                let impressionsQuery = self.firestore.collection("analytics_events")
                    .whereField("eventType", isEqualTo: "paywallImpression")
                    .whereField("revenueSource", isEqualTo: source)
                    .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
                
                // Get conversions for this source
                let conversionsQuery = self.firestore.collection("analytics_events")
                    .whereField("eventType", isEqualTo: "purchaseCompleted")
                    .whereField("revenueSource", isEqualTo: source)
                    .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
                
                async let impressionsSnapshot = impressionsQuery.getDocuments()
                async let conversionsSnapshot = conversionsQuery.getDocuments()
                
                let impressions = try await impressionsSnapshot.documents.count
                let conversions = try await conversionsSnapshot.documents.count
                
                conversionRates[source] = impressions > 0 ? Double(conversions) / Double(impressions) : 0.0
            }
            
            return conversionRates
        } ?? [:]
    }
    
    private func getAverageTimeToConversion(dateRange: AnalyticsDateRange) async -> TimeInterval {
        return await withErrorHandling(operation: "getAverageTimeToConversion") {
            let query = self.firestore.collection("analytics_events")
                .whereField("eventType", isEqualTo: "purchaseCompleted")
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            let snapshot = try await query.getDocuments()
            
            var totalTime: TimeInterval = 0
            var conversionCount = 0
            
            for document in snapshot.documents {
                if let sessionStartTime = document.data()["sessionStartTime"] as? Timestamp,
                   let conversionTime = document.data()["timestamp"] as? Timestamp {
                    totalTime += conversionTime.dateValue().timeIntervalSince(sessionStartTime.dateValue())
                    conversionCount += 1
                }
            }
            
            return conversionCount > 0 ? totalTime / Double(conversionCount) : 0
        } ?? 0
    }
    
    private func getExitIntentRecoveryRate(dateRange: AnalyticsDateRange) async -> Double {
        return await withErrorHandling(operation: "getExitIntentRecoveryRate") {
            // Get exit intent events
            let exitIntentQuery = self.firestore.collection("analytics_events")
                .whereField("eventType", isEqualTo: "exit_intent_triggered")
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            // Get subsequent conversions within 10 minutes
            let recoveryQuery = self.firestore.collection("analytics_events")
                .whereField("eventType", isEqualTo: "purchaseCompleted")
                .whereField("exitIntentRecovered", isEqualTo: true)
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            async let exitIntentSnapshot = exitIntentQuery.getDocuments()
            async let recoverySnapshot = recoveryQuery.getDocuments()
            
            let exitIntentCount = try await exitIntentSnapshot.documents.count
            let recoveryCount = try await recoverySnapshot.documents.count
            
            return exitIntentCount > 0 ? Double(recoveryCount) / Double(exitIntentCount) : 0.0
        } ?? 0
    }
    
    private func getAttributionBreakdown(dateRange: AnalyticsDateRange) async -> DashboardRevenueAttributionBreakdown {
        return await withErrorHandling(operation: "getAttributionBreakdown") {
            // For now, return a basic implementation
            // TODO: Implement proper attribution breakdown calculation
            return DashboardRevenueAttributionBreakdown(
                totalRevenue: 0,
                sourceBreakdown: []
            )
        } ?? DashboardRevenueAttributionBreakdown.empty
    }
    
    private func getFeatureRevenueAnalysis(dateRange: AnalyticsDateRange) async -> [FeatureRevenueData] {
        return await withErrorHandling(operation: "getFeatureRevenueAnalysis") {
            // Query subscription events to get revenue by feature
            let query = self.firestore.collection("subscription_events")
                .whereField("eventType", isEqualTo: "purchase_completed")
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            let snapshot = try await query.getDocuments()
            
            var featureRevenues: [String: Double] = [:]
            var featureConversions: [String: Int] = [:]
            
            for document in snapshot.documents {
                let data = document.data()
                guard let revenueAmount = data["revenueAmount"] as? Double,
                      let revenueSourceString = data["revenueSource"] as? String else { continue }
                
                // Map revenue source to feature
                let feature = self.mapRevenueSourceToFeature(revenueSourceString)
                if let feature = feature {
                    featureRevenues[feature, default: 0.0] += revenueAmount
                    featureConversions[feature, default: 0] += 1
                }
            }
            
            let totalRevenue = featureRevenues.values.reduce(0, +)
            
            return featureRevenues.map { feature, revenue in
                FeatureRevenueData(
                    featureName: self.getFeatureDisplayName(feature),
                    revenue: revenue,
                    percentage: totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0
                )
            }.sorted { $0.revenue > $1.revenue }
        } ?? []
    }
    
    private func calculateRevenueGrowthRate(dateRange: AnalyticsDateRange) async -> Double {
        return await withErrorHandling(operation: "calculateRevenueGrowthRate") {
            // Calculate previous period of same duration
            let duration = dateRange.endDate.timeIntervalSince(dateRange.startDate)
            let previousPeriodStart = Calendar.current.date(byAdding: .second, value: -Int(duration), to: dateRange.startDate) ?? dateRange.startDate
            let previousPeriodEnd = dateRange.startDate
            
            // Get current period revenue
            let currentRevenueQuery = self.firestore.collection("subscription_events")
                .whereField("eventType", isEqualTo: "purchase_completed")
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            // Get previous period revenue
            let previousRevenueQuery = self.firestore.collection("subscription_events")
                .whereField("eventType", isEqualTo: "purchase_completed")
                .whereField("timestamp", isGreaterThanOrEqualTo: previousPeriodStart)
                .whereField("timestamp", isLessThanOrEqualTo: previousPeriodEnd)
            
            async let currentSnapshot = currentRevenueQuery.getDocuments()
            async let previousSnapshot = previousRevenueQuery.getDocuments()
            
            let currentRevenue = try await currentSnapshot.documents.reduce(0.0) { sum, doc in
                let amount = doc.data()["revenueAmount"] as? Double ?? 0.0
                return sum + amount
            }
            
            let previousRevenue = try await previousSnapshot.documents.reduce(0.0) { sum, doc in
                let amount = doc.data()["revenueAmount"] as? Double ?? 0.0
                return sum + amount
            }
            
            return previousRevenue > 0 ? (currentRevenue - previousRevenue) / previousRevenue : 0.0
        } ?? 0
    }
    
    private func getAverageRevenuePerUser(dateRange: AnalyticsDateRange) async -> Double {
        return await withErrorHandling(operation: "getAverageRevenuePerUser") {
            let query = self.firestore.collection("subscription_events")
                .whereField("eventType", isEqualTo: "purchase_completed")
                .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
            
            let snapshot = try await query.getDocuments()
            
            var totalRevenue = 0.0
            var uniqueUsers = Set<String>()
            
            for document in snapshot.documents {
                if let userId = document.data()["userId"] as? String,
                   let revenue = document.data()["revenueAmount"] as? Double {
                    totalRevenue += revenue
                    uniqueUsers.insert(userId)
                }
            }
            
            return uniqueUsers.count > 0 ? totalRevenue / Double(uniqueUsers.count) : 0.0
        } ?? 0
    }
    
    private func getExperimentResults(_ experimentId: String) async -> ExperimentResults? {
        return await withCheckedContinuation { continuation in
            experimentService.getExperimentResults(experimentId) { results in
                continuation.resume(returning: results)
            }
        }
    }
    
    private func getCohortPerformanceData(dateRange: AnalyticsDateRange) async -> [String: CohortPerformance] {
        return await withErrorHandling(operation: "getCohortPerformanceData") {
            var cohortData: [String: CohortPerformance] = [:]
            
            let cohorts = ["newUser", "returningFreeUser", "trialUser", "expiredSubscriber", "activePowerUser", "cancelledSubscriber", "reactivatedUser"]
            
            for cohort in cohorts {
                // Get users in this cohort
                let usersQuery = self.firestore.collection("analytics_events")
                    .whereField("userCohort", isEqualTo: cohort)
                    .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
                
                // Get conversions for this cohort
                let conversionsQuery = self.firestore.collection("analytics_events")
                    .whereField("eventType", isEqualTo: "purchaseCompleted")
                    .whereField("userCohort", isEqualTo: cohort)
                    .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
                
                async let usersSnapshot = usersQuery.getDocuments()
                async let conversionsSnapshot = conversionsQuery.getDocuments()
                
                let uniqueUsers = Set(try await usersSnapshot.documents.compactMap { $0.data()["userId"] as? String })
                let conversions = try await conversionsSnapshot.documents
                
                let totalRevenue = conversions.reduce(0.0) { sum, doc in
                    let amount = doc.data()["revenueAmount"] as? Double ?? 0.0
                    return sum + amount
                }
                
                let conversionRate = uniqueUsers.count > 0 ? Double(conversions.count) / Double(uniqueUsers.count) : 0.0
                let averageRevenue = conversions.count > 0 ? totalRevenue / Double(conversions.count) : 0.0
                
                cohortData[cohort] = CohortPerformance(
                    conversionRate: conversionRate,
                    averageRevenue: averageRevenue,
                    userCount: uniqueUsers.count
                )
            }
            
            return cohortData
        } ?? [:]
    }
    
    private func getAcquisitionChannelData(dateRange: AnalyticsDateRange) async -> [String: AcquisitionChannelData] {
        return await withErrorHandling(operation: "getAcquisitionChannelData") {
            var channelData: [String: AcquisitionChannelData] = [:]
            
            let query = self.firestore.collection("user_acquisition")
                .whereField("acquisitionDate", isGreaterThanOrEqualTo: dateRange.startDate)
                .whereField("acquisitionDate", isLessThanOrEqualTo: dateRange.endDate)
            
            let snapshot = try await query.getDocuments()
            
            var channelStats: [String: (users: Set<String>, conversions: Int, cost: Double)] = [:]
            
            for document in snapshot.documents {
                let data = document.data()
                guard let channel = data["acquisitionChannel"] as? String,
                      let userId = data["userId"] as? String else { continue }
                
                let cost = data["acquisitionCost"] as? Double ?? 0.0
                let hasConverted = data["hasConverted"] as? Bool ?? false
                
                if channelStats[channel] == nil {
                    channelStats[channel] = (users: Set<String>(), conversions: 0, cost: 0.0)
                }
                
                channelStats[channel]?.users.insert(userId)
                channelStats[channel]?.cost += cost
                
                if hasConverted {
                    channelStats[channel]?.conversions += 1
                }
            }
            
            for (channel, stats) in channelStats {
                let conversionRate = stats.users.count > 0 ? Double(stats.conversions) / Double(stats.users.count) : 0.0
                
                channelData[channel] = AcquisitionChannelData(
                    userCount: stats.users.count,
                    conversionRate: conversionRate,
                    cost: stats.cost
                )
            }
            
            return channelData
        } ?? [:]
    }
    
    private func getRetentionRatesByCohort(dateRange: AnalyticsDateRange) async -> [String: RetentionRates] {
        return await withErrorHandling(operation: "getRetentionRatesByCohort") {
            var retentionData: [String: RetentionRates] = [:]
            
            let cohorts = ["newUser", "trialUser", "expiredSubscriber", "activePowerUser"]
            
            for cohort in cohorts {
                // Get users who started in this cohort during the period
                let cohortUsersQuery = self.firestore.collection("user_cohort_tracking")
                    .whereField("cohort", isEqualTo: cohort)
                    .whereField("cohortStartDate", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("cohortStartDate", isLessThanOrEqualTo: dateRange.endDate)
                
                let cohortSnapshot = try await cohortUsersQuery.getDocuments()
                let cohortUsers = Set(cohortSnapshot.documents.compactMap { $0.data()["userId"] as? String })
                
                if cohortUsers.isEmpty { continue }
                
                // Calculate retention for 30, 60, 90 days
                var retainedDay30 = 0
                var retainedDay60 = 0
                var retainedDay90 = 0
                
                for userId in cohortUsers {
                    // Check activity at different intervals
                    let day30Date = Calendar.current.date(byAdding: .day, value: 30, to: dateRange.startDate) ?? dateRange.startDate
                    let day60Date = Calendar.current.date(byAdding: .day, value: 60, to: dateRange.startDate) ?? dateRange.startDate
                    let day90Date = Calendar.current.date(byAdding: .day, value: 90, to: dateRange.startDate) ?? dateRange.startDate
                    
                    // Check for activity within 7 days of each milestone
                    let day30Activity = await self.checkUserActivity(userId: userId, aroundDate: day30Date)
                    let day60Activity = await self.checkUserActivity(userId: userId, aroundDate: day60Date)
                    let day90Activity = await self.checkUserActivity(userId: userId, aroundDate: day90Date)
                    
                    if day30Activity { retainedDay30 += 1 }
                    if day60Activity { retainedDay60 += 1 }
                    if day90Activity { retainedDay90 += 1 }
                }
                
                retentionData[cohort] = RetentionRates(
                    day30: Double(retainedDay30) / Double(cohortUsers.count),
                    day60: Double(retainedDay60) / Double(cohortUsers.count),
                    day90: Double(retainedDay90) / Double(cohortUsers.count)
                )
            }
            
            return retentionData
        } ?? [:]
    }
    
    private func getLTVProjections(dateRange: AnalyticsDateRange) async -> [String: Double] {
        return await withErrorHandling(operation: "getLTVProjections") {
            var ltvProjections: [String: Double] = [:]
            
            let cohorts = ["newUser", "trialUser", "expiredSubscriber", "activePowerUser"]
            
            for cohort in cohorts {
                // Get historical revenue data for this cohort
                let revenueQuery = self.firestore.collection("subscription_events")
                    .whereField("userCohort", isEqualTo: cohort)
                    .whereField("eventType", isEqualTo: "purchase_completed")
                    .whereField("timestamp", isGreaterThanOrEqualTo: dateRange.startDate)
                    .whereField("timestamp", isLessThanOrEqualTo: dateRange.endDate)
                
                let snapshot = try await revenueQuery.getDocuments()
                
                var userRevenues: [String: Double] = [:]
                
                for document in snapshot.documents {
                    let data = document.data()
                    guard let userId = data["userId"] as? String,
                          let revenue = data["revenueAmount"] as? Double else { continue }
                    
                    userRevenues[userId, default: 0.0] += revenue
                }
                
                // Calculate average LTV and project based on retention patterns
                let averageRevenue = userRevenues.values.isEmpty ? 0.0 : userRevenues.values.reduce(0, +) / Double(userRevenues.count)
                
                // Apply cohort-specific multipliers based on typical retention patterns
                let cohortMultiplier: Double = {
                    switch cohort {
                    case "newUser": return 1.5 // New users typically have lower LTV
                    case "trialUser": return 4.2 // Trial users have higher conversion potential
                    case "expiredSubscriber": return 2.8 // Some reactivation potential
                    case "activePowerUser": return 6.5 // Highest LTV cohort
                    default: return 2.0 // Default multiplier
                    }
                }()
                
                ltvProjections[cohort] = averageRevenue * cohortMultiplier
            }
            
            return ltvProjections
        } ?? [:]
    }
    
    // MARK: - Helper Methods
    
    private func generateCohortInsights(from data: [String: CohortPerformance]) -> [String] {
        var insights: [String] = []
        
        // Now data is [String: CohortPerformance], so we can access directly
        if let trialUser = data["trialUser"], trialUser.conversionRate > 0.2 {
            insights.append("Trial users show strong conversion rates (25%+)")
        }
        
        if let newUser = data["newUser"], newUser.conversionRate < 0.05 {
            insights.append("New user conversion needs optimization (<5%)")
        }
        
        return insights
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if conversionMetrics.overallConversionRate < 0.10 {
            recommendations.append("Consider A/B testing pricing strategies to improve conversion")
        }
        
        if let topFeature = revenueMetrics.revenueByFeature.first {
            recommendations.append("Expand promotion of \(topFeature.featureName) as top revenue driver")
        }
        
        return recommendations
    }
    
    // MARK: - Export Methods
    
    private func createMetricsReport() -> MetricsReport {
        return MetricsReport(
            period: selectedTimeRange.dateRange,
            conversionMetrics: conversionMetrics,
            revenueMetrics: revenueMetrics,
            experiments: activeExperiments,
            cohortAnalysis: cohortAnalysis,
            generatedAt: Date()
        )
    }
    
    private func exportAsCSV(_ report: MetricsReport) -> URL? {
        // Implementation would create CSV file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("metrics_report.csv")
        
        let csvContent = """
        Metric,Value,Period
        Overall Conversion Rate,\(report.conversionMetrics.overallConversionRate),\(selectedTimeRange.rawValue)
        Total Revenue,\(report.revenueMetrics.totalRevenue),\(selectedTimeRange.rawValue)
        Total Impressions,\(report.conversionMetrics.totalImpressions),\(selectedTimeRange.rawValue)
        """
        
        try? csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    private func exportAsJSON(_ report: MetricsReport) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("metrics_report.json")
        
        // Create a simplified JSON representation
        let jsonData: [String: Any] = [
            "period": [
                "start": report.period.startDate.timeIntervalSince1970,
                "end": report.period.endDate.timeIntervalSince1970
            ],
            "conversion_metrics": [
                "overall_conversion_rate": report.conversionMetrics.overallConversionRate,
                "total_impressions": report.conversionMetrics.totalImpressions,
                "total_purchases": report.conversionMetrics.totalPurchases
            ],
            "revenue_metrics": [
                "total_revenue": report.revenueMetrics.totalRevenue,
                "revenue_per_visitor": report.revenueMetrics.revenuePerVisitor,
                "top_revenue_source": report.revenueMetrics.topRevenueSource
            ],
            "generated_at": report.generatedAt.timeIntervalSince1970
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            logger.error("MetricsDashboard: Error exporting JSON: \(error)")
            return nil
        }
    }
    
    private func exportAsPDF(_ report: MetricsReport) -> URL? {
        // Implementation would create PDF report
        // For now, return nil as PDF generation requires more complex implementation
        return nil
    }
    
    // MARK: - Cache Management
    
    private func getCachedValue(for key: String) -> Any? {
        guard let lastUpdate = lastCacheUpdate,
              Date().timeIntervalSince(lastUpdate) < cacheValidityDuration else {
            return nil
        }
        return metricsCache[key]
    }
    
    private func setCachedValue(_ value: Any, for key: String) {
        metricsCache[key] = value
        lastCacheUpdate = Date()
    }
    
    private func invalidateCache() {
        metricsCache.removeAll()
        lastCacheUpdate = nil
    }
    
    // MARK: - Error Handling
    
    /// Generic error handling wrapper for async operations
    private func withErrorHandling<T>(
        operation: String,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0,
        work: @escaping () async throws -> T
    ) async -> T? {
        let retryKey = operation
        let currentAttempt = retryAttempts[retryKey, default: 0]
        
        do {
            let result = try await work()
            // Reset retry count on success
            retryAttempts[retryKey] = 0
            await updateNetworkStatus(.connected)
            return result
        } catch {
            logger.error("MetricsDashboard: Error in \(operation): \(error)")
            
            // Update error state
            await handleError(error, operation: operation)
            
            // Retry logic
            if currentAttempt < maxRetries {
                retryAttempts[retryKey] = currentAttempt + 1
                logger.info("MetricsDashboard: Retrying \(operation) (attempt \(currentAttempt + 1)/\(maxRetries))")
                
                await MainActor.run {
                    self.isRetrying = true
                }
                
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                
                return await withErrorHandling(
                    operation: operation,
                    maxRetries: maxRetries,
                    retryDelay: retryDelay * 1.5, // Exponential backoff
                    work: work
                )
            } else {
                // Max retries exceeded
                retryAttempts[retryKey] = 0
                await MainActor.run {
                    self.isRetrying = false
                }
                return nil
            }
        }
    }
    
    /// Handle different types of errors
    private func handleError(_ error: Error, operation: String) async {
        await MainActor.run {
            let analyticsError: AnalyticsError
            
            if let nsError = error as NSError? {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    analyticsError = .networkConnectionLost
                    self.networkStatus = .disconnected
                case NSURLErrorTimedOut:
                    analyticsError = .requestTimeout
                    self.networkStatus = .slow
                default:
                    if nsError.domain.contains("Firestore") {
                        analyticsError = .firestoreError(nsError.localizedDescription)
                    } else {
                        analyticsError = .unknownError(nsError.localizedDescription)
                    }
                    self.networkStatus = .connected
                }
            } else {
                analyticsError = .unknownError(error.localizedDescription)
            }
            
            self.errorState = analyticsError
            logger.error("MetricsDashboard: \(operation) failed with error: \(analyticsError)")
        }
    }
    
    /// Update network status
    private func updateNetworkStatus(_ status: NetworkStatus) async {
        await MainActor.run {
            self.networkStatus = status
        }
    }
    
    /// Check if user was active around a specific date (for retention calculation)
    private func checkUserActivity(userId: String, aroundDate: Date) async -> Bool {
        return await withErrorHandling(operation: "checkUserActivity") {
            let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: aroundDate) ?? aroundDate
            let sevenDaysAfter = Calendar.current.date(byAdding: .day, value: 7, to: aroundDate) ?? aroundDate
            
            let query = self.firestore.collection("analytics_events")
                .whereField("userId", isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: sevenDaysBefore)
                .whereField("timestamp", isLessThanOrEqualTo: sevenDaysAfter)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            return !snapshot.documents.isEmpty
        } ?? false
    }
    
    /// Retry failed operations
    public func retryFailedOperations() {
        errorState = nil
        isRetrying = true
        retryAttempts.removeAll()
        refreshAllMetrics()
    }
    
    /// Clear error state
    public func clearError() {
        errorState = nil
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Supporting Models

/// Time range options for dashboard
public enum AnalyticsTimeRange: String, CaseIterable {
    case last24Hours = "last_24_hours"
    case last7Days = "last_7_days"
    case last30Days = "last_30_days"
    case thisMonth = "this_month"
    case last3Months = "last_3_months"
    
    public var displayName: String {
        switch self {
        case .last24Hours: return "Last 24 Hours"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .thisMonth: return "This Month"
        case .last3Months: return "Last 3 Months"
        }
    }
    
    public var dateRange: AnalyticsDateRange {
        let endDate = Date()
        let startDate: Date
        
        switch self {
        case .last24Hours:
            startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate) ?? endDate
        case .last7Days:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .last30Days:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .thisMonth:
            startDate = Calendar.current.dateInterval(of: .month, for: endDate)?.start ?? endDate
        case .last3Months:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        }
        
        return AnalyticsDateRange(startDate: startDate, endDate: endDate)
    }
}

/// Export format options
public enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case json = "json"
    case pdf = "pdf"
    
    public var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }
}

/// Conversion metrics aggregation
public struct ConversionMetrics: Equatable {
    public let overallConversionRate: Double
    public let totalImpressions: Int
    public let totalPurchases: Int
    public let funnelBreakdown: [String: Int]
    public let conversionRatesBySource: [String: Double]
    public let averageTimeToConversion: TimeInterval
    public let exitIntentRecoveryRate: Double
    
    public static func == (lhs: ConversionMetrics, rhs: ConversionMetrics) -> Bool {
        return lhs.overallConversionRate == rhs.overallConversionRate &&
               lhs.totalImpressions == rhs.totalImpressions &&
               lhs.totalPurchases == rhs.totalPurchases &&
               lhs.averageTimeToConversion == rhs.averageTimeToConversion &&
               lhs.exitIntentRecoveryRate == rhs.exitIntentRecoveryRate
    }
    
    public static let empty = ConversionMetrics(
        overallConversionRate: 0,
        totalImpressions: 0,
        totalPurchases: 0,
        funnelBreakdown: [:],
        conversionRatesBySource: [:],
        averageTimeToConversion: 0,
        exitIntentRecoveryRate: 0
    )
}

// RevenueSource is defined in Models/Analytics/FunnelEvent.swift

/// Feature revenue analysis
public struct FeatureRevenueData: Equatable {
    public let featureName: String
    public let revenue: Double
    public let percentage: Double
}

/// Revenue metrics aggregation
public struct RevenueMetrics: Equatable {
    public let totalRevenue: Double
    public let revenuePerVisitor: Double
    public let topRevenueSource: String
    public let revenueByFeature: [FeatureRevenueData]
    public let revenueGrowthRate: Double
    public let averageRevenuePerUser: Double
    
    public static let empty = RevenueMetrics(
        totalRevenue: 0,
        revenuePerVisitor: 0,
        topRevenueSource: "generalPaywall",
        revenueByFeature: [],
        revenueGrowthRate: 0,
        averageRevenuePerUser: 0
    )
}

/// Experiment summary for dashboard
public struct ExperimentSummary {
    public let id: String
    public let name: String
    public let status: ExperimentStatus
    public let startDate: Date
    public let sampleSize: Int
    public let hasSignificantResults: Bool
    public let winningVariant: String?
    public let conversionLift: Double
}

/// Cohort analysis data
public struct CohortAnalysis {
    public let cohortPerformance: [String: CohortPerformance]
    public let acquisitionChannelBreakdown: [String: AcquisitionChannelData]
    public let retentionRates: [String: RetentionRates]
    public let lifetimeValueProjections: [String: Double]
    public let keyInsights: [String]
    
    public static let empty = CohortAnalysis(
        cohortPerformance: [:],
        acquisitionChannelBreakdown: [:],
        retentionRates: [:],
        lifetimeValueProjections: [:],
        keyInsights: []
    )
}

/// Individual cohort performance metrics
public struct CohortPerformance {
    public let conversionRate: Double
    public let averageRevenue: Double
    public let userCount: Int
}

/// Acquisition channel data
public struct AcquisitionChannelData {
    public let userCount: Int
    public let conversionRate: Double
    public let cost: Double
    
    public var costPerAcquisition: Double {
        return userCount > 0 ? cost / Double(userCount) : 0
    }
}

/// Retention rates by time period
public struct RetentionRates {
    public let day30: Double
    public let day60: Double
    public let day90: Double
}

/// Complete metrics report for export
public struct MetricsReport {
    public let period: AnalyticsDateRange
    public let conversionMetrics: ConversionMetrics
    public let revenueMetrics: RevenueMetrics
    public let experiments: [ExperimentSummary]
    public let cohortAnalysis: CohortAnalysis
    public let generatedAt: Date
}

/// Stakeholder summary for email reports
public struct StakeholderSummary {
    public let period: AnalyticsDateRange
    public let overallConversionRate: Double
    public let totalRevenue: Double
    public let topPerformingFeature: String
    public let activeExperimentCount: Int
    public let significantExperiments: [ExperimentSummary]
    public let cohortInsights: [String]
    public let recommendations: [String]
}

/// Revenue attribution breakdown data
public struct DashboardRevenueAttributionBreakdown {
    public let totalRevenue: Double
    public let sourceBreakdown: [RevenueSourceData]
    
    public static let empty = DashboardRevenueAttributionBreakdown(
        totalRevenue: 0,
        sourceBreakdown: []
    )
}

/// Revenue source data
public struct RevenueSourceData {
    public let source: String
    public let revenue: Double
    public let percentage: Double
}

/// DateRange utility for analytics queries
public struct DateRange {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Error Handling Models

/// Analytics-specific error types
public enum AnalyticsError: Error, Equatable {
    case networkConnectionLost
    case requestTimeout
    case firestoreError(String)
    case dataLoadingFailed
    case insufficientData
    case authenticationRequired
    case unknownError(String)
    
    public var localizedDescription: String {
        switch self {
        case .networkConnectionLost:
            return "Network connection lost. Please check your internet connection."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .firestoreError(let message):
            return "Database error: \(message)"
        case .dataLoadingFailed:
            return "Failed to load analytics data. Please try again."
        case .insufficientData:
            return "Insufficient data available for the selected time period."
        case .authenticationRequired:
            return "Authentication required to access analytics data."
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .networkConnectionLost, .requestTimeout, .dataLoadingFailed:
            return true
        case .firestoreError, .unknownError:
            return true
        case .insufficientData, .authenticationRequired:
            return false
        }
    }
    
    public var icon: String {
        switch self {
        case .networkConnectionLost:
            return "wifi.exclamationmark"
        case .requestTimeout:
            return "clock.badge.exclamationmark"
        case .firestoreError, .dataLoadingFailed:
            return "server.rack"
        case .insufficientData:
            return "chart.bar.doc.horizontal"
        case .authenticationRequired:
            return "person.crop.circle.badge.exclamationmark"
        case .unknownError:
            return "exclamationmark.triangle"
        }
    }
}

/// Network status for UI feedback
public enum NetworkStatus {
    case connected
    case disconnected
    case slow
    
    public var displayText: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .slow:
            return "Slow Connection"
        }
    }
    
    public var color: UIColor {
        switch self {
        case .connected:
            return .systemGreen
        case .disconnected:
            return .systemRed
        case .slow:
            return .systemOrange
        }
    }
}