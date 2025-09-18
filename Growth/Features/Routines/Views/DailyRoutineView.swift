import SwiftUI
import UIKit
import FirebaseAuth
import Combine
import Foundation  // For Logger

struct DailyRoutineView: View {
    let schedule: DaySchedule
    var isEmbedded: Bool = false
    var onExit: (() -> Void)? = nil
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @StateObject private var viewModel: DailyRoutineViewModel
    @StateObject private var sessionViewModel: MultiMethodSessionViewModel
    @StateObject private var completionViewModel = SessionCompletionViewModel()
    @ObservedObject private var timerService = TimerService.shared
    @StateObject private var quickPracticeTracker = QuickPracticeTimerTracker.shared
    @StateObject private var entitlementManager = SimplifiedEntitlementManager()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var navigationContext: NavigationContext
    @EnvironmentObject var smartNavigationService: SmartNavigationService
    @State private var showExitConfirm = false
    @State private var hasActiveTimer = false
    @State private var showTimerConflictAlert = false
    @State private var hasRestoredTimer = false
    @State private var hasHandledTimerCompletion = false
    @State private var lastTimerState: TimerState = .stopped
    @State private var hasConfiguredTimer = false
    @State private var isConfiguringTimer = false
    @State private var isShowingCompletionPrompt = false

    @State private var expandedMethods: Set<String> = []
    
    // For handling Live Activity stop notifications
    @State private var notificationCancellable: AnyCancellable?
    
    // Track if view is visible (to prevent presenting sheet from detached view)
    @State private var isViewVisible = false
    
    // Timer blocked message
    @State private var timerBlockedMessage = ""
    
    // Track previous values for onChange handlers
    @State private var previousCompletionPromptState = false
    @State private var previousMethodIndex = 0
    @State private var previousMethodId: String? = nil
    @State private var previousLoadingState = false
    
    // Free tier limitation alert
    @State private var showFreeTierAlert = false

    init(schedule: DaySchedule, routinesViewModel: RoutinesViewModel, isEmbedded: Bool = false, onExit: (() -> Void)? = nil) {
        self.schedule = schedule
        self.routinesViewModel = routinesViewModel
        self.isEmbedded = isEmbedded
        self.onExit = onExit
        _viewModel = StateObject(wrappedValue: DailyRoutineViewModel(schedule: schedule))
        _sessionViewModel = StateObject(wrappedValue: MultiMethodSessionViewModel(schedule: schedule))
    }

