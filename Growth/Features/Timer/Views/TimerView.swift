//
//  TimerView.swift
//  Growth
//
//  Created by Developer on 4/10/2023.
//

import SwiftUI
import UserNotifications

/// TimerView presents the timer interface with controls and displays.
/// It supports three modes: stopwatch, countdown, and interval.
/// Story 7.3: Added overexertion warning for extended sessions
/// Story 7.4: Added session logging after timer completion
/// Story 16.1: Added multi-method session support
/// Story 16.4: Added intelligent exit handling and session completion prompts
struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @StateObject private var completionViewModel = SessionCompletionViewModel()
    @Environment(\.dismiss) var dismiss // For dismissing the view
    @EnvironmentObject var navigationContext: NavigationContext
    
    // Multi-method session properties
    let isMultiMethod: Bool
    let sessionViewModel: MultiMethodSessionViewModel?
    let onMethodComplete: (() -> Void)?

    // Initialize with an optional GrowthMethod
    // If method is nil, viewModel initializes with default (stopwatch)
    init(growthMethod: GrowthMethod? = nil, 
         isMultiMethod: Bool = false,
         sessionViewModel: MultiMethodSessionViewModel? = nil,
         onMethodComplete: (() -> Void)? = nil) {
        let vm = TimerViewModel(growthMethod: growthMethod)
        
        // Configure callbacks for multi-method sessions
        if isMultiMethod, let sessionVM = sessionViewModel {
            vm.onTimeUpdate = { timeRemaining in
                sessionVM.updateMethodTime(Int(timeRemaining))
            }
            vm.onTimerComplete = onMethodComplete
        }
        
        _viewModel = StateObject(wrappedValue: vm)
        self.isMultiMethod = isMultiMethod
        self.sessionViewModel = sessionViewModel
        self.onMethodComplete = onMethodComplete
    }

    var body: some View {
        TimerViewContent(viewModel: viewModel, 
                       completionViewModel: completionViewModel,
                       dismiss: dismiss, 
                       isMultiMethod: isMultiMethod,
                       sessionViewModel: sessionViewModel,
                       onMethodComplete: onMethodComplete)
        .onAppear {
            // Story 16.4: Start session tracking only if not resuming from background
            if !viewModel.timerService.hasActiveBackgroundTimer() {
                if let method = viewModel.getCurrentMethod() {
                    completionViewModel.startSession(
                        type: isMultiMethod ? .multiMethod : .single,
                        methodId: method.id ?? UUID().uuidString,
                        methodName: method.title,
                        totalMethods: sessionViewModel?.totalMethods ?? 1
                    )
                } else {
                    completionViewModel.startSession(type: .quickPractice)
                }
            }
        }
        // Story 7.3: Add sheet for overexertion warning
        .sheet(isPresented: $viewModel.isOverexertionWarningActive, onDismiss: {
            if viewModel.isOverexertionWarningActive { 
                 viewModel.acknowledgeOverexertion()
            }
        }) {
            OverexertionWarningView(viewModel: viewModel)
        }
        // Story 16.4: Add intelligent completion prompt
        .sheet(isPresented: $completionViewModel.showCompletionPrompt) {
            if let sessionLog = completionViewModel.sessionLog, let method = viewModel.getCurrentMethod() {
                // Create SessionProgress with proper times from sessionLog
                let sessionProgress = SessionProgress(
                    sessionType: isMultiMethod ? .multiMethod : .single,
                    sessionId: sessionLog.id,
                    methodId: method.id,
                    methodName: method.title,
                    startTime: sessionLog.startTime,
                    endTime: sessionLog.endTime,
                    totalMethods: sessionViewModel?.totalMethods ?? 1,
                    completedMethods: sessionViewModel?.methodsCompleted ?? 1
                )
                SessionCompletionPromptView(
                    sessionProgress: sessionProgress,
                    onLog: {
                        completionViewModel.saveSession()
                        viewModel.resetAfterCompletion()
                        viewModel.wasStoppedFromLiveActivity = false  // Reset the flag
                        dismiss()
                    },
                    onDismiss: {
                        viewModel.resetAfterCompletion()
                        viewModel.wasStoppedFromLiveActivity = false  // Reset the flag
                        // Post notification that session was dismissed without logging
                        NotificationCenter.default.post(name: .sessionDismissedWithoutLogging, object: nil)
                        dismiss()
                    },
                    onPartialLog: nil
                )
                // Make the sheet persistent when triggered from Live Activity
                .interactiveDismissDisabled(viewModel.wasStoppedFromLiveActivity)
            }
        }
        // Story 7.4: Add sheet for session logging (legacy flow)
        .sheet(isPresented: $viewModel.showLogSessionView) {
            // Only show the LogSessionView if we have a method to log
            if let method = viewModel.getCurrentMethod() {
                LogSessionView(method: method,
                              duration: viewModel.getSessionDurationInMinutes(),
                              preMoodBefore: viewModel.moodBefore)
            }
        }
        // Story 8.4: Pre-Session Mood Check-in
        .sheet(isPresented: $viewModel.showPreSessionMoodSheet) {
            MoodCheckInView(onSelect: { mood in
                viewModel.setPreSessionMood(mood)
            }, onSkip: {
                viewModel.setPreSessionMood(nil)
            })
        }
    }
}

