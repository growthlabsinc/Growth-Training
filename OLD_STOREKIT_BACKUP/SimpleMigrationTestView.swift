/**
 * SimpleMigrationTestView.swift
 * Test harness for verifying the StoreKit 2 migration
 * 
 * This view provides a comprehensive testing interface to verify
 * both implementations work correctly during migration.
 */

import SwiftUI
import StoreKit

/// Comprehensive test view for StoreKit migration
public struct SimpleMigrationTestView: View {
    // MARK: - State
    
    @State private var useSimplified = StoreKitFeatureFlags.useSimplifiedImplementation
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var selectedTab = 0
    
    // Simplified implementation
    @ObservedObject private var simpleEntitlements = SimpleEntitlementManager.shared
    @StateObject private var simplePurchaseManager = SimplePurchaseManager(
        entitlementManager: SimpleEntitlementManager.shared
    )
    
    // Legacy implementation (for comparison)
    @ObservedObject private var legacySubscription = SubscriptionEntitlementService.shared
    @ObservedObject private var legacyFeatureGate = FeatureGateService.shared
    
    public var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab 1: Configuration
                configurationTab
                    .tabItem {
                        Label("Config", systemImage: "gearshape")
                    }
                    .tag(0)
                
                // Tab 2: State Comparison
                stateComparisonTab
                    .tabItem {
                        Label("State", systemImage: "chart.bar")
                    }
                    .tag(1)
                
                // Tab 3: Feature Testing
                featureTestingTab
                    .tabItem {
                        Label("Features", systemImage: "star")
                    }
                    .tag(2)
                
