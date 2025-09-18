//
//  SettingsView.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import SwiftUI
import FirebaseAuth
import Foundation  // For Logger
import StoreKit
import Combine

/// Settings view for the app
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManager
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @State private var showingPaywall = false
    @State private var showLogoutAlert = false
    @State private var showResetSessionsAlert = false
    @State private var sessionsResetSuccess = false
    @State private var userData: User?
    @State private var isLoadingUser = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            // User Account Section
            if let user = Auth.auth().currentUser {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("GrowthGreen"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userData?.firstName ?? user.displayName ?? "User")
                                .font(AppTheme.Typography.gravitySemibold(16))
                                .foregroundColor(Color("TextColor"))
                            Text(user.email ?? "")
                                .font(AppTheme.Typography.gravityBook(13))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    NavigationLink {
                        AccountView(authViewModel: authViewModel)
                    } label: {
                        settingRow(title: "Account Settings", icon: "person.crop.circle", color: Color("GrowthGreen"))
                    }
                }
                .listRowBackground(Color("FormSectionBackground"))
            }
            
            // Subscription Section
            //
            Section(header: Text("Subscription")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
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
                            
                            // Simplified entitlement manager doesn't track expiration dates
                            // This information would come from StoreKit Transaction.currentEntitlements
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Manage Subscription button for premium users
                if entitlements.hasPremium {
                    Button(action: {
                        Task {
                            await openSubscriptionManagement()
                        }
                    }) {
                        settingRow(
                            title: "Manage Subscription",
                            icon: "creditcard.fill",
                            color: .blue
                        )
                    }
                }
                
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
                        do {
                            try await purchaseManager.restorePurchases()
                        } catch {
                            print("Failed to restore purchases: \(error)")
                        }
                    }
                }) {
                    settingRow(
                        title: "Restore Purchases", 
                        icon: "arrow.clockwise", 
                        color: .blue
                    )
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Feature Access Section
            Section(header: Text("Feature Access")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                // AI Coach
                HStack {
                    Text("AI Coach")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    if entitlements.hasPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 2)
                
                // Custom Routines
                HStack {
                    Text("Custom Routines")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    if entitlements.hasPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 2)
                
                // Advanced Analytics
                HStack {
                    Text("Advanced Analytics")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    if entitlements.hasPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 2)
                
                // Advanced Timer
                HStack {
                    Text("Advanced Timer")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    if entitlements.hasPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // App Settings Section
            Section(header: Text("Preferences")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    NotificationPreferencesView()
                } label: {
                    settingRow(title: "Notifications", icon: "bell.fill", color: .blue)
                }
                
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    settingRow(title: "Appearance", icon: "paintbrush.fill", color: .purple)
                }
                
                NavigationLink {
                    UnitsSettingsView()
                } label: {
                    settingRow(title: "Units & Measurements", icon: "ruler.fill", color: .orange)
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Security Section
            Section(header: Text("Security")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    BiometricSettingsView()
                } label: {
                    settingRow(title: "Face ID & Passcode", icon: "faceid", color: .indigo)
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Data & Privacy Section
            Section(header: Text("Data & Privacy")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    ExportDataView()
                } label: {
                    settingRow(title: "Export My Data", icon: "square.and.arrow.up", color: .green)
                }
                
                NavigationLink {
                    BackupRestoreView()
                } label: {
                    settingRow(title: "Backup & Restore", icon: "icloud.and.arrow.up", color: .blue)
                }
                
                NavigationLink {
                    DeleteAccountView()
                } label: {
                    settingRow(title: "Delete Account", icon: "trash.fill", color: .red)
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Support Section
            Section(header: Text("Support")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    HelpCenterView()
                } label: {
                    settingRow(title: "Help Center", icon: "questionmark.circle.fill", color: .blue)
                }
                
                NavigationLink {
                    ContactSupportView()
                } label: {
                    settingRow(title: "Contact Support", icon: "envelope.fill", color: .green)
                }
                
                NavigationLink {
                    FAQView()
                } label: {
                    settingRow(title: "FAQ", icon: "book.fill", color: .purple)
                }
                
                NavigationLink {
                    AllCitationsView()
                        .navigationTitle("Scientific References")
                } label: {
                    settingRow(title: "Scientific References", icon: "text.book.closed.fill", color: Color("GrowthGreen"))
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Legal Section
            Section(header: Text("Legal")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    LegalDocumentView(documentId: "privacy_policy")
                        .navigationTitle("Privacy Policy")
                } label: {
                    settingRow(title: "Privacy Policy", icon: "hand.raised.fill", color: .gray)
                }
                
                NavigationLink {
                    LegalDocumentView(documentId: "terms_of_use")
                        .navigationTitle("Terms of Use")
                } label: {
                    settingRow(title: "Terms of Use", icon: "doc.text.fill", color: .gray)
                }
                
                NavigationLink {
                    LegalDocumentView(documentId: "disclaimer")
                        .navigationTitle("Medical Disclaimer")
                } label: {
                    settingRow(title: "Medical Disclaimer", icon: "exclamationmark.triangle.fill", color: Color("ErrorColor"))
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // About Section
            Section(header: Text("About")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    AboutView()
                } label: {
                    settingRow(title: "About Growth", icon: "info.circle.fill", color: .blue)
                }
                
                HStack {
                    Text("Version")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    Text(getAppVersion())
                        .foregroundColor(Color("TextSecondaryColor"))
                        .font(AppTheme.Typography.gravityBook(13))
                }
                
                HStack {
                    Text("Build")
                        .font(AppTheme.Typography.gravityBook(14))
                    Spacer()
                    Text(getBuildNumber())
                        .foregroundColor(Color("TextSecondaryColor"))
                        .font(AppTheme.Typography.gravityBook(13))
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            
            // Admin Section - Only shown for admin users
            if userData?.isAdmin == true {
                Section(header: Text("Admin Tools")
                    .font(AppTheme.Typography.gravitySemibold(13))
                    .foregroundColor(Color("TextColor"))) {
                    NavigationLink {
                        ReportManagementView()
                    } label: {
                        settingRow(title: "Report Management", icon: "exclamationmark.shield.fill", color: .orange)
                    }
                }
                .listRowBackground(Color("FormSectionBackground"))
            }
            
            // Development Tools Section
            #if DEBUG
            Section(header: Text("Development Tools")
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(Color("TextColor"))) {
                NavigationLink {
                    Text("Mock Data Manager").navigationTitle("Mock Data")
                } label: {
                    settingRow(title: "Mock Data Manager", icon: "hammer.fill", color: .orange)
                }
                
                NavigationLink {
                    SubscriptionDebugView()
                } label: {
                    settingRow(title: "Subscription Debug", icon: "wrench.fill", color: .orange)
                }
                
                Button(action: {
                    showResetSessionsAlert = true
                }) {
                    settingRow(title: "Reset Today's Sessions", icon: "arrow.clockwise.circle", color: .red)
                }
                
                // StoreKit Debug - Available in debug builds
                NavigationLink {
                    StoreKitDebugView()
                } label: {
                    settingRow(title: "StoreKit Debug Info", icon: "ladybug.fill", color: .purple)
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
            #endif
            
            // Log Out Section
            Section {
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            .listRowBackground(Color("FormSectionBackground"))
        }
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Reset Today's Sessions", isPresented: $showResetSessionsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetTodaysSessions()
            }
        } message: {
            Text("This will clear all completed methods for today. You'll be able to complete them again.")
        }
        .alert("Success", isPresented: $sessionsResetSuccess) {
            Button("OK") { }
        } message: {
            Text("Today's completed sessions have been reset successfully.")
        }
        .sheet(isPresented: $showingPaywall) {
            StoreKit2PaywallView()
                .presentationDetents([.large])
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - User Data Loading
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoadingUser = true
        UserService.shared.fetchUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoadingUser = false
                switch result {
                case .success(let user):
                    self.userData = user
                    print("SettingsView: Loaded user firstName: '\(user.firstName ?? "nil")'")
                case .failure(let error):
                    print("SettingsView: Failed to load user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Create a consistent row for settings items
    private func settingRow(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 25, height: 25)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.opacity(0.2))
                        .frame(width: 30, height: 30)
                )
            
            Text(title).font(AppTheme.Typography.gravityBook(14))
                .padding(.leading, 5)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Open App Store subscription management page
    private func openSubscriptionManagement() async {
        do {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                try await AppStore.showManageSubscriptions(in: windowScene)
            }
        } catch {
            // If the above fails, try opening the App Store subscriptions URL directly
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await UIApplication.shared.open(url)
            }
        }
    }
    
    /// Log out the user
    private func logOut() {
        authViewModel.signOut()
        // Navigation will be handled by MainView based on auth state
    }
    
    private func resetTodaysSessions() {
        guard let userId = authViewModel.user?.id else {
            return
        }
        
        // Get today's cache key components
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)
        
        // Clear all possible cache keys for today (with and without routine ID)
        let possibleKeys = [
            "completedMethods_\(dateString)_none",
            "completedMethods_\(dateString)"
        ]
        
        // Also check for any routine-specific keys
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.starts(with: "completedMethods_\(dateString)") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // Clear the main keys
        for key in possibleKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset the completion state in Firebase RoutineProgress
        // This is crucial for when the day has been marked as complete
        UserService.shared.fetchSelectedRoutineId(userId: userId) { routineId in
            if let routineId = routineId {
                RoutineProgressService.shared.resetTodaysCompletion(userId: userId, routineId: routineId) { _ in
                    Logger.debug("Reset day completion in Firebase RoutineProgress for routine: \(routineId)")
                }
            }
        }
        
        // Also clear any session logs for today
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        FirestoreService.shared.getSessionLogsForDateRange(
            userId: userId,
            startDate: startOfDay,
            endDate: endOfDay
        ) { (logs, error) in
            // Delete each session log if no error occurred
            if error == nil {
                for log in logs {
                    SessionService.shared.deleteSessionLog(logId: log.id) { _ in }
                }
            }
            
            // Post notifications to update UI
            DispatchQueue.main.async {
                // Post multiple notifications to ensure all views update
                NotificationCenter.default.post(name: .routineProgressUpdated, object: nil)
                NotificationCenter.default.post(name: .sessionLogged, object: nil)
                
                // Also post a specific notification for session reset
                NotificationCenter.default.post(name: Notification.Name("sessionsReset"), object: nil)
                
                // Force refresh of practice tab by posting with a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .sessionLogged, object: nil, userInfo: ["action": "reset"])
                }
                
                self.sessionsResetSuccess = true
            }
        }
    }
    
    /// Get app version from Info.plist
    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Get build number from Info.plist
    private func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Date formatter for subscription expiration display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            // AuthViewModel would be provided by the parent view in production
    }
}