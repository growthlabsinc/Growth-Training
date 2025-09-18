/**
 * PaywallABTestingService.swift
 * Growth App Paywall A/B Testing
 *
 * Manages A/B testing variations for paywall optimization,
 * including messaging, layout, and pricing experiments.
 */

import Foundation
import Combine
import FirebaseAuth
import UIKit

// MARK: - A/B Test Variations

/// Available A/B test variations for paywall optimization
public enum PaywallVariation: String, CaseIterable {
    case control = "control"
    case emphasizeDiscount = "emphasize_discount"
    case socialProofFocus = "social_proof_focus"
    case featureBenefits = "feature_benefits"
    case urgencyMessaging = "urgency_messaging"
}

/// Specific A/B test experiments
public enum PaywallExperiment: String, CaseIterable {
    case headerMessaging = "header_messaging"
    case pricingDisplay = "pricing_display"
    case socialProofPlacement = "social_proof_placement"
    case ctaButtonText = "cta_button_text"
    case exitIntentOffer = "exit_intent_offer"
}

// MARK: - A/B Testing Configuration

/// Configuration for a specific A/B test
public struct ABTestConfig {
    let experiment: PaywallExperiment
    let variation: PaywallVariation
    let trafficAllocation: Double // 0.0 to 1.0
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    
    /// Check if the test is currently active
    var isCurrentlyActive: Bool {
        guard isActive else { return false }
        
        let now = Date()
        let isAfterStart = now >= startDate
        
        if let endDate = endDate {
            return isAfterStart && now <= endDate
        }
        
        return isAfterStart
    }
}

// MARK: - A/B Testing Service

