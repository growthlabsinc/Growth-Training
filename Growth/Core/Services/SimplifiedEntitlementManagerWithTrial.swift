/**
 * SimplifiedEntitlementManagerWithTrial.swift
 * Growth App Enhanced Entitlement Management with Trial Support
 *
 * Extends the simplified entitlement system with 3-day trial functionality
 * Integrates Firebase Remote Config for server-controlled trial parameters
 * Includes robust edge case handling and App Group synchronization
 */

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFunctions
import FirebaseAnalytics
import Security
import Combine

@MainActor
public class SimplifiedEntitlementManagerWithTrial: ObservableObject {

    // MARK: - App Group UserDefaults
    static let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining")!

    // MARK: - Singleton
    public static let shared = SimplifiedEntitlementManagerWithTrial()

    // MARK: - Entitlement Flags (Legacy)
    @AppStorage("hasPremium", store: userDefaults)
    public var hasPremium: Bool = false

    @AppStorage("hasLifetime", store: userDefaults)
    public var hasLifetime: Bool = false

    // MARK: - Trial State (Not using @AppStorage to minimize SwiftUI updates)
    private var _firstLaunchTimestamp: Double = 0
    private var _dailyAICoachUsage: Int = 0
    private var _dailyGuidedSessionUsage: Int = 0
    private var _lastUsageResetUTC: Double = 0
    private var _nextResetUTC: Double = 0

    // MARK: - Published Properties for UI
    @Published private(set) var trialStatus: TrialStatus = .checking
    @Published private(set) var displayedAICoachUsage: Int = 0
    @Published private(set) var displayedGuidedSessionUsage: Int = 0
    @Published private(set) var trialDaysRemaining: Int = 0
    @Published private(set) var nextLimitResetTime: Date?

    // MARK: - Private Properties
    private let keychainService = "com.growthlabs.growthtraining"
    private let functions = Functions.functions()
    private var serverTimeOffset: TimeInterval = 0
    private var updateTimer: Timer?
    private var pendingUsageUpdates = PendingUsageUpdates()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Trial Status Enum
    public enum TrialStatus {
        case checking
        case active(daysRemaining: Int)
        case expired
        case notEligible // Already had trial on another device
        case disabled // Trial feature disabled via Remote Config
        case error(String)
    }

    // MARK: - Pending Usage Updates
    private struct PendingUsageUpdates {
        var aiCoachIncrement: Int = 0
        var guidedSessionIncrement: Int = 0
    }

    // MARK: - Convenience Properties
    public var hasAnyPremiumAccess: Bool {
        let result = hasPremium || hasLifetime
        if result {
            print("⚠️ [EntitlementManager] User has premium access - hasPremium: \(hasPremium), hasLifetime: \(hasLifetime)")
        }
        return result
    }

    public var isInTrial: Bool {
        switch trialStatus {
        case .active:
            return true
        default:
            return false
        }
    }

    public var subscriptionTier: SubscriptionTier {
        if hasAnyPremiumAccess {
            return .premium
        // Trial is not a separate tier
        } else {
            return .none
        }
    }

    // MARK: - Initializer
    private init() {
        print("🚀 [EntitlementManager] Initializing SimplifiedEntitlementManagerWithTrial")
        print("  - Initial hasPremium: \(hasPremium)")
        print("  - Initial hasLifetime: \(hasLifetime)")
        print("  - Initial hasAnyPremiumAccess: \(hasAnyPremiumAccess)")

        loadTrialState()
        setupDarwinNotificationObserver()
        setupRemoteConfigListener()

        Task {
            await initializeTrialSystem()
        }
    }

    // MARK: - Trial System Initialization
    private func initializeTrialSystem() async {
        print("🔍 [EntitlementManager] Initializing trial system")
        print("  - Remote config trial enabled: \(RemoteConfigManager.shared.isTrialEnabled)")

        // Check if trial is enabled via Remote Config
        #if targetEnvironment(simulator) || DEBUG
        // In debug/simulator, respect Remote Config
        guard RemoteConfigManager.shared.isTrialEnabled else {
            print("  ❌ Trial disabled via Remote Config")
            trialStatus = .disabled
            return
        }
        #else
        // In TestFlight/Release, always enable trial for testing
        if !RemoteConfigManager.shared.isTrialEnabled {
            print("  ⚠️ Trial disabled in Remote Config but forcing enabled for TestFlight")
        }
        #endif

        // Migrate and verify trial state
        await migrateAndVerifyTrial()

        // Start periodic checks
        startPeriodicChecks()
    }

