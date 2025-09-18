/**
 * FeatureGateView.swift
 * Growth App Feature Gate UI Components
 *
 * Reusable SwiftUI components for feature gating with contextual upgrade prompts,
 * usage limits display, and conversion optimization features.
 */

import SwiftUI
import Combine

// MARK: - Feature Gate View

/// Reusable component that wraps content with feature gating logic
public struct FeatureGateView<Content: View>: View {
    private let feature: String
    private let content: () -> Content
    private let context: PaywallContext
    private let showUpgradePrompt: Bool
    private let fallbackView: AnyView?
    
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @State private var showingUpgradePrompt = false
    @State private var access: FeatureAccess = .denied(reason: .noSubscription)
    
    public init(
        feature: String,
        context: PaywallContext? = nil,
        showUpgradePrompt: Bool = true,
        fallbackView: AnyView? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.feature = feature
        self.content = content
        // Default to general context if not provided
        // Cannot use .featureGate here since feature is String, not FeatureType
        self.context = context ?? .general
        self.showUpgradePrompt = showUpgradePrompt
        self.fallbackView = fallbackView
    }
    
    public var body: some View {
        Group {
            switch access {
        case .granted:
            content()
                    .onAppear {
                        // Analytics: trackFeatureGateInteraction(feature, action: .accessed, context: context)
                    }
                
            case .limited(let usage):
                VStack(spacing: 0) {
                    // Usage warning banner
                    if usage.usagePercentage > 0.5 {
                        UsageLimitBanner(feature: feature, usage: usage)
                            .onAppear {
                                // Analytics: trackFeatureGateInteraction(feature, action: .usageLimitWarningShown, context: context)
                            }
                    }
                    
                    content()
                        .onAppear {
                            // Analytics: trackFeatureGateInteraction(feature, action: .accessed, context: context)
                        }
                }
                
            case .denied(let reason):
                if let fallback = fallbackView {
                    fallback
                        .onAppear {
                            // Analytics: trackFeatureGateInteraction(feature, action: .blocked, context: context)
                        }
                } else if showUpgradePrompt {
                    FeatureLockedView(
                        feature: feature,
                        reason: reason,
                        context: context,
                        onUpgradeTapped: {
                            // Analytics: trackFeatureGateInteraction(feature, action: .upgradePromptTapped, context: context)
                            showingUpgradePrompt = true
                        }
                    )
                    .onAppear {
                        // Analytics: trackFeatureGateInteraction(feature, action: .upgradePromptShown, context: context)
                    }
                } else {
                    EmptyView()
                        .onAppear {
                            // Analytics: trackFeatureGateInteraction(feature, action: .blocked, context: context)
                        }
                }
            }
        }
        .onAppear {
            updateAccess()
        }
        .onChange(of: entitlementManager.hasPremium) { _ in
            updateAccess()
        }
        .sheet(isPresented: .constant(FeatureFlags.paywallsEnabled && showingUpgradePrompt)) {
            UpgradePromptView(feature: feature, context: context)
                .onDisappear {
                    // Analytics: trackFeatureGateInteraction(feature, action: .upgradePromptDismissed, context: context)
                }
        }
    }
    
    private func updateAccess() {
        access = FeatureAccess.from(feature: feature, using: entitlementManager.asEntitlementProvider)
    }
}

// MARK: - Feature Locked View

/// View displayed when a feature is locked
public struct FeatureLockedView: View {
    let feature: String  // Changed to String to match FeatureGateView
    let reason: DenialReason
    let context: PaywallContext
    let onUpgradeTapped: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            // Feature icon and lock overlay
            ZStack {
                Image(systemName: getFeatureIcon(for: feature))
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.6))
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                    )
                    .offset(x: 20, y: -20)
            }
            .frame(width: 80, height: 80)
            
            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(reason.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Feature benefits removed since feature is now a String, not FeatureType
            }
            
            // Upgrade button
            Button(action: onUpgradeTapped) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                    
                    Text(reason.suggestedAction)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Usage Limit Banner

