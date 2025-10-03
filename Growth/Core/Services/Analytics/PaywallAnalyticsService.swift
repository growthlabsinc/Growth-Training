/**
 * PaywallAnalyticsService.swift
 * Growth App Enhanced Analytics Service
 *
 * Comprehensive analytics service for paywall conversion funnel tracking,
 * revenue attribution, and user cohort analysis with Firebase integration.
 */

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import os.log

/// Enhanced analytics service for paywall optimization and revenue tracking
public class PaywallAnalyticsService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = PaywallAnalyticsService()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isTracking: Bool = true
    @Published public private(set) var lastEventTimestamp: Date?
    @Published public private(set) var eventQueue: [FunnelEvent] = []
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private let sessionId: String = UUID().uuidString
    private var currentUserCohort: UserCohort = .newUser
    private var activeExperiments: [String: String] = [:]
    
    // Event batching for performance
    private let eventBatchSize = 10
    private let eventFlushInterval: TimeInterval = 30
    private var flushTimer: Timer?
    
    // Cache for user properties
    private var userPropertiesCache: [String: Any] = [:]
    private var lastUserPropertiesUpdate: Date?
    
    // Access entitlements through UserDefaults to avoid MainActor isolation issues
    private func checkPremiumStatus() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") ?? UserDefaults.standard
        return userDefaults.bool(forKey: "hasPremium")
    }
    
    private init() {
        setupEventBatching()
        refreshUserCohort()
    }
    
    // MARK: - Funnel Tracking
    
    /// Track a funnel step with comprehensive context
    public func trackFunnelStep(
        _ step: FunnelStep,
        context: PaywallContext,
        revenueSource: RevenueSource? = nil,
        metadata: [String: Any] = [:]
    ) {
        guard isTracking else { return }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            os_log(.default, "PaywallAnalytics: No authenticated user for funnel tracking")
            return
        }
        
        // Convert metadata to AnyCodable
        let codableMetadata = metadata.mapValues { AnyCodable($0) }
        
        // Determine revenue source from context if not provided
        let source = revenueSource ?? deriveRevenueSource(from: context)
        
        // Create funnel event
        let event = FunnelEvent(
            userId: userId,
            sessionId: sessionId,
            step: step,
            paywallContext: context,
            userCohort: currentUserCohort,
            revenueSource: source,
            experimentAssignments: activeExperiments,
            metadata: codableMetadata
        )
        
        // Queue event for batching
        addEventToQueue(event)
        
        // Track in Firebase Analytics for immediate insights
        trackFirebaseAnalyticsEvent(event)
        
        os_log(.info, "PaywallAnalytics: Tracked funnel step %@ for context %@", step.rawValue, String(describing: context))
    }
    
    /// Track conversion event with revenue data
    public func trackConversionEvent(
        _ event: ConversionEvent,
        context: PaywallContext,
        revenueAmount: Double? = nil,
        subscriptionTier: SubscriptionTier? = nil,
        subscriptionDuration: SubscriptionDuration? = nil,
        metadata: [String: Any] = [:]
    ) {
        guard isTracking else { return }
        
        guard Auth.auth().currentUser?.uid != nil else {
            os_log(.default, "PaywallAnalytics: No authenticated user for conversion tracking")
            return
        }
        
        // Enhanced metadata for conversion events
        var enhancedMetadata = metadata
        enhancedMetadata["conversion_event"] = event.rawValue
        enhancedMetadata["revenue_impact"] = event.revenueImpact.rawValue
        
        if let amount = revenueAmount {
            enhancedMetadata["revenue_amount"] = amount
        }
        if let tier = subscriptionTier {
            enhancedMetadata["subscription_tier"] = tier.rawValue
        }
        if let duration = subscriptionDuration {
            enhancedMetadata["subscription_duration"] = duration.rawValue
        }
        
        // Track as funnel step
        let funnelStep: FunnelStep = event == .subscriptionPurchased ? .purchaseCompleted : .purchaseCompleted
        trackFunnelStep(funnelStep, context: context, metadata: enhancedMetadata)
        
        // Track revenue attribution
        if let amount = revenueAmount {
            let source = deriveRevenueSource(from: context)
            attributeRevenue(amount, source: source, event: event)
        }
        
        os_log(.info, "PaywallAnalytics: Tracked conversion event %@", event.rawValue)
    }
    
    // MARK: - User Cohort Analysis
    
    /// Track user cohort assignment
    public func trackUserCohort(_ cohort: UserCohort, acquisitionSource: String? = nil) {
        currentUserCohort = cohort
        
        var properties: [String: Any] = [
            "user_cohort": cohort.rawValue,
            "cohort_assigned_at": Date().timeIntervalSince1970
        ]
        
        if let source = acquisitionSource {
            properties["acquisition_source"] = source
        }
        
        updateUserProperties(properties)
        
        os_log(.info, "PaywallAnalytics: User assigned to cohort %@", cohort.rawValue)
    }
    
    /// Refresh user cohort based on current subscription state
    public func refreshUserCohort() {
        // Determine cohort based on subscription state
        let hasPremium = checkPremiumStatus()
        let newCohort = hasPremium ? UserCohort.activePowerUser : UserCohort.newUser
        
        if newCohort != currentUserCohort {
            trackUserCohort(newCohort)
        }
    }
    
    // MARK: - Revenue Attribution
    
    /// Attribute revenue to specific source
    public func attributeRevenue(
        _ amount: Double,
        source: RevenueSource,
        event: ConversionEvent,
        metadata: [String: Any] = [:]
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let attribution = RevenueAttribution(
            userId: userId,
            amount: amount,
            source: source,
            event: event,
            timestamp: Date(),
            experimentAssignments: activeExperiments,
            metadata: metadata
        )
        
        // Store in Firestore for analysis
        saveRevenueAttribution(attribution)
        
        // Track in Firebase Analytics for revenue reporting
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterValue: amount,
            AnalyticsParameterCurrency: "USD",
            "revenue_source": source.rawValue,
            "conversion_event": event.rawValue,
            "user_cohort": currentUserCohort.rawValue
        ])
    }
    
    /// Get revenue attribution by feature for specified time range
    public func getRevenueByFeature(
        timeRange: AnalyticsDateRange,
        completion: @escaping ([FeatureRevenue]) -> Void
    ) {
        let startDate = timeRange.startDate
        let endDate = timeRange.endDate
        
        firestore.collection("revenueAttributions")
            .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
            .whereField("timestamp", isLessThanOrEqualTo: endDate)
            .getDocuments { snapshot, error in
                if let error = error {
                    os_log(.error, "PaywallAnalytics: Error fetching revenue data: %@", error.localizedDescription)
                    completion([])
                    return
                }
                
                let attributions = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: RevenueAttribution.self)
                } ?? []
                
                let featureRevenues = self.aggregateRevenueByFeature(attributions)
                completion(featureRevenues)
            }
    }
    
    // MARK: - Experiment Integration
    
    /// Update active experiment assignments
    public func updateExperimentAssignments(_ assignments: [String: String]) {
        activeExperiments = assignments
        updateUserProperties(["active_experiments": assignments])
    }
    
    /// Track experiment event
    public func trackExperimentEvent(
        experimentId: String,
        variant: String,
        event: String,
        context: PaywallContext,
        metadata: [String: Any] = [:]
    ) {
        var enhancedMetadata = metadata
        enhancedMetadata["experiment_id"] = experimentId
        enhancedMetadata["experiment_variant"] = variant
        enhancedMetadata["experiment_event"] = event
        
        // Track as generic funnel step with experiment context
        trackFunnelStep(.featureHighlightView, context: context, metadata: enhancedMetadata)
    }
    
    // MARK: - User Properties Management
    
    /// Update user properties for enhanced segmentation
    public func updateUserProperties(_ properties: [String: Any]) {
        // Update cache
        for (key, value) in properties {
            userPropertiesCache[key] = value
        }
        lastUserPropertiesUpdate = Date()
        
        // Update Firebase Analytics user properties
        for (key, value) in properties {
            if let stringValue = value as? String {
                Analytics.setUserProperty(stringValue, forName: key)
            }
        }
        
        // Store in Firestore for detailed analysis
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        firestore.collection("userProperties").document(userId).setData([
            "properties": properties,
            "updated_at": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    // MARK: - Event Batching and Performance
    
    private func setupEventBatching() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: eventFlushInterval, repeats: true) { _ in
            if !self.eventQueue.isEmpty {
                os_log(.debug, "PaywallAnalytics: Timer flush triggered with %d events", self.eventQueue.count)
                self.flushEventQueue()
            }
        }
        
        // Also flush when app enters background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            os_log(.info, "PaywallAnalytics: App backgrounded, flushing pending events")
            self.flushEventQueue()
        }
    }
    
    private func addEventToQueue(_ event: FunnelEvent) {
        eventQueue.append(event)
        lastEventTimestamp = event.timestamp
        
        // Flush if batch size reached
        if eventQueue.count >= eventBatchSize {
            flushEventQueue()
        }
    }
    
    private func flushEventQueue() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToFlush = eventQueue
        eventQueue.removeAll()
        
        // Enhanced error handling for Firestore batch operations
        Task {
            await flushEventsWithRetry(eventsToFlush, retryCount: 0)
        }
    }
    
    private func flushEventsWithRetry(_ events: [FunnelEvent], retryCount: Int, maxRetries: Int = 3) async {
        let batch = firestore.batch()
        var encodingErrors: [Error] = []
        
        // Encode events with error collection
        for event in events {
            let documentRef = firestore.collection("analytics_events").document(event.id)
            do {
                var eventData = try Firestore.Encoder().encode(event)
                // Add additional indexable fields for querying
                eventData["eventType"] = event.step.rawValue
                eventData["userCohort"] = event.userCohort.rawValue
                eventData["revenueSource"] = event.revenueSource.rawValue
                eventData["timestamp"] = Timestamp(date: event.timestamp)
                
                batch.setData(eventData, forDocument: documentRef)
            } catch {
                os_log(.error, "PaywallAnalytics: Error encoding event %@: %@", event.id, error.localizedDescription)
                encodingErrors.append(error)
            }
        }
        
        // Commit batch with comprehensive error handling
        do {
            try await batch.commit()
            os_log(.info, "PaywallAnalytics: Successfully flushed %d events to Firestore", events.count)
            
            // Also save conversion events to separate collection for revenue tracking
            await saveConversionEvents(events.filter { $0.step == .purchaseCompleted })
        } catch {
            await handleFlushError(error, events: events, retryCount: retryCount, maxRetries: maxRetries)
        }
    }
    
    private func handleFlushError(_ error: Error, events: [FunnelEvent], retryCount: Int, maxRetries: Int) async {
        os_log(.error, "PaywallAnalytics: Error flushing events (attempt %d): %@", retryCount + 1, error.localizedDescription)
        
        if retryCount < maxRetries {
            // Exponential backoff retry
            let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s delays
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            os_log(.info, "PaywallAnalytics: Retrying event flush (attempt %d/%d)", retryCount + 1, maxRetries)
            await flushEventsWithRetry(events, retryCount: retryCount + 1, maxRetries: maxRetries)
        } else {
            // Max retries exceeded - re-queue for next flush cycle
            await MainActor.run {
                os_log(.default, "PaywallAnalytics: Max retries exceeded, re-queuing %d events", events.count)
                self.eventQueue.insert(contentsOf: events, at: 0)
            }
        }
    }
    
    private func saveConversionEvents(_ conversionEvents: [FunnelEvent]) async {
        guard !conversionEvents.isEmpty else { return }
        
        let batch = firestore.batch()
        
        for event in conversionEvents {
            let documentRef = firestore.collection("subscription_events").document(event.id)
            
            var conversionData: [String: Any] = [
                "userId": event.userId,
                "eventType": "purchase_completed",
                "timestamp": Timestamp(date: event.timestamp),
                "userCohort": event.userCohort.rawValue,
                "revenueSource": event.revenueSource.rawValue,
                "sessionId": event.sessionId
            ]
            
            // Extract revenue amount from metadata
            if let revenueAmount = event.metadata["revenue_amount"]?.value as? Double {
                conversionData["revenueAmount"] = revenueAmount
            }
            
            if let subscriptionTier = event.metadata["subscription_tier"]?.value as? String {
                conversionData["subscriptionTier"] = subscriptionTier
            }
            
            batch.setData(conversionData, forDocument: documentRef)
        }
        
        do {
            try await batch.commit()
            os_log(.info, "PaywallAnalytics: Successfully saved %d conversion events", conversionEvents.count)
        } catch {
            os_log(.error, "PaywallAnalytics: Error saving conversion events: %@", error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func deriveRevenueSource(from context: PaywallContext) -> RevenueSource {
        switch context {
        case .featureGate(let feature):
            switch feature {
            case .aiCoach: return .featureGateAICoach
            case .customRoutines: return .featureGateCustomRoutines
            case .progressTracking: return .featureGateProgressTracking
            case .advancedAnalytics: return .featureGateAdvancedAnalytics
            case .liveActivities: return .featureGateLiveActivities
            default: return .generalPaywall
            }
        case .settings: return .settingsUpgrade
        case .onboarding: return .onboardingFlow
        case .sessionCompletion: return .sessionCompletion
        case .general: return .generalPaywall
        }
    }
    
    private func determineCohort(from subscriptionState: SubscriptionState) -> UserCohort {
        switch subscriptionState.status {
        case .none:
            // Check if this is a new user or returning free user
            return userPropertiesCache["first_app_launch"] != nil ? .newUser : .returningFreeUser
        case .active:
            return subscriptionState.isTrialActive ? .trialUser : .activePowerUser
        case .expired:
            return .expiredSubscriber
        case .cancelled:
            return .cancelledSubscriber
        case .pending, .grace:
            return .trialUser
        }
    }
    
    private func trackFirebaseAnalyticsEvent(_ event: FunnelEvent) {
        Analytics.logEvent("paywall_funnel_step", parameters: [
            "funnel_step": event.step.rawValue,
            "funnel_position": event.step.funnelPosition,
            "paywall_context": "\(event.paywallContext)",
            "user_cohort": event.userCohort.rawValue,
            "revenue_source": event.revenueSource.rawValue,
            "session_id": event.sessionId
        ])
    }
    
    private func saveRevenueAttribution(_ attribution: RevenueAttribution) {
        do {
            let data = try Firestore.Encoder().encode(attribution)
            firestore.collection("revenueAttributions").document(attribution.id).setData(data)
        } catch {
            os_log(.error, "PaywallAnalytics: Error saving revenue attribution: %@", error.localizedDescription)
        }
    }
    
    private func aggregateRevenueByFeature(_ attributions: [RevenueAttribution]) -> [FeatureRevenue] {
        var featureRevenueMap: [String: Double] = [:]
        
        for attribution in attributions {
            if let feature = attribution.source.associatedFeature {
                featureRevenueMap[feature, default: 0] += attribution.amount
            }
        }
        
        return featureRevenueMap.map { feature, revenue in
            FeatureRevenue(feature: feature, totalRevenue: revenue, conversionCount: 1)
        }.sorted { $0.totalRevenue > $1.totalRevenue }
    }
}

// MARK: - Supporting Models

/// Revenue attribution record
public struct RevenueAttribution: Codable {
    public let id: String
    public let userId: String
    public let amount: Double
    public let source: RevenueSource
    public let event: ConversionEvent
    public let timestamp: Date
    public let experimentAssignments: [String: String]
    public let metadata: [String: AnyCodable]
    
    public init(
        userId: String,
        amount: Double,
        source: RevenueSource,
        event: ConversionEvent,
        timestamp: Date,
        experimentAssignments: [String: String] = [:],
        metadata: [String: Any] = [:]
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.amount = amount
        self.source = source
        self.event = event
        self.timestamp = timestamp
        self.experimentAssignments = experimentAssignments
        self.metadata = metadata.mapValues { AnyCodable($0) }
    }
}

/// Feature revenue aggregation
public struct FeatureRevenue {
    public let feature: String
    public let totalRevenue: Double
    public let conversionCount: Int
    
    public var averageRevenuePerConversion: Double {
        guard conversionCount > 0 else { return 0 }
        return totalRevenue / Double(conversionCount)
    }
}

