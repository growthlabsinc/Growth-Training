/**
 * FeatureFlags.swift
 * Growth App Feature Flags
 *
 * Centralized feature flag management for enabling/disabling features
 * Used to temporarily hide paywalls for App Store approval
 */

import Foundation

/// Feature flags for controlling app functionality
struct FeatureFlags {
    
    // MARK: - Paywall Flags
    
    /// Master switch for all paywall functionality
    /// Set to false to hide paywalls for App Store approval
    /// Set to true once subscriptions are approved
    /// 
    /// TO RE-ENABLE PAYWALLS:
    /// 1. Change this value from false to true
    /// 2. Rebuild the app
    /// 3. All paywall functionality will be restored automatically
    /// 
    /// AFFECTED AREAS:
    /// - Onboarding flow (paywall step)
    /// - Settings menu (subscription section)
    /// - Feature gates (upgrade prompts)
    /// - Paywall coordinator (presentation logic)
    static let paywallsEnabled = true // Re-enabled for App Store submission with binary
    
    /// Show paywall in onboarding flow
    static var showPaywallInOnboarding: Bool {
        return paywallsEnabled
    }
    
    /// Show subscription section in settings
    static var showSubscriptionInSettings: Bool {
        return paywallsEnabled
    }
    
    /// Show upgrade prompts throughout the app
    static var showUpgradePrompts: Bool {
        return paywallsEnabled
    }
    
    /// Allow paywall presentation from feature gates
    static var enableFeatureGates: Bool {
        return paywallsEnabled
    }
    
    // MARK: - Debug Flags
    
    /// Show debug options in settings (only in debug builds)
    #if DEBUG
    static let showDebugOptions = true
    #else
    static let showDebugOptions = false
    #endif
}