/// Banner showing usage limits for features
public struct UsageLimitBanner: View {
    let feature: String
    let usage: FeatureUsage
    
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @State private var showingUpgradePrompt = false
    
    private var usageIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                .frame(width: 24, height: 24)
            
            Circle()
                .trim(from: 0, to: usage.usagePercentage)
                .stroke(
                    usage.usagePercentage > 0.8 ? Color.red : Color.orange,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
            
            Text("\(usage.remaining)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
        }
    }
    
    private var usageInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(usage.usageMessage)
                .font(.caption)
                .fontWeight(.medium)
            
            if !usage.isPermanent, let resetDate = usage.resetDate {
                Text("Resets \(resetDate, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            usageIndicator
            usageInfo
            
            Spacer()
            
            Button("Upgrade") {
                // Analytics: trackFeatureGateInteraction(feature, action: .upgradePromptTapped)
                showingUpgradePrompt = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(usage.usagePercentage > 0.8 ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(usage.usagePercentage > 0.8 ? Color.red.opacity(0.3) : Color.orange.opacity(0.3))
        )
        .sheet(isPresented: $showingUpgradePrompt) {
            // Use general context since feature is a String, not FeatureType
            UpgradePromptView(feature: feature, context: .general)
        }
    }
}

// MARK: - Premium Badge

/// Small badge indicating premium features
public struct PremiumBadge: View {
    let size: BadgeSize
    
    public enum BadgeSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .footnote
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .medium: return EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
            case .large: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }
    }
    
    public init(size: BadgeSize = .medium) {
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: size.iconSize))
            
            Text("PREMIUM")
                .font(size.fontSize)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(size.padding)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(size == .small ? 4 : (size == .medium ? 6 : 8))
    }
}

// MARK: - Feature Type Extensions

extension FeatureType {
    /// Icon name for the feature
    public var iconName: String {
        switch self {
        case .aiCoach:
            return "brain.head.profile"
        case .customRoutines:
            return "list.bullet.rectangle"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        case .liveActivities:
            return "livephoto"
        case .progressTracking:
            return "chart.line.uptrend.xyaxis"
        case .advancedTimer:
            return "timer"
        case .goalSetting:
            return "target"
        case .prioritySupport:
            return "person.badge.key"
        case .unlimitedBackup:
            return "icloud"
        case .advancedCustomization:
            return "paintbrush"
        case .expertInsights:
            return "lightbulb"
        case .premiumContent:
            return "star.fill"
        default:
            return "lock.fill"
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Wraps content in a feature gate
    public func gatedFeature(
        _ feature: FeatureType,
        context: PaywallContext? = nil,
        showUpgradePrompt: Bool = true,
        fallbackView: AnyView? = nil
    ) -> some View {
        FeatureGateView(
            feature: feature.rawValue,
            context: context,
            showUpgradePrompt: showUpgradePrompt,
            fallbackView: fallbackView
        ) {
            self
        }
    }
    
    /// Adds a premium badge overlay
    public func premiumBadge(size: PremiumBadge.BadgeSize = .medium) -> some View {
        overlay(
            PremiumBadge(size: size),
            alignment: .topTrailing
        )
    }
}

// MARK: - Helper Functions

private func getFeatureIcon(for feature: String) -> String {
    // Map feature strings to appropriate SF Symbols
    switch feature {
    case "custom_routines":
        return "list.bullet.clipboard"
    case "advanced_timer":
        return "timer"
    case "progress_tracking":
        return "chart.line.uptrend.xyaxis"
    case "advanced_analytics":
        return "chart.bar.xaxis"
    case "goal_setting":
        return "target"
    case "ai_coach":
        return "sparkles"
    case "live_activities":
        return "apps.iphone"
    case "priority_support":
        return "star.fill"
    case "unlimited_backup":
        return "icloud.fill"
    case "advanced_customization":
        return "slider.horizontal.3"
    case "expert_insights":
        return "lightbulb.fill"
    case "premium_content":
        return "crown.fill"
    case "quick_timer":
        return "stopwatch"
    case "articles":
        return "doc.text"
    default:
        return "star.circle"
    }
}