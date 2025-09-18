/**
 * AdvancedTrialService.swift
 * Growth App Advanced Trial Management
 *
 * Comprehensive trial management service with dynamic trial lengths,
 * feature-based trials, personalized trial experiences, and trial optimization.
 */

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import StoreKit

/// Advanced trial management service for subscription optimization
@MainActor
public class AdvancedTrialService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = AdvancedTrialService()
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentTrial: TrialExperience?
    @Published public private(set) var trialHistory: [TrialRecord] = []
    @Published public private(set) var isEligibleForTrial: Bool = false
    @Published public private(set) var trialRecommendations: [TrialRecommendation] = []
    @Published public private(set) var isProcessing: Bool = false
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private let subscriptionManager = SubscriptionStateManager.shared
    private let purchaseManager = PurchaseManager.shared
    private let analyticsService = PaywallAnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Trial configuration
    private let trialConfigurations = TrialConfigurations.default
    private let conversionOptimizer = TrialConversionOptimizer()
    
    private init() {
        loadTrialHistory()
        checkTrialEligibility()
        loadTrialRecommendations()
        setupTrialMonitoring()
    }
    
    // MARK: - Trial Management
    
    /// Start a personalized trial experience
    public func startPersonalizedTrial(
        type: TrialType,
        userProfile: UserTrialProfile
    ) async -> Result<TrialExperience, TrialError> {
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return .failure(.userNotAuthenticated)
        }
        
        // Check eligibility
        guard await checkTrialEligibility(for: type) else {
            return .failure(.notEligible)
        }
        
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Personalize trial based on user profile
        let personalizedConfig = personalizeTrialConfiguration(
            baseType: type,
            userProfile: userProfile
        )
        
        // Create trial experience
        let trialExperience = TrialExperience(
            userId: userId,
            trialType: type,
            configuration: personalizedConfig,
            startDate: Date(),
            expectedEndDate: Date().addingTimeInterval(personalizedConfig.duration),
            status: .active,
            personalizationFactors: extractPersonalizationFactors(userProfile)
        )
        
        // Initialize trial with StoreKit
        let storeKitResult = await initializeTrialWithStoreKit(trialExperience)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Save trial record
        saveTrialExperience(trialExperience)
        
        // Set current trial
        currentTrial = trialExperience
        
        // Schedule trial optimization check-ins
        scheduleTrialOptimizationCheckins(trialExperience)
        
        // Track trial start
        analyticsService.trackConversionEvent(
            .trialStarted,
            context: .onboarding,
            subscriptionTier: personalizedConfig.targetTier,
            metadata: [
                "trial_type": type.rawValue,
                "trial_duration_days": personalizedConfig.duration / (24 * 60 * 60),
                "personalization_factors": trialExperience.personalizationFactors.map { $0.rawValue }
            ]
        )
        
        Logger.info("AdvancedTrial: Started personalized \(type.rawValue) trial for user")
        
        return .success(trialExperience)
    }
    
    /// Extend current trial with personalized offer
    public func extendTrial(
        extensionDays: Int,
        reason: TrialExtensionReason
    ) async -> Result<TrialExtension, TrialError> {
        
        guard var trial = currentTrial else {
            return .failure(.noActiveTrial)
        }
        
        guard trial.status == .active else {
            return .failure(.trialNotActive)
        }
        
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Create extension record
        let trialExtension = TrialExtension(
            trialId: trial.id,
            extensionDays: extensionDays,
            reason: reason,
            originalEndDate: trial.expectedEndDate,
            newEndDate: trial.expectedEndDate.addingTimeInterval(TimeInterval(extensionDays * 24 * 60 * 60)),
            grantedDate: Date()
        )
        
        // Update trial experience
        trial.expectedEndDate = trialExtension.newEndDate
        trial.extensions.append(trialExtension)
        
        // Update with StoreKit
        let storeKitResult = await extendTrialWithStoreKit(trial, extension: trialExtension)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Save updated trial
        saveTrialExperience(trial)
        currentTrial = trial
        
        // Track extension
        analyticsService.trackConversionEvent(
            .trialStarted,
            context: .settings,
            metadata: [
                "extension_days": extensionDays,
                "extension_reason": reason.rawValue,
                "total_trial_days": trial.totalTrialDuration / (24 * 60 * 60)
            ]
        )
        
        Logger.info("AdvancedTrial: Extended trial by \(extensionDays) days")
        
        return .success(trialExtension)
    }
    
    /// Convert trial to paid subscription
    public func convertTrialToSubscription(
        targetTier: SubscriptionTier,
        selectedProduct: Product
    ) async -> Result<TrialConversion, TrialError> {
        
        guard var trial = currentTrial else {
            return .failure(.noActiveTrial)
        }
        
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Create conversion record
        let conversion = TrialConversion(
            trialId: trial.id,
            fromTier: trial.configuration.targetTier,
            toTier: targetTier,
            conversionDate: Date(),
            trialDurationUsed: Date().timeIntervalSince(trial.startDate),
            conversionValue: NSDecimalNumber(decimal: selectedProduct.price).doubleValue,
            conversionChannel: .inApp
        )
        
        // Process subscription purchase
        let purchaseResult = await purchaseManager.purchase(productID: selectedProduct.id)
        if case .failed(let error) = purchaseResult {
            return .failure(.purchaseFailed(error.localizedDescription))
        }
        
        // Update trial status
        trial.status = .converted
        trial.conversionDate = Date()
        trial.conversionDetails = conversion
        
        // Save final trial state
        saveTrialExperience(trial)
        
        // Clear current trial
        currentTrial = nil
        
        // Track conversion
        analyticsService.trackConversionEvent(
            .trialConverted,
            context: .general,
            revenueAmount: conversion.conversionValue,
            subscriptionTier: targetTier,
            metadata: [
                "trial_type": trial.trialType.rawValue,
                "trial_duration_used_days": conversion.trialDurationUsed / (24 * 60 * 60),
                "conversion_channel": conversion.conversionChannel.rawValue,
                "personalization_factors": trial.personalizationFactors.map { $0.rawValue }
            ]
        )
        
        // Update trial optimization models
        conversionOptimizer.recordConversion(trial: trial, conversion: conversion)
        
        Logger.info("AdvancedTrial: Successfully converted trial to \(targetTier.rawValue) subscription")
        
        return .success(conversion)
    }
    
    /// Cancel trial (with retention attempt)
    public func cancelTrial(
        reason: TrialCancellationReason,
        feedback: String? = nil
    ) async -> Result<TrialCancellation, TrialError> {
        
        guard var trial = currentTrial else {
            return .failure(.noActiveTrial)
        }
        
        // Attempt retention intervention
        let retentionOffer = await generateRetentionOffer(trial: trial, reason: reason)
        if retentionOffer != nil {
            // Present retention offer to user (would be handled by UI)
            Logger.info("AdvancedTrial: Generated retention offer for trial cancellation")
        }
        
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Create cancellation record
        let cancellation = TrialCancellation(
            trialId: trial.id,
            reason: reason,
            cancellationDate: Date(),
            trialDurationUsed: Date().timeIntervalSince(trial.startDate),
            feedback: feedback,
            retentionOfferPresented: retentionOffer != nil
        )
        
        // Cancel with StoreKit
        let storeKitResult = await cancelTrialWithStoreKit(trial)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Update trial status
        trial.status = .cancelled
        trial.cancellationDate = Date()
        trial.cancellationDetails = cancellation
        
        // Save final trial state
        saveTrialExperience(trial)
        
        // Clear current trial
        currentTrial = nil
        
        // Track cancellation
        analyticsService.trackConversionEvent(
            .trialExpired,
            context: .settings,
            metadata: [
                "cancellation_reason": reason.rawValue,
                "trial_duration_used_days": cancellation.trialDurationUsed / (24 * 60 * 60),
                "retention_offer_presented": cancellation.retentionOfferPresented,
                "has_feedback": feedback != nil
            ]
        )
        
        Logger.info("AdvancedTrial: Trial cancelled - reason: \(reason.rawValue)")
        
        return .success(cancellation)
    }
    
    // MARK: - Trial Optimization
    
    /// Generate optimized trial recommendations for user
    public func generateTrialRecommendations(
        userProfile: UserTrialProfile
    ) async -> [TrialRecommendation] {
        
        // Analyze user behavior and preferences
        let behaviorAnalysis = await analyzeUserBehavior(userProfile)
        let conversionProbability = await predictConversionProbability(userProfile)
        let optimalDuration = await calculateOptimalTrialDuration(userProfile)
        
        var recommendations: [TrialRecommendation] = []
        
        // Standard trial recommendation
        recommendations.append(TrialRecommendation(
            type: .standard,
            duration: trialConfigurations.standardTrialDuration,
            targetTier: .premium,
            expectedConversionRate: conversionProbability.standard,
            personalizationScore: 0.5,
            features: TrialFeatureSet.standard.features,
            reasoning: "Standard trial experience with core features"
        ))
        
        // Feature-specific trial recommendation
        if let primaryInterest = behaviorAnalysis.primaryFeatureInterest {
            recommendations.append(TrialRecommendation(
                type: .featureSpecific,
                duration: optimalDuration,
                targetTier: .premium,
                expectedConversionRate: conversionProbability.featureSpecific,
                personalizationScore: 0.8,
                features: TrialFeatureSet.focused(on: primaryInterest).features,
                reasoning: "Focused trial highlighting \(primaryInterest.displayName)"
            ))
        }
        
        // Extended trial for high-value users
        if behaviorAnalysis.valueScore > 0.7 {
            recommendations.append(TrialRecommendation(
                type: .extended,
                duration: trialConfigurations.extendedTrialDuration,
                targetTier: .premium,
                expectedConversionRate: conversionProbability.extended,
                personalizationScore: 0.9,
                features: TrialFeatureSet.premium.features,
                reasoning: "Extended trial for high-value user segment"
            ))
        }
        
        // Sort by expected conversion rate
        recommendations.sort { $0.expectedConversionRate > $1.expectedConversionRate }
        
        return recommendations
    }
    
    /// Optimize ongoing trial experience
    public func optimizeTrialExperience() async {
        guard var trial = currentTrial else { return }
        
        // Analyze trial progress
        let progress = analyzeTrialProgress(trial)
        
        // Check for optimization opportunities
        let optimizations = identifyOptimizationOpportunities(trial: trial, progress: progress)
        
        // Apply optimizations
        for optimization in optimizations {
            await applyTrialOptimization(trial: &trial, optimization: optimization)
        }
        
        // Save updated trial
        if !optimizations.isEmpty {
            saveTrialExperience(trial)
            currentTrial = trial
        }
    }
    
    // MARK: - Trial Analytics
    
    /// Get comprehensive trial performance metrics
    public func getTrialPerformanceMetrics(
        timeRange: DateRange
    ) async -> TrialPerformanceMetrics {
        
        // Fetch trial data from Firestore
        let trials = await fetchTrialsInRange(timeRange)
        
        // Calculate metrics
        let totalTrials = trials.count
        let conversions = trials.filter { $0.status == .converted }.count
        let conversionRate = totalTrials > 0 ? Double(conversions) / Double(totalTrials) : 0
        
        let averageTrialDuration = trials.map { $0.totalTrialDuration }.reduce(0, +) / Double(totalTrials)
        let averageTimeToConversion = trials.compactMap { trial in
            trial.conversionDate?.timeIntervalSince(trial.startDate)
        }.reduce(0, +) / Double(conversions)
        
        // Revenue metrics
        let totalRevenue = trials.compactMap { $0.conversionDetails?.conversionValue }.reduce(0, +)
        let averageRevenuePerTrial = totalTrials > 0 ? totalRevenue / Double(totalTrials) : 0
        
        // Segmentation analysis
        let performanceByType = Dictionary(grouping: trials, by: { $0.trialType })
            .mapValues { typeTrials in
                let conversions = typeTrials.filter { $0.status == .converted }.count
                return Double(conversions) / Double(typeTrials.count)
            }
        
        let performanceByDuration = analyzePerformanceByDuration(trials)
        let topPersonalizationFactors = analyzeTopPersonalizationFactors(trials)
        
        return TrialPerformanceMetrics(
            timeRange: timeRange,
            totalTrials: totalTrials,
            conversions: conversions,
            conversionRate: conversionRate,
            averageTrialDuration: averageTrialDuration,
            averageTimeToConversion: averageTimeToConversion,
            totalRevenue: totalRevenue,
            averageRevenuePerTrial: averageRevenuePerTrial,
            performanceByType: performanceByType,
            performanceByDuration: performanceByDuration,
            topPersonalizationFactors: topPersonalizationFactors
        )
    }
    
    // MARK: - Helper Methods
    
    private func personalizeTrialConfiguration(
        baseType: TrialType,
        userProfile: UserTrialProfile
    ) -> TrialConfiguration {
        
        let baseConfig = trialConfigurations.configuration(for: baseType)
        
        // Adjust duration based on user profile
        var adjustedDuration = baseConfig.duration
        if userProfile.engagementLevel == .high {
            adjustedDuration *= 0.8 // Shorter trial for highly engaged users
        } else if userProfile.engagementLevel == .low {
            adjustedDuration *= 1.2 // Longer trial for low engagement users
        }
        
        // Customize features based on interests
        var focusFeatures = baseConfig.focusFeatures
        if let primaryInterest = userProfile.primaryFeatureInterest {
            focusFeatures = [primaryInterest]
        }
        
        // Adjust tier based on usage patterns
        var targetTier = baseConfig.targetTier
        if userProfile.expectedUsageLevel == .heavy {
            targetTier = .premium
        }
        
        // Create new configuration with adjusted values
        let config = TrialConfiguration(
            duration: adjustedDuration,
            targetTier: targetTier,
            features: baseConfig.features,
            focusFeatures: focusFeatures,
            restrictions: baseConfig.restrictions,
            checkpoints: baseConfig.checkpoints
        )
        
        return config
    }
    
    private func extractPersonalizationFactors(_ profile: UserTrialProfile) -> [PersonalizationFactor] {
        var factors: [PersonalizationFactor] = []
        
        factors.append(.engagementLevel(profile.engagementLevel))
        factors.append(.usageLevel(profile.expectedUsageLevel))
        
        if let interest = profile.primaryFeatureInterest {
            factors.append(.featureInterest(interest))
        }
        
        if let source = profile.acquisitionSource {
            factors.append(.acquisitionSource(source))
        }
        
        return factors
    }
    
    private func scheduleTrialOptimizationCheckins(_ trial: TrialExperience) {
        // Schedule periodic check-ins for trial optimization
        let checkinDays = [3, 7, 14] // Days into trial
        
        for day in checkinDays {
            let checkinDate = trial.startDate.addingTimeInterval(TimeInterval(day * 24 * 60 * 60))
            
            // Schedule local notification or background task
            Task {
                try? await Task.sleep(nanoseconds: UInt64(checkinDate.timeIntervalSinceNow * 1_000_000_000))
                await optimizeTrialExperience()
            }
        }
    }
    
    private func generateRetentionOffer(
        trial: TrialExperience,
        reason: TrialCancellationReason
    ) async -> RetentionOffer? {
        
        // Generate personalized retention offer based on cancellation reason
        switch reason {
        case .tooExpensive:
            return RetentionOffer(
                type: .discount,
                discountPercentage: 30,
                validForDays: 7,
                message: "Get 30% off your first 3 months!"
            )
        case .notEnoughValue:
            return RetentionOffer(
                type: .featureUnlock,
                validForDays: 14,
                message: "Unlock premium features for 2 more weeks!"
            )
        case .needMoreTime:
            return RetentionOffer(
                type: .trialExtension,
                extensionDays: 7,
                validForDays: 7,
                message: "Take 5 more days to explore all features!"
            )
        default:
            return nil
        }
    }
    
    // MARK: - Data Fetching and Analysis
    
    private func analyzeUserBehavior(_ profile: UserTrialProfile) async -> UserBehaviorAnalysis {
        // Analyze user behavior patterns
        return UserBehaviorAnalysis(
            primaryFeatureInterest: profile.primaryFeatureInterest,
            valueScore: calculateValueScore(profile),
            engagementPattern: .moderate
        )
    }
    
    private func predictConversionProbability(_ profile: UserTrialProfile) async -> ConversionProbability {
        // Use ML model or heuristics to predict conversion probability
        return ConversionProbability(
            standard: 0.15,
            featureSpecific: 0.22,
            extended: 0.28
        )
    }
    
    private func calculateOptimalTrialDuration(_ profile: UserTrialProfile) async -> TimeInterval {
        // Calculate optimal trial duration based on user profile
        switch profile.engagementLevel {
        case .low: return 21 * 24 * 60 * 60 // 21 days
        case .moderate: return 14 * 24 * 60 * 60 // 14 days
        case .high: return 5 * 24 * 60 * 60 // 5 days
        }
    }
    
    private func calculateValueScore(_ profile: UserTrialProfile) -> Double {
        var score: Double = 0.5
        
        // Adjust based on engagement level
        switch profile.engagementLevel {
        case .low: score -= 0.2
        case .moderate: break
        case .high: score += 0.3
        }
        
        // Adjust based on usage level
        switch profile.expectedUsageLevel {
        case .light: score -= 0.1
        case .moderate: break
        case .heavy: score += 0.2
        }
        
        return min(max(score, 0), 1)
    }
    
    // MARK: - StoreKit Integration (Placeholder)
    
    private func initializeTrialWithStoreKit(_ trial: TrialExperience) async -> Result<Void, Error> {
        // Integrate with StoreKit for trial initialization
        return .success(())
    }
    
    private func extendTrialWithStoreKit(_ trial: TrialExperience, extension: TrialExtension) async -> Result<Void, Error> {
        // Integrate with StoreKit for trial extension
        return .success(())
    }
    
    private func cancelTrialWithStoreKit(_ trial: TrialExperience) async -> Result<Void, Error> {
        // Integrate with StoreKit for trial cancellation
        return .success(())
    }
    
    // MARK: - Monitoring and Setup
    
    private func loadTrialHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        firestore.collection("trialExperiences")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startDate", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    Logger.error("AdvancedTrial: Error loading trial history: \(error)")
                    return
                }
                
                let trials = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TrialExperience.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.trialHistory = trials.map { TrialRecord(from: $0) }
                    self?.currentTrial = trials.first { $0.status == .active }
                }
            }
    }
    
    private func checkTrialEligibility() {
        // Check if user is eligible for trial
        // This would involve checking subscription status, trial history, etc.
        isEligibleForTrial = subscriptionManager.subscriptionState == .nonSubscribed
    }
    
    private func checkTrialEligibility(for type: TrialType) async -> Bool {
        // Check specific eligibility for trial type
        return isEligibleForTrial && !hasUsedTrialType(type)
    }
    
    private func hasUsedTrialType(_ type: TrialType) -> Bool {
        return trialHistory.contains { $0.trialType == type }
    }
    
    private func loadTrialRecommendations() {
        // Load personalized trial recommendations
        Task {
            // This would typically load from a recommendation service
            trialRecommendations = []
        }
    }
    
    private func setupTrialMonitoring() {
        // Set up monitoring for trial status changes
        subscriptionManager.$subscriptionState
            .sink { [weak self] _ in
                self?.checkTrialEligibility()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func saveTrialExperience(_ trial: TrialExperience) {
        do {
            let data = try Firestore.Encoder().encode(trial)
            firestore.collection("trialExperiences").document(trial.id).setData(data)
        } catch {
            Logger.error("AdvancedTrial: Error saving trial experience: \(error)")
        }
    }
    
    // MARK: - Placeholder implementations
    
    private func analyzeTrialProgress(_ trial: TrialExperience) -> TrialProgress {
        return TrialProgress(
            daysUsed: Int(Date().timeIntervalSince(trial.startDate) / (24 * 60 * 60)),
            featuresExplored: [],
            engagementScore: 0.7,
            conversionLikelihood: 0.3
        )
    }
    
    private func identifyOptimizationOpportunities(trial: TrialExperience, progress: TrialProgress) -> [TrialOptimization] {
        return []
    }
    
    private func applyTrialOptimization(trial: inout TrialExperience, optimization: TrialOptimization) async {
        // Apply specific optimization to trial
    }
    
    private func fetchTrialsInRange(_ range: DateRange) async -> [TrialExperience] {
        return []
    }
    
    private func analyzePerformanceByDuration(_ trials: [TrialExperience]) -> [Int: Double] {
        return [:]
    }
    
    private func analyzeTopPersonalizationFactors(_ trials: [TrialExperience]) -> [PersonalizationFactor] {
        return []
    }
}

// MARK: - Supporting Classes

/// Trial conversion optimizer using machine learning
private class TrialConversionOptimizer {
    func recordConversion(trial: TrialExperience, conversion: TrialConversion) {
        // Record conversion data for ML model training
    }
}