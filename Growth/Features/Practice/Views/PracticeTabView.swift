//
//  PracticeTabView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//  Updated for Story 15.3: Integration with existing functionality
//

import SwiftUI
import FirebaseAuth
import Foundation  // For Logger

struct PracticeTabView: View {
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @StateObject private var viewModel: PracticeTabViewModel
    @Binding var startGuided: Bool
    @Binding var showCompletion: Bool
    @EnvironmentObject var navigationContext: NavigationContext
    @State private var showQuickPracticeTimer = false
    @ObservedObject private var quickPracticeTracker = QuickPracticeTimerTracker.shared
    @ObservedObject private var mainTimerService = TimerService.shared
    @State private var showCompletionSheet = false
    @State private var pendingCompletionData: (elapsedTime: TimeInterval, methodName: String)?
    
    // Cache for progress values to prevent recalculation
    @State private var cachedProgressValue: Double = 0
    @State private var lastProgressUpdateTime: Date?
    
    // Prevent sheet conflicts when transitioning from completion
    @State private var canShowQuickPractice = true
    
    // Free tier limitation alert
    @State private var showFreeTierAlert = false
    @StateObject private var entitlementManager = SimplifiedEntitlementManager()
    
    init(routinesViewModel: RoutinesViewModel, startGuided: Binding<Bool> = .constant(false), showCompletion: Binding<Bool> = .constant(false)) {
        self.routinesViewModel = routinesViewModel
        self._viewModel = StateObject(wrappedValue: PracticeTabViewModel(routinesViewModel: routinesViewModel))
        self._startGuided = startGuided
        self._showCompletion = showCompletion
    }
    
    private var shouldShowPlaceholder: Bool {
        // Show placeholder if no active routine
        if !viewModel.hasActiveRoutine() {
            return true
        }
        
        // Don't show placeholder if routine is complete (we show completion view instead)
        if viewModel.isDailyRoutineComplete() {
            return false
        }
        
        // If we have an active routine but can't start guided session today
        // (e.g., rest day or no schedule), still show the daily routine view
        return false
    }
    
    var body: some View {
        contentWithSheets
    }
    
    private var contentWithSheets: some View {
        mainView
            .customNavigationHeader(title: "Practice")
            .navigationDestination(isPresented: $viewModel.showMethodSelection) {
                GrowthMethodsListView()
            }
            .sheet(isPresented: $viewModel.showTimerView) {
                timerViewSheet
            }
            .sheet(isPresented: $viewModel.showLogSessionView) {
                LogSessionView()
            }
            .sheet(isPresented: $showCompletionSheet, onDismiss: {
                pendingCompletionData = nil
            }) {
                CompletionSheetContent(
                    pendingCompletionData: pendingCompletionData,
                    showCompletionSheet: $showCompletionSheet,
                    viewModel: viewModel
                )
            }
            .fullScreenCover(isPresented: $showQuickPracticeTimer) {
                quickPracticeCover
            }
            .alert("Error", isPresented: errorAlertBinding) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .alert("Free Tier Limit", isPresented: $showFreeTierAlert) {
                Button("OK", role: .cancel) { }
                Button("Upgrade", role: .none) {
                    // Post notification to switch to subscription tab
                    NotificationCenter.default.post(
                        name: Notification.Name("switchToSubscriptionTab"),
                        object: nil
                    )
                }
            } message: {
                Text("You've completed your daily practice session. Upgrade to Premium for unlimited daily sessions and access to all features.")
            }
            .modifier(EventHandlers(
                viewModel: viewModel,
                routinesViewModel: routinesViewModel,
                mainTimerService: mainTimerService,
                showCompletionSheet: $showCompletionSheet,
                pendingCompletionData: $pendingCompletionData,
                canShowQuickPractice: $canShowQuickPractice,
                cachedProgressValue: $cachedProgressValue,
                startGuided: $startGuided,
                showCompletion: $showCompletion,
                checkForPendingTimerCompletion: checkForPendingTimerCompletion,
                updateProgressCache: updateProgressCache,
                areAllMethodsCompletedToday: areAllMethodsCompletedToday
            ))
    }
    
