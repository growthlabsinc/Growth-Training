//
//  DashboardView.swift
//  Growth
//
//  Redesigned as Today View for Story 15.2
//

import SwiftUI
import FirebaseAuth
import Combine

struct DashboardView: View {
    // MARK: - Dependencies
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appTourViewModel: AppTourViewModel
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var todayViewModel: TodayViewViewModel
    @StateObject private var calendarViewModel = WeekCalendarViewModel()
    
    // MARK: - Navigation State
    @State private var showLogSession = false
    @State private var showRoutinesList = false
    @State private var navigateToQuickTimer = false
    
    // MARK: - User Data
    @State private var userData: User?
    @State private var isLoadingUser = false
    @State private var showFirstTimePrompt = false
    
    #if DEBUG
    private let useMockData = false // Changed to false to test real data
    #else
    private let useMockData = false
    #endif
    
    private var userFirstName: String { 
        if useMockData {
            return "Alex"
        } else {
            // Always prioritize the saved first name from userData (Firestore)
            if let firstName = userData?.firstName, !firstName.isEmpty {
                return firstName
            }
            // Only use Firebase Auth display name if it's NOT a Google name pattern (containing space)
            else if let firebaseUser = Auth.auth().currentUser,
               let displayName = firebaseUser.displayName,
               !displayName.isEmpty,
               !displayName.contains(" ") {
                // This is likely a firstName set during email/password signup
                return displayName
            }
            // Last resort: extract from email
            else if let email = authViewModel.user?.email {
                return String(email.prefix(while: { $0 != "@" })).capitalized
            }
            return ""
        }
    }
    
