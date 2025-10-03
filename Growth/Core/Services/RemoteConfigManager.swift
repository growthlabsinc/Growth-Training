//
//  RemoteConfigManager.swift
//  Growth
//
//  Created for managing Firebase Remote Config with real-time updates
//  Handles trial feature flags and configuration parameters
//

import Foundation
import FirebaseRemoteConfig
import Combine
import UIKit

/// Manager for Firebase Remote Config with real-time updates support
@MainActor
class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    // MARK: - Published Properties
    @Published private(set) var isConfigured = false
    @Published private(set) var lastFetchTime: Date?
    @Published private(set) var configUpdateCount = 0

    // MARK: - Trial Configuration Keys
    enum ConfigKey: String, CaseIterable {
        // Trial feature flags
        case trialEnabled = "trial_enabled"
        case trialDurationDays = "trial_duration_days"
        case trialRolloutPercentage = "trial_rollout_percentage"

        // Daily limits during trial
        case aiCoachDailyLimit = "ai_coach_daily_limit"
        case quickTimerLimitMinutes = "quick_timer_limit_minutes"
        case guidedSessionsDailyLimit = "guided_sessions_daily_limit"
        case customRoutinesDailyLimit = "custom_routines_daily_limit"

        // Advanced configuration
        case trialFeaturesConfig = "trial_features_config"
        case forceServerValidation = "force_server_validation"
        case enableTrialExtension = "enable_trial_extension"

        // A/B testing
        case experimentGroup = "experiment_group"
    }

    // MARK: - Private Properties
    private let remoteConfig = RemoteConfig.remoteConfig()
    private var configUpdateListener: ConfigUpdateListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    // Cache for parsed values
    private var cachedTrialConfig: TrialConfiguration?

    // MARK: - Trial Configuration Model
    struct TrialConfiguration: Codable {
        let enabled: Bool
        let durationDays: Int
        let rolloutPercentage: Double
        let limits: TrialLimits
        let serverValidationRequired: Bool
        let extensionEnabled: Bool

        struct TrialLimits: Codable {
            let aiCoachDaily: Int
            let quickTimerMinutes: Int
            let guidedSessionsDaily: Int
            let customRoutinesDaily: Int
            let customLimits: [String: Int]?
        }
    }

    // MARK: - Initialization
    private init() {
        setupRemoteConfig()
    }

    // MARK: - Setup
    private func setupRemoteConfig() {
        // Configure settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour in production
        #if DEBUG
        settings.minimumFetchInterval = 0 // No throttling in debug
        #endif

        remoteConfig.configSettings = settings

        // Set default values
        setDefaultValues()

        // Fetch and activate initial config
        Task {
            _ = await fetchAndActivate()
            await setupRealtimeListener()
        }
    }

    // MARK: - Default Values
    private func setDefaultValues() {
        let defaults: [String: NSObject] = [
            ConfigKey.trialEnabled.rawValue: false as NSObject,
            ConfigKey.trialDurationDays.rawValue: 3 as NSObject,
            ConfigKey.trialRolloutPercentage.rawValue: 0.0 as NSObject,
            ConfigKey.aiCoachDailyLimit.rawValue: 3 as NSObject,
            ConfigKey.quickTimerLimitMinutes.rawValue: 5 as NSObject,
            ConfigKey.guidedSessionsDailyLimit.rawValue: 1 as NSObject,
            ConfigKey.customRoutinesDailyLimit.rawValue: 1 as NSObject,
            ConfigKey.forceServerValidation.rawValue: false as NSObject,
            ConfigKey.enableTrialExtension.rawValue: false as NSObject,
            ConfigKey.experimentGroup.rawValue: "control" as NSObject,
            ConfigKey.trialFeaturesConfig.rawValue: """
            {
                "enabled": false,
                "durationDays": 3,
                "rolloutPercentage": 0.0,
                "limits": {
                    "aiCoachDaily": 3,
                    "quickTimerMinutes": 5,
                    "guidedSessionsDaily": 1,
                    "customRoutinesDaily": 1
                },
                "serverValidationRequired": false,
                "extensionEnabled": false
            }
            """ as NSObject
        ]

        remoteConfig.setDefaults(defaults)
        Logger.debug("🔧 Remote Config defaults set")
    }

    // MARK: - Fetch and Activate
    func fetchAndActivate() async -> Bool {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            lastFetchTime = Date()

            switch status {
            case .successFetchedFromRemote:
                Logger.debug("✅ Remote Config fetched and activated from remote")
                parseTrialConfiguration()
                return true
            case .successUsingPreFetchedData:
                Logger.debug("✅ Remote Config activated using pre-fetched data")
                parseTrialConfiguration()
                return true
            case .error:
                Logger.error("❌ Remote Config fetch error")
                return false
            @unknown default:
                Logger.warning("⚠️ Unknown Remote Config status")
                return false
            }
        } catch {
            Logger.error("❌ Failed to fetch Remote Config: \(error)")
            return false
        }
    }

    // MARK: - Real-time Updates
    private func setupRealtimeListener() async {
        // Add listener for config updates
        configUpdateListener = remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let error = error {
                    Logger.error("❌ Config update error: \(error)")
                    return
                }

                guard let configUpdate = configUpdate else { return }

                Logger.debug("📡 Config update received. Updated keys: \(configUpdate.updatedKeys)")

                // Check if trial-related keys were updated
                let trialKeys = Set(ConfigKey.allCases.map { $0.rawValue })
                let updatedTrialKeys = configUpdate.updatedKeys.filter { trialKeys.contains($0) }

                if !updatedTrialKeys.isEmpty {
                    Logger.info("🔄 Trial configuration updated: \(updatedTrialKeys)")

                    // Activate the new config
                    do {
                        try await self.remoteConfig.activate()
                        self.configUpdateCount += 1
                        self.parseTrialConfiguration()

                        // Notify about config change
                        NotificationCenter.default.post(
                            name: .remoteConfigTrialUpdated,
                            object: nil,
                            userInfo: ["updatedKeys": updatedTrialKeys]
                        )
                    } catch {
                        Logger.error("❌ Failed to activate config: \(error)")
                    }
                }
            }
        }

        isConfigured = true
        Logger.debug("🎯 Real-time config listener configured")
    }

    // MARK: - Parse Configuration
    private func parseTrialConfiguration() {
        // Try to parse the JSON configuration
        let configString = remoteConfig[ConfigKey.trialFeaturesConfig.rawValue].stringValue

        guard let configData = configString.data(using: .utf8) else {
            Logger.error("Failed to convert config string to data")
            return
        }

        do {
            cachedTrialConfig = try JSONDecoder().decode(TrialConfiguration.self, from: configData)
            Logger.debug("✅ Trial configuration parsed successfully")
        } catch {
            Logger.error("Failed to parse trial configuration: \(error)")
            // Fall back to individual values
            cachedTrialConfig = TrialConfiguration(
                enabled: getBool(for: .trialEnabled),
                durationDays: getInteger(for: .trialDurationDays),
                rolloutPercentage: getDouble(for: .trialRolloutPercentage),
                limits: TrialConfiguration.TrialLimits(
                    aiCoachDaily: getInteger(for: .aiCoachDailyLimit),
                    quickTimerMinutes: getInteger(for: .quickTimerLimitMinutes),
                    guidedSessionsDaily: getInteger(for: .guidedSessionsDailyLimit),
                    customRoutinesDaily: getInteger(for: .customRoutinesDailyLimit),
                    customLimits: nil
                ),
                serverValidationRequired: getBool(for: .forceServerValidation),
                extensionEnabled: getBool(for: .enableTrialExtension)
            )
        }
    }

    // MARK: - Value Getters
    func getBool(for key: ConfigKey) -> Bool {
        return remoteConfig[key.rawValue].boolValue
    }

    func getInteger(for key: ConfigKey) -> Int {
        return remoteConfig[key.rawValue].numberValue.intValue
    }

    func getDouble(for key: ConfigKey) -> Double {
        return remoteConfig[key.rawValue].numberValue.doubleValue
    }

    func getString(for key: ConfigKey) -> String {
        return remoteConfig[key.rawValue].stringValue
    }

    // MARK: - Trial Configuration Access
    var trialConfiguration: TrialConfiguration? {
        return cachedTrialConfig
    }

    var isTrialEnabled: Bool {
        #if DEBUG
        // Check for debug override first
        if UserDefaults.standard.object(forKey: "com.growthlabs.trial.debug.forceEnabled") != nil {
            return UserDefaults.standard.bool(forKey: "com.growthlabs.trial.debug.forceEnabled")
        }
        #endif

        // Check if trial is enabled AND user is in rollout percentage
        guard let config = cachedTrialConfig else {
            return getBool(for: .trialEnabled)
        }

        if !config.enabled {
            return false
        }

        // Check rollout percentage
        if config.rolloutPercentage < 100.0 {
            return isUserInRollout(percentage: config.rolloutPercentage)
        }

        return true
    }

    var trialDurationDays: Int {
        return cachedTrialConfig?.durationDays ?? getInteger(for: .trialDurationDays)
    }

    var aiCoachDailyLimit: Int {
        return cachedTrialConfig?.limits.aiCoachDaily ?? getInteger(for: .aiCoachDailyLimit)
    }

    var quickTimerLimitMinutes: Int {
        return cachedTrialConfig?.limits.quickTimerMinutes ?? getInteger(for: .quickTimerLimitMinutes)
    }

    var guidedSessionsDailyLimit: Int {
        return cachedTrialConfig?.limits.guidedSessionsDaily ?? getInteger(for: .guidedSessionsDailyLimit)
    }

    var customRoutinesDailyLimit: Int {
        return cachedTrialConfig?.limits.customRoutinesDaily ?? getInteger(for: .customRoutinesDailyLimit)
    }

    // MARK: - Rollout Management
    private func isUserInRollout(percentage: Double) -> Bool {
        // Use a stable hash based on device identifier for consistent rollout
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let hash = deviceId.hashValue
        let normalizedHash = Double(abs(hash % 100))
        return normalizedHash < percentage
    }

    // MARK: - Experiment Groups
    var experimentGroup: String {
        return getString(for: .experimentGroup)
    }

    func isInExperimentGroup(_ group: String) -> Bool {
        return experimentGroup == group
    }

    // MARK: - Force Fetch
    func forceFetch() async {
        _ = await fetchAndActivate()
    }

    // MARK: - Cleanup
    func removeListener() {
        configUpdateListener?.remove()
        configUpdateListener = nil
    }

    deinit {
        configUpdateListener?.remove()
        configUpdateListener = nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let remoteConfigTrialUpdated = Notification.Name("trialConfigurationUpdated")
}

// MARK: - Logger Extension
private extension RemoteConfigManager {
    enum Logger {
        static func debug(_ message: String) {
            #if DEBUG
            print("[RemoteConfig] \(message)")
            #endif
        }

        static func info(_ message: String) {
            print("[RemoteConfig] ℹ️ \(message)")
        }

        static func warning(_ message: String) {
            print("[RemoteConfig] ⚠️ \(message)")
        }

        static func error(_ message: String) {
            print("[RemoteConfig] ❌ \(message)")
        }
    }
}