    var body: some View {
        mainContent
            .onAppear {
                // Sync completion state from PracticeTabViewModel's cache
                syncCompletionStateFromCache()
                
                // Set up notification listener for stop requests from Live Activity
                notificationCancellable = NotificationCenter.default
                    .publisher(for: .timerStopRequested)
                    .sink { notification in
                        Logger.debug("🔔 DailyRoutineView: Received timerStopRequested notification")
                        // Check if this is for the main timer
                        if let userInfo = notification.userInfo,
                           let timerType = userInfo[Notification.Name.TimerUserInfoKey.timerType] as? String,
                           timerType == Notification.Name.TimerType.main.rawValue {
                            Logger.debug("✅ DailyRoutineView: Stopping timer from Live Activity")
                            
                            // Use timer data from notification if available, otherwise capture from timerService
                            let elapsedTime = userInfo["elapsedTime"] as? TimeInterval ?? timerService.elapsedTime
                            let startTime = userInfo["startTime"] as? Date ?? timerService.startTime ?? Date().addingTimeInterval(-elapsedTime)
                            
                            Logger.debug("📊 Timer data - Elapsed: \(elapsedTime), Start: \(startTime)")
                            
                            // Stop the timer if not already stopped
                            if timerService.timerState != .stopped {
                                timerService.stop()
                            }
                            
                            // Handle completion if there was elapsed time
                            if elapsedTime > 0 {
                                // Get the current method from sessionViewModel
                                if let currentMethod = sessionViewModel.currentMethod {
                                    let methodId = currentMethod.id ?? UUID().uuidString
                                    let methodName = currentMethod.title
                                    
                                    Logger.debug("🎯 Completing session for method: \(methodName)")
                                    
                                    // Complete the session - this should trigger the completion sheet
                                    completionViewModel.completeSession(
                                        methodId: methodId,
                                        duration: elapsedTime,
                                        startTime: startTime,
                                        variation: methodName
                                    )
                                    
                                    // Reset timer configuration for next method
                                    hasConfiguredTimer = false
                                    hasHandledTimerCompletion = false
                                } else {
                                    Logger.warning("⚠️ No current method found for completion")
                                }
                            } else {
                                Logger.warning("⚠️ No elapsed time to log")
                            }
                        } else {
                            Logger.debug("❌ DailyRoutineView: Not for main timer")
                        }
                    }
            }
            .onDisappear {
                // Clean up notification listener
                notificationCancellable?.cancel()
            }
            .onReceive(timerService.$timerState) { newState in
                
                // Check if timer just completed (transitioned from running to paused with 0 remaining)
                if timerService.timerMode == TimerMode.countdown && 
                   lastTimerState == TimerState.running &&
                   newState == TimerState.paused &&
                   timerService.remainingTime <= 0 && 
                   timerService.elapsedTime > 0 &&
                   !hasHandledTimerCompletion &&
                   !isConfiguringTimer &&
                   !completionViewModel.showCompletionPrompt {
                    // Timer completed for current method
                    hasHandledTimerCompletion = true
                    // Don't set isShowingCompletionPrompt here - let handleTimerCompletion do it
                    DispatchQueue.main.async {
                        handleTimerCompletion()
                    }
                }
                // Reset completion flag when timer starts
                if newState == .running && lastTimerState != .running {
                    hasHandledTimerCompletion = false
                    isShowingCompletionPrompt = false
                }
                
                // Update last state
                lastTimerState = newState
            }
            .onReceive(timerService.$remainingTime) { newRemainingTime in
                // Additional check for timer completion based on remainingTime reaching 0
                if timerService.timerMode == .countdown &&
                   timerService.timerState == .running &&
                   newRemainingTime <= 0 &&
                   timerService.elapsedTime > 0 &&
                   !hasHandledTimerCompletion &&
                   !isConfiguringTimer &&
                   !completionViewModel.showCompletionPrompt {
                    hasHandledTimerCompletion = true
                    // Don't set isShowingCompletionPrompt here - let handleTimerCompletion do it
                    DispatchQueue.main.async {
                        handleTimerCompletion()
                    }
                }
            }
            .onChangeCompat(of: scenePhase) { _ in
                if scenePhase == .active {
                    // Mark view as visible when app becomes active
                    isViewVisible = true
                    
                    
                    // Check if timer completed while in background
                    if timerService.timerMode == TimerMode.countdown &&
                       timerService.timerState == TimerState.paused &&
                       timerService.remainingTime <= 0 &&
                       timerService.elapsedTime > 0 &&
                       !hasHandledTimerCompletion &&
                       !completionViewModel.showCompletionPrompt {
                        hasHandledTimerCompletion = true
                        // Don't set isShowingCompletionPrompt here - let handleTimerCompletion do it
                        
                        // Mark method as completed
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.markMethodCompleted(methodId, duration: timerService.elapsedTime)
                        }
                        
                        // Use a longer delay to ensure UI is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            handleTimerCompletion()
                        }
                    }
                } else if scenePhase == .background {
                    // Save completed methods when app goes to background
                    sessionViewModel.saveCompletedMethodsToCache()
                }
            }
            .onChangeCompat(of: completionViewModel.showCompletionPrompt) { newValue in
                if previousCompletionPromptState && !newValue {
                    // Completion prompt was dismissed
                    isShowingCompletionPrompt = false
                }
                previousCompletionPromptState = newValue
            }
    }

    // MARK: - Main Content Views
    
    private var mainContent: some View {
        Group {
            if schedule.isRestDay {
                RestDayExperienceView(schedule: schedule)
            } else {
                practiceContent
            }
        }
        .modifier(NavigationSetupModifier(isEmbedded: isEmbedded, schedule: schedule))
        .modifier(ToolbarModifier(
            schedule: schedule,
            timerService: timerService,
            completionViewModel: completionViewModel,
            dismiss: dismiss
        ))
        // Add completion sheet
        .sheet(isPresented: $completionViewModel.showCompletionPrompt) {
            if let sessionLog = completionViewModel.sessionLog {
                let sessionProgress = SessionProgress(
                    sessionType: .multiMethod,
                    sessionId: sessionLog.id,
                    methodName: sessionViewModel.currentMethod?.title ?? "Practice Session",
                    startTime: sessionLog.startTime,
                    endTime: sessionLog.endTime,
                    totalMethods: sessionViewModel.totalMethods,
                    completedMethods: sessionViewModel.methodsCompleted,
                    attemptedMethods: sessionViewModel.methodsStarted
                )
                
                SessionCompletionPromptView(
                    sessionProgress: sessionProgress,
                    onLog: {
                        // Mark the current method as completed when user logs the session
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            let methodDuration = completionViewModel.elapsedTimeInSeconds
                            sessionViewModel.markMethodCompleted(methodId, duration: methodDuration)
                        }
                        
                        // Save session
                        completionViewModel.saveSession()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Check free tier limitation before auto-starting
                                    if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
                                        // Don't auto-start for free tier users who have completed a session
                                        showFreeTierAlert = true
                                    } else if TimerCoordinator.shared.canStartTimer(type: "main") {
                                        // Auto-start the timer for the next method
                                        timerService.start()
                                    }
                                }
                            }
                        } else {
                            // All methods complete - dismiss
                            dismiss()
                        }
                    },
                    onDismiss: {
                        completionViewModel.skipLogging()
                        
                        // Stop the timer and clear state when dismissing after completion
                        // This ensures we show the start session card instead of timer controls
                        timerService.stop()
                        BackgroundTimerTracker.shared.clearSavedState()
                        
                        // Reset the completion state for the current method since it wasn't logged
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.resetMethodCompletion(methodId)
                        }
                        
                        // Reset completion tracking flags
                        hasHandledTimerCompletion = false
                        isShowingCompletionPrompt = false
                    },
                    onPartialLog: sessionProgress.isPartiallyComplete ? {
                        // Log partial progress without navigating away
                        completionViewModel.skipLogging()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Check free tier limitation before auto-starting
                                    if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
                                        // Don't auto-start for free tier users who have completed a session
                                        showFreeTierAlert = true
                                    } else if TimerCoordinator.shared.canStartTimer(type: "main") {
                                        // Auto-start the timer for the next method
                                        timerService.start()
                                    }
                                }
                            }
                        } else {
                            // All methods complete - dismiss
                            dismiss()
                        }
                    } : nil
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .modifier(LifecycleModifier(
            schedule: schedule,
            sessionViewModel: sessionViewModel,
            completionViewModel: completionViewModel,
            timerService: timerService,
            hasActiveTimer: $hasActiveTimer,
            hasRestoredTimer: $hasRestoredTimer,
            hasHandledTimerCompletion: $hasHandledTimerCompletion,
            hasConfiguredTimer: $hasConfiguredTimer,
            isShowingCompletionPrompt: $isShowingCompletionPrompt,
            isViewVisible: $isViewVisible,
            previousMethodIndex: $previousMethodIndex,
            previousMethodId: $previousMethodId,
            previousLoadingState: $previousLoadingState,
            configureTimerForMethod: configureTimerForMethod,
            handleTimerCompletion: handleTimerCompletion
        ))
        .alert("Timer Already Running", isPresented: $showTimerConflictAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please stop the quick practice timer before starting this session.")
        }
        .alert("Free Tier Limit", isPresented: $showFreeTierAlert) {
            Button("OK", role: .cancel) { }
            Button("Upgrade", role: .none) {
                // Navigate to subscription view
                if !isEmbedded {
                    dismiss()
                }
                // Post notification to switch to subscription tab
                NotificationCenter.default.post(
                    name: Notification.Name("switchToSubscriptionTab"),
                    object: nil
                )
            }
        } message: {
            Text("You've completed your daily practice session. Upgrade to Premium for unlimited daily sessions and access to all features.")
        }
    }
    
    private var practiceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                playbackControlsSection
                methodsListSection
            }
            .padding()
        }
    }

    // MARK: - Subviews
    
    private var integratedTimerSection: some View {
        VStack(spacing: 24) {
            // Timer display card
            VStack(spacing: 12) {
                // Time display
                Text(displayTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextColor"))
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                
                // Current method name
                if let method = sessionViewModel.currentMethod {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("GrowthGreen"))
                        .multilineTextAlignment(.center)
                }
                
                // Progress bar
                if timerService.timerMode == TimerMode.countdown {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color("NeutralGray").opacity(0.15))
                                .frame(height: 6)
                            
                            // Progress
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * timerProgress, height: 6)
                                .animation(.linear(duration: 0.5), value: timerProgress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            
            // Auto-progression toggle for multi-method sessions
            if sessionViewModel.totalMethods > 1 {
                HStack {
                    Label("Auto-progress to next method", systemImage: "arrow.right.circle")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    Spacer()
                    
                    Toggle("", isOn: $sessionViewModel.autoProgressionEnabled)
                        .tint(Color("GrowthGreen"))
                        .scaleEffect(0.85)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            
            // Error message
            if !timerBlockedMessage.isEmpty {
                Text(timerBlockedMessage)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("ErrorColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: timerBlockedMessage)
            }
            
            // Timer controls - unified row
            HStack(spacing: 16) {
                // Back button (go to previous method)
                Button(action: {
                    // Move to previous method
                    sessionViewModel.goToPreviousMethod()
                    
                    // Configure timer for previous method
                    if let previousMethod = sessionViewModel.currentMethod {
                        configureTimerForMethod(previousMethod)
                        // Keep timer in its current state (don't auto-start)
                        if timerService.timerState == .running {
                            timerService.start()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(sessionViewModel.currentMethodIndex > 0 ? Color("TextColor") : Color("TextColor").opacity(0.3))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(sessionViewModel.currentMethodIndex == 0)
                
                // Stop button
                Button(action: {
                    // Ensure session tracking is up to date before stopping
                    if let method = sessionViewModel.currentMethod {
                        updateSessionTracking(for: method)
                        
                        // Don't mark the method as completed here - wait for user to log it
                        // This ensures the completion prompt always shows
                        // The method will be marked complete when the user taps "Log Session"
                    }
                    
                    // Stop timer and show completion prompt
                    let timerElapsedTime = timerService.elapsedTime
                    timerService.stop()
                    
                    // Complete session with proper parameters
                    if let currentMethod = sessionViewModel.currentMethod {
                        completionViewModel.completeSession(
                            methodId: currentMethod.id,
                            duration: timerElapsedTime,
                            startTime: Date().addingTimeInterval(-timerElapsedTime)
                        )
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("ErrorColor").opacity(0.12))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("ErrorColor"))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Play/Pause button - central and larger
                Button(action: {
                    if timerService.timerState == .running {
                        timerService.pause()
                    } else if timerService.timerState == .paused {
                        timerService.resume()
                    } else {
                        // Timer is stopped - check free tier limitation first
                        if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
                            showFreeTierAlert = true
                            return
                        }
                        
                        // Then check if we can start the timer
                        if !TimerCoordinator.shared.canStartTimer(type: "main") {
                            // Set error message
                            timerBlockedMessage = "Quick timer is already running"
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            // Clear message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                timerBlockedMessage = ""
                            }
                            return
                        }
                        timerService.start()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color("GrowthGreen").opacity(0.35), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: timerService.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Skip button (advances to next method)
                if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                    Button(action: {
                        // Mark current method as completed
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.markMethodCompleted(methodId, duration: 0)
                        }
                        
                        // Move to next method
                        sessionViewModel.goToNextMethod()
                        
                        // Configure timer for new method
                        if let nextMethod = sessionViewModel.currentMethod {
                            configureTimerForMethod(nextMethod)
                            
                            // Check free tier limitation before starting
                            if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
                                showFreeTierAlert = true
                            } else if TimerCoordinator.shared.canStartTimer(type: "main") {
                                // Check if we can start the timer
                                timerService.start()
                            } else {
                                // Set error message
                                timerBlockedMessage = "Quick timer is already running"
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                // Clear message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    timerBlockedMessage = ""
                                }
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color("TextColor"))
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    // Empty spacer to maintain balance
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 56, height: 56)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Compact header info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.dayName)
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(Color("TextColor"))
                    
                    if let methodCount = schedule.methodIds?.count {
                        HStack(spacing: 6) {
                            Image(systemName: practiceTypeIcon)
                                .font(.system(size: 14))
                                .foregroundColor(practiceTypeColor)
                            
                            Text("\(methodCount) Method\(methodCount == 1 ? "" : "s")")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                            
                            Text("•")
                                .foregroundColor(Color("TextSecondaryColor").opacity(0.5))
                            
                            Text(practiceType.accessibilityLabel)
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                }
                
                Spacer()
                
                // Intensity indicator - refined
                VStack(spacing: 6) {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < intensityLevel ? practiceTypeColor : Color("NeutralGray").opacity(0.2))
                                .frame(width: 4, height: 12 + CGFloat(index * 4))
                        }
                    }
                    
                    Text("Intensity")
                        .font(AppTheme.Typography.gravityBook(10))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Description
            if !schedule.description.isEmpty {
                Text(schedule.description)
                    .font(AppTheme.Typography.gravityBook(15))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            practiceTypeColor.opacity(0.08),
                            practiceTypeColor.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(practiceTypeColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var playbackControlsSection: some View {
        if sessionViewModel.isSessionComplete {
            return AnyView(
                VStack(spacing: 16) {
                    Text("Routine Completed ✅")
                        .font(AppTheme.Typography.gravitySemibold(17))
                        .foregroundColor(Color("GrowthGreen"))
                        .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        // Story 16.4: Complete session and show intelligent prompt
                        if let currentMethod = sessionViewModel.currentMethod {
                            completionViewModel.completeSession(
                                methodId: currentMethod.id,
                                duration: TimeInterval(sessionViewModel.totalElapsedTime),
                                startTime: Date().addingTimeInterval(-TimeInterval(sessionViewModel.totalElapsedTime))
                            )
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Routine")
                                .font(AppTheme.Typography.gravitySemibold(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("GrowthGreen"))
                        .cornerRadius(12)
                    }
                }
            )
        }

        return AnyView(
            VStack(spacing: 0) {
                // Integrated timer display section
                // Show timer section when it's running or paused
                if timerService.timerState != .stopped {
                    integratedTimerSection
                        .padding(.bottom, 24)
                } else {
                    // Start session card when timer is stopped
                    VStack(spacing: 16) {
                        // Current method info
                        if sessionViewModel.isLoadingMethods {
                            // Show loading state while methods are being fetched
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading methods...")
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        } else if let method = sessionViewModel.currentMethod {
                            VStack(spacing: 8) {
                                Text("Ready to start")
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                
                                Text(method.title)
                                    .font(AppTheme.Typography.gravitySemibold(20))
                                    .foregroundColor(Color("TextColor"))
                                    .multilineTextAlignment(.center)
                                
                                if let duration = sessionViewModel.getCurrentMethodCustomDuration() ?? method.estimatedDurationMinutes {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 12))
                                        Text("\(duration) minutes")
                                            .font(AppTheme.Typography.gravityBook(13))
                                    }
                                    .foregroundColor(Color("TextSecondaryColor"))
                                }
                            }
                        }
                        
                        // Error message
                        if !timerBlockedMessage.isEmpty {
                            Text(timerBlockedMessage)
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(Color("ErrorColor"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: timerBlockedMessage)
                        }
                        
                        // Start button
                        Button(action: {
                            // Check free tier limitation
                            if !entitlementManager.hasAnyPremiumAccess && hasCompletedSessionToday() {
                                showFreeTierAlert = true
                                return
                            }
                            
                            // Check if we can start the main timer
                            if !TimerCoordinator.shared.canStartTimer(type: "main") {
                                // Set error message
                                timerBlockedMessage = "Quick timer is already running"
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                // Clear message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    timerBlockedMessage = ""
                                }
                                return
                            }
                            
                            // Don't start if we're showing completion prompt
                            if completionViewModel.showCompletionPrompt {
                                return
                            }
                            
                            if let method = sessionViewModel.currentMethod {
                                // Configure timer first
                                configureTimerForMethod(method)
                                
                                // Check if timer can start through coordinator
                                if TimerCoordinator.shared.canStartTimer(type: "main") {
                                    // Start timer
                                    timerService.start()
                                    
                                    // Update session tracking
                                    updateSessionTracking(for: method)
                                } else {
                                    // Set error message
                                    timerBlockedMessage = "Quick timer is already running"
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    // Clear message after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        timerBlockedMessage = ""
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Start Session")
                                    .font(AppTheme.Typography.gravitySemibold(17))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color("GrowthGreen").opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                    .padding(.bottom, 24)
                }
            }
        )
    }

    private var routineInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(AppTheme.Typography.gravitySemibold(15))
                .foregroundColor(Color("GrowthGreen"))
            Text(schedule.description)
                .font(AppTheme.Typography.gravityBook(13))
        }
    }

    private var methodsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Methods")
                .font(AppTheme.Typography.gravitySemibold(15))
                .foregroundColor(Color("GrowthGreen"))
            
            if schedule.isRestDay {
                restDayCard
            } else if sessionViewModel.isLoadingMethods {
                ProgressView()
            } else if !sessionViewModel.methods.isEmpty {
                methodsList
            }
        }
    }
    
    private var restDayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Take a Rest Day ��")
                .font(AppTheme.Typography.gravitySemibold(15))
            Text("Today is focused on recovery. Consider light walking, gentle stretching, hydration, and adequate sleep. Listen to your body and avoid strenuous activity.")
                .font(AppTheme.Typography.gravityBook(13))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var methodsList: some View {
        ForEach(Array(sessionViewModel.methods.enumerated()), id: \.element.id) { index, method in
            methodCard(method: method, index: index)
        }
    }
    
    @ViewBuilder
    private func methodCard(method: GrowthMethod, index: Int) -> some View {
        let methodId = method.id ?? ""
        let isCurrentMethod = index == sessionViewModel.currentMethodIndex
        let isCompleted = sessionViewModel.methodCompletionStatus[methodId]?.completed ?? false
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                // Method number indicator with completion state
                Circle()
                    .fill(isCompleted ? Color("GrowthGreen") : (isCurrentMethod ? Color("GrowthGreen").opacity(0.7) : Color.gray.opacity(0.3)))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(AppTheme.Typography.gravitySemibold(12))
                                    .foregroundColor(isCurrentMethod ? .white : Color("TextSecondaryColor"))
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(isCompleted ? Color("GrowthGreen") : (isCurrentMethod ? Color("GrowthGreen").opacity(0.8) : Color("TextColor")))
                        .strikethrough(isCompleted, color: Color("GrowthGreen").opacity(0.5))
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(isCompleted ? Color("TextSecondaryColor").opacity(0.7) : .secondary)
                }
                Spacer()
                // Recommended time - use custom duration if available
                if let customMins = sessionViewModel.getCustomDuration(for: index), customMins > 0 {
                    Text("\(customMins) min")
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(.secondary)
                } else if let mins = method.estimatedDurationMinutes, mins > 0 {
                    Text("\(mins) min")
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(.secondary)
                }
                Button(action: {
                    withAnimation {
                        if expandedMethods.contains(methodId) {
                            expandedMethods.remove(methodId)
                        } else {
                            expandedMethods.insert(methodId)
                        }
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expandedMethods.contains(methodId) ? 180 : 0))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: expandedMethods.contains(methodId))
                }
            }

            if expandedMethods.contains(methodId) {
                methodSteps(for: method)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentMethod ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrentMethod)
    }
    
    @ViewBuilder
    private func methodSteps(for method: GrowthMethod) -> some View {
        let methodId = method.id ?? ""
        let steps = method.instructionsText.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(idx+1).")
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(Color("GrowthGreen"))
                    Text(step)
                        .font(AppTheme.Typography.gravityBook(13))
                }
            }
        }
        .transition(.opacity.combined(with: .slide))
        .animation(.spring(), value: expandedMethods.contains(methodId))
    }

    private var progress: Double {
        let total = Double(viewModel.totalDurationMinutes * 60)
        guard total > 0 else { return 0 }
        // Calculate elapsed time
        let elapsed = total - Double(viewModel.remainingSeconds)
        return elapsed / total
    }
    
    private var timerProgress: Double {
        switch timerService.timerMode {
        case .stopwatch:
            return 0
        case .countdown:
            guard let totalDuration = timerService.totalDuration, totalDuration > 0 else { return 0 }
            return timerService.elapsedTime / totalDuration
        case .interval:
            return timerService.overallProgress
        }
    }
    
    private var displayTime: String {
        switch timerService.timerMode {
        case .stopwatch:
            return formatTime(timerService.elapsedTime)
        case .countdown, .interval:
            // Always show remaining time for countdown/interval modes
            // If it's 0 and we have a method, show the custom duration or method duration
            if timerService.remainingTime == 0,
               let method = sessionViewModel.currentMethod,
               let duration = sessionViewModel.getCurrentMethodCustomDuration() ?? method.estimatedDurationMinutes {
                return formatTime(TimeInterval(duration * 60))
            }
            return formatTime(timerService.remainingTime)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Computed Properties for Day Type
    
    private var practiceType: PracticeType {
        let dayNameLower = schedule.dayName.lowercased()
        
        if schedule.isRestDay {
            return .rest
        } else if dayNameLower.contains("heavy") {
            return .heavy
        } else if dayNameLower.contains("moderate") {
            return .moderate
        } else if dayNameLower.contains("light") {
            return .light
        } else {
            // Default based on method count
            let methodCount = schedule.methodIds?.count ?? 0
            if methodCount >= 3 {
                return .heavy
            } else if methodCount == 2 {
                return .moderate
            } else {
                return .light
            }
        }
    }
    
    private var practiceTypeColor: Color {
        switch practiceType {
        case .heavy:
            return Color("GrowthGreen")
        case .moderate:
            return Color("BrightTeal")
        case .light:
            return Color("MintGreen")
        case .rest:
            return Color("PaleGreen")
        }
    }
    
    private var practiceTypeIcon: String {
        switch practiceType {
        case .heavy:
            return "flame.fill"
        case .moderate:
            return "bolt.fill"
        case .light:
            return "sparkle"
        case .rest:
            return "leaf.fill"
        }
    }
    
    private var intensityLevel: Int {
        switch practiceType {
        case .heavy:
            return 3
        case .moderate:
            return 2
        case .light:
            return 1
        case .rest:
            return 0
        }
    }

    // Helper for time formatting
    private func format(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // Check if user has completed a session today (for free tier limitation)
    private func hasCompletedSessionToday() -> Bool {
        // Check if any methods have been completed today
        return sessionViewModel.methodsCompleted > 0
    }

    private func heroImageName() -> String? {
        // Implementation of heroImageName function
        return nil
    }
    
    // MARK: - Timer Configuration
    
    private func configureTimerForMethod(_ method: GrowthMethod) {
        // Set method ID and name for tracking
        timerService.currentMethodId = method.id
        timerService.currentMethodName = method.title
        
        // Reset completion view model if we're configuring a new method
        // This ensures previous session completion state doesn't block new timer configuration
        if completionViewModel.showCompletionPrompt {
            completionViewModel.reset()
        }
        
        // Reset completion flag and timer state tracking when configuring for a new method
        hasHandledTimerCompletion = false
        isShowingCompletionPrompt = false
        lastTimerState = timerService.timerState
        isConfiguringTimer = true
        
        
        
        // If timer is paused with 0 remaining time and we're configuring a new method,
        // it means we're transitioning to a new method - force stop to reset
        if timerService.timerState == TimerState.paused && 
           timerService.remainingTime <= 0 &&
           timerService.currentMethodId != method.id {
            timerService.stop()
        }
        
        // Don't reconfigure if timer is running (likely restored from background)
        if timerService.timerState == TimerState.running {
            return
        }
        
        // Force timer to stopped state before configuration
        if timerService.timerState != TimerState.stopped {
            timerService.stop()
        }
        
        // Configure timer based on method configuration
        if let config = method.timerConfig {
            
            // Only use timerConfig if it has valid duration or intervals
            if (config.recommendedDurationSeconds ?? 0) > 0 || (config.intervals?.count ?? 0) > 0 {
                timerService.configure(with: config)
            } else {
                // Use custom duration if available, otherwise fall back to method's estimated duration
                let customDuration = sessionViewModel.getCurrentMethodCustomDuration()
                let estimatedDuration = method.estimatedDurationMinutes
                let duration = customDuration ?? estimatedDuration ?? 10 // Default 10 minutes
                timerService.configure(with: TimerConfiguration(
                    recommendedDurationSeconds: duration * 60,
                    isCountdown: true,
                    hasIntervals: false,
                    intervals: nil,
                    maxRecommendedDurationSeconds: nil
                ))
            }
        } else {
            // Default to countdown timer - use custom duration if available
            let customDuration = sessionViewModel.getCurrentMethodCustomDuration()
            let estimatedDuration = method.estimatedDurationMinutes
            let duration = customDuration ?? estimatedDuration ?? 10 // Default 10 minutes
            timerService.configure(with: TimerConfiguration(
                recommendedDurationSeconds: duration * 60,
                isCountdown: true,
                hasIntervals: false,
                intervals: nil,
                maxRecommendedDurationSeconds: nil
            ))
        }
        
        
        // Clear configuration flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isConfiguringTimer = false
        }
    }
    
    private func updateSessionTracking(for method: GrowthMethod) {
        // Session tracking is handled by sessionViewModel
        // completionViewModel is only for the final completion prompt
        
        // Mark method as started in sessionViewModel
        if let methodId = method.id {
            sessionViewModel.markMethodStarted(methodId)
        }
    }
    
    private func syncCompletionStateFromCache() {
        // Use the view model's built-in cache loading
        sessionViewModel.loadCompletedMethodsFromCache()
        
        // Advance to the next uncompleted method
        if sessionViewModel.methodsCompleted > 0 {
            var shouldAdvance = true
            while shouldAdvance && sessionViewModel.canGoNext {
                // Check if current method is completed
                if let currentMethod = sessionViewModel.currentMethod,
                   let methodId = currentMethod.id,
                   let status = sessionViewModel.methodCompletionStatus[methodId],
                   status.completed {
                    // Current method is completed, advance to next
                    sessionViewModel.goToNextMethod()
                } else {
                    // Current method is not completed, stop advancing
                    shouldAdvance = false
                }
            }
            
            // Force UI update
            sessionViewModel.objectWillChange.send()
        }
    }
    
    private func handleTimerCompletion() {
        // Prevent duplicate handling
        guard !completionViewModel.showCompletionPrompt else {
            return
        }
        
        // Check if view is still visible before showing sheet
        if !isViewVisible {
            // Still mark the method as completed for progress tracking
            if let method = sessionViewModel.currentMethod,
               let methodId = method.id {
                sessionViewModel.markMethodCompleted(methodId, duration: timerService.elapsedTime)
            }
            return
        }
        
        // Mark that we're showing the completion prompt immediately
        isShowingCompletionPrompt = true
        
        
        // Pause the timer (TimerService calls this when timer completes)
        // Only pause if not already paused to avoid triggering extra state changes
        if timerService.timerState != TimerState.paused {
            timerService.pause()
        }
        
        // Play completion sound/haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Capture the elapsed time BEFORE any state changes
        let capturedElapsedTime = timerService.elapsedTime
        
        // Mark current method as completed
        if let method = sessionViewModel.currentMethod,
           let methodId = method.id {
            
            // Update completion in session view model with captured duration
            sessionViewModel.markMethodCompleted(methodId, duration: capturedElapsedTime)
            
            
            // Update routine progress to increment nextMethodIndex
            if let userId = Auth.auth().currentUser?.uid,
               let routineId = routinesViewModel.selectedRoutineId {
                RoutineProgressService.shared.incrementMethodIndex(userId: userId, routineId: routineId) { updatedProgress in
                    if let progress = updatedProgress {
                        // Update the routinesViewModel's progress
                        DispatchQueue.main.async {
                            self.routinesViewModel.routineProgress = progress
                            // Post notification to update UI
                            NotificationCenter.default.post(name: .routineProgressUpdated, object: progress)
                        }
                    }
                }
            }
            
            // Post notification for method completion
            NotificationCenter.default.post(name: .methodCompleted, object: nil, userInfo: ["methodId": methodId])
        }
        
        // Check if auto-progression is enabled and we can go to next method
        let isAutoProgressEnabled = sessionViewModel.autoProgressionEnabled
        let canProgress = sessionViewModel.canGoNext
        
        Logger.debug("[DailyRoutineView] Timer completed. Auto-progression enabled: \(isAutoProgressEnabled), canGoNext: \(canProgress)")
        
        // Only auto-advance if explicitly enabled by user
        if isAutoProgressEnabled == true && canProgress == true {
            
            // Stop the timer before progressing to next method
            timerService.stop()
            
            // Auto-progress to next method after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Move to next method
                sessionViewModel.goToNextMethod()
                
                // Configure timer for next method
                if let nextMethod = sessionViewModel.currentMethod {
                    configureTimerForMethod(nextMethod)
                    
                    // Start the timer automatically if possible
                    if TimerCoordinator.shared.canStartTimer(type: "main") {
                        timerService.start()
                    } else {
                        // Set error message
                        timerBlockedMessage = "Quick timer is already running"
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        // Clear message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            timerBlockedMessage = ""
                        }
                    }
                    
                    // Update session tracking for the new method
                    if let methodId = nextMethod.id {
                        sessionViewModel.markMethodStarted(methodId)
                    }
                }
            }
        } else {
            // If not auto-progressing, stop the timer after a short delay to allow completion handling
            // This ensures the timer doesn't remain in paused state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                timerService.stop()
                TimerCoordinator.shared.timerStopped(type: "main")
            }
            
            // Show completion prompt if auto-progression is disabled or on last method
            if let currentMethod = sessionViewModel.currentMethod {
                
                // Call completeSession directly - it's already @MainActor
                completionViewModel.completeSession(
                    methodId: currentMethod.id,
                    duration: capturedElapsedTime,
                    startTime: Date().addingTimeInterval(-capturedElapsedTime),
                    variation: currentMethod.title
                )
                
                // Use global completion service to show the prompt
                // Wait a bit for sessionLog to be populated after completeSession
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let sessionLog = completionViewModel.sessionLog {
                        let sessionProgress = SessionProgress(
                            sessionType: .multiMethod,
                            sessionId: sessionLog.id,
                            methodName: sessionViewModel.currentMethod?.title ?? "Practice Session",
                            startTime: sessionLog.startTime,
                            endTime: sessionLog.endTime,
                            totalMethods: sessionViewModel.totalMethods,
                            completedMethods: sessionViewModel.methodsCompleted,
                            attemptedMethods: sessionViewModel.methodsStarted
                        )
                        
                        SessionCompletionService.shared.showCompletion(
                            sessionProgress: sessionProgress,
                            completionViewModel: completionViewModel,
                            sessionViewModel: sessionViewModel,
                            timerService: timerService,
                            configureTimerForMethod: configureTimerForMethod,
                            hasHandledTimerCompletion: $hasHandledTimerCompletion,
                            isShowingCompletionPrompt: $isShowingCompletionPrompt
                        )
                    }
                }
            }
            
            // Special handling for the last method
            if !sessionViewModel.canGoNext {
                
                // Delay stopping the timer to allow the completion sheet to appear
                // The timer will be stopped when the user logs or dismisses the completion sheet
                // This ensures the sheet has time to present properly
                
                // Don't mark as completed here - let the session logging handle it
                // This prevents the practice view from showing completed state prematurely
            }
        }
    }
}

// MARK: - View Modifiers

private struct NavigationSetupModifier: ViewModifier {
    let isEmbedded: Bool
    let schedule: DaySchedule
    
    func body(content: Content) -> some View {
        if !isEmbedded {
            content
                .breadcrumb(style: .practice)
                .navigationTitle(schedule.dayName)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
        }
    }
}

private struct ToolbarModifier: ViewModifier {
    let schedule: DaySchedule
    let timerService: TimerService
    let completionViewModel: SessionCompletionViewModel
    let dismiss: DismissAction
    
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    if schedule.isRestDay {
                        timerService.stop()
                        BackgroundTimerTracker.shared.clearSavedState()
                        dismiss()
                    } else {
                        // Just handle exit directly
                        timerService.stop()
                        BackgroundTimerTracker.shared.clearSavedState()
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Practice")
                            .font(AppTheme.Typography.bodyFont())
                    }
                }
            }
        }
    }
}