/// Service for managing paywall A/B testing experiments
@MainActor
public class PaywallABTestingService: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = PaywallABTestingService()
    
    // MARK: - Published Properties
    @Published public var activeExperiments: [PaywallExperiment: ABTestConfig] = [:]
    @Published public var userVariations: [PaywallExperiment: PaywallVariation] = [:]
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let analytics = PaywallAnalytics.shared
    
    // MARK: - Constants
    private let userVariationsKey = "paywall_ab_test_variations"
    private let experimentsConfigKey = "paywall_ab_experiments_config"
    
    private init() {
        loadUserVariations()
        loadExperimentsConfig()
    }
    
    // MARK: - Public Methods
    
    /// Get the variation for a specific experiment for the current user
    public func getVariation(for experiment: PaywallExperiment) -> PaywallVariation {
        // Check if user already has an assigned variation
        if let existingVariation = userVariations[experiment] {
            return existingVariation
        }
        
        // Check if experiment is active
        guard let config = activeExperiments[experiment],
              config.isCurrentlyActive else {
            return .control
        }
        
        // Assign new variation based on traffic allocation
        let variation = assignVariation(for: experiment, config: config)
        
        // Store the assignment
        userVariations[experiment] = variation
        saveUserVariations()
        
        // Track assignment
        analytics.trackABTestAssignment(experiment: experiment, variation: variation)
        
        return variation
    }
    
    /// Get header messaging based on A/B test
    public func getHeaderMessaging(for context: PaywallContext) -> String {
        let variation = getVariation(for: .headerMessaging)
        
        switch variation {
        case .control:
            return context.contextualMessage
            
        case .emphasizeDiscount:
            return "Save up to 45% with Premium"
            
        case .socialProofFocus:
            return "Join 10,000+ users who upgraded"
            
        case .featureBenefits:
            return "Unlock all premium features today"
            
        case .urgencyMessaging:
            return "Limited time: Premium at special pricing"
        }
    }
    
    /// Get CTA button text based on A/B test
    public func getCTAButtonText(for duration: SubscriptionDuration) -> String {
        let variation = getVariation(for: .ctaButtonText)
        
        switch variation {
        case .control:
            if duration == .yearly {
                return "Start 5-Day Trial"
            } else {
                return "Subscribe Now"
            }
            
        case .emphasizeDiscount:
            switch duration {
            case .weekly:
                return "Subscribe Weekly"
            case .quarterly:
                return "Save 40% - Subscribe"
            case .yearly:
                return "Try 5 Days Free - Save 80%"
            }
            
        case .socialProofFocus:
            if duration == .yearly {
                return "Join Premium - 5 Days Free"
            } else {
                return "Join Premium Users"
            }
            
        case .featureBenefits:
            if duration == .yearly {
                return "Unlock All - 5 Days Free"
            } else {
                return "Unlock All Features"
            }
            
        case .urgencyMessaging:
            if duration == .yearly {
                return "Claim Trial Offer"
            } else {
                return "Claim Special Offer"
            }
        }
    }
    
    /// Check if social proof should be prominently displayed
    public func shouldShowProminentSocialProof() -> Bool {
        let variation = getVariation(for: .socialProofPlacement)
        return variation == .socialProofFocus
    }
    
    /// Get exit intent offer percentage
    public func getExitIntentOfferPercentage() -> Int {
        let variation = getVariation(for: .exitIntentOffer)
        
        switch variation {
        case .control:
            return 0 // No offer
        case .emphasizeDiscount:
            return 25
        case .socialProofFocus:
            return 15
        case .featureBenefits:
            return 20
        case .urgencyMessaging:
            return 30
        }
    }
    
    /// Force assign a variation for testing
    public func forceVariation(_ variation: PaywallVariation, for experiment: PaywallExperiment) {
        userVariations[experiment] = variation
        saveUserVariations()
    }
    
    /// Reset all A/B test assignments (for testing)
    public func resetAllAssignments() {
        userVariations.removeAll()
        saveUserVariations()
    }
    
    // MARK: - Configuration Management
    
    /// Load default experiment configurations
    public func loadDefaultExperiments() {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: now)
        
        activeExperiments = [
            .headerMessaging: ABTestConfig(
                experiment: .headerMessaging,
                variation: .control,
                trafficAllocation: 1.0,
                isActive: true,
                startDate: now,
                endDate: futureDate
            ),
            .ctaButtonText: ABTestConfig(
                experiment: .ctaButtonText,
                variation: .control,
                trafficAllocation: 1.0,
                isActive: true,
                startDate: now,
                endDate: futureDate
            ),
            .socialProofPlacement: ABTestConfig(
                experiment: .socialProofPlacement,
                variation: .control,
                trafficAllocation: 0.5,
                isActive: true,
                startDate: now,
                endDate: futureDate
            ),
            .exitIntentOffer: ABTestConfig(
                experiment: .exitIntentOffer,
                variation: .control,
                trafficAllocation: 0.8,
                isActive: true,
                startDate: now,
                endDate: futureDate
            )
        ]
        
        saveExperimentsConfig()
    }
    
    // MARK: - Private Methods
    
    private func assignVariation(for experiment: PaywallExperiment, config: ABTestConfig) -> PaywallVariation {
        // Use user ID or device ID as seed for consistent assignment
        let userId = getCurrentUserId()
        let seed = "\(userId)_\(experiment.rawValue)".hashValue
        
        // Create deterministic random assignment
        let random = Double(abs(seed) % 10000) / 10000.0
        
        if random < config.trafficAllocation {
            // User is in the test group - assign variation
            let variations = PaywallVariation.allCases
            let variationIndex = abs(seed) % variations.count
            return variations[variationIndex]
        } else {
            // User is in control group
            return .control
        }
    }
    
    private func getCurrentUserId() -> String {
        // Try to get Firebase user ID, fallback to device identifier
        if let userId = Auth.auth().currentUser?.uid {
            return userId
        } else {
            return UIDevice.current.identifierForVendor?.uuidString ?? "anonymous"
        }
    }
    
    private func loadUserVariations() {
        if let data = userDefaults.data(forKey: userVariationsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            
            userVariations = decoded.compactMapValues { PaywallVariation(rawValue: $0) }
                .reduce(into: [:]) { result, pair in
                    if let experiment = PaywallExperiment(rawValue: pair.key) {
                        result[experiment] = pair.value
                    }
                }
        }
    }
    
    private func saveUserVariations() {
        let stringDict = userVariations.reduce(into: [String: String]()) { result, pair in
            result[pair.key.rawValue] = pair.value.rawValue
        }
        
        if let encoded = try? JSONEncoder().encode(stringDict) {
            userDefaults.set(encoded, forKey: userVariationsKey)
        }
    }
    
    private func loadExperimentsConfig() {
        // In a real implementation, this would load from server
        // For now, load default experiments
        if activeExperiments.isEmpty {
            loadDefaultExperiments()
        }
    }
    
    private func saveExperimentsConfig() {
        // In a real implementation, this would sync with server
        // For now, just keep in memory
    }
}

// MARK: - Analytics Extensions

extension PaywallAnalytics {
    
    /// Track A/B test assignment
    func trackABTestAssignment(experiment: PaywallExperiment, variation: PaywallVariation) {
        let parameters: [String: Any] = [
            "experiment": experiment.rawValue,
            "variation": variation.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("PaywallAnalytics: A/B Test Assignment - \(parameters)")
    }
    
    /// Track A/B test conversion
    func trackABTestConversion(experiment: PaywallExperiment, variation: PaywallVariation, duration: SubscriptionDuration) {
        let parameters: [String: Any] = [
            "experiment": experiment.rawValue,
            "variation": variation.rawValue,
            "duration": duration.rawValue,
            "price_cents": duration.priceCents,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("PaywallAnalytics: A/B Test Conversion - \(parameters)")
    }
}