                // Tab 4: Automated Tests
                automatedTestsTab
                    .tabItem {
                        Label("Tests", systemImage: "checkmark.circle")
                    }
                    .tag(3)
            }
            .navigationTitle("StoreKit Migration Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Configuration Tab
    
    private var configurationTab: some View {
        Form {
            Section("Implementation Selection") {
                Toggle("Use Simplified Implementation", isOn: $useSimplified)
                    .onChange(of: useSimplified) { newValue in
                        if newValue {
                            StoreKitFeatureFlags.enableSimplified()
                        } else {
                            StoreKitFeatureFlags.disableSimplified()
                        }
                    }
                
                HStack {
                    Text("Current:")
                    Spacer()
                    Text(useSimplified ? "SIMPLIFIED ✅" : "LEGACY ⚠️")
                        .font(.headline)
                        .foregroundColor(useSimplified ? .green : .orange)
                }
            }
            
            Section("Quick Actions") {
                Button("Load Products") {
                    Task {
                        if useSimplified {
                            await simplePurchaseManager.loadProducts()
                        } else {
                            await PurchaseManager.shared.loadProducts()
                        }
                    }
                }
                
                Button("Restore Purchases") {
                    Task {
                        if useSimplified {
                            await simplePurchaseManager.restorePurchases()
                        } else {
                            _ = await PurchaseManager.shared.restorePurchases()
                        }
                    }
                }
                
                Button("Refresh State") {
                    Task {
                        if useSimplified {
                            await simplePurchaseManager.updatePurchasedProducts()
                        } else {
                            await SubscriptionStateManager.shared.refreshState()
                        }
                    }
                }
            }
            
            #if DEBUG
            Section("Debug Controls") {
                Button("Force Premium (Debug)") {
                    simpleEntitlements.debugSetPremium(true)
                }
                .foregroundColor(.green)
                
                Button("Clear Premium (Debug)") {
                    simpleEntitlements.debugSetPremium(false)
                }
                .foregroundColor(.red)
                
                Button("Print Debug State") {
                    SimplifiedStoreKitService.shared.debugPrintState()
                    simpleEntitlements.debugPrintState()
                }
            }
            #endif
        }
    }
    
    // MARK: - State Comparison Tab
    
    private var stateComparisonTab: some View {
        List {
            Section("Subscription Status") {
                ComparisonRow(
                    label: "Has Premium",
                    simple: simpleEntitlements.hasPremium ? "Yes" : "No",
                    legacy: legacySubscription.isSubscriptionActive ? "Yes" : "No"
                )
                
                ComparisonRow(
                    label: "Subscription Tier",
                    simple: simpleEntitlements.subscriptionTier,
                    legacy: legacySubscription.currentTier.rawValue
                )
                
                if let simpleExpiration = simpleEntitlements.expirationDate,
                   let legacyExpiration = legacySubscription.expirationDate {
                    ComparisonRow(
                        label: "Expiration",
                        simple: formatDate(simpleExpiration),
                        legacy: formatDate(legacyExpiration)
                    )
                }
            }
            
            Section("Feature Access") {
                ComparisonRow(
                    label: "AI Coach",
                    simple: simpleEntitlements.hasAICoach ? "✅" : "❌",
                    legacy: legacyFeatureGate.hasAccessBool(to: .aiCoach) ? "✅" : "❌"
                )
                
                ComparisonRow(
                    label: "Custom Routines",
                    simple: simpleEntitlements.hasCustomRoutines ? "✅" : "❌",
                    legacy: legacyFeatureGate.hasAccessBool(to: .customRoutines) ? "✅" : "❌"
                )
                
                ComparisonRow(
                    label: "Advanced Analytics",
                    simple: simpleEntitlements.hasAdvancedAnalytics ? "✅" : "❌",
                    legacy: legacyFeatureGate.hasAccessBool(to: .advancedAnalytics) ? "✅" : "❌"
                )
                
                ComparisonRow(
                    label: "All Methods",
                    simple: simpleEntitlements.hasAllMethods ? "✅" : "❌",
                    legacy: legacyFeatureGate.hasAccessBool(to: .allMethods) ? "✅" : "❌"
                )
            }
            
            Section("Products") {
                ComparisonRow(
                    label: "Products Loaded",
                    simple: "\(simplePurchaseManager.products.count)",
                    legacy: "\(PurchaseManager.shared.products.count)"
                )
                
                ComparisonRow(
                    label: "Is Loading",
                    simple: simplePurchaseManager.isLoading ? "Yes" : "No",
                    legacy: PurchaseManager.shared.isLoading ? "Yes" : "No"
                )
            }
        }
    }
    
    // MARK: - Feature Testing Tab
    
    private var featureTestingTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Test Paywall
                GroupBox("Paywall Test") {
                    VStack(spacing: 12) {
                        Text("Test the paywall presentation and purchase flow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        NavigationLink("Open Simple Paywall") {
                            SimplePaywallView()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        NavigationLink("Open Legacy Paywall") {
                            PaywallView()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Test Feature Gates
                GroupBox("Feature Gate Tests") {
                    VStack(spacing: 12) {
                        // Simple feature gate test
                        VStack {
                            Text("Simple Feature Gate:")
                                .font(.caption)
                            
                            Text("This content is gated")
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                                .simpleFeatureGated(.aiCoach)
                        }
                        
                        Divider()
                        
                        // Legacy feature gate test
                        VStack {
                            Text("Legacy Feature Gate:")
                                .font(.caption)
                            
                            Text("This content is gated")
                                .padding()
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                                .featureGated(.aiCoach)
                        }
                    }
                }
                
                // Test Conditional Access
                GroupBox("Conditional Access Test") {
                    SimpleConditionalAccessView(
                        feature: .advancedAnalytics,
                        content: {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text("Analytics Unlocked!")
                                    .font(.headline)
                            }
                            .padding()
                        },
                        locked: {
                            VStack {
                                Image(systemName: "lock.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Analytics Locked")
                                    .font(.headline)
                                SimplePremiumBadge()
                            }
                            .padding()
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Automated Tests Tab
    
    private var automatedTestsTab: some View {
        VStack {
            if isRunningTests {
                ProgressView("Running Tests...")
                    .padding()
            } else {
                List(testResults) { result in
                    HStack {
                        Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.passed ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .font(.headline)
                            
                            if let message = result.message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Button("Run All Tests") {
                    runAutomatedTests()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func runAutomatedTests() {
        isRunningTests = true
        testResults = []
        
        Task {
            // Test 1: Products Loading
            await testProductsLoading()
            
            // Test 2: Feature Access Consistency
            testFeatureAccessConsistency()
            
            // Test 3: Purchase State Persistence
            await testPurchaseStatePersistence()
            
            // Test 4: Feature Flag Toggle
            testFeatureFlagToggle()
            
            // Test 5: Entitlement Updates
            await testEntitlementUpdates()
            
            isRunningTests = false
        }
    }
    
    private func testProductsLoading() async {
        await simplePurchaseManager.loadProducts()
        
        let result = TestResult(
            name: "Products Loading",
            passed: !simplePurchaseManager.products.isEmpty,
            message: "Loaded \(simplePurchaseManager.products.count) products"
        )
        
        await MainActor.run {
            testResults.append(result)
        }
    }
    
    private func testFeatureAccessConsistency() {
        let aiCoachMatch = simpleEntitlements.hasAICoach == legacyFeatureGate.hasAccessBool(to: .aiCoach)
        
        let result = TestResult(
            name: "Feature Access Consistency",
            passed: aiCoachMatch,
            message: aiCoachMatch ? "Implementations match" : "Mismatch detected!"
        )
        
        testResults.append(result)
    }
    
    private func testPurchaseStatePersistence() async {
        let initialState = simpleEntitlements.hasPremium
        
        // Force refresh
        await simplePurchaseManager.updatePurchasedProducts()
        
        let finalState = simpleEntitlements.hasPremium
        
        let result = TestResult(
            name: "State Persistence",
            passed: initialState == finalState,
            message: "State remained consistent after refresh"
        )
        
        await MainActor.run {
            testResults.append(result)
        }
    }
    
    private func testFeatureFlagToggle() {
        let initial = StoreKitFeatureFlags.useSimplifiedImplementation
        
        StoreKitFeatureFlags.disableSimplified()
        let afterDisable = StoreKitFeatureFlags.useSimplifiedImplementation
        
        StoreKitFeatureFlags.enableSimplified()
        let afterEnable = StoreKitFeatureFlags.useSimplifiedImplementation
        
        // Restore initial state
        if initial {
            StoreKitFeatureFlags.enableSimplified()
        } else {
            StoreKitFeatureFlags.disableSimplified()
        }
        
        let result = TestResult(
            name: "Feature Flag Toggle",
            passed: !afterDisable && afterEnable,
            message: "Feature flag toggles correctly"
        )
        
        testResults.append(result)
    }
    
    private func testEntitlementUpdates() async {
        // This would test actual purchase flow in a real scenario
        // For now, we'll test the update mechanism
        
        let testProductIDs: Set<String> = ["premium_monthly"]
        simpleEntitlements.updateFromPurchases(testProductIDs)
        
        let hasUpdated = simpleEntitlements.hasPremium
        
        // Clear test state
        simpleEntitlements.clearEntitlements()
        
        let result = TestResult(
            name: "Entitlement Updates",
            passed: hasUpdated,
            message: "Entitlements update correctly from purchases"
        )
        
        await MainActor.run {
            testResults.append(result)
        }
    }
}

// MARK: - Supporting Views

struct ComparisonRow: View {
    let label: String
    let simple: String
    let legacy: String
    
    var matches: Bool {
        simple == legacy
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Simple:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(simple)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Legacy:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(legacy)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Image(systemName: matches ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(matches ? .green : .orange)
        }
    }
}

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let passed: Bool
    let message: String?
}

// MARK: - Preview

struct SimpleMigrationTestView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleMigrationTestView()
    }
}