// MARK: - Completion Sheet Modifier (Moved to global SessionCompletionService)
/*
private struct CompletionSheetModifier: ViewModifier {
    @ObservedObject var completionViewModel: SessionCompletionViewModel
    @ObservedObject var sessionViewModel: MultiMethodSessionViewModel
    let timerService: TimerService
    let dismiss: DismissAction
    let configureTimerForMethod: (GrowthMethod) -> Void
    @Binding var hasHandledTimerCompletion: Bool
    @Binding var isShowingCompletionPrompt: Bool
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: $completionViewModel.showCompletionPrompt) {
            if let sessionLog = completionViewModel.sessionLog {
                let sessionProgress = SessionProgress(
                    sessionType: .multiMethod,
                    sessionId: sessionLog.id,
                    methodName: sessionViewModel.currentMethod?.title ?? "Practice Session",
                    startTime: sessionLog.startTime,
                    endTime: sessionLog.endTime,
                    totalMethods: sessionViewModel.totalMethods,
                    completedMethods: sessionViewModel.methodsCompleted,
                    attemptedMethods: sessionViewModel.methodsStarted
                )
                
                SessionCompletionPromptView(
                    sessionProgress: sessionProgress,
                    onLog: {
                        // Mark the current method as completed when user logs the session
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            let methodDuration = completionViewModel.elapsedTimeInSeconds
                            sessionViewModel.markMethodCompleted(methodId, duration: methodDuration)
                        }
                        
                        // Save session
                        completionViewModel.saveSession()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        } else {
                            // All methods completed - reset state but don't dismiss
                            // Let the user decide when to leave the routine view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                BackgroundTimerTracker.shared.clearSavedState()
                                // Reset completion tracking flags
                                hasHandledTimerCompletion = false
                                isShowingCompletionPrompt = false
                                // Don't call dismiss() - let user navigate away when ready
                            }
                        }
                    },
                    onDismiss: {
                        completionViewModel.skipLogging()
                        
                        // Stop the timer and clear state when dismissing after completion
                        // This ensures we show the start session card instead of timer controls
                        timerService.stop()
                        BackgroundTimerTracker.shared.clearSavedState()
                        
                        // Reset the completion state for the current method since it wasn't logged
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.resetMethodCompletion(methodId)
                        }
                        
                        // Reset completion tracking flags
                        hasHandledTimerCompletion = false
                        isShowingCompletionPrompt = false
                        // Post notification that session was dismissed without logging
                        NotificationCenter.default.post(name: .sessionDismissedWithoutLogging, object: nil)
                        // Don't call dismiss() - let user stay in the view
                    },
                    onPartialLog: sessionProgress.isPartiallyComplete ? {
                        // Log partial progress without navigating away
                        completionViewModel.skipLogging()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        }
                        // Don't dismiss - stay in the routine view
                    } : nil
                )
            } else {
                // Fallback if no session log exists yet
                let sessionProgress = SessionProgress(
                    sessionType: .multiMethod,
                    methodName: sessionViewModel.currentMethod?.title ?? "Practice Session",
                    totalMethods: sessionViewModel.totalMethods,
                    completedMethods: sessionViewModel.methodsCompleted,
                    attemptedMethods: sessionViewModel.methodsStarted
                )
                
                SessionCompletionPromptView(
                    sessionProgress: sessionProgress,
                    onLog: {
                        // Mark the current method as completed when user logs the session
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            let methodDuration = completionViewModel.elapsedTimeInSeconds
                            sessionViewModel.markMethodCompleted(methodId, duration: methodDuration)
                        }
                        
                        // Save session
                        completionViewModel.saveSession()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        } else {
                            // All methods completed - reset state but don't dismiss
                            // Let the user decide when to leave the routine view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                BackgroundTimerTracker.shared.clearSavedState()
                                // Reset completion tracking flags
                                hasHandledTimerCompletion = false
                                isShowingCompletionPrompt = false
                                // Don't call dismiss() - let user navigate away when ready
                            }
                        }
                    },
                    onDismiss: {
                        completionViewModel.skipLogging()
                        
                        // Stop the timer and clear state when dismissing after completion
                        // This ensures we show the start session card instead of timer controls
                        timerService.stop()
                        BackgroundTimerTracker.shared.clearSavedState()
                        
                        // Reset the completion state for the current method since it wasn't logged
                        if let method = sessionViewModel.currentMethod,
                           let methodId = method.id {
                            sessionViewModel.resetMethodCompletion(methodId)
                        }
                        
                        // Reset completion tracking flags
                        hasHandledTimerCompletion = false
                        isShowingCompletionPrompt = false
                        // Post notification that session was dismissed without logging
                        NotificationCenter.default.post(name: .sessionDismissedWithoutLogging, object: nil)
                        // Don't call dismiss() - let user stay in the view
                    },
                    onPartialLog: sessionProgress.isPartiallyComplete ? {
                        // Log partial progress without navigating away
                        completionViewModel.skipLogging()
                        
                        // Stop the timer first to ensure clean state
                        timerService.stop()
                        
                        // Check if there are more methods to complete
                        if sessionViewModel.currentMethodIndex < sessionViewModel.totalMethods - 1 {
                            // Move to next method after logging
                            sessionViewModel.goToNextMethod()
                            
                            // Configure timer for next method after a small delay to ensure clean state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let nextMethod = sessionViewModel.currentMethod {
                                    configureTimerForMethod(nextMethod)
                                    
                                    // Update session tracking for the new method
                                    if let methodId = nextMethod.id {
                                        // Mark method as started in session view model
                                        sessionViewModel.markMethodStarted(methodId)
                                    }
                                }
                            }
                        }
                        // Don't dismiss - stay in the routine view
                    } : nil
                )
            }
        }
    }
}
*/