    // MARK: - Load Trial State from UserDefaults
    private func loadTrialState() {
        _firstLaunchTimestamp = Self.userDefaults.double(forKey: "com.growthlabs.firstLaunchTimestamp")
        _dailyAICoachUsage = Self.userDefaults.integer(forKey: "com.growthlabs.dailyAICoachUsage")
        _dailyGuidedSessionUsage = Self.userDefaults.integer(forKey: "com.growthlabs.dailyGuidedSessionUsage")
        _lastUsageResetUTC = Self.userDefaults.double(forKey: "com.growthlabs.lastUsageResetUTC")
        _nextResetUTC = Self.userDefaults.double(forKey: "com.growthlabs.nextResetUTC")

        print("📱 [EntitlementManager] Loaded trial state from UserDefaults:")
        print("  - First launch timestamp: \(_firstLaunchTimestamp)")
        if _firstLaunchTimestamp > 0 {
            let firstLaunchDate = Date(timeIntervalSince1970: _firstLaunchTimestamp)
            print("  - First launch date: \(firstLaunchDate)")
        }
        print("  - AI Coach usage: \(_dailyAICoachUsage)")
        print("  - Guided session usage: \(_dailyGuidedSessionUsage)")

        // Update displayed values
        displayedAICoachUsage = _dailyAICoachUsage
        displayedGuidedSessionUsage = _dailyGuidedSessionUsage
    }

