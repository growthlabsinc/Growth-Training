/**
 * STOREKIT_MIGRATION_IMPLEMENTATION.swift
 * 
 * This file demonstrates how to migrate existing views from the old complex
 * StoreKit implementation to the new simplified version.
 * 
 * Copy these code snippets into the appropriate files to complete the migration.
 */

// ============================================================================
// MARK: - 1. Update CoachChatView.swift
// ============================================================================

// Replace line 56:
// OLD: .featureGated(.aiCoach)
// NEW: .simpleFeatureGated(.aiCoach)

/*
 In CoachChatView.swift, update the feature gate:
 
 OLD CODE (line 56):
 ```swift
 .featureGated(.aiCoach)
 ```
 
 NEW CODE:
 ```swift
 .simpleFeatureGated(.aiCoach)
 ```
*/

// ============================================================================
// MARK: - 2. Update CreateCustomRoutineView.swift
// ============================================================================

// Replace line 73:
// OLD: .featureGated(.customRoutines)
// NEW: .simpleFeatureGated(.customRoutines)

/*
 In CreateCustomRoutineView.swift, update the feature gate:
 
 OLD CODE (line 73):
 ```swift
 .featureGated(.customRoutines)
 ```
 
 NEW CODE:
 ```swift
 .simpleFeatureGated(.customRoutines)
 ```
*/

// ============================================================================
// MARK: - 3. Update SettingsView.swift for Simplified Subscription Management
// ============================================================================

/*
 Replace the subscription section in SettingsView.swift with this simplified version:
 
 OLD CODE (lines 14-17):
 ```swift
 @StateObject private var subscriptionService = SubscriptionEntitlementService.shared
 @StateObject private var featureAccess = FeatureAccessViewModel()
 @StateObject private var paywallCoordinator = PaywallCoordinator.shared
 ```
 
 NEW CODE:
 ```swift
 @ObservedObject private var entitlements = SimpleEntitlementManager.shared
 @StateObject private var purchaseManager = SimplePurchaseManager(
     entitlementManager: SimpleEntitlementManager.shared
 )
 @State private var showingPaywall = false
 ```
 
 Then replace the subscription section (lines 55-150) with:
*/

struct SimplifiedSubscriptionSection: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        Section(header: Text("Subscription").font(AppTheme.Typography.gravitySemibold(13))) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(entitlements.hasPremium ? Color("GrowthGreen") : .gray)
                    .frame(width: 25, height: 25)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill((entitlements.hasPremium ? Color("GrowthGreen") : .gray).opacity(0.2))
                            .frame(width: 30, height: 30)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Plan")
                        .font(AppTheme.Typography.gravityBook(14))
                        .padding(.leading, 5)
                    
                    Text(entitlements.hasPremium ? "Premium" : "Free")
                        .font(AppTheme.Typography.gravitySemibold(13))
                        .foregroundColor(entitlements.hasPremium ? Color("GrowthGreen") : Color("TextSecondaryColor"))
                        .padding(.leading, 5)
                }
                
                Spacer()
                
                if entitlements.hasPremium {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Active")
                            .font(AppTheme.Typography.gravitySemibold(12))
                            .foregroundColor(Color("GrowthGreen"))
                        
                        if let expirationDate = entitlements.expirationDate {
                            Text("Until \(expirationDate, formatter: dateFormatter)")
                                .font(AppTheme.Typography.gravityBook(10))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Upgrade button for free users
            if !entitlements.hasPremium {
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.white)
                            .frame(width: 25, height: 25)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: 30, height: 30)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(Color("TextColor"))
                                .padding(.leading, 5)
                            
                            Text("Unlock all features")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("TextSecondaryColor"))
                                .padding(.leading, 5)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color("TextSecondaryColor"))
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Restore purchases button
            Button(action: {
                Task {
                    await SimplePurchaseManager(
                        entitlementManager: SimpleEntitlementManager.shared
                    ).restorePurchases()
                }
            }) {
                settingRow(
                    title: "Restore Purchases", 
                    icon: "arrow.clockwise", 
                    color: .blue
                )
            }
        }
        .sheet(isPresented: $showingPaywall) {
            SimplePaywallView()
        }
    }
}