/// Content view for the timer to help break up complex view hierarchy
struct TimerViewContent: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var completionViewModel: SessionCompletionViewModel
    @EnvironmentObject var navigationContext: NavigationContext
    var dismiss: DismissAction
    
    // Multi-method session properties
    let isMultiMethod: Bool
    let sessionViewModel: MultiMethodSessionViewModel?
    let onMethodComplete: (() -> Void)?

    var body: some View {
        mainContent
            .background(AppTheme.Colors.background)
            .appleIntelligenceGlow(
                isActive: viewModel.timerState == .running,
                cornerRadius: 0,
                intensity: 0.7
            )
            .ignoresSafeArea(edges: .bottom)
            .overlay(overexertionOverlay)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: navigationBarLeading)
            .onAppear(perform: handleOnAppear)
            .onChange(of: viewModel.wasStoppedFromLiveActivity, perform: handleLiveActivityStop)
            .onDisappear(perform: handleOnDisappear)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Trigger check when app becomes active while this view is visible
                viewModel.checkForPendingTimerCompletion()
            }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Breadcrumb for navigation context
            if navigationContext.showBreadcrumb {
                BreadcrumbView(style: .practice)
                    .padding(.top, 8)
                    .padding(.bottom, AppTheme.Layout.spacingM)
            }
            
            VStack(spacing: AppTheme.Layout.spacingM) {
                // Sound Toggle
                soundToggleView
                
                // Method Progress Indicator for multi-method sessions
                methodProgressIndicator
                
                Spacer()
                
                // Debug components
                debugComponents
                
                // Timer display
                timerDisplay
                
                // Up Next Preview for multi-method sessions
                upNextPreview
                
                // Interval display (only for interval mode)
                intervalDisplaySection
                
                Spacer()
                
                // Controls or completion actions
                controlsSection
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Component Views
    
    private var methodProgressIndicator: some View {
        Group {
            if isMultiMethod, let sessionVM = sessionViewModel {
                MethodProgressIndicator(
                    currentMethod: sessionVM.currentMethodIndex + 1,
                    totalMethods: sessionVM.totalMethods,
                    totalTimeRemaining: sessionVM.totalTimeRemaining,
                    sessionProgress: sessionVM.sessionProgress,
                    isTimerRunning: viewModel.timerState == .running
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var debugComponents: some View {
        Group {
            #if DEBUG
            debugSpeedIndicator
            debugButtons
            #endif
        }
    }
    
    #if DEBUG
    private var debugSpeedIndicator: some View {
        Group {
            if viewModel.timerService.isDebugSpeedActive {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.system(size: 14, weight: .bold))
                    Text("DEV MODE: 5x Speed")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange, lineWidth: 2)
                )
                .scaleEffect(viewModel.timerState == .running ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.timerState)
            }
        }
    }
    
    private var debugButtons: some View {
        VStack(spacing: 8) {
            Button(action: {
                viewModel.performLiveActivityDebugCheck()
            }) {
                HStack {
                    Image(systemName: "ant.circle")
                    Text("Debug Live Activity")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .cornerRadius(8)
            }
            
            Button(action: {
                viewModel.testManualPushUpdate()
            }) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Test Push Update")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding(.top, 8)
    }
    #endif
    
    private var timerDisplay: some View {
        TimerDisplayView(time: viewModel.displayTime)
            .appleIntelligenceGlow(
                isActive: viewModel.timerState == .running,
                cornerRadius: 16,
                intensity: 1.0
            )
            .scaleEffect(viewModel.timerState == .running ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: viewModel.timerState)
    }
    
    private var upNextPreview: some View {
        Group {
            if isMultiMethod,
               let sessionVM = sessionViewModel,
               sessionVM.showUpNextPreview,
               let nextMethod = sessionVM.nextMethod {
                UpNextPreview(nextMethod: nextMethod)
                    .padding(.horizontal)
                    .transition(AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity))
                    .animation(Animation.spring(response: 0.5, dampingFraction: 0.8), value: sessionVM.showUpNextPreview)
            }
        }
    }
    
    private var overexertionOverlay: some View {
        viewModel.isOverexertionWarningActive ?
            Color.red.opacity(0.1) : Color.clear
    }
    
    private var navigationBarLeading: some View {
        Group {
            if !viewModel.showCompletionActions {
                Button("Close") {
                    // Story 16.4: Check if exit should show prompt
                    if completionViewModel.handleExitRequest() {
                        viewModel.stopTimer()
                        dismiss()
                    }
                    // Otherwise, the completion prompt will be shown
                }
                .foregroundColor(AppTheme.Colors.text)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleOnAppear() {
        // Check for and restore background timer state
        // Add a small delay to ensure any pending Live Activity actions are processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if viewModel.timerService.hasActiveBackgroundTimer() {
                // Double-check the timer state hasn't been stopped
                if viewModel.timerService.state != .stopped {
                    viewModel.timerService.restoreFromBackground()
                }
            }
        }
        
        // Request notification permissions if not already granted
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("TimerView: Notification permissions granted")
                    }
                }
            }
        }
    }
    
    private func handleLiveActivityStop(wasStoppedFromLiveActivity: Bool) {
        // When the timer is stopped from Live Activity, trigger the completion flow
        if wasStoppedFromLiveActivity {
            // Reset the flag
            viewModel.wasStoppedFromLiveActivity = false
            
            // Trigger the completion flow if we have a method
            if let method = viewModel.getCurrentMethod() {
                // Use the captured values from when stop was pressed
                completionViewModel.completeSession(
                    methodId: method.id,
                    duration: viewModel.lastCapturedElapsedTime,
                    startTime: viewModel.lastCapturedStartTime,
                    variation: method.title
                )
            }
        }
    }
    
    private func handleOnDisappear() {
        // If timer is running and view disappears (not due to completion), save state for background tracking
        if viewModel.timerState == .running && !viewModel.showCompletionActions {
            let methodName = viewModel.getCurrentMethod()?.title ?? "Practice Session"
            viewModel.timerService.saveStateForBackground(methodName: methodName)
        }
    }
    
    // MARK: - Helper Views
    
    /// Sound toggle button view
    private var soundToggleView: some View {
        HStack {
            Spacer()
            Button {
                viewModel.isSoundEnabled.toggle()
            } label: {
                Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, AppTheme.Layout.spacingS)
    }
    
    /// Interval display section (only shown in interval mode)
    private var intervalDisplaySection: some View {
        Group {
            if viewModel.timerMode == .interval {
                IntervalDisplayView(
                    intervalName: viewModel.currentIntervalName,
                    intervalProgress: viewModel.intervalProgress,
                    overallProgress: viewModel.overallProgress,
                    currentIntervalIndex: viewModel.timerService.currentIntervalIndex,
                    totalIntervals: viewModel.timerService.totalIntervals
                )
                .padding(.horizontal)
            }
        }
    }
    
    /// Controls or completion actions section
    private var controlsSection: some View {
        Group {
            if viewModel.showCompletionActions {
                completionActionsView
            } else {
                TimerControlsView(viewModel: viewModel, onExit: {
                    // Use the same exit logic as the close button
                    if completionViewModel.handleExitRequest() {
                        viewModel.stopTimer()
                        dismiss()
                    }
                })
            }
        }
    }
    
    /// Completion actions view
    private var completionActionsView: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            Text(viewModel.timerMode == .countdown ? "Countdown Complete!" : "Workout Complete!")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(AppTheme.Colors.text)
            
            // Story 16.4: Use intelligent completion prompt
            Button("Continue") {
                // Capture the elapsed time before any state changes
                let capturedElapsedTime = viewModel.elapsedTime
                viewModel.showCompletionActions = false
                
                if let method = viewModel.getCurrentMethod() {
                    completionViewModel.completeSession(
                        methodId: method.id,
                        duration: capturedElapsedTime,
                        startTime: Date().addingTimeInterval(-capturedElapsedTime),
                        variation: method.title
                    )
                }
                
                // For multi-method sessions, notify the parent
                if isMultiMethod {
                    onMethodComplete?()
                } else {
                    // For single-method sessions, reset after showing completion prompt
                    // The actual reset will happen when the prompt is dismissed
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.card.opacity(0.7))
        .cornerRadius(AppTheme.Layout.cornerRadiusL)
        .padding()
        .onAppear {
            // Update session progress when completion is shown
            if isMultiMethod, 
               let method = viewModel.getCurrentMethod(),
               let methodId = method.id {
                completionViewModel.updateMethodProgress(
                    methodId: methodId,
                    methodName: method.title,
                    completed: true
                )
            }
        }
    }
    
    
    /// Dynamic navigation title
    private var navigationTitle: String {
        viewModel.timerMode == .stopwatch 
            ? "Timer" 
            : viewModel.timerService.activeTimerConfig?.intervals?.first?.name ?? "Exercise Timer"
    }
}

