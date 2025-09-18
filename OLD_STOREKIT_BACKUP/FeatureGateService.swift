/**
 * FeatureGateService.swift
 * Growth App Advanced Feature Gating System
 *
 * Centralized service for managing feature access control based on subscription state.
 * Provides real-time feature access decisions with offline support, usage limits, 
 * and comprehensive analytics integration for conversion optimization.
 */

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

/// Central coordinator for feature access control and gating
@MainActor
public final class FeatureGateService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current user's feature access state
    @Published public private(set) var accessState: FeatureAccessState = .loading
    
    /// Whether feature access is currently being refreshed
    @Published public private(set) var isRefreshing: Bool = false
    
    /// Last error encountered during feature access operations
    @Published public private(set) var lastError: Error?
    
    /// Cache of accessible features for performance
    @Published public private(set) var accessibleFeatures: Set<FeatureType> = []
    
    /// Feature access results with detailed information
    @Published public private(set) var featureAccess: [FeatureType: FeatureAccess] = [:]
    
    // MARK: - Private Properties
    
    private let subscriptionStateManager = SubscriptionStateManager.shared
    private let entitlementService = SubscriptionEntitlementService.shared
    private let analyticsService = PaywallAnalyticsService.shared
    private let revenueAttributionService = RevenueAttributionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Enhanced cache for feature access decisions
    private let cache = FeatureAccessCache()
    
    /// Usage tracking for feature limits
    private let usageTracker = FeatureUsageTracker()
    
    /// Last refresh timestamp
    private var lastRefresh: Date?
    
    // MARK: - Singleton
    
    public static let shared = FeatureGateService()
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
        refreshAccessState()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor subscription state changes
        subscriptionStateManager.$subscriptionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAccessState()
            }
            .store(in: &cancellables)
        
        // Monitor entitlement service changes
        entitlementService.$currentTier
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAccessState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Feature Access Control
    
    /// Check if user has access to a specific feature with detailed information
    public func hasAccess(to feature: FeatureType) -> FeatureAccess {
        // Return cached result if available
        if let cachedAccess = featureAccess[feature] {
            return cachedAccess
        }
        
        // Calculate access based on current state
        let access = calculateFeatureAccess(for: feature)
        featureAccess[feature] = access
        
        return access
    }
    
    /// Check if user has access to a specific feature (boolean convenience method)
    public func hasAccessBool(to feature: FeatureType) -> Bool {
        return hasAccess(to: feature).isGranted
    }
    
    /// Get all features the user currently has access to
    public func getAccessibleFeatures() -> Set<FeatureType> {
        return Set(FeatureType.allCases.filter { hasAccess(to: $0).isGranted })
    }
    
    /// Check if user has access to all premium features
    public func hasAllPremiumAccess() -> Bool {
        return subscriptionStateManager.subscriptionState.hasActiveAccess
    }
    
    /// Check if user is currently in trial period
    public func isInTrialPeriod() -> Bool {
        return subscriptionStateManager.subscriptionState.isTrialActive
    }
    
    /// Get remaining trial days
    public func getRemainingTrialDays() -> Int {
        guard isInTrialPeriod(),
              let trialExpirationDate = subscriptionStateManager.subscriptionState.trialExpirationDate else {
            return 0
        }
        
        let remainingTime = trialExpirationDate.timeIntervalSinceNow
        return max(0, Int(ceil(remainingTime / (24 * 60 * 60))))
    }
    
    // MARK: - Advanced Feature Access Methods
    
    /// Refresh all feature access permissions
    public func refreshAccess() async {
        let state = subscriptionStateManager.subscriptionState
        
        // Calculate access for all features
        var newAccess: [FeatureType: FeatureAccess] = [:]
        
        for feature in FeatureType.allCases {
            newAccess[feature] = calculateFeatureAccess(for: feature, subscriptionState: state)
        }
        
        featureAccess = newAccess
        lastRefresh = Date()
        
        // Cache results
        cache.cacheAccess(newAccess)
        
        // Update accessible features set
        accessibleFeatures = Set(FeatureType.allCases.filter { newAccess[$0]?.isGranted == true })
    }
    
    /// Track feature gate interaction for analytics
    public func trackFeatureGateInteraction(
        _ feature: FeatureType,
        action: GateAction,
        context: PaywallContext? = nil
    ) {
        let finalContext = context ?? .featureGate(feature)
        // Track analytics event
        analyticsService.trackConversionEvent(
            ConversionEvent.featureGateInteraction,
            context: finalContext,
            metadata: [
                "feature": feature.rawValue,
                "action": action.rawValue,
                "subscription_tier": subscriptionStateManager.currentTier.rawValue,
                "trial_active": subscriptionStateManager.subscriptionState.isTrialActive
            ]
        )
        
        // Track revenue attribution touchpoint
        let touchpointType: TouchpointType = action == .upgradePromptShown ? .impression : .interaction
        revenueAttributionService.recordTouchpoint(
            source: feature.revenueSource,
            context: finalContext,
            touchpointType: touchpointType,
            metadata: ["action": action.rawValue]
        )
    }
    
    /// Check and consume feature usage
    public func consumeFeatureUsage(for feature: FeatureType) async -> Bool {
        guard let access = featureAccess[feature] else { return false }
        
        switch access {
        case .granted:
            return true
            
        case .limited(let usage):
            if usage.remainingUsage > 0 {
                usageTracker.incrementUsage(for: feature)
                
                // Refresh access to update usage counts
                await refreshAccess()
                
                return true
            }
            return false
            
        case .denied:
            return false
        }
    }
    
    /// Get detailed feature information including benefits
    public func getFeatureInfo(for feature: FeatureType) -> FeatureInfo {
        let access = hasAccess(to: feature)
        let tier = subscriptionStateManager.currentTier
        
        return FeatureInfo(
            feature: feature,
            access: access,
            currentTier: tier,
            requiredTier: feature.requiredTier,
            benefits: feature.premiumBenefits,
            upgradePrompt: feature.upgradePrompt(for: tier)
        )
    }
    
    // MARK: - Premium Feature Checks
    
    /// Check if user should see upgrade prompts for a feature
    public func shouldShowUpgradePrompt(for feature: FeatureType) -> Bool {
        return !hasAccess(to: feature).isGranted && !feature.isFreeFeature
    }
    
    /// Get the subscription tier required for a feature
    public func getRequiredTier(for feature: FeatureType) -> SubscriptionTier {
        return feature.isFreeFeature ? .none : .premium
    }
    
    /// Get premium features that user doesn't have access to
    public func getUnavailablePremiumFeatures() -> Set<FeatureType> {
        let premiumFeatures = Set(FeatureType.allCases.filter { !$0.isFreeFeature })
        let accessibleFeatures = getAccessibleFeatures()
        return premiumFeatures.subtracting(accessibleFeatures)
    }
    
    // MARK: - State Management
    
    /// Refresh feature access state from subscription data
    public func refreshAccessState() {
        isRefreshing = true
        
        // Determine access state based on subscription
        let subscriptionState = subscriptionStateManager.subscriptionState
        
        switch subscriptionState.status {
        case .none:
            accessState = .free
        case .active:
            if subscriptionState.isTrialActive {
                accessState = .trial(remainingDays: getRemainingTrialDays())
            } else {
                accessState = .premium
            }
        case .expired:
            accessState = .expired
        case .pending:
            accessState = .pending
        case .grace:
            // Grace period still provides access
            accessState = .premium
        case .cancelled:
            // Cancelled but still active until expiration
            if subscriptionState.hasActiveAccess {
                accessState = .premium
            } else {
                accessState = .expired
            }
        }
        
        // Refresh feature access asynchronously
        Task {
            await refreshAccess()
        }
        
        isRefreshing = false
        lastError = nil
        
        Logger.info("FeatureGateService: Access state updated to \(accessState)")
    }
    
    /// Force refresh from subscription state manager
    public func forceRefresh() async {
        await subscriptionStateManager.forceRefresh()
        refreshAccessState()
    }
    
    // MARK: - Private Implementation
    
    private func calculateFeatureAccess(
        for feature: FeatureType,
        subscriptionState: SubscriptionState? = nil
    ) -> FeatureAccess {
        let state = subscriptionState ?? subscriptionStateManager.subscriptionState
        
        // Free features are always available
        if feature.isFreeFeature {
            return .granted
        }
        
        // Premium users get unlimited access to all features
        if state.hasActiveAccess && state.tier == .premium {
            return .granted
        }
        
        // For non-premium users, check usage limits
        if let usageLimit = feature.usageLimit {
            let currentUsage = usageTracker.getTotalUsage(for: feature)
            let usage = FeatureUsage(
                currentUsage: currentUsage,
                limit: usageLimit.totalLimit,
                resetDate: usageLimit.resetDate,
                isPermanent: usageLimit.isPermanent
            )
            
            if usage.isAtLimit {
                return .denied(reason: .usageLimitExceeded)
            } else if usageLimit.shouldShowLimitedAccess {
                return .limited(usage: usage)
            }
            
            return .granted
        }
        
        // Check if user has active subscription for other premium features
        if !state.hasActiveAccess {
            return .denied(reason: .requiresPremium)
        }
        
        // Check if user's tier includes this feature
        if state.tier.entitlements.hasFeature(feature) {
            return .granted
        }
        
        // Feature not available in current tier
        return .denied(reason: .requiresPremium)
    }
    
    // MARK: - Debug Support
    
    public func debugPrintAccessState() {
        Logger.info("🎯 FeatureGateService Debug:")
        Logger.info("Access State: \(accessState)")
        Logger.info("Accessible Features: \(accessibleFeatures.map { $0.displayName })")
        Logger.info("Subscription State: \(subscriptionStateManager.subscriptionState)")
        Logger.info("Feature Access Cache Size: \(featureAccess.count)")
        Logger.info("Last Refresh: \(lastRefresh?.description ?? "Never")")
    }
}