// ============================================================================
// MARK: - 4. Create New AI Coach Tab View with Simple Feature Gating
// ============================================================================

struct SimpleAICoachTabView: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    
    var body: some View {
        if entitlements.hasAICoach {
            CoachChatView()
        } else {
            SimplePaywallView()
        }
    }
}

// ============================================================================
// MARK: - 5. Analytics Feature Gate Example
// ============================================================================

struct SimpleAnalyticsView: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic stats always available
                BasicStatsCard()
                
                // Advanced analytics - premium only
                if entitlements.hasAdvancedAnalytics {
                    AdvancedAnalyticsSection()
                } else {
                    // Premium prompt card
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("Advanced Analytics")
                            .font(.headline)
                        
                        Text("Upgrade to Premium to unlock detailed insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // Show paywall
                        }) {
                            Label("Unlock Premium", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

// ============================================================================
// MARK: - 6. Custom Routines Feature Gate Example
// ============================================================================

struct SimpleRoutinesListView: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    @State private var showingPaywall = false
    @State private var showingCreateRoutine = false
    
    var body: some View {
        List {
            // Preset routines - always available
            Section("Preset Routines") {
                ForEach(presetRoutines) { routine in
                    RoutineRow(routine: routine)
                }
            }
            
            // Custom routines section
            Section("Custom Routines") {
                if entitlements.hasCustomRoutines {
                    // Create button
                    Button(action: {
                        showingCreateRoutine = true
                    }) {
                        Label("Create Custom Routine", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    
                    // User's custom routines
                    ForEach(customRoutines) { routine in
                        RoutineRow(routine: routine)
                    }
                } else {
                    // Premium prompt
                    Button(action: {
                        showingPaywall = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Custom Routines", systemImage: "lock.fill")
                                    .font(.headline)
                                
                                Text("Create personalized training plans")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            SimplePremiumBadge()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            SimplePaywallView()
        }
        .sheet(isPresented: $showingCreateRoutine) {
            CreateCustomRoutineView()
        }
    }
}

// ============================================================================
// MARK: - 7. Method Selection with Free Tier Limits
// ============================================================================

struct SimpleMethodSelectionView: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    @Binding var selectedMethods: Set<String>
    @State private var showingPaywall = false
    
    let allMethods = ["Method1", "Method2", "Method3", "Method4", "Method5", "Method6"]
    
    var maxFreeMethods: Int {
        entitlements.hasAllMethods ? Int.max : 3
    }
    
    var body: some View {
        List {
            Section {
                ForEach(allMethods, id: \.self) { method in
                    HStack {
                        // Method info
                        VStack(alignment: .leading) {
                            Text(method)
                                .font(.headline)
                            Text("Method description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Selection state
                        if selectedMethods.contains(method) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else if !entitlements.hasAllMethods && selectedMethods.count >= maxFreeMethods {
                            // Show lock for additional methods when limit reached
                            Button(action: {
                                showingPaywall = true
                            }) {
                                SimplePremiumBadge()
                            }
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedMethods.contains(method) {
                            selectedMethods.remove(method)
                        } else if entitlements.hasAllMethods || selectedMethods.count < maxFreeMethods {
                            selectedMethods.insert(method)
                        } else {
                            showingPaywall = true
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Available Methods")
                    Spacer()
                    if !entitlements.hasAllMethods {
                        Text("\(selectedMethods.count)/\(maxFreeMethods)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                if !entitlements.hasAllMethods {
                    Text("Free users can select up to \(maxFreeMethods) methods. Upgrade to Premium for unlimited access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            SimplePaywallView()
        }
    }
}

// ============================================================================
// MARK: - 8. Dashboard Integration Example
// ============================================================================

struct SimpleDashboardView: View {
    @ObservedObject private var entitlements = SimpleEntitlementManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's session - always available
                TodaySessionCard()
                
                // Quick stats - always available
                QuickStatsCard()
                
                // AI Coach Card - show different states
                if entitlements.hasAICoach {
                    AICoachActiveCard()
                } else {
                    AICoachPromoCard()
                }
                
                // Analytics preview
                SimpleConditionalAccessView(
                    feature: .advancedAnalytics,
                    content: {
                        AnalyticsPreviewCard()
                    },
                    locked: {
                        LockedFeatureCard(
                            title: "Advanced Analytics",
                            description: "Track detailed progress metrics",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                )
            }
            .padding()
        }
    }
}

// ============================================================================
// MARK: - 9. Testing the Migration in Debug Mode
// ============================================================================

struct DebugMigrationTestView: View {
    @State private var useSimplified = StoreKitFeatureFlags.useSimplifiedImplementation
    
    var body: some View {
        VStack(spacing: 20) {
            Text("StoreKit Implementation Test")
                .font(.largeTitle)
            
            Toggle("Use Simplified Implementation", isOn: $useSimplified)
                .onChange(of: useSimplified) { newValue in
                    if newValue {
                        StoreKitFeatureFlags.enableSimplified()
                    } else {
                        StoreKitFeatureFlags.disableSimplified()
                    }
                }
            
            Text("Current: \(useSimplified ? "SIMPLIFIED" : "LEGACY")")
                .font(.headline)
                .foregroundColor(useSimplified ? .green : .orange)
            
            #if DEBUG
            Button("Debug Print State") {
                SimplifiedStoreKitService.shared.debugPrintState()
            }
            
            Button("Force Premium (Debug)") {
                SimpleEntitlementManager.shared.debugSetPremium(true)
            }
            
            Button("Clear Premium (Debug)") {
                SimpleEntitlementManager.shared.debugSetPremium(false)
            }
            #endif
            
            Divider()
            
            // Test views
            Group {
                NavigationLink("Test Paywall") {
                    SimplePaywallView()
                }
                
                NavigationLink("Test Feature Gate") {
                    TestFeatureGateView()
                }
                
                NavigationLink("Test Settings") {
                    SimplifiedSubscriptionSection()
                }
            }
        }
        .padding()
    }
}

struct TestFeatureGateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Coach Feature")
                .simpleFeatureGated(.aiCoach)
            
            Text("Custom Routines Feature")
                .simpleFeatureGated(.customRoutines)
            
            Text("Analytics Feature")
                .simpleFeatureGated(.advancedAnalytics)
        }
        .padding()
    }
}

// ============================================================================
// MARK: - Helper Components Used Above
// ============================================================================

struct BasicStatsCard: View {
    var body: some View {
        VStack {
            Text("Basic Stats")
            // Implementation
        }
    }
}

struct AdvancedAnalyticsSection: View {
    var body: some View {
        VStack {
            Text("Advanced Analytics")
            // Implementation
        }
    }
}

struct TodaySessionCard: View {
    var body: some View {
        VStack {
            Text("Today's Session")
            // Implementation
        }
    }
}

struct QuickStatsCard: View {
    var body: some View {
        VStack {
            Text("Quick Stats")
            // Implementation
        }
    }
}

struct AICoachActiveCard: View {
    var body: some View {
        VStack {
            Text("AI Coach Active")
            // Implementation
        }
    }
}

struct AICoachPromoCard: View {
    var body: some View {
        VStack {
            Text("Try AI Coach")
            // Implementation
        }
    }
}

struct AnalyticsPreviewCard: View {
    var body: some View {
        VStack {
            Text("Analytics Preview")
            // Implementation
        }
    }
}

struct LockedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(title)
            Text(description)
            // Implementation
        }
    }
}

struct RoutineRow: View {
    let routine: String // Replace with actual Routine model
    
    var body: some View {
        HStack {
            Text(routine)
            // Implementation
        }
    }
}

// Placeholder properties
let presetRoutines = ["Routine 1", "Routine 2"]
let customRoutines = ["Custom 1", "Custom 2"]
let dateFormatter = DateFormatter()

func settingRow(title: String, icon: String, color: Color) -> some View {
    HStack {
        Image(systemName: icon)
            .foregroundColor(color)
        Text(title)
        Spacer()
    }
}