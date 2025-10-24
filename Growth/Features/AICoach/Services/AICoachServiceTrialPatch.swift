//
//  AICoachServiceTrialPatch.swift
//  Growth
//
//  Extension to AICoachService for trial support
//

import Foundation
import FirebaseFunctions
import FirebaseAnalytics
import OSLog

// MARK: - AICoachService Trial Extension

extension AICoachService {

    /// Send a message with trial-aware access checking
    /// This method should be used instead of the original sendMessage when trial support is enabled
    func sendMessageWithTrialSupport(
        _ message: String,
        conversationHistory: [ChatMessage] = []
    ) async throws -> ChatMessage {

        // Get the entitlement manager
        let entitlements = await SimplifiedEntitlementManagerWithTrial.shared

        // Check feature access with trial support
        let access = await entitlements.checkFeatureAccess(for: .aiCoach)

        switch access {
        case .granted:
            // Full access - proceed normally
            print("✅ [AICoach] Access granted for user")

        case .limited(let usage):
            // Limited access during trial - check if user can consume usage
            print("⚠️ [AICoach] Limited access: \(usage.currentUsage)/\(usage.maxUsage)")

            if usage.currentUsage >= usage.maxUsage {
                // Limit reached - throw error with reset time
                throw AICoachError.usageLimitExceeded(
                    remaining: usage.maxUsage - usage.currentUsage,
                    resetDate: usage.resetDate
                )
            }

            // Increment usage BEFORE making the call
            // This prevents race conditions with multiple rapid calls
            await entitlements.incrementAICoachUsage()

        case .denied(let reason):
            // Access denied - throw appropriate error
            print("❌ [AICoach] Access denied: \(reason)")

            // Map the denial reason to appropriate error
            let trialStatus = await entitlements.trialStatus
            let hasPremium = await entitlements.hasAnyPremiumAccess

            if case .expired = trialStatus {
                throw AICoachError.trialExpired
            } else if !hasPremium {
                throw AICoachError.premiumRequired
            } else {
                throw AICoachError.featureUnavailable
            }
        }

        // Validate with server if Remote Config requires it
        if await RemoteConfigManager.shared.trialConfiguration?.serverValidationRequired == true {
            let validationResult = await validateUsageWithServer(feature: "aiCoach")

            if !validationResult.allowed {
                throw AICoachError.usageLimitExceeded(
                    remaining: validationResult.remaining,
                    resetDate: validationResult.resetDate
                )
            }
        }

        // Proceed with the actual AI Coach call using the base implementation
        // We need to provide an entitlement provider for the base method
        let entitlementBridge = TrialAwareEntitlementProvider(entitlements: entitlements)

        do {
            let response = try await sendMessage(
                message,
                conversationHistory: conversationHistory,
                entitlementProvider: entitlementBridge
            )

            // Log successful usage for analytics
            logUsageAnalytics(feature: "aiCoach", success: true)

            return response

        } catch {
            // Log failed attempt (but don't decrement usage - user was charged already)
            logUsageAnalytics(feature: "aiCoach", success: false)
            throw error
        }
    }

    /// Validate usage with server for extra security
    private func validateUsageWithServer(feature: String) async -> (allowed: Bool, remaining: Int, resetDate: Date?) {
        let functions = Functions.functions()
        let callable = functions.httpsCallable("validateAndIncrementUsage")

        do {
            let result = try await callable.call([
                "feature": feature,
                "timestamp": Date().timeIntervalSince1970
            ])

            guard let data = result.data as? [String: Any] else {
                return (false, 0, nil)
            }

            let allowed = data["allowed"] as? Bool ?? false
            let remaining = (data["limit"] as? Int ?? 0) - (data["usage"] as? Int ?? 0)
            let resetTimestamp = data["resetTime"] as? Double
            let resetDate = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

            return (allowed, remaining, resetDate)

        } catch {
            print("❌ [AICoach] Failed to validate usage with server: \(error)")
            // In case of server error, allow the request (fail open)
            return (true, 999, nil)
        }
    }

    /// Log usage analytics for monitoring
    private func logUsageAnalytics(feature: String, success: Bool) {
        Task {
            // Log to Firebase Analytics
            Analytics.logEvent("trial_feature_usage", parameters: [
                "feature": feature,
                "success": success,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }
}

// MARK: - Trial-Aware Entitlement Provider

/// Bridge to provide EntitlementProvider interface for trial-aware entitlements
private struct TrialAwareEntitlementProvider: EntitlementProvider {
    let entitlements: SimplifiedEntitlementManagerWithTrial

    var hasPremium: Bool {
        // Since we're in an async context and can't access @MainActor properties synchronously,
        // we check UserDefaults directly which is what the entitlement manager uses
        let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
        return userDefaults.bool(forKey: "hasPremium") || userDefaults.bool(forKey: "hasLifetime")
    }
}

// MARK: - Convenience Methods for View Models

extension AICoachService {

    /// Get remaining AI Coach questions for today
    func getRemainingQuestions() async -> (used: Int, limit: Int, resetTime: Date?) {
        let entitlements = await SimplifiedEntitlementManagerWithTrial.shared

        // Premium users have unlimited
        if await entitlements.hasAnyPremiumAccess {
            return (0, Int.max, nil)
        }

        // Check trial status
        let access = await entitlements.checkFeatureAccess(for: .aiCoach)

        switch access {
        case .limited(let usage):
            return (usage.currentUsage, usage.maxUsage, usage.resetDate)
        default:
            return (0, 0, nil)
        }
    }

    /// Check if user can ask a question
    func canAskQuestion() async -> Bool {
        let entitlements = await SimplifiedEntitlementManagerWithTrial.shared
        let access = await entitlements.checkFeatureAccess(for: .aiCoach)

        switch access {
        case .granted:
            return true
        case .limited(let usage):
            return usage.currentUsage < usage.maxUsage
        case .denied:
            return false
        }
    }

    /// Get appropriate message for current access state
    func getAccessMessage() async -> String? {
        let entitlements = await SimplifiedEntitlementManagerWithTrial.shared
        let access = await entitlements.checkFeatureAccess(for: .aiCoach)

        switch access {
        case .granted:
            return nil // Full access, no message needed

        case .limited(let usage):
            let remaining = usage.maxUsage - usage.currentUsage
            if remaining > 0 {
                return "You have \(remaining) AI Coach question\(remaining == 1 ? "" : "s") remaining today"
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Daily limit reached. Resets at \(formatter.string(from: usage.resetDate ?? Date()))"
            }

        case .denied(let reason):
            return reason.localizedDescription
        }
    }
}