// MARK: - Feature Access Result

/// Represents the access status for a feature
public enum FeatureAccess {
    case granted
    case denied(reason: DenialReason)
    case limited(usage: FeatureUsage)
    
    /// Whether access is granted
    public var isGranted: Bool {
        switch self {
        case .granted:
            return true
        case .denied, .limited:
            return false
        }
    }
    
    /// Whether this is a limited access (e.g., trial or usage-limited)
    public var isLimited: Bool {
        switch self {
        case .limited:
            return true
        default:
            return false
        }
    }
}

// MARK: - Denial Reason

/// Reasons why feature access might be denied
public enum DenialReason: String, CaseIterable {
    case requiresPremium = "requires_premium"
    case trialExpired = "trial_expired"
    case usageLimitExceeded = "usage_limit_exceeded"
    case featureDisabled = "feature_disabled"
    case networkRequired = "network_required"
    
    /// User-friendly description
    public var localizedDescription: String {
        switch self {
        case .requiresPremium:
            return "This feature requires a Premium subscription"
        case .trialExpired:
            return "Your free trial has expired"
        case .usageLimitExceeded:
            return "You've used all 3 free AI coaching sessions. Upgrade to Premium for unlimited access."
        case .featureDisabled:
            return "This feature is currently unavailable"
        case .networkRequired:
            return "Network connection required for this feature"
        }
    }
    