    // MARK: - Darwin Notification Observer for App Group Sync
    private func setupDarwinNotificationObserver() {
        // Use NotificationCenter instead of CFNotificationCenter for Swift compatibility
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUsageUpdateNotification),
            name: Notification.Name("com.growthlabs.usage.updated"),
            object: nil
        )
    }

    @objc private func handleUsageUpdateNotification() {
        syncFromUserDefaults()
    }

    // MARK: - Remote Config Listener
    private func setupRemoteConfigListener() {
        NotificationCenter.default.publisher(for: .trialConfigurationUpdated)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshTrialConfiguration()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync from UserDefaults
    private func syncFromUserDefaults() {
        let oldAIUsage = _dailyAICoachUsage
        let oldGuidedUsage = _dailyGuidedSessionUsage

        loadTrialState()

        // Only publish changes if values actually changed
        if oldAIUsage != _dailyAICoachUsage || oldGuidedUsage != _dailyGuidedSessionUsage {
            objectWillChange.send()
        }
    }

    // MARK: - Migration and Verification
    private func migrateAndVerifyTrial() async {
        print("🔍 [TRIAL] Starting migration and verification")
        print("  - Current firstLaunchTimestamp: \(_firstLaunchTimestamp)")
        print("  - Current user: \(Auth.auth().currentUser?.uid ?? "none")")

        // Step 1: Check local firstLaunchDate
        if _firstLaunchTimestamp == 0 {
            print("  📱 No local trial timestamp found")
            // Step 2: Check server for this user's trial history
            if let userId = Auth.auth().currentUser?.uid {
                print("  🔍 Checking server for user trial history...")
                if let serverTrialData = await fetchTrialDataFromFirebase(userId: userId) {
                    // User has trial history on server
                    print("  ✅ Found server trial data")
                    _firstLaunchTimestamp = serverTrialData.firstLaunchDate.timeIntervalSince1970
                    saveTrialState()
                } else {
                    print("  ❌ No server trial data found")
                    // Step 3: Check device identifier to prevent reinstall gaming
                    let deviceId = getDeviceIdentifier()
                    print("  🔍 Checking device trial history for: \(deviceId)")
                    if let deviceTrialData = await checkDeviceTrialHistory(deviceId: deviceId) {
                        // This device has been used before
                        print("  ⚠️ Device has previous trial history")
                        _firstLaunchTimestamp = deviceTrialData.firstLaunchDate.timeIntervalSince1970
                        trialStatus = .notEligible
                        saveTrialState()
                    } else {
                        // Genuine new user/device
                        print("  🎉 Starting new trial for user")
                        await startNewTrial(userId: userId, deviceId: deviceId)
                    }
                }
            } else {
                // Anonymous user - use device-based trial
                print("  👤 Anonymous user - handling device-based trial")
                await handleAnonymousUserTrial()
            }
        } else {
            print("  ✅ Existing trial timestamp found: \(Date(timeIntervalSince1970: _firstLaunchTimestamp))")
        }

        // Step 4: Validate trial integrity
        validateTrialIntegrity()

        // Step 5: Update trial status
        updateTrialStatus()
    }

    // MARK: - Device Identifier (Persists across reinstalls)
    private func getDeviceIdentifier() -> String {
        // Use keychain for persistence across reinstalls
        if let existingId = loadFromKeychain(key: "deviceTrialId") {
            return existingId
        }

        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        _ = saveToKeychain(key: "deviceTrialId", value: newId)
        return newId
    }

    // MARK: - Start New Trial
    private func startNewTrial(userId: String?, deviceId: String) async {
        let now = Date()
        _firstLaunchTimestamp = now.timeIntervalSince1970

        // Record on server immediately
        let callable = functions.httpsCallable("recordTrialStart")
        do {
            _ = try await callable.call([
                "userId": userId ?? "",
                "deviceId": deviceId,
                "startDate": now.timeIntervalSince1970
            ])
        } catch {
            print("Failed to record trial start on server: \(error)")
        }

        saveTrialState()
        updateTrialStatus()

        // Initialize daily reset times
        await checkAndResetDailyLimits()
    }

    // MARK: - Validate Trial Integrity
    private func validateTrialIntegrity() {
        guard _firstLaunchTimestamp > 0 else { return }

        let firstLaunch = Date(timeIntervalSince1970: _firstLaunchTimestamp)
        let serverTime = Date().addingTimeInterval(serverTimeOffset)

        // Check if firstLaunchDate is in the future (time manipulation)
        if firstLaunch > serverTime {
            // Trial start date is in the future - invalidate
            expireTrial(reason: "Time manipulation detected")
            return
        }

        // Check if trial duration exceeds maximum (timezone gaming)
        let trialDuration = serverTime.timeIntervalSince(firstLaunch)
        let maxDuration = Double(RemoteConfigManager.shared.trialDurationDays + 1) * 24 * 3600

        if trialDuration > maxDuration {
            // Trial has definitely expired
            trialStatus = .expired
        }
    }

    // MARK: - Refresh Trial Status (Public method for forcing update)
    @MainActor
    public func refreshTrialStatus() async {
        print("🔄 [EntitlementManager] Force refreshing trial status...")

        // For new users without a timestamp, start a new trial
        if _firstLaunchTimestamp == 0 {
            if let userId = Auth.auth().currentUser?.uid {
                let deviceId = getDeviceIdentifier()
                await startNewTrial(userId: userId, deviceId: deviceId)
            }
        }

        // Update the status
        updateTrialStatus()

        // Trigger UI update
        objectWillChange.send()
    }

    // MARK: - Update Trial Status
    public func updateTrialStatus() {
        print("🔄 [EntitlementManager] Updating trial status...")

        // Reload state from UserDefaults first to ensure we have the latest values
        loadTrialState()

        guard _firstLaunchTimestamp > 0 else {
            print("  ⏳ No first launch timestamp - setting status to checking")
            trialStatus = .checking
            return
        }

        // For TestFlight builds, always enable trial
        #if targetEnvironment(simulator) || DEBUG
        // In debug/simulator, respect Remote Config
        guard RemoteConfigManager.shared.isTrialEnabled else {
            print("  🚫 Trial disabled in Remote Config")
            trialStatus = .disabled
            return
        }
        #else
        // In TestFlight/Release, always enable trial for testing
        if !RemoteConfigManager.shared.isTrialEnabled {
            print("  ⚠️ Trial disabled in Remote Config but forcing enabled for TestFlight")
        }
        #endif

        let firstLaunch = Date(timeIntervalSince1970: _firstLaunchTimestamp)
        let now = Date().addingTimeInterval(serverTimeOffset)
        let daysSinceStart = Calendar.current.dateComponents([.day], from: firstLaunch, to: now).day ?? 0
        let trialDuration = RemoteConfigManager.shared.trialDurationDays

        print("  📅 Trial calculation:")
        print("  - First launch: \(firstLaunch)")
        print("    - Current time: \(now)")
        print("    - Days since start: \(daysSinceStart)")
        print("    - Trial duration: \(trialDuration) days")

        if daysSinceStart < trialDuration {
            let remaining = trialDuration - daysSinceStart
            trialDaysRemaining = remaining
            trialStatus = .active(daysRemaining: remaining)
            print("  ✅ Trial ACTIVE - \(remaining) days remaining")
        } else {
            trialDaysRemaining = 0
            trialStatus = .expired
            print("  ⏰ Trial EXPIRED")
        }
    }

    // MARK: - Check and Reset Daily Limits
    func checkAndResetDailyLimits() async {
        // Get server time for accuracy
        let serverTime = await fetchServerTime()
        let localTime = Date()
        serverTimeOffset = serverTime.timeIntervalSince(localTime)

        // Use server time for reset check
        let currentUTC = serverTime

        // Calculate next midnight UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentUTC)!
        let nextMidnightUTC = calendar.startOfDay(for: tomorrow)

        // Check if we've passed the reset time
        if _nextResetUTC == 0 || currentUTC >= Date(timeIntervalSince1970: _nextResetUTC) {
            // Reset counters
            await performDailyReset(serverTime: serverTime, nextReset: nextMidnightUTC)
        }

        nextLimitResetTime = Date(timeIntervalSince1970: _nextResetUTC)
    }

    // MARK: - Perform Daily Reset
    private func performDailyReset(serverTime: Date, nextReset: Date) async {
        // Reset locally
        _dailyAICoachUsage = 0
        _dailyGuidedSessionUsage = 0
        _lastUsageResetUTC = serverTime.timeIntervalSince1970
        _nextResetUTC = nextReset.timeIntervalSince1970

        saveTrialState()

        // Update displayed values
        displayedAICoachUsage = 0
        displayedGuidedSessionUsage = 0

        // Sync with server
        if let userId = Auth.auth().currentUser?.uid {
            let callable = functions.httpsCallable("recordDailyReset")
            do {
                _ = try await callable.call([
                    "userId": userId,
                    "resetTime": serverTime.timeIntervalSince1970,
                    "nextReset": nextReset.timeIntervalSince1970
                ])
            } catch {
                print("Failed to record daily reset on server: \(error)")
            }
        }

        // Notify Darwin notification for extensions
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.growthlabs.usage.reset" as CFString),
            nil, nil, true
        )

        // Notify UI if app is active
        if UIApplication.shared.applicationState == .active {
            NotificationCenter.default.post(
                name: .dailyLimitsReset,
                object: nil
            )
        }
    }

    // MARK: - Feature Access Methods
    public func checkFeatureAccess(for feature: FeatureType) -> FeatureAccess {
        // Premium users have full access
        if hasAnyPremiumAccess {
            return .granted
        }

        // Check trial status
        switch trialStatus {
        case .active:
            return checkTrialFeatureAccess(for: feature)
        case .expired:
            // After trial, only Quick Timer under 5 minutes is available
            if feature == .quickTimer {
                return .granted // Will be limited by TimerService
            }
            return .denied(reason: .trialExpired)
        case .disabled, .notEligible:
            // No trial, check free tier
            return checkFreeTierAccess(for: feature)
        default:
            return .denied(reason: .featureNotAvailable)
        }
    }

    private func checkTrialFeatureAccess(for feature: FeatureType) -> FeatureAccess {
        let remoteConfig = RemoteConfigManager.shared

        switch feature {
        case .aiCoach:
            let limit = remoteConfig.aiCoachDailyLimit
            if _dailyAICoachUsage >= limit {
                let resetTime = nextLimitResetTime ?? Date().addingTimeInterval(3600)
                return .limited(usage: FeatureUsage(
                    feature: feature.rawValue,
                    currentUsage: _dailyAICoachUsage,
                    maxUsage: limit,
                    resetDate: resetTime,
                    isPermanent: false
                ))
            }
            return .granted

        case .customRoutines:
            let limit = remoteConfig.customRoutinesDailyLimit
            if _dailyGuidedSessionUsage >= limit {
                let resetTime = nextLimitResetTime ?? Date().addingTimeInterval(3600)
                return .limited(usage: FeatureUsage(
                    feature: feature.rawValue,
                    currentUsage: _dailyGuidedSessionUsage,
                    maxUsage: limit,
                    resetDate: resetTime,
                    isPermanent: false
                ))
            }
            return .granted

        case .quickTimer:
            // Limited by duration in TimerService
            return .granted

        default:
            // Other features blocked during trial
            return .denied(reason: .featureNotAvailable)
        }
    }

    private func checkFreeTierAccess(for feature: FeatureType) -> FeatureAccess {
        // Free tier only has articles and limited quick timer
        if feature == .articles || feature == .quickTimer {
            return .granted
        }
        return .denied(reason: .noSubscription)
    }

    // MARK: - Increment Usage (with batching)
    public func incrementAICoachUsage() {
        pendingUsageUpdates.aiCoachIncrement += 1
        scheduleUpdate()
    }

    public func incrementGuidedSessionUsage() {
        pendingUsageUpdates.guidedSessionIncrement += 1
        scheduleUpdate()
    }

    private func scheduleUpdate() {
        // Cancel existing timer
        updateTimer?.invalidate()

        // Batch updates after 0.5 seconds of inactivity
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.commitPendingUpdates()
            }
        }
    }

    private func commitPendingUpdates() {
        guard pendingUsageUpdates.aiCoachIncrement > 0 || pendingUsageUpdates.guidedSessionIncrement > 0 else { return }

        // Update actual storage
        _dailyAICoachUsage += pendingUsageUpdates.aiCoachIncrement
        _dailyGuidedSessionUsage += pendingUsageUpdates.guidedSessionIncrement

        saveTrialState()

        // Update Firebase in background
        Task {
            await updateUsageOnServer(
                aiCoach: _dailyAICoachUsage,
                guidedSessions: _dailyGuidedSessionUsage
            )
        }

        // Update displayed values (triggers SwiftUI update)
        displayedAICoachUsage = _dailyAICoachUsage
        displayedGuidedSessionUsage = _dailyGuidedSessionUsage

        // Notify extensions via Darwin notification
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.growthlabs.usage.updated" as CFString),
            nil, nil, true
        )

        // Reset pending
        pendingUsageUpdates = PendingUsageUpdates()
    }

    // MARK: - Save Trial State
    private func saveTrialState() {
        Self.userDefaults.set(_firstLaunchTimestamp, forKey: "com.growthlabs.firstLaunchTimestamp")
        Self.userDefaults.set(_dailyAICoachUsage, forKey: "com.growthlabs.dailyAICoachUsage")
        Self.userDefaults.set(_dailyGuidedSessionUsage, forKey: "com.growthlabs.dailyGuidedSessionUsage")
        Self.userDefaults.set(_lastUsageResetUTC, forKey: "com.growthlabs.lastUsageResetUTC")
        Self.userDefaults.set(_nextResetUTC, forKey: "com.growthlabs.nextResetUTC")
    }

    // MARK: - Server Communication
    private func fetchTrialDataFromFirebase(userId: String) async -> AppTrialData? {
        let callable = functions.httpsCallable("getTrialData")
        do {
            let result = try await callable.call(["userId": userId])
            guard let data = result.data as? [String: Any],
                  let firstLaunch = data["firstLaunchDate"] as? Double else {
                return nil
            }
            return AppTrialData(firstLaunchDate: Date(timeIntervalSince1970: firstLaunch))
        } catch {
            print("Failed to fetch trial data: \(error)")
            return nil
        }
    }

    private func checkDeviceTrialHistory(deviceId: String) async -> AppTrialData? {
        let callable = functions.httpsCallable("checkDeviceTrial")
        do {
            let result = try await callable.call(["deviceId": deviceId])
            guard let data = result.data as? [String: Any],
                  let firstLaunch = data["firstLaunchDate"] as? Double else {
                return nil
            }
            return AppTrialData(firstLaunchDate: Date(timeIntervalSince1970: firstLaunch))
        } catch {
            print("Failed to check device trial: \(error)")
            return nil
        }
    }

    private func handleAnonymousUserTrial() async {
        let deviceId = getDeviceIdentifier()

        if let deviceTrialData = await checkDeviceTrialHistory(deviceId: deviceId) {
            _firstLaunchTimestamp = deviceTrialData.firstLaunchDate.timeIntervalSince1970
            saveTrialState()
        } else {
            await startNewTrial(userId: nil, deviceId: deviceId)
        }
    }

    private func fetchServerTime() async -> Date {
        let callable = functions.httpsCallable("getServerTime")
        do {
            let result = try await callable.call()
            if let timestamp = (result.data as? [String: Any])?["timestamp"] as? Double {
                return Date(timeIntervalSince1970: timestamp)
            }
        } catch {
            print("Failed to fetch server time: \(error)")
        }
        return Date()
    }

    private func updateUsageOnServer(aiCoach: Int, guidedSessions: Int) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let callable = functions.httpsCallable("updateUsageStats")
        do {
            _ = try await callable.call([
                "userId": userId,
                "aiCoachUsage": aiCoach,
                "guidedSessionUsage": guidedSessions,
                "timestamp": Date().timeIntervalSince1970
            ])
        } catch {
            print("Failed to update usage on server: \(error)")
        }
    }

    private func refreshTrialConfiguration() async {
        // Re-evaluate trial status when Remote Config changes
        updateTrialStatus()
        await checkAndResetDailyLimits()
    }

    // MARK: - Periodic Checks
    private func startPeriodicChecks() {
        // Check every hour for daily reset and trial expiration
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndResetDailyLimits()
                await self?.updateTrialStatus()
            }
        }
    }

    // MARK: - Expire Trial
    private func expireTrial(reason: String) {
        trialStatus = .error(reason)
        _firstLaunchTimestamp = Date().timeIntervalSince1970 - (4 * 24 * 3600) // 4 days ago
        saveTrialState()
    }

    // MARK: - Anti-Tampering
    func detectAndPreventAbuse() {
        // Check 1: Keychain persistence for device ID
        _ = getDeviceIdentifier()

        // Check 2: Compare local and server trial data
        Task {
            if let userId = Auth.auth().currentUser?.uid,
               let serverData = await fetchTrialDataFromFirebase(userId: userId) {
                let localFirstLaunch = Date(timeIntervalSince1970: _firstLaunchTimestamp)
                let difference = abs(serverData.firstLaunchDate.timeIntervalSince(localFirstLaunch))

                if difference > 3600 { // More than 1 hour difference
                    // Use server date as source of truth
                    _firstLaunchTimestamp = serverData.firstLaunchDate.timeIntervalSince1970
                    saveTrialState()
                    updateTrialStatus()
                }
            }
        }

        // Check 3: Monitor for app deletion/reinstallation
        if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") == false {
            // First launch after install
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

            // Check keychain for previous installation
            if keychainContains(key: "previousInstallation") {
                // This is a reinstall - restore trial state from server
                Task {
                    await migrateAndVerifyTrial()
                }
            } else {
                // Genuine first installation
                _ = saveToKeychain(key: "previousInstallation", value: "true")
            }
        }
    }

    // MARK: - Debug Methods
    public func debugPrint() {
        print("📱 Current Entitlements:")
        print("   - Premium: \(hasPremium)")
        print("   - Lifetime: \(hasLifetime)")
        print("   - Trial Status: \(trialStatus)")
        print("   - Days Remaining: \(trialDaysRemaining)")
        print("   - AI Coach Usage: \(displayedAICoachUsage)/\(RemoteConfigManager.shared.aiCoachDailyLimit)")
        print("   - Guided Sessions: \(displayedGuidedSessionUsage)/\(RemoteConfigManager.shared.guidedSessionsDailyLimit)")
        print("   - Next Reset: \(nextLimitResetTime?.description ?? "Unknown")")
    }

    // MARK: - Reset
    public func reset() {
        hasPremium = false
        hasLifetime = false
        _firstLaunchTimestamp = 0
        _dailyAICoachUsage = 0
        _dailyGuidedSessionUsage = 0
        _lastUsageResetUTC = 0
        _nextResetUTC = 0

        saveTrialState()

        // Clear keychain
        deleteFromKeychain(key: "deviceTrialId")
        deleteFromKeychain(key: "previousInstallation")

        print("🧹 Entitlements and trial state reset")
    }

    // MARK: - Computed Properties for Compatibility
    public var firstLaunchDate: Date? {
        guard _firstLaunchTimestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: _firstLaunchTimestamp)
    }
}

