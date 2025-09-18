/**
 * FeatureAccessViewModel.swift
 * Growth App Feature Access View Model
 *
 * Observable view model for managing feature access UI state throughout the app.
 * Provides reactive updates when subscription status changes and handles upgrade flows.
 */

import Foundation
import Combine
import SwiftUI

/// View model for managing feature access UI state
@MainActor
public final class FeatureAccessViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current subscription tier display information
    @Published public private(set) var tierInfo: TierDisplayInfo = .loading
    
    /// Available features for current user
    @Published public private(set) var availableFeatures: Set<FeatureType> = []
    
    /// Premium features that are locked
    @Published public private(set) var lockedFeatures: Set<FeatureType> = []
    
    /// Whether trial countdown should be shown
    @Published public private(set) var showTrialCountdown: Bool = false
    
    /// Trial countdown information
    @Published public private(set) var trialInfo: TrialInfo?
    
    /// Current upgrade prompt state
    @Published public var upgradePromptState: UpgradePromptState = .hidden
    
    /// Loading state for UI operations
    @Published public private(set) var isLoading: Bool = false
    
    /// Last error message for display
    @Published public private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let featureGateService = FeatureGateService.shared
    private let subscriptionStateManager = SubscriptionStateManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        setupBindings()
        updateDisplayInfo()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor feature gate service changes
        featureGateService.$accessState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplayInfo()
            }
            .store(in: &cancellables)
        
        featureGateService.$accessibleFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] features in
                self?.availableFeatures = features
                self?.updateLockedFeatures()
            }
            .store(in: &cancellables)
        
        featureGateService.$isRefreshing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshing in
                self?.isLoading = isRefreshing
            }
            .store(in: &cancellables)
        
        featureGateService.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error?.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Check if user has access to a specific feature
    public func hasAccess(to feature: FeatureType) -> Bool {
        return featureGateService.hasAccess(to: feature).isGranted
    }
    
    /// Show upgrade prompt for a specific feature
    public func showUpgradePrompt(for feature: FeatureType) {
        upgradePromptState = .feature(feature)
    }
    
    /// Show general upgrade prompt
    public func showGeneralUpgradePrompt() {
        upgradePromptState = .general
    }
    
    /// Hide upgrade prompt
    public func hideUpgradePrompt() {
        upgradePromptState = .hidden
    }
    
    /// Refresh feature access state
    public func refreshAccess() async {
        await featureGateService.forceRefresh()
    }
    
    /// Check if feature should show premium indicator
    public func shouldShowPremiumIndicator(for feature: FeatureType) -> Bool {
        return featureGateService.shouldShowUpgradePrompt(for: feature)
    }
    
    /// Get tier required for a feature
    public func getRequiredTier(for feature: FeatureType) -> SubscriptionTier {
        return featureGateService.getRequiredTier(for: feature)
    }
    
    // MARK: - Trial Management
    
    /// Get formatted trial countdown text
    public func getTrialCountdownText() -> String? {
        guard let trialInfo = trialInfo else { return nil }
        
        if trialInfo.remainingDays > 0 {
            return "\(trialInfo.remainingDays) day\(trialInfo.remainingDays == 1 ? "" : "s") left"
        } else {
            return "Trial expires today"
        }
    }
    
    /// Check if trial warning should be shown (less than 3 days)
    public func shouldShowTrialWarning() -> Bool {
        return trialInfo?.remainingDays ?? 0 < 3 && showTrialCountdown
    }
    
    // MARK: - Feature Categories
    
    /// Get features grouped by category for display
    public func getFeaturesByCategory() -> [FeatureCategory] {
        return [
            FeatureCategory(
                name: "Timer Features",
                features: [.quickTimer, .advancedTimer, .liveActivities]
            ),
            FeatureCategory(
                name: "Content & Learning",
                features: [.articles, .premiumContent, .expertInsights]
            ),
            FeatureCategory(
                name: "Customization",
                features: [.customRoutines, .advancedCustomization, .goalSetting]
            ),
            FeatureCategory(
                name: "Analytics & Progress",
                features: [.progressTracking, .advancedAnalytics]
            ),
            FeatureCategory(
                name: "AI & Support",
                features: [.aiCoach, .prioritySupport]
            ),
            FeatureCategory(
                name: "Data & Backup",
                features: [.unlimitedBackup]
            )
        ]
    }
    
    // MARK: - Private Implementation
    
    private func updateDisplayInfo() {
        let accessState = featureGateService.accessState
        
        switch accessState {
        case .loading:
            tierInfo = .loading
            showTrialCountdown = false
            trialInfo = nil
            
        case .free:
            tierInfo = .free
            showTrialCountdown = false
            trialInfo = nil
            
        case .trial(let remainingDays):
            tierInfo = .trial
            showTrialCountdown = true
            trialInfo = TrialInfo(remainingDays: remainingDays)
            
        case .premium:
            tierInfo = .premium
            showTrialCountdown = false
            trialInfo = nil
            
        case .expired:
            tierInfo = .expired
            showTrialCountdown = false
            trialInfo = nil
            
        case .pending:
            tierInfo = .pending
            showTrialCountdown = false
            trialInfo = nil
        }
        
        updateLockedFeatures()
    }
    
    private func updateLockedFeatures() {
        let allFeatures = Set(FeatureType.allCases)
        lockedFeatures = allFeatures.subtracting(availableFeatures)
    }
}

// MARK: - Supporting Models

/// Display information for subscription tiers
public enum TierDisplayInfo {
    case loading
    case free
    case trial
    case premium
    case expired
    case pending
    
    public var displayName: String {
        switch self {
        case .loading: return "Loading..."
        case .free: return "Free"
        case .trial: return "Trial"
        case .premium: return "Premium"
        case .expired: return "Expired"
        case .pending: return "Pending"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .loading: return .gray
        case .free: return .blue
        case .trial: return .orange
        case .premium: return .green
        case .expired: return .red
        case .pending: return .yellow
        }
    }
    
    public var icon: String {
        switch self {
        case .loading: return "hourglass"
        case .free: return "person"
        case .trial: return "clock"
        case .premium: return "crown.fill"
        case .expired: return "exclamationmark.triangle"
        case .pending: return "hourglass.bottomhalf.filled"
        }
    }
}

/// Trial period information
public struct TrialInfo {
    public let remainingDays: Int
    
    public var isExpiringSoon: Bool {
        return remainingDays <= 3
    }
    
    public var urgencyLevel: UrgencyLevel {
        switch remainingDays {
        case 0:
            return .critical
        case 1...2:
            return .high
        case 3...7:
            return .medium
        default:
            return .low
        }
    }
}

/// Urgency level for trial expiration
public enum UrgencyLevel {
    case low, medium, high, critical
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

/// Upgrade prompt states
public enum UpgradePromptState: Equatable {
    case hidden
    case general
    case feature(FeatureType)
    
    public var isVisible: Bool {
        switch self {
        case .hidden: return false
        case .general, .feature: return true
        }
    }
}

/// Feature category for organization
public struct FeatureCategory {
    public let name: String
    public let features: [FeatureType]
    
    public init(name: String, features: [FeatureType]) {
        self.name = name
        self.features = features
    }
}

// MARK: - View Extensions for FeatureAccessViewModel

extension View {
    /// Binds a FeatureAccessViewModel to this view
    public func featureAccess(_ viewModel: FeatureAccessViewModel) -> some View {
        self.environmentObject(viewModel)
    }
}