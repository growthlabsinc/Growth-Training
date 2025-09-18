/**
 * StoreKit2FeatureGate.swift
 * Simplified Feature Gating using the new architecture
 * 
 * Replaces complex feature gating with simple, direct checks.
 */

import SwiftUI

// MARK: - Simple Feature Gate View Modifier

/// Simplified feature gate that directly checks entitlements
public struct StoreKit2FeatureGate: ViewModifier {
    let feature: String
    let showPaywall: Bool
    
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManager
    @State private var showingPaywall = false
    
    public func body(content: Content) -> some View {
        if entitlements.hasPremium {
            // User has access - show content
            content
        } else if showPaywall {
            // Show paywall button
            VStack {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                
                Text("\(feature.replacingOccurrences(of: "_", with: " ").capitalized) is a Premium Feature")
                    .font(.headline)
                    .padding(.top)
                
                Text("Upgrade to Premium to unlock this and other features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showingPaywall = true
                }) {
                    Label("Upgrade to Premium", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
            .padding()
            .sheet(isPresented: $showingPaywall) {
                StoreKit2PaywallView()
            }
        } else {
            // Don't show anything
            EmptyView()
        }
    }
}

// MARK: - Simple Conditional Access View

/// Simple view that conditionally shows content based on entitlements
public struct StoreKit2ConditionalAccessView<Content: View, Locked: View>: View {
    let feature: String
    let content: () -> Content
    let locked: () -> Locked
    
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManager
    
    public init(
        feature: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder locked: @escaping () -> Locked
    ) {
        self.feature = feature
        self.content = content
        self.locked = locked
    }
    
    public var body: some View {
        if entitlements.hasPremium {
            content()
        } else {
            locked()
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Simple feature gating - much cleaner than the complex version!
    public func storeKit2FeatureGated(
        _ feature: String,
        showPaywall: Bool = true
    ) -> some View {
        modifier(StoreKit2FeatureGate(
            feature: feature,
            showPaywall: showPaywall
        ))
    }
    
    /// Conditional feature gating with custom locked view
    public func gatedContent<Locked: View>(
        feature: String,
        @ViewBuilder locked: @escaping () -> Locked
    ) -> some View {
        StoreKit2ConditionalAccessView(
            feature: feature,
            content: { self },
            locked: locked
        )
    }
}

// MARK: - Simple Premium Badge

/// Simple badge to indicate premium features
public struct StoreKit2PremiumBadge: View {
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManager
    
    public var body: some View {
        if !entitlements.hasPremium {
            Label("PRO", systemImage: "star.fill")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
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
 Examples of using the simplified feature gating:
 
 1. Simple feature gate:
 ```swift
 AICoachView()
     .storeKit2FeatureGated(.aiCoach)
 ```
 
 2. Custom locked view:
 ```swift
 AnalyticsView()
     .gatedContent(feature: .advancedAnalytics) {
         VStack {
             Image(systemName: "chart.bar.fill")
             Text("Analytics is a Premium Feature")
             Button("Upgrade") { }
         }
     }
 ```
 
 3. Direct conditional:
 ```swift
 if entitlements.hasAICoach {
     AICoachButton()
 } else {
     UpgradeButton()
 }
 ```
 
 Much simpler than the old complex system!
 */