// MARK: - Supporting Types
private struct AppTrialData {
    let firstLaunchDate: Date
}

// MARK: - Protocol Conformance for PurchaseManager
// Note: PurchaseEntitlementManager conformance is declared in SimplifiedPurchaseManager.swift
extension SimplifiedEntitlementManagerWithTrial {
    public func updateFromPurchasedProducts(_ purchasedIDs: Set<String>) {
        // Check for known product IDs
        let premiumProductIds = [
            "com.growthlabs.growthtraining.subscription.premium.weekly",
            "com.growthlabs.growthtraining.subscription.premium.quarterly",
            "com.growthlabs.growthtraining.subscription.premium.yearly"
        ]

        let lifetimeProductIds = [
            "com.growthlabs.growthtraining.lifetime"
        ]

        // Update entitlements
        let hasPremiumNew = !purchasedIDs.isDisjoint(with: premiumProductIds)
        let hasLifetimeNew = !purchasedIDs.isDisjoint(with: lifetimeProductIds)

        // Only update if changed
        if hasPremium != hasPremiumNew {
            hasPremium = hasPremiumNew
        }

        if hasLifetime != hasLifetimeNew {
            hasLifetime = hasLifetimeNew
        }

        print("📱 Updated entitlements from purchases: Premium=\(hasPremium), Lifetime=\(hasLifetime)")
    }
}