    @ViewBuilder
    private var timerViewSheet: some View {
        if let method = viewModel.selectedMethod {
            NavigationView {
                TimerView(growthMethod: method)
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private var quickPracticeCover: some View {
        NavigationStack {
            QuickPracticeTimerView()
        }
        .onAppear {
            if !canShowQuickPractice {
                showQuickPracticeTimer = false
            }
        }
    }
    
    private var errorAlertBinding: Binding<Bool> {
        .constant(viewModel.error != nil)
    }
    
    // MARK: - Main View
    private var mainView: some View {
        VStack(spacing: 0) {
            // Quick Session Button
            quickSessionButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // Progress Card with Glow Effect
            if viewModel.hasActiveRoutine() && totalSessions > 0 {
                progressCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            
            // Main content
            mainContentSection
        }
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        Group {
                if routinesViewModel.isLoading {
                    // Show loading state while routines are being fetched
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                        Text("Loading...")
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Use ZStack to prevent view flash by keeping all views in hierarchy
                    ZStack {
                        // Base placeholder view (always in hierarchy but hidden when not needed)
                        GuidedSessionPlaceholderView()
                            .opacity(shouldShowPlaceholder ? 1 : 0)
                            .animation(.none, value: shouldShowPlaceholder)
                        
                        // Daily routine view or completion state
                        if viewModel.hasActiveRoutine() {
                            // Check if there's an active timer that needs to be logged before showing completion
                            let hasUnloggedTimer = mainTimerService.timerState == TimerState.paused && 
                                                  mainTimerService.elapsedTime > 0 && 
                                                  mainTimerService.remainingTime <= 0
                            
                            if (viewModel.isDailyRoutineComplete() || areAllMethodsCompletedToday()) && !hasUnloggedTimer {
                                // Show completion state with quick practice option
                                routineCompleteView
                                    .transition(.identity)
                                    .onAppear {
                                        // Ensure quick practice is disabled briefly when showing completion
                                        canShowQuickPractice = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            canShowQuickPractice = true
                                        }
                                    }
                            } else if let todaySchedule = viewModel.getTodaySchedule() {
                                // Show daily routine view
                                // Use the routine ID as part of the view's identity to force recreation when routine changes
                                DailyRoutineView(schedule: todaySchedule, routinesViewModel: routinesViewModel, isEmbedded: true, onExit: {
                                    // Handle exit - could navigate to home or show a message
                                    // For now, we'll just print since we can't actually navigate from embedded view
                                    Logger.debug("Exit practice requested")
                                })
                                    .id("\(routinesViewModel.selectedRoutineId ?? "none")_\(todaySchedule.dayNumber)")
                                    .transition(.identity) // Prevent transition animations
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
        }
    
    // MARK: - Quick Session Button
    private var quickSessionButton: some View {
        Button(action: {
            handleQuickSessionButtonTap()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen").opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("GrowthGreen"))
                        .appleIntelligenceGlow(
                            isActive: quickPracticeTracker.isTimerActive,
                            cornerRadius: 20,
                            intensity: 0.5
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Session")
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Start a standalone practice")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(progressDescription)
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                // Percentage
                Text("\(progressPercentage)%")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color("GrowthGreen").opacity(0.1))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * progressValue), height: 12)
                        .animation(.linear(duration: 0.1), value: progressValue)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundColor"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .appleIntelligenceGlow(
            isActive: mainTimerService.timerState == .running,
            cornerRadius: 16,
            intensity: 0.6
        )
    }
    
    // MARK: - Helper Methods
    private func areAllMethodsCompletedToday() -> Bool {
        // Check if we have completed all methods for today
        return completedSessions >= totalSessions && totalSessions > 0
    }
    
    // MARK: - Computed Properties for Progress
    private var completedSessions: Int {
        // If the day is already complete, return total sessions
        if viewModel.isDailyRoutineComplete() {
            // Make sure we have a valid total sessions count
            let total = totalSessions
            return total > 0 ? total : 3 // Default to 3 if no schedule
        }
        
        // Get completed sessions count from viewModel
        let completed = viewModel.getCompletedSessionsCount()
        
        // If there's an unlogged timer (completed but not saved), don't count it as completed yet
        let hasUnloggedTimer = mainTimerService.timerState == TimerState.paused && 
                              mainTimerService.elapsedTime > 0 && 
                              mainTimerService.remainingTime <= 0
        
        // If we have an unlogged timer and it would be the last session, reduce count by 1
        if hasUnloggedTimer && completed == totalSessions {
            return max(0, completed - 1)
        }
        
        return completed
    }
    
    private var totalSessions: Int {
        // This comes from today's routine schedule
        if let todaySchedule = viewModel.getTodaySchedule() {
            // Check if it's a rest day
            if todaySchedule.isRestDay {
                return 0
            }
            // Return the count of methods
            return todaySchedule.methods.count > 0 ? todaySchedule.methods.count : 3
        }
        // Default to 3 sessions if no schedule found
        return 3
    }
    
    private var progressValue: Double {
        return cachedProgressValue
    }
    
    private func updateProgressCache() {
        // If the day is complete, always show 100%
        if viewModel.isDailyRoutineComplete() {
            cachedProgressValue = 1.0
            return
        }
        
        guard totalSessions > 0 else { 
            cachedProgressValue = 0
            return
        }
        
        // Calculate base progress from completed sessions, capped at 1.0
        let baseProgress = min(Double(completedSessions) / Double(totalSessions), 1.0)
        
        // If there's an active MAIN timer and we haven't reached 100%, add incremental progress
        // Quick practice sessions should NOT affect routine progress
        // Include paused state to show progress even when paused
        // But exclude timers that are paused with 0 remaining time (completed timers)
        if (mainTimerService.timerState == .running || 
            (mainTimerService.timerState == .paused && mainTimerService.remainingTime > 0)) && 
           mainTimerService.elapsedTime > 0 && baseProgress < 1.0 {
            // For an active session, we estimate progress based on timer elapsed time
            // We'll consider a session "in progress" and add partial completion
            
            // For main timer, calculate progress based on elapsed time
            // Use the timer's total duration if available, or default to expected session time
            let expectedDuration: TimeInterval
            if let totalDuration = mainTimerService.totalDuration, totalDuration > 0 {
                expectedDuration = totalDuration
            } else {
                // For stopwatch mode or if no target duration, estimate based on typical session length
                expectedDuration = 900 // Default 15 minutes
            }
            
            let elapsedProgress = min(mainTimerService.elapsedTime / expectedDuration, 1.0)
            let sessionProgressIncrement = elapsedProgress / Double(totalSessions)
            
            cachedProgressValue = min(baseProgress + sessionProgressIncrement, 1.0)
        } else {
            cachedProgressValue = baseProgress
        }
        
        lastProgressUpdateTime = Date()
    }
    
    private func shouldUpdateProgressCache() -> Bool {
        // Update cache if:
        // 1. Never calculated before
        guard let lastUpdate = lastProgressUpdateTime else { return true }
        
        // 2. More than 1 second has passed (to throttle timer updates)
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > 1.0 { return true }
        
        // 3. Timer state changed (started/stopped)
        // This would require tracking previous timer state, so for now we'll rely on time throttling
        
        return false
    }
    
    private var progressPercentage: Int {
        // Ensure we always show 100% for completed days
        if viewModel.isDailyRoutineComplete() {
            return 100
        }
        return min(Int(progressValue * 100), 100)
    }
    
    private var isSessionInProgress: Bool {
        // Check if MAIN timer is running or paused (quick practice doesn't count for routine progress)
        // But exclude timers that are paused with 0 remaining time (completed timers)
        return (mainTimerService.timerState == .running || 
                (mainTimerService.timerState == .paused && mainTimerService.remainingTime > 0)) && 
               mainTimerService.elapsedTime > 0
    }
    
    private var progressDescription: String {
        if viewModel.isDailyRoutineComplete() {
            return "Today's routine complete!"
        } else if let todaySchedule = viewModel.getTodaySchedule(), todaySchedule.isRestDay {
            return "Rest day - no sessions scheduled"
        } else if isSessionInProgress {
            if completedSessions == 0 {
                return "1 session in progress..."
            } else {
                return "\(completedSessions) completed, 1 in progress..."
            }
        } else {
            let total = totalSessions
            if total == 0 {
                return "No sessions scheduled"
            }
            return "\(completedSessions) of \(total) sessions completed"
        }
    }
    
    // MARK: - Routine Complete View
    private var routineCompleteView: some View {
        VStack(spacing: 24) {
            // Success message
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Daily Routine Complete!")
                    .font(AppTheme.Typography.gravitySemibold(24))
                    .foregroundColor(Color("TextColor"))
                
                Text("Great job completing all \(totalSessions) methods today")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Options
            VStack(spacing: 16) {
                // Quick practice option
                Button(action: {
                    if canShowQuickPractice {
                        showQuickPracticeTimer = true
                    }
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue with Quick Practice")
                                .font(AppTheme.Typography.gravitySemibold(16))
                            Text("Start an additional practice session")
                                .font(AppTheme.Typography.gravityBook(13))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color("TextColor"))
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("GrowthGreen").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("GrowthGreen"), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // View progress option
                Button(action: {
                    // Navigate to progress tab using notification
                    NotificationCenter.default.post(
                        name: Notification.Name("switchToProgressTab"),
                        object: nil
                    )
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                        
                        Text("View Today's Progress")
                            .font(AppTheme.Typography.gravityBook(16))
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color("TextColor"))
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func hasCompletedSessionToday() -> Bool {
        // Check if user has completed at least one session today
        return viewModel.getCompletedSessionsCount() > 0
    }
    
    private func handleQuickSessionButtonTap() {
        // Check free tier limitation
        if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
            showFreeTierAlert = true
            return
        }
        
        // Don't stop the timer here - let the quick practice view handle its own state
        if canShowQuickPractice {
            showQuickPracticeTimer = true
        }
    }
    
    // MARK: - Pending Completion Check
    
    private func checkForPendingTimerCompletion() {
        // Don't process if sheet is already showing
        guard !showCompletionSheet else {
            Logger.debug("PracticeTabView: Completion sheet already showing, skipping check")
            return
        }
        
        // Check if there's pending timer completion data from Live Activity
        let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod")
        if let completionData = sharedDefaults?.dictionary(forKey: "pendingTimerCompletion"),
           let elapsedTime = completionData["elapsedTime"] as? TimeInterval,
           let timestamp = completionData["timestamp"] as? TimeInterval {
            
            // Only process if the data is recent (within 60 seconds to handle app launch delays)
            let dataAge = Date().timeIntervalSince1970 - timestamp
            Logger.info("PracticeTabView: Found pending timer completion - age: \(dataAge)s, elapsed: \(elapsedTime)s")
            
            if dataAge < 60 && elapsedTime > 0 {
                Logger.info("PracticeTabView: Processing pending timer completion from \(dataAge)s ago")
                
                let methodName = completionData["methodName"] as? String ?? "Practice"
                
                // Store the data for sheet presentation
                pendingCompletionData = (elapsedTime: elapsedTime, methodName: methodName)
                
                // Clear the pending data from UserDefaults immediately to prevent re-processing
                sharedDefaults?.removeObject(forKey: "pendingTimerCompletion")
                sharedDefaults?.synchronize()
                
                Logger.info("PracticeTabView: Will show completion sheet for \(methodName) - elapsed: \(elapsedTime)s")
                
                // Capture the data in a local variable to ensure it's available when sheet shows
                let capturedData = (elapsedTime: elapsedTime, methodName: methodName)
                
                // Show the completion sheet after a short delay to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Ensure data is still set before showing sheet
                    if self.pendingCompletionData == nil {
                        self.pendingCompletionData = capturedData
                        Logger.warning("PracticeTabView: pendingCompletionData was nil, restored from captured data")
                    }
                    Logger.info("PracticeTabView: About to show sheet with data - method: \(self.pendingCompletionData?.methodName ?? "nil"), elapsed: \(self.pendingCompletionData?.elapsedTime ?? 0)")
                    showCompletionSheet = true
                }
            } else {
                Logger.warning("PracticeTabView: Pending timer completion data is too old (\(dataAge)s) or invalid, clearing")
                // Clear old data
                sharedDefaults?.removeObject(forKey: "pendingTimerCompletion")
                sharedDefaults?.synchronize()
            }
        } else {
            Logger.debug("PracticeTabView: No pending timer completion data found")
        }
    }
    
    // MARK: - Event Handlers
    private func handleOnAppear() {
        // Load routines only if not already loaded
        if routinesViewModel.routines.isEmpty {
            routinesViewModel.loadRoutines()
        }
        // Don't update progress cache immediately - wait for session logs to load
        // This ensures we have accurate completion data from Firebase
        
        // If timer is already running (e.g., restored from background), ensure we're tracking it
        if mainTimerService.timerState == .running {
            updateProgressCache()
        }
        
        // Check for pending timer completion from Live Activity
        checkForPendingTimerCompletion()
    }
    
    private func handleRoutineProgressUpdated() {
        // Refresh the progress when routine progress is updated
        viewModel.refreshProgress()
        // Update cache
        updateProgressCache()
    }
    
    private func handleDidBecomeActive() {
        // Check for pending timer completion when app becomes active
        // Only check if we're not already showing the sheet and don't have pending data
        if !showCompletionSheet && pendingCompletionData == nil {
            checkForPendingTimerCompletion()
        }
    }
    
    private func handleSessionsReset() {
        // Handle sessions reset - clear everything
        viewModel.clearAllSessions()
        viewModel.refreshProgress()
        updateProgressCache()
    }
    
    private func handleSessionLogged(notification: Notification) {
        // Check if this is a reset action
        if let userInfo = notification.userInfo,
           let action = userInfo["action"] as? String,
           action == "reset" {
            // Force complete refresh for reset
            viewModel.clearAllSessions()
            viewModel.refreshProgress()
            updateProgressCache()
            return
        }
        
        // Update session count when a ROUTINE session is logged (not quick practice)
        if let userInfo = notification.userInfo,
           let sessionType = userInfo["sessionType"] as? String {
            if sessionType == SessionType.quickPractice.rawValue {
                // Ignore quick practice sessions
                return
            }
        }
        
        // Temporarily disable quick practice button to prevent sheet conflicts
        canShowQuickPractice = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            canShowQuickPractice = true
        }
        
        // For routine sessions, refresh the progress to ensure it updates
        viewModel.refreshProgress()
        
        // Wait a moment for Firestore to update and fetch the new data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Update cache after data is fetched
            self.updateProgressCache()
            // Force UI update to show completion state if all methods are done
            self.viewModel.objectWillChange.send()
            
            // Ensure progress value is properly set for completed state
            if self.viewModel.isDailyRoutineComplete() || self.areAllMethodsCompletedToday() {
                self.cachedProgressValue = 1.0
            }
        }
    }
    
    private func handleMethodCompleted() {
        // Update progress when a method is completed
        // This ensures the count updates correctly during auto-progression
        viewModel.onMethodCompleted()
        // Update cache
        updateProgressCache()
        // Force UI update to check if we should show completion state
        if areAllMethodsCompletedToday() {
            // Set progress to 100% immediately when all methods are completed
            cachedProgressValue = 1.0
            // Temporarily disable quick practice button when showing completion state
            canShowQuickPractice = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                canShowQuickPractice = true
            }
            viewModel.objectWillChange.send()
        }
    }
    
    private func handleSessionDismissedWithoutLogging() {
        // When exiting without logging, refresh the progress from actual logged sessions
        // This ensures we show the correct progress based on what was actually logged
        viewModel.refreshProgress()
        updateProgressCache()
    }
    
    private func handleSessionLogsLoaded() {
        // Update progress cache after session logs are loaded from Firebase
        // This ensures we show the correct progress on app startup
        updateProgressCache()
        
        // If all methods are completed, ensure progress shows 100%
        if areAllMethodsCompletedToday() || viewModel.isDailyRoutineComplete() {
            cachedProgressValue = 1.0
        }
    }
    
    private func handleElapsedTimeChange() {
        // Update cache frequently when timer is running
        if mainTimerService.timerState == .running || mainTimerService.timerState == .paused {
            updateProgressCache()
        }
    }
    
    private func handleRoutineIdChange() {
        // Force view model to refresh when routine changes
        viewModel.refreshProgress()
        updateProgressCache()
    }
    
    private func handleStartGuidedChange(newValue: Bool) {
        // If startGuided becomes true, automatically start guided practice
        if newValue {
            if viewModel.canStartGuidedSession() {
                viewModel.selectedPracticeOption = .guided
                viewModel.startPracticeSession()
            }
            // Reset the flag after processing
            Task { @MainActor in
                startGuided = false
            }
        }
    }
    
    private func handleShowCompletionChange(newValue: Bool) {
        // If showCompletion becomes true, just check for pending completion without starting a session
        if newValue {
            Logger.debug("🎯 PracticeTabView: showCompletion triggered from Live Activity navigation")
            
            // Immediately check and capture the pending data
            let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod")
            if let completionData = sharedDefaults?.dictionary(forKey: "pendingTimerCompletion"),
               let elapsedTime = completionData["elapsedTime"] as? TimeInterval,
               let timestamp = completionData["timestamp"] as? TimeInterval {
                
                let dataAge = Date().timeIntervalSince1970 - timestamp
                if dataAge < 60 && elapsedTime > 0 {
                    let methodName = completionData["methodName"] as? String ?? "Practice"
                    
                    // Set the pending data immediately
                    pendingCompletionData = (elapsedTime: elapsedTime, methodName: methodName)
                    
                    // Clear from UserDefaults
                    sharedDefaults?.removeObject(forKey: "pendingTimerCompletion")
                    sharedDefaults?.synchronize()
                    
                    Logger.info("🎯 PracticeTabView: Set completion data from showCompletion - method: \(methodName), elapsed: \(elapsedTime)s")
                    
                    // Show the sheet immediately
                    showCompletionSheet = true
                }
            }
            
            // Reset the flag after processing
            Task { @MainActor in
                showCompletion = false
            }
        }
    }
}

// MARK: - Completion Sheet Content
private struct CompletionSheetContent: View {
    let pendingCompletionData: (elapsedTime: TimeInterval, methodName: String)?
    @Binding var showCompletionSheet: Bool
    @ObservedObject var viewModel: PracticeTabViewModel
    
    var body: some View {
        if let data = pendingCompletionData {
            let sessionProgress = SessionProgress(
                sessionType: .single,
                sessionId: UUID().uuidString,
                methodId: nil,
                methodName: data.methodName,
                startTime: Date().addingTimeInterval(-data.elapsedTime),
                endTime: Date(),
                totalMethods: 1,
                completedMethods: data.elapsedTime > 0 ? 1 : 0
            )
            
            SessionCompletionPromptView(
                sessionProgress: sessionProgress,
                onLog: {
                    handleLogSession(data: data)
                },
                onDismiss: {
                    handleDismiss()
                },
                onPartialLog: nil
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        } else {
            // Fallback view
            let sessionProgress = SessionProgress(
                sessionType: .single,
                sessionId: UUID().uuidString,
                methodId: nil,
                methodName: "Practice Session",
                startTime: Date().addingTimeInterval(-60),
                endTime: Date(),
                totalMethods: 1,
                completedMethods: 1
            )
            
            SessionCompletionPromptView(
                sessionProgress: sessionProgress,
                onLog: {
                    showCompletionSheet = false
                    NotificationCenter.default.post(
                        name: .sessionLogged,
                        object: nil,
                        userInfo: ["sessionType": "quickPractice"]
                    )
                },
                onDismiss: {
                    handleDismiss()
                },
                onPartialLog: nil
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
    }
    
    private func handleLogSession(data: (elapsedTime: TimeInterval, methodName: String)) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showCompletionSheet = false
            return
        }
        
        let sessionLog = SessionLog(
            id: UUID().uuidString,
            userId: userId,
            duration: Int(data.elapsedTime / 60), // Convert seconds to minutes
            startTime: Date().addingTimeInterval(-data.elapsedTime),
            endTime: Date(),
            userNotes: nil,
            methodId: nil,
            sessionIndex: nil,
            moodBefore: .neutral,
            moodAfter: .neutral,
            intensity: nil,
            variation: nil
        )
        
        // Use SessionService to save the log
        SessionService.shared.saveSessionLog(sessionLog) { error in
            if let error = error {
                Logger.error("Failed to save session log: \(error)")
            } else {
                Logger.info("Session log saved successfully from Live Activity completion")
                // Post notification that session was logged
                NotificationCenter.default.post(
                    name: .sessionLogged,
                    object: nil,
                    userInfo: ["sessionType": "quickPractice"]
                )
            }
        }
        
        showCompletionSheet = false
    }
    
    private func handleDismiss() {
        showCompletionSheet = false
        NotificationCenter.default.post(name: .sessionDismissedWithoutLogging, object: nil)
    }
}

// MARK: - Event Handlers Modifier

private struct EventHandlers: ViewModifier {
    let viewModel: PracticeTabViewModel
    let routinesViewModel: RoutinesViewModel  
    let mainTimerService: TimerService
    @Binding var showCompletionSheet: Bool
    @Binding var pendingCompletionData: (elapsedTime: TimeInterval, methodName: String)?
    @Binding var canShowQuickPractice: Bool
    @Binding var cachedProgressValue: Double
    @Binding var startGuided: Bool
    @Binding var showCompletion: Bool
    let checkForPendingTimerCompletion: () -> Void
    let updateProgressCache: () -> Void
    let areAllMethodsCompletedToday: () -> Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if routinesViewModel.routines.isEmpty {
                    routinesViewModel.loadRoutines()
                }
                if mainTimerService.timerState == .running {
                    updateProgressCache()
                }
                checkForPendingTimerCompletion()
            }
            .onReceive(NotificationCenter.default.publisher(for: .routineProgressUpdated)) { _ in
                viewModel.refreshProgress()
                updateProgressCache()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if !showCompletionSheet && pendingCompletionData == nil {
                    checkForPendingTimerCompletion()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("sessionsReset"))) { _ in
                viewModel.clearAllSessions()
                viewModel.refreshProgress()
                updateProgressCache()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sessionLogged)) { notification in
                handleSessionLogged(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .methodCompleted)) { _ in
                handleMethodCompleted()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sessionDismissedWithoutLogging)) { _ in
                viewModel.refreshProgress()
                updateProgressCache()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("sessionLogsLoaded"))) { _ in
                updateProgressCache()
                if areAllMethodsCompletedToday() || viewModel.isDailyRoutineComplete() {
                    cachedProgressValue = 1.0
                }
            }
            .onReceive(mainTimerService.$timerState) { _ in
                updateProgressCache()
            }
            .onReceive(mainTimerService.$elapsedTime
                .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            ) { _ in
                if mainTimerService.timerState == .running || mainTimerService.timerState == .paused {
                    updateProgressCache()
                }
            }
            .onChangeCompat(of: routinesViewModel.selectedRoutineId) { _ in
                viewModel.refreshProgress()
                updateProgressCache()
            }
            .onChangeCompat(of: startGuided) { newValue in
                handleStartGuidedChange(newValue: newValue)
            }
            .onChangeCompat(of: showCompletion) { newValue in
                handleShowCompletionChange(newValue: newValue)
            }
    }
    
    private func handleSessionLogged(notification: Notification) {
        if let userInfo = notification.userInfo,
           let action = userInfo["action"] as? String,
           action == "reset" {
            viewModel.clearAllSessions()
            viewModel.refreshProgress()
            updateProgressCache()
            return
        }
        
        if let userInfo = notification.userInfo,
           let sessionType = userInfo["sessionType"] as? String {
            if sessionType == SessionType.quickPractice.rawValue {
                return
            }
        }
        
        canShowQuickPractice = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            canShowQuickPractice = true
        }
        
        viewModel.refreshProgress()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateProgressCache()
            viewModel.objectWillChange.send()
            
            if viewModel.isDailyRoutineComplete() || areAllMethodsCompletedToday() {
                cachedProgressValue = 1.0
            }
        }
    }
    
    private func handleMethodCompleted() {
        viewModel.onMethodCompleted()
        updateProgressCache()
        if areAllMethodsCompletedToday() {
            cachedProgressValue = 1.0
            canShowQuickPractice = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                canShowQuickPractice = true
            }
            viewModel.objectWillChange.send()
        }
    }
    