    /// Suggested action for the user
    public var suggestedAction: String {
        switch self {
        case .requiresPremium, .trialExpired:
            return "Upgrade to Premium"
        case .usageLimitExceeded:
            return "Upgrade for unlimited access"
        case .featureDisabled:
            return "Check back later"
        case .networkRequired:
            return "Connect to the internet"
        }
    }
}

// MARK: - Feature Usage

/// Tracks usage limits for features
public struct FeatureUsage {
    public let currentUsage: Int
    public let limit: Int
    public let resetDate: Date?
    public let isPermanent: Bool
    
    public var remainingUsage: Int {
        max(0, limit - currentUsage)
    }
    
    public var usagePercentage: Double {
        guard limit > 0 else { return 0 }
        return Double(currentUsage) / Double(limit)
    }
    
    public var isAtLimit: Bool {
        currentUsage >= limit
    }
    
    /// User-friendly message about usage status
    public var usageMessage: String {
        if isPermanent && isAtLimit {
            return "You've used all \(limit) free AI coaching sessions. Upgrade to Premium for unlimited access."
        } else if isPermanent {
            return "You have \(remainingUsage) of \(limit) free AI coaching sessions remaining."
        } else if isAtLimit {
            return "Daily limit reached. Resets tomorrow."
        } else {
            return "\(remainingUsage) uses remaining today"
        }
    }
}