// UsageLimit is replaced by FeatureUsage from FeatureAccess.swift

// MARK: - Notification Names
extension Notification.Name {
    static let dailyLimitsReset = Notification.Name("dailyLimitsReset")
    static let trialConfigurationUpdated = Notification.Name("trialConfigurationUpdated")
}

// MARK: - Subscription Tier Extension
// Trial is handled as a special case, not as a separate SubscriptionTier

// MARK: - Offer Code Support (Story 9.3)
extension SimplifiedEntitlementManagerWithTrial {

    /// Computed property to retrieve last offer code redemption details
    var lastOfferCodeRedemption: (offerID: String, timestamp: Date)? {
        guard let offerID = Self.userDefaults.string(forKey: "com.growthlabs.lastOfferCodeRedeemed"),
              let timestampDouble = Self.userDefaults.object(forKey: "com.growthlabs.lastOfferCodeTimestamp") as? Double else {
            return nil
        }
        return (offerID, Date(timeIntervalSince1970: timestampDouble))
    }

    /// Store offer code redemption details in App Group UserDefaults
    func storeOfferCodeRedemption(offerID: String, timestamp: Date) {
        Self.userDefaults.set(offerID, forKey: "com.growthlabs.lastOfferCodeRedeemed")
        Self.userDefaults.set(timestamp.timeIntervalSince1970, forKey: "com.growthlabs.lastOfferCodeTimestamp")

        // Store user ID if authenticated
        if let userId = Auth.auth().currentUser?.uid {
            Self.userDefaults.set(userId, forKey: "com.growthlabs.lastOfferCodeUserId")
        }

        print("💾 Stored offer code redemption: \(offerID) at \(timestamp)")
    }

