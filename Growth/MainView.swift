//
//  MainView.swift
//  GrowthTraining
//
//  Created by Developer on 5/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import UIKit
import Foundation  // For Logger


// MARK: - Update placeholder views to use the AppLogo component

// Placeholder view for dashboard
struct DashboardPlaceholderView: View {
    var body: some View {
        VStack {
            AppLogo(size: 60)
                .padding(.bottom, 20)
            
            Text("Dashboard")
                .font(AppTheme.Typography.largeTitleFont())
                .padding()
            Text("Coming soon...")
                .foregroundColor(.gray)
        }
    }
}

// Placeholder view for profile
struct ProfilePlaceholderView: View {
    var body: some View {
        VStack {
            AppLogo(size: 60)
                .padding(.bottom, 20)
            
            Text("Profile")
                .font(AppTheme.Typography.largeTitleFont())
                .padding()
            Text("Coming soon...")
                .foregroundColor(.gray)
        }
    }
}

// Placeholder view for stats
struct StatsPlaceholderView: View {
    var body: some View {
        VStack {
            AppLogo(size: 60)
                .padding(.bottom, 20)
            
            Text("Stats")
                .font(AppTheme.Typography.largeTitleFont())
                .padding()
            Text("Coming soon...")
                .foregroundColor(.gray)
        }
    }
}

struct MainView: View {
    // State for managing Firebase connection status
    @State private var showConnectionError: Bool = false
    @State private var connectionError: String = "Failed to connect to Firebase. Please check your internet connection and try again."
    @State private var retryCount: Int = 0
    
    // Get the AuthViewModel from the environment instead of creating a new instance
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Get the ThemeManager from the environment
    @EnvironmentObject var themeManager: ThemeManager
    
    // Subscription state management
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    
    // Splash screen state - bypass if already authenticated
    @State private var showSplash: Bool
    @State private var showValueProposition = false
    @State private var showDisclaimer = false
    @State private var showPrivacyTerms = false
    @State private var showCreateAccount = false
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    // Affirmation overlay properties
    @State private var globalAffirmation: Affirmation?
    @State private var showGlobalAffirmation = false
    private let affirmationService = AffirmationService.shared
    
    // Session completion service for global prompts
    @StateObject private var sessionCompletionService = SessionCompletionService.shared
    
    init() {
        // Initialize routinesViewModel with empty string - will be updated when auth state changes
        self._routinesViewModel = StateObject(wrappedValue: RoutinesViewModel(userId: ""))
        
        // Always show splash initially - will be updated based on auth state
        self._showSplash = State(initialValue: true)
    }
    
    // MARK: - Tab Handling (Story 15.1 - New IA)
    enum Tab: Hashable {
        case home, routines, practice, progress, learn

        var filledIconName: String {
            switch self {
            case .home: return "house.fill"
            case .routines: return "list.bullet.rectangle.fill"
            case .practice: return "play.circle.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .learn: return "book.fill"
            }
        }