    // MARK: - Initialization
    init(routinesViewModel: RoutinesViewModel) {
        self.routinesViewModel = routinesViewModel
        let progressVM = ProgressViewModel()
        
        self._progressViewModel = StateObject(wrappedValue: progressVM)
        self._todayViewModel = StateObject(wrappedValue: TodayViewViewModel(routinesViewModel: routinesViewModel, progressViewModel: progressVM))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // First-time user prompt
                if showFirstTimePrompt, let user = userData {
                    FirstTimeUserPrompt(
                        user: user,
                        onDismiss: dismissFirstTimePrompt,
                        onActionTap: handleFirstTimeAction
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Today's Focus - Primary Section
                TodaysFocusView(
                    viewModel: todayViewModel,
                    onStartRoutine: handleStartRoutine,
                    onQuickPractice: handleQuickPractice,
                    onLogRestDay: { showLogSession = true },
                    onSelectRoutine: { showRoutinesList = true }
                )
                
                // Weekly Progress Snapshot - Secondary Section
                WeeklyProgressSnapshotView(
                    viewModel: todayViewModel,
                    onViewProgress: { navigateToProgressTab() }
                )
                
                // Gains Tracking Card
                GainsInputCard()
                
                // Contextual Quick Actions - Tertiary Section
                ContextualQuickActionsView(
                    viewModel: todayViewModel,
                    onStartRoutine: handleStartRoutine,
                    onQuickPractice: { navigateToQuickTimer = true }, // Navigate to quick timer
                    onLogSession: { showLogSession = true },
                    onViewProgress: { navigateToProgressTab() },
                    onBrowseRoutines: { showRoutinesList = true }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16) // Add spacing from sticky header
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            // Sticky header containing both greeting and weekly calendar
            VStack(spacing: 0) {
                // Header section with greeting
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                // Weekly Calendar
                WeekCalendarView(viewModel: calendarViewModel)
                    .onChangeCompat(of: calendarViewModel.selectedDate) { newValue in
                        // Update Today's Focus based on selected date
                        todayViewModel.updateFocusForDate(newValue)
                    }
                    .padding(.bottom, 8)
            }
            .background(
                GeometryReader { geometry in
                    Color(.systemBackground)
                        .frame(height: geometry.size.height + geometry.safeAreaInsets.top)
                        .offset(y: -geometry.safeAreaInsets.top)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            )
        }
        .refreshable {
            await refreshData()
        }
        .onAppear {
            if authViewModel.isAuthenticated {
                // First fetch the progress data
                progressViewModel.fetchLoggedDates()

                // Then refresh the view model after a short delay to ensure data is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    todayViewModel.refresh()
                }

                // Sync calendar with progress data
                calendarViewModel.loadSessionData()
                // Force reload user data on appear
                loadUserData()

                // If coming from onboarding, add a delay to ensure Firebase sync
                if routinesViewModel.selectedRoutineId == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        routinesViewModel.fetchSelectedRoutineId()
                        todayViewModel.refresh()
                    }
                }
            }
        }
        .sheet(isPresented: $showLogSession) {
            LogSessionView()
        }
        .sheet(isPresented: $showRoutinesList) {
            NavigationView {
                RoutinesListView(viewModel: routinesViewModel)
                    .navigationTitle("Browse Routines")
                    .navigationBarItems(trailing: Button("Done") {
                        showRoutinesList = false
                    })
            }
        }
        .navigationDestination(isPresented: $navigateToQuickTimer) {
            QuickPracticeTimerView()
        }
        .onAppear {
            loadUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reload all data when app comes to foreground
            loadUserData()
            progressViewModel.fetchLoggedDates()
            // Delay the view model refresh to ensure progress data is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                todayViewModel.refresh()
            }
            calendarViewModel.loadSessionData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Also refresh when app becomes active (covers more cases than just foreground)
            progressViewModel.fetchLoggedDates()
            // Delay the view model refresh to ensure progress data is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                todayViewModel.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDataUpdated"))) { _ in
            // Reload when user data is updated
            loadUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionLogged)) { _ in
            // Refresh data when a session is logged
            todayViewModel.refresh()
            progressViewModel.fetchLoggedDates()
            // Add delay to ensure session data is persisted to Firestore
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Reload calendar data with fresh session info
                calendarViewModel.loadSessionData()
            }
        }
        .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
            // Reload user data when authentication state changes
            if isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadUserData()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if useMockData || !userFirstName.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(greetingTime)")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        Text("Hello, \(userFirstName)")
                            .font(AppTheme.Typography.gravityBoldFont(24))
                            .foregroundColor(Color("TextColor"))
                            .modifier(TourTarget(id: "dashboard_title"))
                    }
                    
                    Spacer()
                    
                    // Profile/Settings button
                    ProfileNavigationButton()
                        .frame(width: 44, height: 44)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        default:
            return "evening"
        }
    }
    
    private func handleStartRoutine() {
        // Navigate to Practice tab with routine context
        navigateToPracticeTab(startGuided: true)
    }
    
    private func handleQuickPractice() {
        // Navigate directly to quick timer view
        navigateToQuickTimer = true
    }
    
    private func navigateToPracticeTab(startGuided: Bool = false) {
        // Post notification to switch to practice tab with context
        NotificationCenter.default.post(
            name: .switchToPracticeTab, 
            object: nil,
            userInfo: ["startGuided": startGuided]
        )
    }
    
    private func navigateToProgressTab() {
        // Post notification to switch to progress tab
        NotificationCenter.default.post(
            name: .switchToProgressTab,
            object: nil
        )
    }
    
    @MainActor
    private func refreshData() async {
        todayViewModel.refresh()
        progressViewModel.fetchLoggedDates()
        routinesViewModel.loadRoutines()
    }
    
    // MARK: - User Data Loading
    private func loadUserData() {
        guard let userId = authViewModel.user?.id else { return }
        
        isLoadingUser = true
        UserService.shared.fetchUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoadingUser = false
                switch result {
                case .success(let user):
                    self.userData = user
                    self.checkFirstTimeUser()
                case .failure(_):
                    break
                }
            }
        }
    }
    
    // MARK: - First Time User Methods
    private func checkFirstTimeUser() {
        guard let userId = authViewModel.user?.id else { return }
        
        // Check if user has seen dashboard before
        if !OnboardingRetentionService.shared.hasSeenDashboard(userId: userId) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFirstTimePrompt = true
            }
            
            // Mark dashboard as seen
            OnboardingRetentionService.shared.markDashboardSeen(userId: userId)
        }
    }
    
    private func dismissFirstTimePrompt() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showFirstTimePrompt = false
        }
    }
    
    private func handleFirstTimeAction() {
        guard let user = userData else { return }
        
        // Navigate based on user's practice preference
        if user.preferredPracticeMode == "routine" {
            // Show routines list
            showRoutinesList = true
        } else if user.initialMethodId != nil {
            // Start quick practice with their initial method
            handleQuickPractice()
        } else {
            // Navigate to practice tab to explore methods
            navigateToPracticeTab()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        DashboardView(routinesViewModel: RoutinesViewModel(userId: "preview"))
            .environmentObject(AuthViewModel())
    }
}