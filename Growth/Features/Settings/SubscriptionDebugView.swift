//
//  SubscriptionDebugView.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import SwiftUI
import FirebaseAuth

/// Debug view for monitoring subscription state
@available(iOS 15.0, *)
struct SubscriptionDebugView: View {
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManagerWithTrial
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @State private var showRefreshConfirmation = false
    @State private var isRefreshing = false
    @State private var refreshError: String?
    @State private var showTrialActionConfirmation = false
    @State private var lastTrialAction: String = ""

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var timeIntervalFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }

    var body: some View {
        List {
            // Trial Information Section
            Section("Trial Information") {
                // Trial Status
                HStack {
                    Text("Trial Status")
                    Spacer()
                    Group {
                        switch entitlementManager.trialStatus {
                        case .checking:
                            Text("Checking...")
                                .foregroundColor(.orange)
                        case .active(let days):
                            Text("Active (\(days) days left)")
                                .foregroundColor(.green)
                        case .expired:
                            Text("Expired")
                                .foregroundColor(.red)
                        case .notEligible:
                            Text("Not Eligible")
                                .foregroundColor(.gray)
                        case .disabled:
                            Text("Disabled")
                                .foregroundColor(.gray)
                        case .error(let message):
                            Text("Error: \(message)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                // Trial Days Remaining
                HStack {
                    Text("Days Remaining")
                    Spacer()
                    Text("\(entitlementManager.trialDaysRemaining)")
                        .foregroundColor(entitlementManager.trialDaysRemaining > 0 ? .green : .secondary)
                }

                // First Launch Date
                if let firstLaunch = getFirstLaunchDate() {
                    HStack {
                        Text("Trial Started")
                        Spacer()
                        Text(dateFormatter.string(from: firstLaunch))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Trial End Date
                    HStack {
                        Text("Trial Ends")
                        Spacer()
                        Text(dateFormatter.string(from: firstLaunch.addingTimeInterval(3 * 24 * 60 * 60)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Next Limit Reset
                if let nextReset = entitlementManager.nextLimitResetTime {
                    HStack {
                        Text("Next Limit Reset")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(dateFormatter.string(from: nextReset))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let timeRemaining = timeIntervalFormatter.string(from: Date(), to: nextReset) {
                                Text("in \(timeRemaining)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }

            // Trial Usage Section
            Section("Trial Usage Limits") {
                HStack {
                    Text("AI Coach Usage")
                    Spacer()
                    Text("\(entitlementManager.displayedAICoachUsage) / 3")
                        .foregroundColor(entitlementManager.displayedAICoachUsage >= 3 ? .red : .green)
                }

                HStack {
                    Text("Guided Sessions")
                    Spacer()
                    Text("\(entitlementManager.displayedGuidedSessionUsage) / 2")
                        .foregroundColor(entitlementManager.displayedGuidedSessionUsage >= 2 ? .red : .green)
                }

                HStack {
                    Text("Is In Trial")
                    Spacer()
                    Text(entitlementManager.isInTrial ? "Yes" : "No")
                        .foregroundColor(entitlementManager.isInTrial ? .green : .secondary)
                }
            }

            Section("Current State") {
                HStack {
                    Text("Subscription Tier")
                    Spacer()
                    Text(entitlementManager.subscriptionTier.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Has Premium")
                    Spacer()
                    Text(entitlementManager.hasPremium ? "Yes" : "No")
                        .foregroundColor(entitlementManager.hasPremium ? .green : .secondary)
                }
                HStack {
                    Text("Has Any Premium Access")
                    Spacer()
                    Text(entitlementManager.hasPremium ? "Yes" : "No")
                        .foregroundColor(entitlementManager.hasPremium ? .green : .secondary)
                }
                HStack {
                    Text("Active Subscriptions")
                    Spacer()
                    Text("\(purchaseManager.purchasedProductIDs.count)")
                        .foregroundColor(.secondary)
                }
            }

            Section("Available Products") {
                if purchaseManager.products.isEmpty {
                    Text("No products loaded")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(purchaseManager.products) { product in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName)
                                    .font(.caption)
                                Text(product.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Purchased Product IDs") {
                if purchaseManager.purchasedProductIDs.isEmpty {
                    Text("No active purchases")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(purchaseManager.purchasedProductIDs), id: \.self) { productID in
                        HStack {
                            Text(productID)
                                .font(.caption)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            Section("Trial Debug Actions") {
                Button("Start New Trial") {
                    Task {
                        await startNewTrialDebug()
                    }
                }
                .foregroundColor(.blue)

                Button("Expire Trial") {
                    expireTrialDebug()
                }
                .foregroundColor(.orange)

                Button("Reset Trial State") {
                    resetTrialDebug()
                }
                .foregroundColor(.red)

                Button("Reset Daily Limits") {
                    Task {
                        await resetDailyLimitsDebug()
                    }
                }
                .foregroundColor(.blue)

                Button("Refresh Trial Status") {
                    Task {
                        await entitlementManager.refreshTrialStatus()
                        lastTrialAction = "Trial status refreshed"
                        showTrialActionConfirmation = true
                    }
                }
            }

            Section("Debug Actions") {
                Button("Refresh Products") {
                    Task {
                        isRefreshing = true
                        do {
                            try await purchaseManager.loadProducts()
                            await purchaseManager.updatePurchasedProducts()
                            showRefreshConfirmation = true
                        } catch {
                            refreshError = error.localizedDescription
                        }
                        isRefreshing = false
                    }
                }
                .disabled(isRefreshing)

                Button("Restore Purchases") {
                    Task {
                        isRefreshing = true
                        do {
                            try await purchaseManager.restorePurchases()
                            showRefreshConfirmation = true
                        } catch {
                            refreshError = error.localizedDescription
                        }
                        isRefreshing = false
                    }
                }
                .disabled(isRefreshing)

                Button("Reset Entitlements") {
                    entitlementManager.reset()
                    showRefreshConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Subscription Debug")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Action Complete", isPresented: $showRefreshConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = refreshError {
                Text("Error: \(error)")
            } else {
                Text("Products: \(purchaseManager.products.count) loaded\nPurchases: \(purchaseManager.purchasedProductIDs.count) active")
            }
        }
        .alert("Error", isPresented: .constant(refreshError != nil)) {
            Button("OK") { refreshError = nil }
        } message: {
            if let error = refreshError {
                Text(error)
            }
        }
        .alert("Trial Action", isPresented: $showTrialActionConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(lastTrialAction)
        }
    }

    // MARK: - Helper Functions
    private func getFirstLaunchDate() -> Date? {
        let timestamp = SimplifiedEntitlementManagerWithTrial.userDefaults.double(forKey: "com.growthlabs.firstLaunchTimestamp")
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    // MARK: - Debug Actions
    private func startNewTrialDebug() async {
        // Clear existing trial data
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.firstLaunchTimestamp")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.dailyAICoachUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.dailyGuidedSessionUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.lastUsageResetUTC")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.nextResetUTC")
        SimplifiedEntitlementManagerWithTrial.userDefaults.synchronize()

        // Set new trial start time
        let now = Date().timeIntervalSince1970
        SimplifiedEntitlementManagerWithTrial.userDefaults.set(now, forKey: "com.growthlabs.firstLaunchTimestamp")
        SimplifiedEntitlementManagerWithTrial.userDefaults.synchronize()

        // Refresh trial status
        await entitlementManager.refreshTrialStatus()

        lastTrialAction = "New trial started (3 days from now)"
        showTrialActionConfirmation = true
    }

    private func expireTrialDebug() {
        // Set trial start to more than 3 days ago
        let expiredDate = Date().addingTimeInterval(-4 * 24 * 60 * 60).timeIntervalSince1970
        SimplifiedEntitlementManagerWithTrial.userDefaults.set(expiredDate, forKey: "com.growthlabs.firstLaunchTimestamp")
        SimplifiedEntitlementManagerWithTrial.userDefaults.synchronize()

        // Update trial status
        entitlementManager.updateTrialStatus()

        lastTrialAction = "Trial expired (set to 4 days ago)"
        showTrialActionConfirmation = true
    }

    private func resetTrialDebug() {
        // Clear all trial-related data
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.firstLaunchTimestamp")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.dailyAICoachUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.dailyGuidedSessionUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.lastUsageResetUTC")
        SimplifiedEntitlementManagerWithTrial.userDefaults.removeObject(forKey: "com.growthlabs.nextResetUTC")
        SimplifiedEntitlementManagerWithTrial.userDefaults.synchronize()

        // Reset entitlement manager
        entitlementManager.reset()

        lastTrialAction = "All trial data cleared. Restart app to initialize new trial."
        showTrialActionConfirmation = true
    }

    private func resetDailyLimitsDebug() async {
        // Reset usage counts
        SimplifiedEntitlementManagerWithTrial.userDefaults.set(0, forKey: "com.growthlabs.dailyAICoachUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.set(0, forKey: "com.growthlabs.dailyGuidedSessionUsage")
        SimplifiedEntitlementManagerWithTrial.userDefaults.synchronize()

        // Check and reset
        await entitlementManager.checkAndResetDailyLimits()

        lastTrialAction = "Daily usage limits reset to 0"
        showTrialActionConfirmation = true
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
struct SubscriptionDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubscriptionDebugView()
                .environmentObject(SimplifiedEntitlementManagerWithTrial.shared)
                .environmentObject(SimplifiedPurchaseManager(entitlementManager: SimplifiedEntitlementManagerWithTrial.shared))
        }
    }
}