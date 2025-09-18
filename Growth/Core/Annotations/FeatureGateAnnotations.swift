/**
 * FeatureGateAnnotations.swift
 * Growth App Feature Gating Property Wrappers
 *
 * Declarative property wrappers for feature gating functionality.
 * Provides elegant syntax for marking premium features and handling access control.
 */

import Foundation
import SwiftUI
import Combine

// MARK: - Premium Feature Property Wrapper

/// Property wrapper that automatically gates premium features based on subscription state
@propertyWrapper
@MainActor
public struct PremiumFeature<T> {
    private let feature: String
    private let fallback: T
    
    public init(
        _ feature: String,
        fallback: T
            ) {
        self.feature = feature
        self.fallback = fallback
    }
    
    public var wrappedValue: T {
        let access = FeatureAccess.from(feature: feature)
        return access.isGranted ? getValue() : fallback
    }
    
    /// Override this in concrete implementations to get the actual value
    private func getValue() -> T {
        // This is a placeholder - actual implementation would need the real value
        // In practice, this wrapper would be used differently
        return fallback
    }
    
    public var projectedValue: FeatureAccess {
        return FeatureAccess.from(feature: feature)
    }
}

// MARK: - Trial Feature Property Wrapper

/// Property wrapper for features available during trial period
@propertyWrapper
@MainActor
public struct TrialFeature<T> {
    private let feature: String
    private let fallback: T
    
    public init(
        _ feature: String,
        fallback: T
            ) {
        self.feature = feature
        self.fallback = fallback
    }
    
    public var wrappedValue: T {
        let access = FeatureAccess.from(feature: feature)
        // For now, just use the basic access check
        // Trial logic can be added later if needed
        return access.isGranted ? getValue() : fallback
    }
    
    private func getValue() -> T {
        return fallback
    }
    
    public var projectedValue: FeatureAccess {
        return FeatureAccess.from(feature: feature)
    }
}

// MARK: - Freemium Feature Property Wrapper

/// Property wrapper for features with limited free tier functionality
@propertyWrapper
@MainActor
public struct FreemiumFeature<T> {
    private let feature: String
    private let freeValue: T
    private let premiumValue: T
    
    public init(
        _ feature: String,
        freeValue: T,
        premiumValue: T
            ) {
        self.feature = feature
        self.freeValue = freeValue
        self.premiumValue = premiumValue
    }
    
    public var wrappedValue: T {
        let access = FeatureAccess.from(feature: feature)
        return access.isGranted ? premiumValue : freeValue
    }
    
    public var projectedValue: FeatureAccess {
        return FeatureAccess.from(feature: feature)
    }
}

// MARK: - Usage Limited Feature Property Wrapper

/// Property wrapper for features with usage limits
@propertyWrapper
@MainActor
public struct UsageLimitedFeature<T> {
    private let feature: String
    private let limitedValue: T
    private let unlimitedValue: T
    private let deniedValue: T
    
    public init(
        _ feature: String,
        limitedValue: T,
        unlimitedValue: T,
        deniedValue: T
            ) {
        self.feature = feature
        self.limitedValue = limitedValue
        self.unlimitedValue = unlimitedValue
        self.deniedValue = deniedValue
        // Entitlement manager is already initialized
    }
    
    public var wrappedValue: T {
        let access = FeatureAccess.from(feature: feature)
        
        switch access {
        case .granted:
            return unlimitedValue
        case .limited:
            return limitedValue
        case .denied:
            return deniedValue
        }
    }
    
    public var projectedValue: FeatureAccess {
        return FeatureAccess.from(feature: feature)
    }
}

// MARK: - Feature Gate View Modifier

/// SwiftUI View modifier for feature gating
public struct FeatureGated: ViewModifier {
    private let feature: String
    private let showUpgradePrompt: Bool
    private let fallbackView: AnyView?
    
    @State private var showingUpgradeSheet = false
    @State private var access: FeatureAccess = .denied(reason: .noSubscription)
    
    public init(
        feature: String,
        showUpgradePrompt: Bool = true,
        fallbackView: AnyView? = nil
    ) {
        self.feature = feature
        self.showUpgradePrompt = showUpgradePrompt
        self.fallbackView = fallbackView
    }
    
    public func body(content: Content) -> some View {
        Group {
            if access.isGranted {
                content
                    .onAppear {
                        // Track feature access if needed
                    }
            } else {
                if let fallbackView = fallbackView {
                    fallbackView
                } else if showUpgradePrompt {
                    upgradePromptView(for: access)
                } else {
                    EmptyView()
                }
            }
        }
        .onAppear {
            updateAccess()
            if !access.isGranted {
                // Track feature block if needed
            }
        }
    }
    
    private func updateAccess() {
        access = FeatureAccess.from(feature: feature)
    }
    
    private func denialReasonDescription(_ reason: DenialReason) -> String {
        switch reason {
        case .noSubscription:
            return "This feature requires a premium subscription."
        case .insufficientTier:
            return "This feature requires a higher subscription tier."
        case .trialExpired:
            return "Your trial period has expired."
        case .usageLimitReached:
            return "You've reached the usage limit for this feature."
        case .featureNotAvailable:
            return "This feature is not currently available."
        }
    }
    
    private func denialReasonAction(_ reason: DenialReason) -> String {
        switch reason {
        case .noSubscription, .insufficientTier:
            return "Upgrade to Premium"
        case .trialExpired:
            return "Subscribe Now"
        case .usageLimitReached:
            return "Upgrade for Unlimited Access"
        case .featureNotAvailable:
            return "Learn More"
        }
    }
    
    @ViewBuilder
    private func upgradePromptView(for access: FeatureAccess) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(feature.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.headline)
            
            if case .denied(let reason) = access {
                Text(denialReasonDescription(reason))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // Track upgrade prompt tap if needed
                    showingUpgradeSheet = true
                }) {
                    Text(denialReasonAction(reason))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .onAppear {
                    // Track upgrade prompt shown if needed
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingUpgradeSheet) {
            // This would show the paywall - simplified for now
            Text("Upgrade to Premium")
                .onDisappear {
                    // Track upgrade prompt dismissed if needed
                }
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies feature gating to a view
    public func featureGated(
        _ feature: String,
        showUpgradePrompt: Bool = true,
        fallbackView: AnyView? = nil
    ) -> some View {
        modifier(FeatureGated(
            feature: feature,
            showUpgradePrompt: showUpgradePrompt,
            fallbackView: fallbackView
        ))
    }
    
    /// Conditionally shows content based on feature access
    public func premiumOnly(_ feature: String) -> some View {
        modifier(FeatureGated(
            feature: feature,
            showUpgradePrompt: false,
            fallbackView: AnyView(EmptyView())
        ))
    }
}

// MARK: - Observable Feature Access

/// Observable wrapper for feature access that updates automatically
@MainActor
public final class ObservableFeatureAccess: ObservableObject {
    @Published public private(set) var access: FeatureAccess
    
    private let feature: String
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        feature: String
            ) {
        self.feature = feature
        self.access = FeatureAccess.from(feature: feature)
        
        setupBinding()
    }
    
    private func setupBinding() {
        // For now, just update access when needed
        // Can add more sophisticated monitoring later
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.access = FeatureAccess.from(feature: self.feature)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Feature Access Helpers
// Equatable conformance is now in FeatureAccess.swift