private struct LifecycleModifier: ViewModifier {
    let schedule: DaySchedule
    @ObservedObject var sessionViewModel: MultiMethodSessionViewModel
    @ObservedObject var completionViewModel: SessionCompletionViewModel
    @ObservedObject var timerService: Growth.TimerService
    @Binding var hasActiveTimer: Bool
    @Binding var hasRestoredTimer: Bool
    @Binding var hasHandledTimerCompletion: Bool
    @Binding var hasConfiguredTimer: Bool
    @Binding var isShowingCompletionPrompt: Bool
    @Binding var isViewVisible: Bool
    @Binding var previousMethodIndex: Int
    @Binding var previousMethodId: String?
    @Binding var previousLoadingState: Bool
    let configureTimerForMethod: (GrowthMethod) -> Void
    let handleTimerCompletion: () -> Void
    
    @EnvironmentObject var navigationContext: NavigationContext
    @EnvironmentObject var smartNavigationService: SmartNavigationService
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                handleOnAppear()
            }
            .onDisappear {
                handleOnDisappear()
            }
            .onChangeCompat(of: sessionViewModel.currentMethodIndex) { newIndex in
                handleMethodIndexChange(oldIndex: previousMethodIndex, newIndex: newIndex)
                self.previousMethodIndex = newIndex
            }
            .onChangeCompat(of: sessionViewModel.currentMethod?.id) { newId in
                handleMethodIdChange(oldId: previousMethodId, newId: newId)
                self.previousMethodId = newId
            }
            .onChangeCompat(of: sessionViewModel.isLoadingMethods) { isLoading in
                handleLoadingChange(wasLoading: previousLoadingState, isLoading: isLoading)
                self.previousLoadingState = isLoading
            }
    }
    
    private func handleOnAppear() {
        
        // Mark view as visible
        isViewVisible = true
        
        // Practice view tracking removed
        
        hasActiveTimer = BackgroundTimerTracker.shared.hasActiveBackgroundTimer()
        if hasActiveTimer && !hasRestoredTimer {
            timerService.restoreFromBackground(isQuickPractice: false)
            hasRestoredTimer = true
            
            // Check immediately after restore
            
            // Check if timer was already completed in background
            if timerService.timerMode == TimerMode.countdown && 
               timerService.timerState == TimerState.paused && 
               timerService.remainingTime <= 0 && 
               timerService.elapsedTime > 0 &&
               !hasHandledTimerCompletion &&
               !completionViewModel.showCompletionPrompt &&
               !isShowingCompletionPrompt {  // Prevent duplicate handling
                hasHandledTimerCompletion = true
                isShowingCompletionPrompt = true
                
                // Update the method progress immediately
                if let method = sessionViewModel.currentMethod,
                   let methodId = method.id {
                    sessionViewModel.markMethodCompleted(methodId, duration: timerService.elapsedTime)
                }
                
                // Show completion prompt after a longer delay to ensure UI is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.handleTimerCompletion()
                }
            }
        }
        
        let methodCount = schedule.methodIds?.count ?? 0
        navigationContext.setupRoutineContext(
            dayNumber: schedule.dayNumber,
            dayName: schedule.dayName,
            totalMethods: methodCount,
            routineId: nil
        )
        
        if !schedule.isRestDay {
            if hasActiveTimer {
                // Ensure session is tracked when restoring from background
                // Session tracking is handled by sessionViewModel
                if let method = sessionViewModel.currentMethod,
                   let methodId = method.id {
                    sessionViewModel.markMethodStarted(methodId)
                }
            } else {
                // Check if timer is in completed state (paused with 0 remaining time)
                // This can happen when returning to the view after timer completed
                if timerService.timerMode == TimerMode.countdown && 
                   timerService.timerState == TimerState.paused && 
                   timerService.remainingTime <= 0 && 
                   timerService.elapsedTime > 0 &&
                   !hasHandledTimerCompletion &&
                   !completionViewModel.showCompletionPrompt &&
                   !isShowingCompletionPrompt {
                    hasHandledTimerCompletion = true
                    isShowingCompletionPrompt = true
                    
                    // Update the method progress immediately
                    if let method = sessionViewModel.currentMethod,
                       let methodId = method.id {
                        sessionViewModel.markMethodCompleted(methodId, duration: timerService.elapsedTime)
                    }
                    
                    // Show completion prompt after a delay to ensure UI is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.handleTimerCompletion()
                    }
                }
                // Session initialization is handled by sessionViewModel
            }
        }
    }
    
    private func handleOnDisappear() {
        // Mark view as not visible
        isViewVisible = false
        
        // Save completed methods to cache
        sessionViewModel.saveCompletedMethodsToCache()
        
        // Practice view tracking removed
        
        if timerService.timerState == TimerState.running {
            let methodName = sessionViewModel.currentMethod?.title ?? "Practice Session"
            timerService.saveStateForBackground(methodName: methodName)
        } else if sessionViewModel.isSessionComplete && timerService.timerState == TimerState.paused {
            // If session is complete and timer is just paused, stop it to end Live Activity
            timerService.stop()
        }
        
        navigationContext.clearContext()
    }
    
    private func handleMethodIndexChange(oldIndex: Int, newIndex: Int) {
        navigationContext.updateMethodProgress(to: newIndex + 1)
        smartNavigationService.prepareMethodTransition(
            from: oldIndex,
            to: newIndex
        )
        
        // Reset timer configuration flag when method changes
        hasConfiguredTimer = false
        
        if let newMethod = sessionViewModel.currentMethod,
           let methodId = newMethod.id {
            sessionViewModel.markMethodStarted(methodId)
        }
    }
    
    private func handleMethodIdChange(oldId: String?, newId: String?) {
        if oldId == nil && newId != nil && timerService.timerState == .stopped && !hasActiveTimer && !hasConfiguredTimer,
           let method = sessionViewModel.currentMethod {
            hasConfiguredTimer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                configureTimerForMethod(method)
            }
        } else if oldId == nil && newId != nil && hasActiveTimer {
        }
    }
    
    private func handleLoadingChange(wasLoading: Bool, isLoading: Bool) {
        if wasLoading && !isLoading && sessionViewModel.methods.count > 0 {
            
            // Session initialization is handled by sessionViewModel
            
            if !hasActiveTimer && !hasConfiguredTimer {
                if let firstMethod = sessionViewModel.currentMethod,
                   let methodId = firstMethod.id {
                    
                    if timerService.timerState == TimerState.stopped {
                        hasConfiguredTimer = true
                        configureTimerForMethod(firstMethod)
                    }
                    
                    sessionViewModel.markMethodStarted(methodId)
                }
            } else {
                if let firstMethod = sessionViewModel.currentMethod,
                   let methodId = firstMethod.id {
                    sessionViewModel.markMethodStarted(methodId)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let schedule = DaySchedule(id: "d3", dayNumber: 3, dayName: "Day 3: Moderate Day", description: "Angion Method 2.0 and S2S stretches. Optional light pumping.", methodIds: ["m1", "m2"], isRestDay: false, additionalNotes: nil)
    let routinesViewModel = RoutinesViewModel(userId: "preview_user")
    NavigationStack {
        DailyRoutineView(schedule: schedule, routinesViewModel: routinesViewModel)
    }
    .environmentObject(NavigationContext())
    .environmentObject(SmartNavigationService())
}
#endif

 