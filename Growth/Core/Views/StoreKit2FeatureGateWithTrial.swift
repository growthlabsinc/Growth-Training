/**
 * StoreKit2FeatureGateWithTrial.swift
 * Enhanced Feature Gating with Trial Support
 *
 * Extends the simplified feature gating with trial awareness and usage limits
 */

import SwiftUI

// Note: FeatureType is defined in SubscriptionTier.swift
// SimplifiedEntitlementManagerWithTrial is in Core/Services
// StoreKit2PaywallView is in Core/Views
// PaywallContext is in Core/Models

// MARK: - Trial-Aware Feature Gate View Modifier

/// Enhanced feature gate that handles trial status and usage limits
public struct StoreKit2TrialAwareFeatureGate: ViewModifier {
    let feature: FeatureType
    let showPaywall: Bool
    let context: PaywallContext

    @EnvironmentObject private var entitlements: SimplifiedEntitlementManagerWithTrial
    @State private var showingPaywall = false

    public func body(content: Content) -> some View {
        let featureAccess = entitlements.checkFeatureAccess(for: feature)

        switch featureAccess {
        case .granted:
            // Full access - show content
            content

        case .limited(let usage):
            // Limited access during trial
            VStack(spacing: 16) {
                // Usage indicator
                TrialUsageIndicator(
                    feature: feature,
                    usage: usage
                )

                if usage.currentUsage < usage.maxUsage {
                    // Still have uses remaining
                    content
                } else {
                    // Limit reached
                    LimitReachedView(
                        feature: feature,
                        resetTime: usage.resetDate,
                        onUpgrade: {
                            showingPaywall = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showingPaywall) {
                StoreKit2PaywallView()
            }

        case .denied(let reason):
            // No access - show appropriate message
            if showPaywall {
                TrialFeatureLockedView(
                    feature: feature,
                    reason: reason.localizedDescription,
                    trialStatus: entitlements.trialStatus,
                    onUpgrade: {
                        showingPaywall = true
                    }
                )
                .sheet(isPresented: $showingPaywall) {
                    StoreKit2PaywallView()
                }
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Trial Usage Indicator

struct TrialUsageIndicator: View {
    let feature: FeatureType
    let usage: FeatureUsage

    var body: some View {
        HStack {
            Image(systemName: "hourglass")
                .foregroundColor(.orange)

            Text("\(usage.currentUsage) of \(usage.maxUsage) \(feature.usageUnit) used today")
                .font(.caption)
                .foregroundColor(Color.secondary)

            Spacer()

            if let resetTime = usage.resetDate {
                TimeUntilReset(resetTime: resetTime)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Time Until Reset View

struct TimeUntilReset: View {
    let resetTime: Date
    @State private var timeRemaining: String = ""

    var body: some View {
        Text("Resets in \(timeRemaining)")
            .font(.caption)
            .foregroundColor(.blue)
            .onAppear {
                updateTimeRemaining()
                startTimer()
            }
    }

    private func updateTimeRemaining() {
        let interval = resetTime.timeIntervalSince(Date())
        if interval > 0 {
            let hours = Int(interval) / 3600
            let minutes = (Int(interval) % 3600) / 60
            timeRemaining = "\(hours)h \(minutes)m"
        } else {
            timeRemaining = "Soon"
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
}

// MARK: - Limit Reached View

struct LimitReachedView: View {
    let feature: FeatureType
    let resetTime: Date?
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Daily Limit Reached")
                .font(.headline)

            Text("You've used all your \(feature.displayName) for today during your trial.")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let resetTime = resetTime {
                TimeUntilReset(resetTime: resetTime)
            }

            HStack(spacing: 16) {
                Button("Wait") {
                    // Just dismiss
                }
                .buttonStyle(.bordered)

                Button("Upgrade Now") {
                    onUpgrade()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Feature Locked View

struct TrialFeatureLockedView: View {
    let feature: FeatureType
    let reason: String
    let trialStatus: SimplifiedEntitlementManagerWithTrial.TrialStatus
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon based on trial status
            switch trialStatus {
            case .expired:
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

            case .disabled, .notEligible:
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.secondary)

            default:
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
            }

            // Title based on trial status
            Text(lockTitle)
                .font(.title2)
                .fontWeight(.semibold)

            // Reason or description
            Text(lockDescription)
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Call to action
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    Label(buttonTitle, systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }

                if case .expired = trialStatus {
                    Text("Only Quick Timer (< 5 min) remains available")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var lockTitle: String {
        switch trialStatus {
        case .expired:
            return "Trial Expired"
        case .disabled, .notEligible:
            return "\(feature.displayName) is Premium"
        default:
            return reason
        }
    }

    private var lockDescription: String {
        switch trialStatus {
        case .expired:
            return "Your 3-day trial has ended. Upgrade to continue using all features."
        case .notEligible:
            return "You've already used your trial on another device. Upgrade to unlock all features."
        case .disabled:
            return "This feature requires a Premium subscription."
        default:
            return reason
        }
    }

    private var buttonTitle: String {
        switch trialStatus {
        case .expired:
            return "Upgrade to Continue"
        default:
            return "Upgrade to Premium"
        }
    }
}

// MARK: - Trial Status Banner

public struct TrialStatusBanner: View {
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManagerWithTrial
    @State private var showingPaywall = false

    public var body: some View {
        if case .active(let daysRemaining) = entitlements.trialStatus {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trial: \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        // AI Coach usage
                        if entitlements.displayedAICoachUsage > 0 {
                            Label("\(entitlements.displayedAICoachUsage)/\(RemoteConfigManager.shared.aiCoachDailyLimit) AI",
                                  systemImage: "brain")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        // Guided sessions usage
                        if entitlements.displayedGuidedSessionUsage > 0 {
                            Label("\(entitlements.displayedGuidedSessionUsage)/\(RemoteConfigManager.shared.customRoutinesDailyLimit) Sessions",
                                  systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()

                Button("Upgrade") {
                    showingPaywall = true
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal)
            .shadow(radius: 4)
            .sheet(isPresented: $showingPaywall) {
                StoreKit2PaywallView()
            }
        }
    }
}

// MARK: - Premium Feature Extension

extension FeatureType {
    var usageUnit: String {
        switch self {
        case .aiCoach:
            return "questions"
        case .customRoutines:
            return "sessions"
        case .quickTimer:
            return "minutes"
        default:
            return "uses"
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Trial-aware feature gating
    public func trialAwareFeatureGated(
        _ feature: FeatureType,
        showPaywall: Bool = true,
        context: PaywallContext = .general
    ) -> some View {
        modifier(StoreKit2TrialAwareFeatureGate(
            feature: feature,
            showPaywall: showPaywall,
            context: context
        ))
    }

    /// Adds trial status banner to the top of the view
    public func withTrialStatusBanner() -> some View {
        VStack(spacing: 0) {
            TrialStatusBanner()
                .padding(.top, 8)
            self
        }
    }
}

// MARK: - Trial Badge

/// Badge to indicate trial features
public struct TrialBadge: View {
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManagerWithTrial

    public var body: some View {
        if case .active = entitlements.trialStatus {
            Label("TRIAL", systemImage: "clock.fill")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
        }
    }
}

// MARK: - Usage Examples

/*
 Examples of using the trial-aware feature gating:

 1. Simple trial-aware gate:
 ```swift
 AICoachView()
     .trialAwareFeatureGated(.aiCoach)
 ```

 2. With trial status banner:
 ```swift
 DashboardView()
     .withTrialStatusBanner()
 ```

 3. Conditional with trial check:
 ```swift
 if case .active = entitlements.trialStatus {
     TrialBadge()
 }
 ```

 4. Custom context for paywall:
 ```swift
 AdvancedAnalyticsView()
     .trialAwareFeatureGated(
         .advancedAnalytics,
         context: .trialExpired
     )
 ```
 */