#if DEBUG
struct TimerView_Previews: PreviewProvider {
    static let sampleMethodWithIntervals: GrowthMethod = {
        let interval1 = MethodInterval(name: "Warm-up", durationSeconds: 60)
        let interval2 = MethodInterval(name: "Work Phase 1", durationSeconds: 120)
        let interval3 = MethodInterval(name: "Rest", durationSeconds: 30)
        let interval4 = MethodInterval(name: "Work Phase 2", durationSeconds: 120)
        let interval5 = MethodInterval(name: "Cool Down", durationSeconds: 60)
        let timerConfig = TimerConfiguration(
            recommendedDurationSeconds: 390,
            isCountdown: true, // Will be overridden by intervals if present
            hasIntervals: true,
            intervals: [interval1, interval2, interval3, interval4, interval5],
            maxRecommendedDurationSeconds: 600
        )
        return GrowthMethod(
            id: "previewMethod1",
            stage: 1, title: "Interval Training Preview",
            methodDescription: "A sample method with intervals.",
            instructionsText: "Follow the on-screen prompts for each interval.",
            timerConfig: timerConfig
        )
    }()
    
    static let sampleMethodCountdown: GrowthMethod = {
        let timerConfig = TimerConfiguration(
            recommendedDurationSeconds: 180, // 3 minutes
            isCountdown: true,
            hasIntervals: false
        )
        return GrowthMethod(
            id: "previewMethod2",
            stage: 1, title: "Countdown Preview",
            methodDescription: "A sample method for countdown.",
            instructionsText: "Complete the exercise for 3 minutes.",
            timerConfig: timerConfig
        )
    }()

    static var previews: some View {
        Group {
            TimerView() // Stopwatch
                .previewDisplayName("Stopwatch Timer")
            
            TimerView(growthMethod: sampleMethodCountdown) // Countdown
                .previewDisplayName("Countdown Timer")
            
            TimerView(growthMethod: sampleMethodWithIntervals) // Intervals
                .previewDisplayName("Interval Timer")
        }
    }
}
#endif 