    private func handleStartGuidedChange(newValue: Bool) {
        if newValue {
            if viewModel.canStartGuidedSession() {
                viewModel.selectedPracticeOption = .guided
                viewModel.startPracticeSession()
            }
            Task { @MainActor in
                startGuided = false
            }
        }
    }
    
    private func handleShowCompletionChange(newValue: Bool) {
        if newValue {
            Logger.debug("🎯 PracticeTabView: showCompletion triggered from Live Activity navigation")
            
            let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod")
            if let completionData = sharedDefaults?.dictionary(forKey: "pendingTimerCompletion"),
               let elapsedTime = completionData["elapsedTime"] as? TimeInterval,
               let timestamp = completionData["timestamp"] as? TimeInterval {
                
                let dataAge = Date().timeIntervalSince1970 - timestamp
                if dataAge < 60 && elapsedTime > 0 {
                    let methodName = completionData["methodName"] as? String ?? "Practice"
                    
                    pendingCompletionData = (elapsedTime: elapsedTime, methodName: methodName)
                    
                    sharedDefaults?.removeObject(forKey: "pendingTimerCompletion")
                    sharedDefaults?.synchronize()
                    
                    Logger.info("🎯 PracticeTabView: Set completion data from showCompletion - method: \(methodName), elapsed: \(elapsedTime)s")
                    
                    showCompletionSheet = true
                }
            }
            
            Task { @MainActor in
                showCompletion = false
            }
        }
    }
}


#Preview {
    NavigationStack {
        PracticeTabView(
            routinesViewModel: RoutinesViewModel(userId: "preview"),
            startGuided: .constant(false)
        )
    }
    .environmentObject(AuthViewModel())
    .environmentObject(NavigationContext())
}