// MARK: - Gate Action

/// Actions that can be performed on feature gates
public enum GateAction: String, CaseIterable {
    case accessed = "accessed"
    case blocked = "blocked"
    case upgradePromptShown = "upgrade_prompt_shown"
    case upgradePromptTapped = "upgrade_prompt_tapped"
    case upgradePromptDismissed = "upgrade_prompt_dismissed"
    case usageLimitWarningShown = "usage_limit_warning_shown"
}

// MARK: - Feature Info

/// Comprehensive information about a feature and its access status
public struct FeatureInfo {
    public let feature: FeatureType
    public let access: FeatureAccess
    public let currentTier: SubscriptionTier
    public let requiredTier: SubscriptionTier
    public let benefits: [String]
    public let upgradePrompt: String
}

// MARK: - Feature Extensions

extension FeatureType {
    /// Required subscription tier for this feature
    public var requiredTier: SubscriptionTier {
        return isFreeFeature ? .none : .premium
    }
    
    /// Usage limits for this feature (if any) - only applies to non-premium users
    public var usageLimit: FeatureUsageLimit? {
        switch self {
        case .aiCoach:
            // Only return usage limit for non-premium users (checked in calculateFeatureAccess)
            return FeatureUsageLimit(totalLimit: 3, isPermanent: true)
        default:
            return nil
        }
    }
    
    /// Revenue source for attribution
    public var revenueSource: RevenueSource {
        switch self {
        case .aiCoach:
            return .featureGateAICoach
        case .customRoutines:
            return .featureGateCustomRoutines
        case .progressTracking:
            return .featureGateProgressTracking
        case .advancedAnalytics:
            return .featureGateAdvancedAnalytics
        case .liveActivities:
            return .featureGateLiveActivities
        default:
            return .generalPaywall
        }
    }
    
    /// Premium benefits for this feature
    public var premiumBenefits: [String] {
        switch self {
        case .aiCoach:
            return ["Unlimited AI coaching sessions", "Personalized guidance", "Advanced insights"]
        case .customRoutines:
            return ["Unlimited custom routines", "Advanced scheduling", "Routine templates"]
        case .advancedAnalytics:
            return ["Detailed progress tracking", "Trend analysis", "Export capabilities"]
        case .liveActivities:
            return ["Custom complications", "Multiple sessions", "Advanced widgets"]
        case .progressTracking:
            return ["Long-term progress tracking", "Goal setting", "Milestone tracking"]
        default:
            return ["Premium feature access", "Enhanced functionality"]
        }
    }
    
    /// Contextual upgrade prompt for different tiers
    public func upgradePrompt(for tier: SubscriptionTier) -> String {
        switch self {
        case .aiCoach:
            return tier == .none ? "Get unlimited AI coaching with Premium" : "Upgrade for unlimited AI sessions"
        case .customRoutines:
            return "Create unlimited custom routines with Premium"
        case .advancedAnalytics:
            return "Unlock detailed analytics with Premium"
        default:
            return "Upgrade to Premium to access this feature"
        }
    }
}

// MARK: - Feature Usage Limit

