//
//  TrialDebugView.swift
//  Growth
//
//  Comprehensive debug view for testing trial system implementation
//

import SwiftUI
import FirebaseAuth
import Foundation

struct TrialDebugView: View {
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManagerWithTrial

    // State for UI updates
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false

    // Trial information
    @State private var trialStatus = "Loading..."
    @State private var daysRemaining = 0
    @State private var trialStartDate: Date?
    @State private var trialEndDate: Date?

    // Usage tracking
    @State private var aiCoachUsage = 0
    @State private var guidedSessionUsage = 0
    @State private var quickTimerUsage = 0

    // Device info
    @State private var deviceId = ""
    @State private var userId = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Current Status
                statusSection

                // Trial Management Controls
                trialControlsSection

                // Usage Management
                usageControlsSection

                // Advanced Debug Controls
                advancedControlsSection

                // System Information
                systemInfoSection
            }
            .padding()
        }
        .navigationTitle("Trial Debug Console")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAllInfo()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trial System Debug Console")
                .font(.title2)
                .fontWeight(.bold)

            Text("Complete control over trial system for testing")
                .font(.caption)
                .foregroundColor(.secondary)

            if case .active(let days) = entitlements.trialStatus {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Trial Active: \(days) day(s) remaining")
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Trial Status
                StatusRow(
                    icon: "hourglass",
                    title: "Trial Status",
                    value: getTrialStatusText(),
                    color: getTrialStatusColor()
                )

                // Premium Status
                StatusRow(
                    icon: "star.fill",
                    title: "Premium",
                    value: entitlements.hasPremium ? "Active" : "Inactive",
                    color: entitlements.hasPremium ? .green : .gray
                )

                // Trial Dates
                if let startDate = trialStartDate {
                    StatusRow(
                        icon: "calendar",
                        title: "Trial Started",
                        value: formatDate(startDate),
                        color: .blue
                    )
                }

                if let endDate = trialEndDate {
                    StatusRow(
                        icon: "calendar.badge.exclamationmark",
                        title: "Trial Ends",
                        value: formatDate(endDate),
                        color: .orange
                    )
                }

                // Usage Stats
                StatusRow(
                    icon: "chart.bar.fill",
                    title: "AI Coach Usage",
                    value: "\(entitlements.displayedAICoachUsage)/\(RemoteConfigManager.shared.aiCoachDailyLimit)",
                    color: .purple
                )

                StatusRow(
                    icon: "figure.run",
                    title: "Guided Sessions",
                    value: "\(entitlements.displayedGuidedSessionUsage)/\(RemoteConfigManager.shared.guidedSessionsDailyLimit)",
                    color: .indigo
                )
            }
        } label: {
            Label("Current Status", systemImage: "info.circle.fill")
                .font(.headline)
        }
    }

    // MARK: - Trial Controls Section
    private var trialControlsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Trial Management")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Enable/Disable Trials
                HStack(spacing: 12) {
                    Button {
                        enableTrials()
                    } label: {
                        Label("Enable Trials", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button {
                        disableTrials()
                    } label: {
                        Label("Disable Trials", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.regular)
                }

                Divider()

                // Start/End Trial
                HStack(spacing: 12) {
                    Button {
                        startTrial()
                    } label: {
                        Label("Start Trial", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.regular)

                    Button {
                        endTrial()
                    } label: {
                        Label("End Trial", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.regular)
                }

                // Extend Trial
                Button {
                    extendTrial()
                } label: {
                    Label("Extend Trial (+3 days)", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.regular)

                Divider()

                // Reset Everything
                Button {
                    resetAllTrialData()
                } label: {
                    Label("Reset All Trial Data", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
            }
        } label: {
            Label("Trial Controls", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
    }

    // MARK: - Usage Controls Section
    private var usageControlsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Usage Management")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Reset Daily Usage
                Button {
                    resetDailyUsage()
                } label: {
                    Label("Reset Daily Usage", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Max Out Usage
                Button {
                    maxOutUsage()
                } label: {
                    Label("Max Out Usage Limits", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                // Test Feature Access
                Button {
                    testAllFeatures()
                } label: {
                    Label("Test All Feature Gates", systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }
        } label: {
            Label("Usage Controls", systemImage: "chart.bar.xaxis")
                .font(.headline)
        }
    }

    // MARK: - Advanced Controls Section
    private var advancedControlsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Advanced Debug")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Server Sync
                Button {
                    syncWithServer()
                } label: {
                    Label("Force Server Sync", systemImage: "icloud.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Clear Keychain
                Button {
                    clearKeychain()
                } label: {
                    Label("Clear Keychain Data", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                // Time Travel
                HStack(spacing: 12) {
                    Button {
                        timeTravel(-1)
                    } label: {
                        Label("-1 Day", systemImage: "arrow.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        timeTravel(1)
                    } label: {
                        Label("+1 Day", systemImage: "arrow.forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                // Print Debug Info
                Button {
                    printDebugInfo()
                } label: {
                    Label("Print Debug Info to Console", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        } label: {
            Label("Advanced", systemImage: "gearshape.2.fill")
                .font(.headline)
        }
    }

    // MARK: - System Info Section
    private var systemInfoSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                TrialInfoRow(label: "Device ID", value: deviceId.isEmpty ? "Loading..." : String(deviceId.prefix(12)) + "...")
                TrialInfoRow(label: "User ID", value: userId.isEmpty ? "Not logged in" : String(userId.prefix(12)) + "...")
                TrialInfoRow(label: "Environment", value: currentEnvironment())
                TrialInfoRow(label: "App Version", value: appVersion())
                TrialInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                TrialInfoRow(label: "Device Model", value: UIDevice.current.model)
            }
        } label: {
            Label("System Information", systemImage: "info.circle.fill")
                .font(.headline)
        }
    }

    // MARK: - Helper Functions

    private func getDeviceId() -> String {
        // Get device ID from keychain if available
        if let deviceIdFromKeychain = getDeviceIdFromKeychain() {
            return deviceIdFromKeychain
        }
        // Otherwise use vendor ID
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }

    private func getDeviceIdFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.growthlabs.growthmethod",
            kSecAttrAccount as String: "deviceId",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let deviceId = String(data: data, encoding: .utf8) else {
            return nil
        }

        return deviceId
    }

    private func loadAllInfo() {
        // Load device and user info
        deviceId = getDeviceId()
        userId = Auth.auth().currentUser?.uid ?? "Anonymous"

        // Load trial dates
        let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
        if let timestamp = userDefaults.object(forKey: "firstLaunchTimestamp") as? TimeInterval {
            trialStartDate = Date(timeIntervalSince1970: timestamp)
            trialEndDate = trialStartDate?.addingTimeInterval(3 * 24 * 60 * 60) // 3 days
        }

        // Load usage
        aiCoachUsage = entitlements.displayedAICoachUsage
        guidedSessionUsage = entitlements.displayedGuidedSessionUsage
    }

    private func enableTrials() {
        isLoading = true
        Task {
            // Enable trials in UserDefaults
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            userDefaults.set(true, forKey: "com.growthlabs.trial.debug.forceEnabled")
            userDefaults.synchronize()

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trials Enabled", "Trial system has been enabled")
                loadAllInfo()
            }
        }
    }

    private func disableTrials() {
        isLoading = true
        Task {
            // Disable trials in UserDefaults
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            userDefaults.set(false, forKey: "com.growthlabs.trial.debug.forceEnabled")
            userDefaults.synchronize()

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trials Disabled", "Trial system has been disabled")
                loadAllInfo()
            }
        }
    }

    private func startTrial() {
        isLoading = true
        Task {
            // Set first launch timestamp to now
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            userDefaults.set(Date().timeIntervalSince1970, forKey: "firstLaunchTimestamp")
            userDefaults.set(false, forKey: "hasPremium")
            userDefaults.synchronize()

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trial Started", "3-day trial has been activated")
                loadAllInfo()
            }
        }
    }

    private func endTrial() {
        isLoading = true
        Task {
            // Set first launch timestamp to 4 days ago
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            let fourDaysAgo = Date().addingTimeInterval(-4 * 24 * 60 * 60)
            userDefaults.set(fourDaysAgo.timeIntervalSince1970, forKey: "firstLaunchTimestamp")
            userDefaults.synchronize()

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trial Ended", "Trial has been marked as expired")
                loadAllInfo()
            }
        }
    }

    private func extendTrial() {
        isLoading = true
        Task {
            // Move first launch timestamp back by 3 days
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            if let currentTimestamp = userDefaults.object(forKey: "firstLaunchTimestamp") as? TimeInterval {
                let extendedDate = Date(timeIntervalSince1970: currentTimestamp).addingTimeInterval(-3 * 24 * 60 * 60)
                userDefaults.set(extendedDate.timeIntervalSince1970, forKey: "firstLaunchTimestamp")
            } else {
                // If no trial, start one
                userDefaults.set(Date().timeIntervalSince1970, forKey: "firstLaunchTimestamp")
            }
            userDefaults.synchronize()

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trial Extended", "Trial has been extended by 3 days")
                loadAllInfo()
            }
        }
    }

    private func resetAllTrialData() {
        isLoading = true
        Task {
            // Reset all trial-related data
            entitlements.reset()

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Trial Reset", "All trial data has been cleared")
                loadAllInfo()
            }
        }
    }

    private func resetDailyUsage() {
        isLoading = true
        Task {
            // Reset usage counters
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            userDefaults.set(0, forKey: "dailyAICoachUsage")
            userDefaults.set(0, forKey: "dailyGuidedSessionUsage")
            userDefaults.set(0, forKey: "dailyQuickTimerUsage")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "lastUsageResetUTC")
            userDefaults.synchronize()

            // Refresh display
            await MainActor.run {
                // Reload info to show reset values
            }

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Usage Reset", "Daily usage counters have been reset")
                loadAllInfo()
            }
        }
    }

    private func maxOutUsage() {
        isLoading = true
        Task {
            // Max out usage counters
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard
            userDefaults.set(RemoteConfigManager.shared.aiCoachDailyLimit, forKey: "dailyAICoachUsage")
            userDefaults.set(RemoteConfigManager.shared.guidedSessionsDailyLimit, forKey: "dailyGuidedSessionUsage")
            userDefaults.set(5, forKey: "dailyQuickTimerUsage") // 5 minutes
            userDefaults.synchronize()

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Usage Maxed", "All usage limits have been reached")
                loadAllInfo()
            }
        }
    }

    private func testAllFeatures() {
        let features: [FeatureType] = [.aiCoach, .customRoutines, .quickTimer, .advancedAnalytics]
        var results: [String] = []

        for feature in features {
            let access = entitlements.checkFeatureAccess(for: feature)
            switch access {
            case .granted:
                results.append("\(feature.displayName): ✅ Granted")
            case .limited(let usage):
                results.append("\(feature.displayName): ⚠️ Limited (\(usage.currentUsage)/\(usage.maxUsage))")
            case .denied(let reason):
                results.append("\(feature.displayName): ❌ Denied - \(reason)")
            }
        }

        showSuccessAlert("Feature Test Results", results.joined(separator: "\n"))
    }

    private func syncWithServer() {
        isLoading = true
        Task {
            // Server sync is automatically handled by accessing trial status
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Server Sync", "Trial data synced with server")
                loadAllInfo()
            }
        }
    }

    private func clearKeychain() {
        isLoading = true
        Task {
            // Clear device ID from keychain
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.growthlabs.growthmethod"
            ]
            SecItemDelete(query as CFDictionary)

            await MainActor.run {
                isLoading = false
                showSuccessAlert("Keychain Cleared", "Device ID has been removed from keychain")
                loadAllInfo()
            }
        }
    }

    private func timeTravel(_ days: Int) {
        isLoading = true
        Task {
            let userDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthtraining") ?? UserDefaults.standard

            // Adjust first launch timestamp
            if let timestamp = userDefaults.object(forKey: "firstLaunchTimestamp") as? TimeInterval {
                let newDate = Date(timeIntervalSince1970: timestamp).addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
                userDefaults.set(newDate.timeIntervalSince1970, forKey: "firstLaunchTimestamp")
                userDefaults.synchronize()
            }

            // Force refresh - just accessing trialStatus will trigger update
            _ = entitlements.trialStatus

            await MainActor.run {
                isLoading = false
                let direction = days > 0 ? "forward" : "backward"
                showSuccessAlert("Time Travel", "Moved \(abs(days)) day(s) \(direction)")
                loadAllInfo()
            }
        }
    }

    private func printDebugInfo() {
        print("=== TRIAL DEBUG INFO ===")
        print("Trial Status: \(getTrialStatusText())")
        print("Device ID: \(deviceId)")
        print("User ID: \(userId)")
        print("Has Premium: \(entitlements.hasPremium)")
        print("Has Lifetime: \(entitlements.hasLifetime)")
        print("AI Coach Usage: \(entitlements.displayedAICoachUsage)/\(RemoteConfigManager.shared.aiCoachDailyLimit)")
        print("Guided Session Usage: \(entitlements.displayedGuidedSessionUsage)/\(RemoteConfigManager.shared.guidedSessionsDailyLimit)")

        if let startDate = trialStartDate {
            print("Trial Start: \(startDate)")
        }
        if let endDate = trialEndDate {
            print("Trial End: \(endDate)")
        }

        print("======================")

        showSuccessAlert("Debug Info", "Check Xcode console for detailed information")
    }

    // MARK: - Helper Views & Functions

    private func getTrialStatusText() -> String {
        switch entitlements.trialStatus {
        case .checking:
            return "Checking..."
        case .active(let days):
            return "Active (\(days) days left)"
        case .expired:
            return "Expired"
        case .notEligible:
            return "Not Eligible"
        case .disabled:
            return "Disabled"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private func getTrialStatusColor() -> Color {
        switch entitlements.trialStatus {
        case .active:
            return .green
        case .expired:
            return .orange
        case .disabled, .notEligible:
            return .gray
        case .error:
            return .red
        case .checking:
            return .blue
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func currentEnvironment() -> String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func showSuccessAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct TrialInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        TrialDebugView()
            .environmentObject(SimplifiedEntitlementManagerWithTrial.shared)
    }
}