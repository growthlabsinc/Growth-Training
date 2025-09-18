/**
 * PaywallContext.swift
 * Growth App Paywall Context Definition
 *
 * Defines the context in which paywalls are presented to users
 */

import Foundation

// MARK: - Paywall Context

/// Context in which the paywall is being presented
public enum PaywallContext: Equatable, Codable {
    case onboarding
    case settings  
    case featureGate(FeatureType)
    case sessionCompletion
    case general
    
    /// Primary feature to highlight for this context
    var primaryFeature: FeatureType? {
        switch self {
        case .onboarding:
            return .customRoutines
        case .featureGate(let feature):
            return feature
        case .sessionCompletion:
            return .progressTracking
        case .settings, .general:
            return nil
        }
    }
    
    /// Contextual message for this paywall
    var contextualMessage: String {
        switch self {
        case .onboarding:
            return "Start your growth journey with premium features"
        case .settings:
            return "Upgrade to unlock all features"
        case .featureGate(let feature):
            return "Unlock \(feature.displayName) with premium"
        case .sessionCompletion:
            return "Track your progress with premium features"
        case .general:
            return "Enhance your experience with premium"
        }
    }
}

// MARK: - CustomStringConvertible

extension PaywallContext: CustomStringConvertible {
    public var description: String {
        switch self {
        case .onboarding:
            return "onboarding"
        case .settings:
            return "settings"
        case .featureGate(let feature):
            return "feature_gate_\(feature.rawValue)"
        case .sessionCompletion:
            return "session_completion"
        case .general:
            return "general"
        }
    }
}

// MARK: - String Conversion

extension PaywallContext {
    /// Convert PaywallContext to string representation
    public func toString() -> String {
        return self.description
    }
    
    /// Convert string representation back to PaywallContext
    public static func fromString(_ string: String) -> PaywallContext? {
        switch string {
        case "onboarding":
            return .onboarding
        case "settings":
            return .settings
        case "session_completion":
            return .sessionCompletion
        case "general":
            return .general
        default:
            if string.hasPrefix("feature_gate_") {
                let featureString = String(string.dropFirst("feature_gate_".count))
                if let feature = FeatureType(rawValue: featureString) {
                    return .featureGate(feature)
                }
            }
            return nil
        }
    }
}