/// Defines usage limits for features
public struct FeatureUsageLimit {
    public let totalLimit: Int
    public let isPermanent: Bool  // If true, limit never resets
    
    public var shouldShowLimitedAccess: Bool {
        // Show limited access for permanent limits
        return isPermanent
    }
    
    public var resetDate: Date? {
        // Permanent limits don't have a reset date
        return isPermanent ? nil : Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
    }
}

// MARK: - Feature Access Cache

/// Caches feature access results for performance
private class FeatureAccessCache {
    private var cache: [FeatureType: (access: FeatureAccess, timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    
    func getCachedAccess(for feature: FeatureType) -> FeatureAccess? {
        guard let cached = cache[feature],
              Date().timeIntervalSince(cached.timestamp) < cacheExpiry else {
            return nil
        }
        return cached.access
    }
    
    func cacheAccess(_ access: [FeatureType: FeatureAccess]) {
        let timestamp = Date()
        for (feature, featureAccess) in access {
            cache[feature] = (featureAccess, timestamp)
        }
    }
}

// MARK: - Feature Usage Tracker

/// Tracks feature usage for limit enforcement
private class FeatureUsageTracker {
    private let userDefaults = UserDefaults.standard
    
    /// Get total usage for permanent limits (e.g., AI Coach free tier)
    func getTotalUsage(for feature: FeatureType) -> Int {
        let key = "feature_usage_total_\(feature.rawValue)"
        return userDefaults.integer(forKey: key)
    }
    
    /// Get current daily usage
    func getCurrentUsage(for feature: FeatureType) -> Int {
        let key = "feature_usage_\(feature.rawValue)_\(todayKey)"
        return userDefaults.integer(forKey: key)
    }
    
    /// Increment usage for a feature
    func incrementUsage(for feature: FeatureType) {
        // Increment total usage for permanent limits
        if feature == .aiCoach {
            let totalKey = "feature_usage_total_\(feature.rawValue)"
            let currentTotal = userDefaults.integer(forKey: totalKey)
            userDefaults.set(currentTotal + 1, forKey: totalKey)
        }
        
        // Also track daily usage
        let key = "feature_usage_\(feature.rawValue)_\(todayKey)"
        let currentUsage = userDefaults.integer(forKey: key)
        userDefaults.set(currentUsage + 1, forKey: key)
    }
    
    /// Reset usage for a feature (used when user upgrades to premium)
    func resetUsage(for feature: FeatureType) {
        let totalKey = "feature_usage_total_\(feature.rawValue)"
        userDefaults.removeObject(forKey: totalKey)
    }
    
    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Feature Access State

/// Represents the current feature access state for the user
public enum FeatureAccessState: Equatable {
    case loading
    case free
    case trial(remainingDays: Int)
    case premium
    case expired
    case pending
    
    public var displayName: String {
        switch self {
        case .loading:
            return "Loading..."
        case .free:
            return "Free"
        case .trial(let days):
            return "Trial (\(days) days left)"
        case .premium:
            return "Premium"
        case .expired:
            return "Expired"
        case .pending:
            return "Pending"
        }
    }
    
    public var hasActiveAccess: Bool {
        switch self {
        case .trial, .premium:
            return true
        case .loading, .free, .expired, .pending:
            return false
        }
    }
    
    public var shouldShowUpgradePrompts: Bool {
        switch self {
        case .free, .expired:
            return true
        case .loading, .trial, .premium, .pending:
            return false
        }
    }
}

// MARK: - Feature Gate Errors

extension FeatureGateService {
    enum FeatureGateError: LocalizedError {
        case featureNotAvailable
        case subscriptionRequired
        case trialExpired
        case validationFailed
        
        var errorDescription: String? {
            switch self {
            case .featureNotAvailable:
                return "Feature not available"
            case .subscriptionRequired:
                return "Premium subscription required"
            case .trialExpired:
                return "Trial period has expired"
            case .validationFailed:
                return "Feature access validation failed"
            }
        }
    }
}