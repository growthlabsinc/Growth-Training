/**
 * FeatureGate.swift
 * Growth App Feature Gating UI Components
 *
 * SwiftUI view modifiers and components for implementing feature gating throughout the app.
 * Provides declarative syntax for protecting premium features and showing upgrade prompts.
 */

import SwiftUI
import Combine

// MARK: - Feature Gate View Modifier

/// View modifier that gates access to premium features
public struct FeatureGateModifier: ViewModifier {
    let feature: FeatureType
    let fallbackContent: AnyView?
    let showUpgradePrompt: Bool
    let onUpgradePrompt: (() -> Void)?
    
    @ObservedObject private var featureGate = FeatureGateService.shared
    @State private var showingUpgradeSheet = false
    
    public func body(content: Content) -> some View {
        let access = featureGate.hasAccess(to: feature)
        
        return Group {
            if access.isGranted {
                // User has access - show content
                content
            } else {
                // User doesn't have access - show fallback or upgrade prompt
                if let fallback = fallbackContent {
                    fallback
                } else if showUpgradePrompt {
                    // Get the denial reason from the access result
                    let reason: DenialReason = {
                        switch access {
                        case .denied(let denialReason):
                            return denialReason
                        case .limited:
                            return .usageLimitExceeded
                        default:
                            return .requiresPremium
                        }
                    }()
                    
                    FeatureLockedView(
                        feature: feature,
                        reason: reason,
                        context: .featureGate(feature),
                        onUpgradeTapped: {
                            if let customAction = onUpgradePrompt {
                                customAction()
                            } else {
                                showingUpgradeSheet = true
                            }
                        }
                    )
                } else {
                    // No fallback and no upgrade prompt - show nothing
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradePromptView(feature: feature, context: .featureGate(feature))
        }
    }
}

// MARK: - View Extension

extension View {
    /// Gate access to this view based on feature availability
    public func featureGated(
        _ feature: FeatureType,
        fallback: AnyView? = nil,
        showUpgradePrompt: Bool = true,
        onUpgradePrompt: (() -> Void)? = nil
    ) -> some View {
        modifier(FeatureGateModifier(
            feature: feature,
            fallbackContent: fallback,
            showUpgradePrompt: showUpgradePrompt,
            onUpgradePrompt: onUpgradePrompt
        ))
    }
}

// MARK: - Feature Locked View

/// Legacy feature locked view - now uses the comprehensive FeatureLockedView from Components
/// This is kept for backwards compatibility but delegates to the new implementation

// MARK: - Premium Indicator Badge

/// Small badge indicating a premium feature
public struct PremiumIndicatorBadge: View {
    let feature: FeatureType
    
    @ObservedObject private var featureGate = FeatureGateService.shared
    
    public var body: some View {
        Group {
            if !featureGate.hasAccess(to: feature).isGranted {
                premiumBadge
            }
        }
    }
    
    private var premiumBadge: some View {
        Text("PRO")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .offset(x: -8, y: 8)
    }
}

// MARK: - Upgrade Prompt View

/// Legacy upgrade prompt - now uses the comprehensive UpgradePromptView from Components
/// This is kept for backwards compatibility but delegates to the new implementation