/**
 * PaywallCoordinator.swift
 * Growth App Paywall Coordination
 *
 * Orchestrates paywall presentation logic across the app, handling different
 * entry points and contexts for subscription upgrade flows.
 */

import Foundation
import SwiftUI
import Combine

// MARK: - Paywall Coordinator

/// Coordinates paywall presentation and user flow management
@MainActor
public class PaywallCoordinator: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = PaywallCoordinator()
    
    // MARK: - Published Properties
    @Published public var isPaywallPresented = false
    @Published public var currentContext: PaywallContext = .general
    @Published public var shouldDismissAfterPurchase = true
    
    // MARK: - Dependencies
    private let analytics = PaywallAnalytics.shared
    private let featureGateService = FeatureGateService.shared
    
    // MARK: - Private Properties
    private var onDismissAction: (() -> Void)?
    private var onPurchaseAction: (() -> Void)?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Present paywall with specific context
    public func presentPaywall(
        context: PaywallContext,
        shouldDismissAfterPurchase: Bool = true,
        onDismiss: (() -> Void)? = nil,
        onPurchase: (() -> Void)? = nil
    ) {
        // Check if paywalls are enabled
        guard FeatureFlags.paywallsEnabled else {
            // Silently return without presenting paywall
            return
        }
        
        // Track paywall impression
        analytics.trackPaywallImpression(context: context)
        
        // Store callbacks
        self.onDismissAction = onDismiss
        self.onPurchaseAction = onPurchase
        self.shouldDismissAfterPurchase = shouldDismissAfterPurchase
        
        // Update state
        self.currentContext = context
        
        // Present with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isPaywallPresented = true
        }
    }
    
    /// Dismiss paywall
    public func dismissPaywall() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isPaywallPresented = false
        }
        
        // Execute dismiss callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onDismissAction?()
            self.onDismissAction = nil
            self.onPurchaseAction = nil
        }
    }
    
    /// Handle successful purchase
    public func handlePurchaseSuccess() {
        // Track successful purchase
        analytics.trackPurchaseSuccess(context: currentContext)
        
        // Execute purchase callback
        onPurchaseAction?()
        
        // Dismiss if configured to do so
        if shouldDismissAfterPurchase {
            dismissPaywall()
        }
    }
    
    /// Handle purchase failure
    public func handlePurchaseFailure(error: Error) {
        // Track purchase failure
        analytics.trackPurchaseFailure(context: currentContext, error: error)
        
        // Note: We don't dismiss on failure to allow retry
    }
    
    /// Present paywall from feature gate
    public func presentFromFeatureGate(_ feature: FeatureType) {
        presentPaywall(context: .featureGate(feature))
    }
    
    /// Check if feature gate should show paywall
    public func shouldShowPaywallForFeature(_ feature: FeatureType) -> Bool {
        return !featureGateService.hasAccess(to: feature).isGranted
    }
}

// MARK: - Paywall Analytics

/// Handles analytics tracking for paywall interactions
public class PaywallAnalytics: ObservableObject {
    
    public static let shared = PaywallAnalytics()
    
    private init() {}
    
    // MARK: - Tracking Methods
    
    /// Track paywall impression
    func trackPaywallImpression(context: PaywallContext) {
        let _ : [String: Any] = [
            "context": contextString(context),
            "primary_feature": context.primaryFeature?.rawValue ?? "none",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Integrate with Analytics service
        // print("PaywallAnalytics: Impression - \(parameters)")
    }
    
    /// Track purchase success
    func trackPurchaseSuccess(context: PaywallContext) {
        let _ : [String: Any] = [
            "context": contextString(context),
            "primary_feature": context.primaryFeature?.rawValue ?? "none",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Integrate with Analytics service
        // print("PaywallAnalytics: Purchase Success - \(parameters)")
    }
    
    /// Track purchase failure
    func trackPurchaseFailure(context: PaywallContext, error: Error) {
        let _ : [String: Any] = [
            "context": contextString(context),
            "primary_feature": context.primaryFeature?.rawValue ?? "none",
            "error": error.localizedDescription,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Integrate with Analytics service
        // print("PaywallAnalytics: Purchase Failure - \(parameters)")
    }
    
    /// Track paywall dismissal without purchase
    func trackPaywallDismissal(context: PaywallContext) {
        let _ : [String: Any] = [
            "context": contextString(context),
            "primary_feature": context.primaryFeature?.rawValue ?? "none",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Integrate with Analytics service
        // print("PaywallAnalytics: Dismissal - \(parameters)")
    }
    
    // MARK: - Helper Methods
    
    private func contextString(_ context: PaywallContext) -> String {
        switch context {
        case .featureGate(_):
            return "feature_gate"
        case .settings:
            return "settings"
        case .onboarding:
            return "onboarding"
        case .sessionCompletion:
            return "session_completion"
        case .general:
            return "general"
        }
    }
}