    /// Handle offer code transaction from SimplifiedPurchaseManager
    func handleOfferCodeTransaction(offerID: String, productID: String) async {
        let timestamp = Date()

        print("✅ Offer code \(offerID) granted premium access")

        // Store offer code redemption locally
        storeOfferCodeRedemption(offerID: offerID, timestamp: timestamp)

        // Sync to Firebase (offline resilient)
        await syncOfferCodeToFirebase(offerID: offerID, productID: productID, timestamp: timestamp)

        // Track analytics event
        trackOfferCodeAttribution(offerID: offerID, productID: productID, timestamp: timestamp)
    }

    /// Sync offer code redemption to Firebase
    private func syncOfferCodeToFirebase(offerID: String, productID: String, timestamp: Date) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ Cannot sync offer code - user not authenticated")
            return
        }

        let callable = functions.httpsCallable("logOfferCodeRedemption")
        do {
            _ = try await callable.call([
                "offerCodeRef": offerID,
                "timestamp": timestamp.timeIntervalSince1970,
                "platform": "iOS",
                "subscriptionProductId": productID
            ])
            print("✅ Offer code synced to Firebase")
        } catch {
            print("⚠️ Failed to sync offer code to Firebase: \(error.localizedDescription)")
            // Don't block user - offline resilience
        }
    }

    /// Track offer code attribution analytics event
    private func trackOfferCodeAttribution(offerID: String, productID: String, timestamp: Date) {
        Analytics.logEvent("offer_code_attributed_subscription", parameters: [
            "offer_code_ref": offerID,
            "user_id": Auth.auth().currentUser?.uid ?? "unknown",
            "timestamp": timestamp.timeIntervalSince1970,
            "platform": "iOS",
            "subscription_product_id": productID
        ])
        print("📊 Analytics: offer_code_attributed_subscription - \(offerID)")
    }
}

// MARK: - Keychain Helper Methods
private extension SimplifiedEntitlementManagerWithTrial {

    func saveToKeychain(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }

        return nil
    }

    func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    func keychainContains(key: String) -> Bool {
        return loadFromKeychain(key: key) != nil
    }
}