        var outlineIconName: String {
            switch self {
            case .home: return "house"
            case .routines: return "list.bullet.rectangle"
            case .practice: return "play.circle"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .learn: return "book"
            }
        }
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .routines: return "Routines"
            case .practice: return "Practice"
            case .progress: return "Progress"
            case .learn: return "Learn"
            }
        }
    }

    @State private var selectedTab: Tab = .home
    @State private var practiceTabStartGuided: Bool = false
    @State private var practiceTabShowCompletion: Bool = false
    @State private var showPaywall: Bool = false
    
    // Navigation context for smart navigation
    @StateObject private var navigationContext = NavigationContext()
    @StateObject private var smartNavigationService = SmartNavigationService()
    
    // Shared ViewModels for consistency across tabs - will be initialized when authenticated
    @StateObject private var routinesViewModel: RoutinesViewModel
    
    // App Tour ViewModel
    @StateObject private var appTourViewModel = AppTourViewModel()
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView(
                    onGetStarted: { 
                        showSplash = false
                        showValueProposition = true
                    },
                    onLogin: { showSplash = false }
                )
                .environmentObject(authViewModel)
            } else if showValueProposition {
                ValuePropositionView(
                    onContinue: {
                        showValueProposition = false
                        showDisclaimer = true
                    }
                )
                .environmentObject(authViewModel)
            } else if showDisclaimer {
                DisclaimerView(
                    onAccepted: {
                        showDisclaimer = false
                        showPrivacyTerms = true
                    },
                    onBack: {
                        showDisclaimer = false
                        showValueProposition = true
                    }
                )
                .environmentObject(authViewModel)
            } else if showPrivacyTerms {
                NavigationStack {
                    PrivacyTermsConsentView(
                        onNext: {
                            showPrivacyTerms = false
                            showCreateAccount = true
                        },
                        onBack: {
                            showPrivacyTerms = false
                            showDisclaimer = true
                        }
                    )
                }
                .environmentObject(authViewModel)
            } else if showCreateAccount && !authViewModel.isAuthenticated {
                NavigationStack {
                    CreateAccountView(showCreateAccount: Binding<Bool?>(
                        get: { showCreateAccount },
                        set: { showCreateAccount = $0 ?? false }
                    ))
                }
                .environmentObject(authViewModel)
            } else if authViewModel.isAuthenticated {
                // Check if onboarding is complete
                if onboardingViewModel.isCheckingStatus {
                    // Show loading while checking onboarding status
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.top)
                        Spacer()
                    }
                } else if onboardingViewModel.isOnboardingComplete {
                    // Main app content when user is authenticated and onboarding is complete
                    mainContent
                        .onAppear {
                            // Ensure routines are loaded when transitioning from onboarding
                            if let userId = Auth.auth().currentUser?.uid {
                                Logger.info("MainView: Onboarding complete, ensuring routine data is loaded for user: \(userId)")
                                routinesViewModel.updateUser(userId)
                                routinesViewModel.fetchSelectedRoutineId()
                            }
                        }
                } else {
                    // Show onboarding flow for authenticated users who haven't completed it
                    OnboardingFlowCoordinator(viewModel: onboardingViewModel)
                }
            } else {
                // Authentication flow when user is not authenticated
                authenticationFlow
            }
            
            // Error overlay
            if showConnectionError {
                connectionErrorOverlay
            }
            
            // Global affirmation overlay at the bottom
            VStack {
                Spacer()
                if let affirmation = globalAffirmation {
                    AffirmationView(affirmation: affirmation, isPresented: $showGlobalAffirmation)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        }
        // Global session completion prompt
        .sheet(isPresented: $sessionCompletionService.showCompletionPrompt) {
            if let pending = sessionCompletionService.pendingCompletion,
               pending.completionViewModel.sessionLog != nil {
                SessionCompletionPromptView(
                    sessionProgress: pending.sessionProgress,
                    onLog: {
                        // Save session
                        pending.completionViewModel.saveSession()
                        
                        // Stop the timer first to ensure clean state
                        pending.timerService.stop()
                        
                        // Check the session type to handle different flows
                        if pending.sessionProgress.sessionType == .quickPractice {
                            // Quick practice flow - clear state and hide completion
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                BackgroundTimerTracker.shared.clearSavedState()
                                sessionCompletionService.hideCompletion()
                            }
                        } else if pending.sessionProgress.sessionType == .single {
                            // Single method timer flow - clear state and hide completion
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                BackgroundTimerTracker.shared.clearSavedState()
                                sessionCompletionService.hideCompletion()
                            }
                        } else if let sessionViewModel = pending.sessionViewModel,
                                  sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Multi-method flow with more methods to complete
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod,
                                   let configureTimer = pending.configureTimerForMethod {
                                    configureTimer(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        } else {
                            // All methods completed - reset state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                BackgroundTimerTracker.shared.clearSavedState()
                                // Reset completion tracking flags
                                pending.hasHandledTimerCompletion?.wrappedValue = false
                                pending.isShowingCompletionPrompt?.wrappedValue = false
                                // Hide the global completion prompt
                                sessionCompletionService.hideCompletion()
                            }
                        }
                    },
                    onDismiss: {
                        pending.completionViewModel.skipLogging()
                        
                        // Stop the timer and clear state when dismissing after completion
                        pending.timerService.stop()
                        
                        // Check session type for proper cleanup
                        if pending.sessionProgress.sessionType == .quickPractice {
                            BackgroundTimerTracker.shared.clearSavedState()
                        } else {
                            BackgroundTimerTracker.shared.clearSavedState()
                        }
                        
                        // Reset the completion state for the current method since it wasn't logged
                        if let sessionViewModel = pending.sessionViewModel,
                           let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.resetMethodCompletion(methodId)
                        }
                        
                        // Reset completion tracking flags
                        pending.hasHandledTimerCompletion?.wrappedValue = false
                        pending.isShowingCompletionPrompt?.wrappedValue = false
                        // Post notification that session was dismissed without logging
                        NotificationCenter.default.post(name: .sessionDismissedWithoutLogging, object: nil)
                        // Hide the global completion prompt
                        sessionCompletionService.hideCompletion()
                    },
                    onPartialLog: pending.sessionProgress.isPartiallyComplete ? {
                        // Log partial progress without navigating away
                        pending.completionViewModel.skipLogging()
                        
                        // Stop the timer first to ensure clean state
                        pending.timerService.stop()
                        
                        // Check if there are more methods to complete
                        if let sessionViewModel = pending.sessionViewModel,
                           sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod,
                                   let configureTimer = pending.configureTimerForMethod {
                                    configureTimer(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        }
                        // Hide the global completion prompt
                        sessionCompletionService.hideCompletion()
                    } : nil
                )
                .interactiveDismissDisabled() // Prevent swipe to dismiss
            }
        }
        .onAppear {
            // Update showSplash based on current auth state
            showSplash = !authViewModel.isAuthenticated
            
            // Update routinesViewModel with current user ID if authenticated
            if let userId = authViewModel.user?.id {
                routinesViewModel.updateUser(userId)
            }
            
            // Delay Firebase connection test to ensure initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                FirebaseClient.shared.testConnection { success, errorMessage in
                    if !success {
                        // Only show error if it's not just an initialization timing issue
                        if errorMessage != "Firebase not initialized" {
                            showConnectionError = true
                            connectionError = "Firebase connection failed: \(errorMessage ?? "Unknown error")"
                        }
                    }
                }
            }
            
            // Check onboarding status for already authenticated users
            if authViewModel.isAuthenticated {
                onboardingViewModel.checkOnboardingStatus()
            }
        }
        // Listen for affirmations published elsewhere
        .onReceive(affirmationService.$latestAffirmation) { affirmation in
            guard let affirmation = affirmation else { return }
            globalAffirmation = affirmation
            showGlobalAffirmation = true
        }
        // Listen for tab switching notifications
        .onReceive(NotificationCenter.default.publisher(for: .switchToPracticeTab)) { notification in
            selectedTab = .practice
            if let userInfo = notification.userInfo {
                if let startGuided = userInfo["startGuided"] as? Bool {
                    practiceTabStartGuided = startGuided
                }
                if let showCompletion = userInfo["showCompletion"] as? Bool {
                    practiceTabShowCompletion = showCompletion
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToProgressTab)) { _ in
            selectedTab = .progress
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToRoutinesTab)) { _ in
            selectedTab = .routines
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("switchToSubscriptionTab"))) { _ in
            // Show paywall as a sheet instead of switching tabs
            showPaywall = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAppTour)) { _ in
            // Switch to home tab first
            selectedTab = .home
            // Trigger the app tour
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appTourViewModel.startTour()
                // Note: Tab frames will be set up by the onChange handler in mainContent
            }
        }
        // Reset onboarding flow when user becomes authenticated
        .onChangeCompat(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Reset all onboarding states
                showSplash = false
                showValueProposition = false
                showDisclaimer = false
                showPrivacyTerms = false
                showCreateAccount = false
                
                // Update routines view model with the new user ID
                if let userId = authViewModel.user?.id ?? Auth.auth().currentUser?.uid {
                    routinesViewModel.updateUser(userId)
                    
                    // Check onboarding status for the new user
                    onboardingViewModel.checkOnboardingStatus()
                }
            }
        }
    }
    
    // Main authenticated app content
    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $selectedTab) {
            // Home Tab (Dashboard)
            NavigationStack {
                DashboardView(routinesViewModel: routinesViewModel)
            }
            .tabItem {
                icon(for: .home)
            }
            .tag(Tab.home)

            // Routines Tab
            NavigationStack {
                RoutinesTabView(routinesViewModel: routinesViewModel)
            }
            .tabItem {
                icon(for: .routines)
            }
            .tag(Tab.routines)

            // Practice Tab (Unified)
            NavigationStack {
                PracticeTabView(routinesViewModel: routinesViewModel, startGuided: $practiceTabStartGuided, showCompletion: $practiceTabShowCompletion)
            }
            .tabItem {
                icon(for: .practice)
            }
            .tag(Tab.practice)

            // Progress Tab (Consolidated)
            NavigationStack {
                ProgressTabView()
            }
            .tabItem {
                icon(for: .progress)
            }
            .tag(Tab.progress)

            // Learn Tab
            NavigationStack {
                LearnTabView()
            }
            .tabItem {
                icon(for: .learn)
            }
            .tag(Tab.learn)
            }
            .tint(themeManager.currentAccentColor)
            .onChangeCompat(of: selectedTab) { _ in
                // Haptic feedback on tab change
                themeManager.performHapticFeedback(style: .medium)
            }
            .animation(themeManager.animation(base: .easeInOut(duration: 0.15)) ?? .easeInOut(duration: 0), value: selectedTab)
            .environmentObject(authViewModel)
            .environmentObject(navigationContext)
            .environmentObject(smartNavigationService)
            .environmentObject(appTourViewModel)
            .onChangeCompat(of: authViewModel.isAuthenticated) { newValue in
                if newValue, let userId = Auth.auth().currentUser?.uid {
                    // Update routinesViewModel with new user ID when user logs in
                    routinesViewModel.updateUser(userId)
                }
            }
            
                // App Tour Overlay
                AppTourOverlay(viewModel: appTourViewModel)
            }
            .onAppear {
                // Trigger app tour if needed when dashboard appears
                if selectedTab == .home {
                    appTourViewModel.startTourIfNeeded()
                }
                
                // Manually set tab bar item frames for app tour
                setupTabBarFramesForTour(geometry: geometry)
            }
            .onChangeCompat(of: appTourViewModel.isActive) { isActive in
                if isActive {
                    // Ensure tab frames are set up when tour becomes active
                    setupTabBarFramesForTour(geometry: geometry)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            StoreKit2PaywallView()
                .presentationDetents([.large])
        }
    }
    
    // Authentication flow for unauthenticated users
    private var authenticationFlow: some View {
        NavigationStack {
            LoginView()
        }
        .environmentObject(authViewModel)
    }
    
    // MARK: - Connection error overlay

    // Connection error overlay
    private var connectionErrorOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                AppLogo(size: 50, showText: false)
                    .padding(.top, 10)
                
                Text("Connection Error")
                    .font(AppTheme.Typography.headlineFont())
                
                Text(connectionError)
                    .font(AppTheme.Typography.bodyFont())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry") {
                    retryCount += 1
                    
                    // Try to reconnect
                    if retryCount >= 3 {
                        // Force reconfigure on third attempt
                        let environment = EnvironmentDetector.detectEnvironment()
                        let reconfigured = FirebaseClient.shared.forceReconfigure(for: environment)
                        Logger.error("Firebase reconfiguration \(reconfigured ? "successful" : "failed")")
                    }
                    
                    FirebaseClient.shared.testConnection { success, errorMessage in
                        if success {
                            showConnectionError = false
                        } else if let errorMessage = errorMessage {
                            connectionError = "Firebase connection failed: \(errorMessage)"
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Helper Icon View
extension MainView {
    @ViewBuilder
    private func icon(for tab: Tab) -> some View {
        VStack {
            Image(systemName: selectedTab == tab ? tab.filledIconName : tab.outlineIconName)
                .font(.system(size: 26, weight: .regular))
                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: selectedTab)
            Text(tab.title)
        }
    }
    
    // Helper to manually calculate tab bar item frames for app tour
    private func setupTabBarFramesForTour(geometry: GeometryProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Get screen dimensions
            let screenBounds = UIScreen.main.bounds
            let screenWidth = screenBounds.width
            let screenHeight = screenBounds.height
            
            // Standard iOS tab bar height
            let tabBarHeight: CGFloat = 49
            
            // Get safe area from the window
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .first(where: { $0.isKeyWindow })
            let safeAreaBottom = window?.safeAreaInsets.bottom ?? 0
            
            // Calculate tab positions (5 tabs: home, routines, practice, progress, learn)
            let numberOfTabs = 5
            let tabWidth = screenWidth / CGFloat(numberOfTabs)
            
            // Calculate frame for Routines tab (index 1, zero-based)
            let routinesTabIndex = 1
            
            // Tab items are typically centered in their section
            // The actual clickable area is smaller than the full tab width
            let itemWidth: CGFloat = 60  // Typical tab item width
            let itemHeight: CGFloat = 44  // Typical tab item height including icon and text
            
            // Calculate center position of the routines tab
            let tabCenterX = (CGFloat(routinesTabIndex) * tabWidth) + (tabWidth / 2)
            
            // Tab bar starts from the bottom minus safe area
            // The items are vertically centered in the tab bar
            let tabBarTop = screenHeight - tabBarHeight - safeAreaBottom
            let itemCenterY = tabBarTop + (tabBarHeight / 2)
            
            let routinesTabFrame = CGRect(
                x: tabCenterX - (itemWidth / 2),
                y: itemCenterY - (itemHeight / 2),
                width: itemWidth,
                height: itemHeight
            )
            
            // Update the tour view model with this frame
            appTourViewModel.updateTargetFrame(for: "routines_tab_item", frame: routinesTabFrame)
            
            // Calculate frame for Practice tab (index 2, zero-based)
            let practiceTabIndex = 2
            
            // Calculate center position of the practice tab
            let practiceTabCenterX = (CGFloat(practiceTabIndex) * tabWidth) + (tabWidth / 2)
            
            let practiceTabFrame = CGRect(
                x: practiceTabCenterX - (itemWidth / 2),
                y: itemCenterY - (itemHeight / 2),
                width: itemWidth,
                height: itemHeight
            )
            
            // Update the tour view model with practice tab frame
            appTourViewModel.updateTargetFrame(for: "practice_tab_item", frame: practiceTabFrame)
            
            // Calculate frame for Progress tab (index 3, zero-based)
            let progressTabIndex = 3
            
            // Calculate center position of the progress tab
            let progressTabCenterX = (CGFloat(progressTabIndex) * tabWidth) + (tabWidth / 2)
            
            let progressTabFrame = CGRect(
                x: progressTabCenterX - (itemWidth / 2),
                y: itemCenterY - (itemHeight / 2),
                width: itemWidth,
                height: itemHeight
            )
            
            // Update the tour view model with progress tab frame
            appTourViewModel.updateTargetFrame(for: "progress_tab_item", frame: progressTabFrame)
            
            // Calculate frame for Learn tab (index 4, zero-based)
            let learnTabIndex = 4
            
            // Calculate center position of the learn tab
            let learnTabCenterX = (CGFloat(learnTabIndex) * tabWidth) + (tabWidth / 2)
            
            let learnTabFrame = CGRect(
                x: learnTabCenterX - (itemWidth / 2),
                y: itemCenterY - (itemHeight / 2),
                width: itemWidth,
                height: itemHeight
            )
            
            // Update the tour view model with learn tab frame
            appTourViewModel.updateTargetFrame(for: "learn_tab_item", frame: learnTabFrame)
            
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
} 
