import SwiftUI
import FirebaseAuth
import Combine
import UIKit
import Foundation  // For Logger

// Using QuickPracticeTimerTracker from Services folder

/// A timer view for quick practice sessions with method selection
struct QuickPracticeTimerView: View {
    // MARK: - Properties
    
    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Selected method for the practice session
    @State private var selectedMethod: GrowthMethod?
    
    /// Available methods for selection
    @State private var availableMethods: [GrowthMethod] = []
    
    /// Pre-selected method passed from previous view
    let preSelectedMethod: GrowthMethod?
    
    /// Quick practice timer service (singleton for state persistence)
    @ObservedObject private var quickTimerService = QuickPracticeTimerService.shared
    
    /// Local reference to the timer service for convenience
    private var timerService: TimerService {
        quickTimerService.timerService
    }
    
    /// Reference to the shared timer service to check if it's running
    @ObservedObject private var sharedTimerService = TimerService.shared
    
    /// Alert for timer conflict
    @State private var showTimerConflictAlert = false
    
    /// Quick practice timer tracker
    @StateObject private var quickPracticeTracker = QuickPracticeTimerTracker.shared
    
    /// Loading state for methods
    @State private var isLoadingMethods = true
    
    /// Available session durations (in minutes)
    private let sessionDurations = [5, 10, 15, 20, 30]
    
    /// Selected session duration
    @State private var selectedDuration = 5
    
    /// Show duration picker
    @State private var showDurationPicker = false
    
    /// Session completion view model for intelligent exit handling
    @StateObject private var completionViewModel = SessionCompletionViewModel()
    
    /// State to track if timer is running for glow effect
    @State private var isTimerRunning: Bool = false
    
    /// Flag to prevent multiple restorations
    @State private var hasRestoredFromBackground = false
    
    init(preSelectedMethod: GrowthMethod? = nil) {
        self.preSelectedMethod = preSelectedMethod
    }
    
    // MARK: - Body
    
    private var mainContent: some View {
        ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GrowthGreen").opacity(0.1),
                        Color("BrightTeal").opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Timer display
                        timerSection
                        
                        // Control buttons (moved above method selection)
                        controlButtons
                        
                        // Method selection
                        methodSelectionSection
                        
                        // Selected method details
                        if let method = selectedMethod {
                            methodDetailsSection(method: method)
                        }
                    }
                    .padding()
                }
            }
        .sheet(isPresented: $showDurationPicker) {
            durationPickerSheet
        }
    }
    
    var body: some View {
        contentWithGlow
            .navigationTitle("Quick Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .navigationBarBackButtonHidden(true)
            .onChangeCompat(of: quickTimerService.state, perform: handleTimerStateChange)
            .onReceive(quickTimerService.timerStatePublisher, perform: handleTimerStatePublisher)
            .onAppear(perform: handleViewAppear)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: handleEnterBackground)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: handleEnterForeground)
            .onDisappear(perform: handleViewDisappear)
            .alert("Timer Already Running", isPresented: $showTimerConflictAlert, actions: timerConflictAlertActions, message: timerConflictAlertMessage)
            .onReceive(NotificationCenter.default.publisher(for: .timerPauseRequested), perform: handleTimerPauseRequest)
            .onReceive(NotificationCenter.default.publisher(for: .timerStopRequested), perform: handleTimerStopRequest)
            .onChangeCompat(of: completionViewModel.showCompletionPrompt, perform: handleCompletionPrompt)
    }
    
    // MARK: - View Components
    
    private var contentWithGlow: some View {
        ZStack {
            mainContent
            
            // Apply edge glow as an overlay on the entire ZStack
            if isTimerRunning {
                ScreenEdgeGlowEffect(isActive: true, intensity: 0.8)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(.all, edges: .all)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isTimerRunning)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: handleBackButton) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    private func timerConflictAlertActions() -> some View {
        Button("OK", role: .cancel) {
            dismiss()
        }
    }
    
    private func timerConflictAlertMessage() -> some View {
        Text("Please stop the current timer before starting a quick practice session.")
    }
    
    // MARK: - Event Handlers
    
    private func handleBackButton() {
        // Save timer state before dismissing if timer is active
        if quickTimerService.state != TimerState.stopped {
            BackgroundTimerTracker.shared.saveTimerState(
                from: timerService,
                methodName: selectedMethod?.title ?? "Quick Practice",
                isQuickPractice: true
            )
            Logger.info("QuickPracticeTimerView: Saved timer state before dismissing")
        }
        hasRestoredFromBackground = false
        dismiss()
    }
    
    private func handleTimerStateChange(newState: TimerState) {
        Logger.debug("QuickPracticeTimerView: Timer state changed to \(newState)")
        // Update local state for glow effect
        withAnimation(.easeInOut(duration: 0.3)) {
            isTimerRunning = (newState == .running)
        }
    }
    
    private func handleTimerStatePublisher(state: TimerState) {
        // Update glow state based on timer state changes
        // This only responds to this specific timer's state changes
        let shouldGlow = (state == .running)
        if isTimerRunning != shouldGlow {
            withAnimation(.easeInOut(duration: 0.3)) {
                isTimerRunning = shouldGlow
            }
        }
    }
    
    private func handleViewAppear() {
        loadMethods()
        handleOnAppear()
    }
    
    private func handleEnterBackground(_ notification: Notification) {
        // Save timer state when entering background
        if quickTimerService.state == TimerState.running {
            BackgroundTimerTracker.shared.saveTimerState(
                from: quickTimerService.timerService,
                methodName: selectedMethod?.title ?? "Quick Practice",
                isQuickPractice: true
            )
            Logger.info("QuickPracticeTimerView: Saved timer state for background")
        }
    }
    
    private func handleEnterForeground(_ notification: Notification) {
        // Handle app returning from background with a small delay to ensure Live Activity actions are processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if BackgroundTimerTracker.shared.hasActiveBackgroundTimer() && !hasRestoredFromBackground {
                // Double-check the timer hasn't been stopped
                if quickTimerService.state != TimerState.stopped {
                    Logger.debug("QuickPracticeTimerView: App returning from background, restoring timer")
                    handleOnAppear()
                }
            }
        }
    }
    
    private func handleViewDisappear() {
        // Save timer state for background tracking if running
        if quickTimerService.state == TimerState.running {
            BackgroundTimerTracker.shared.saveTimerState(
                from: quickTimerService.timerService,
                methodName: selectedMethod?.title ?? "Quick Practice",
                isQuickPractice: true
            )
            Logger.info("QuickPracticeTimerView: onDisappear - saved timer state and scheduled notifications")
        } else {
            // Ensure glow state is cleared if timer is not running
            isTimerRunning = false
            
            // If timer is stopped, ensure it's properly unregistered from TimerCoordinator
            if quickTimerService.state == TimerState.stopped {
                // Force clear from TimerCoordinator if somehow still registered
                if TimerCoordinator.shared.activeTimer == "quick" {
                    TimerCoordinator.shared.timerStopped(type: "quick")
                    Logger.info("QuickPracticeTimerView: onDisappear - cleared stale 'quick' timer from coordinator")
                }
            }
        }
    }
    
    private func handleTimerPauseRequest(_ notification: Notification) {
        // Only handle if this timer is actually running or paused
        guard quickTimerService.state != .stopped else { return }
        
        // Check if this notification is meant for the quick timer
        if let timerType = notification.userInfo?[Notification.Name.TimerUserInfoKey.timerType] as? String,
           timerType != Notification.Name.TimerType.quick.rawValue {
            // This notification is for a different timer, ignore it
            return
        }
        
        // Handle pause/resume for quick practice timer
        if quickTimerService.state == TimerState.running {
            quickTimerService.pause()
        } else if quickTimerService.state == TimerState.paused {
            quickTimerService.resume()
        }
    }
    
    private func handleTimerStopRequest(_ notification: Notification) {
        // Only handle if this timer is actually running or paused
        guard quickTimerService.state != .stopped else { return }
        
        // Check if this notification is meant for the quick timer
        if let timerType = notification.userInfo?[Notification.Name.TimerUserInfoKey.timerType] as? String,
           timerType != Notification.Name.TimerType.quick.rawValue {
            // This notification is for a different timer, ignore it
            return
        }
        
        // Capture elapsed time before any state changes
        let elapsedTimeAtStop = quickTimerService.elapsedTime
        let startTime = quickTimerService.timerService.startTime ?? Date().addingTimeInterval(-elapsedTimeAtStop)
        
        // Stop the timer (this will also dismiss the Live Activity)
        quickTimerService.stop()
        
        // Update glow state
        withAnimation(.easeInOut(duration: 0.3)) {
            isTimerRunning = false
        }
        
        // Clear background timer state since we're completing
        BackgroundTimerTracker.shared.clearSavedState()
        
        // Complete session with captured elapsed time
        if selectedMethod != nil {
            completionViewModel.completeSession(
                methodId: selectedMethod?.id,
                duration: elapsedTimeAtStop,
                startTime: startTime,
                variation: selectedMethod?.title
            )
        }
    }
    
    private func handleCompletionPrompt(newValue: Bool) {
        if newValue, completionViewModel.sessionLog != nil, let method = selectedMethod {
            // Use the elapsed time stored in completion view model
            let elapsedTime = completionViewModel.elapsedTimeInSeconds
            
            // Create session progress with proper duration
            let sessionProgress = SessionProgress(
                sessionType: SessionType.quickPractice,
                methodId: method.id,
                methodName: method.title,
                startTime: Date().addingTimeInterval(-elapsedTime),
                endTime: Date(),
                totalMethods: 1,
                completedMethods: 1
            )
            
            // Show completion using global service
            SessionCompletionService.shared.showCompletion(
                sessionProgress: sessionProgress,
                completionViewModel: completionViewModel,
                sessionViewModel: nil,
                timerService: quickTimerService.timerService,
                configureTimerForMethod: nil,
                hasHandledTimerCompletion: nil,
                isShowingCompletionPrompt: nil
            )
        }
    }
    
    // MARK: - Timer Section
    
    private var timerSection: some View {
        VStack(spacing: 20) {
            // Timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerProgress)
                
                // Time display
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(Int(timerProgress * 100))%")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                }
            }
            .appleIntelligenceGlow(
                isActive: isTimerRunning,
                cornerRadius: 100,
                intensity: 0.6
            )
            
            // Time selector button
            Button {
                if quickTimerService.state == TimerState.stopped {
                    showDurationPicker = true
                }
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .font(AppTheme.Typography.captionFont())
                    Text("\(selectedDuration) min session")
                        .font(AppTheme.Typography.captionFont())
                    if quickTimerService.state == TimerState.stopped {
                        Image(systemName: "chevron.down")
                            .font(AppTheme.Typography.captionFont())
                    }
                }
                .foregroundColor(quickTimerService.state != TimerState.stopped ? .secondary : Color("GrowthGreen"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(quickTimerService.state != TimerState.stopped ? Color.secondary.opacity(0.3) : Color("GrowthGreen"), lineWidth: 1)
                )
            }
            .disabled(quickTimerService.state != TimerState.stopped)
            
            // Status text
            Text(sharedTimerService.state != TimerState.stopped ? "Main timer is active" :
                 quickTimerService.state == TimerState.stopped ? "Ready to start" : 
                 quickTimerService.state == TimerState.paused ? "Paused" : "Practice in progress")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(sharedTimerService.state != TimerState.stopped ? .red :
                              quickTimerService.state == TimerState.running ? Color("GrowthGreen") : 
                              quickTimerService.state == TimerState.paused ? .orange : .secondary)
                .onReceive(quickTimerService.$remainingTime) { remaining in
                    // Check if timer completed (for countdown mode)
                    if quickTimerService.timerMode == .countdown && 
                       quickTimerService.state == TimerState.running && 
                       remaining <= 0 && 
                       quickTimerService.elapsedTime > 0 {
                        // Timer completed
                        DispatchQueue.main.async {
                            timerCompleted()
                        }
                    }
                }
        }
        .padding(.vertical)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset button
            Button {
                quickTimerService.stop()
                hasRestoredFromBackground = false // Reset flag
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTimerRunning = false
                }
                // Clear background timer state when resetting
                BackgroundTimerTracker.shared.clearSavedState()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .disabled(quickTimerService.state == TimerState.stopped)
            
            // Play/Pause button
            Button {
                if quickTimerService.state == TimerState.stopped {
                    // Check if shared timer is running
                    if sharedTimerService.state != TimerState.stopped {
                        // Show alert that another timer is running
                        showTimerConflictAlert = true
                        return
                    }
                    
                    if let method = selectedMethod {
                        configureTimer(for: method)
                        quickTimerService.start()
                        
                        // Update glow state immediately
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isTimerRunning = true
                        }
                        
                        // Start session tracking
                        completionViewModel.startSession(
                            type: SessionType.quickPractice,
                            methodId: method.id,
                            methodName: method.title
                        )
                        
                        // Clear any background timer state since we're starting fresh
                        BackgroundTimerTracker.shared.clearSavedState()
                    }
                } else if quickTimerService.state == TimerState.running {
                    quickTimerService.pause()
                } else {
                    quickTimerService.resume()
                }
            } label: {
                Image(systemName: quickTimerService.state == TimerState.running ? "pause.fill" : "play.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedMethod == nil || sharedTimerService.state != TimerState.stopped)
            .scaleEffect(quickTimerService.state == TimerState.running ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: quickTimerService.state)
            .appleIntelligenceGlow(
                isActive: isTimerRunning,
                cornerRadius: 36,
                intensity: 0.8
            )
            
            // Stop button
            Button {
                // Stop the timer and complete session
                if quickTimerService.state != TimerState.stopped {
                    // Capture elapsed time before any state changes
                    let elapsedTimeAtStop = quickTimerService.elapsedTime
                    
                    // Pause first to preserve elapsed time
                    quickTimerService.pause()
                    
                    // Update glow state
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTimerRunning = false
                    }
                    
                    // Clear background timer state since we're completing
                    BackgroundTimerTracker.shared.clearSavedState()
                    
                    // Complete the session with captured elapsed time
                    if selectedMethod != nil {
                        completionViewModel.completeSession(
                            methodId: selectedMethod?.id,
                            duration: elapsedTimeAtStop,
                            startTime: Date().addingTimeInterval(-elapsedTimeAtStop),
                            variation: selectedMethod?.title
                        )
                    }
                }
            } label: {
                Image(systemName: "stop.fill")
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .disabled(quickTimerService.state == TimerState.stopped || selectedMethod == nil)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Duration Picker Sheet
    
    private var durationPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Select Practice Duration")
                    .font(AppTheme.Typography.headlineFont())
                    .padding()
                
                Picker("Duration", selection: $selectedDuration) {
                    ForEach(sessionDurations, id: \.self) { minutes in
                        Text("\(minutes) minutes")
                            .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                
                Button {
                    // Update timer configuration if already started
                    if quickTimerService.state != .stopped && selectedMethod != nil {
                        configureTimer(for: selectedMethod!)
                    }
                    showDurationPicker = false
                } label: {
                    Text("Set Duration")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("GrowthGreen"))
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Practice Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showDurationPicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(400)])
    }
    
    // MARK: - Method Selection Section
    
    private var methodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Method")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(availableMethods.count) available")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            
            if isLoadingMethods {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if availableMethods.isEmpty {
                Text("No methods available")
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableMethods) { method in
                                methodCard(method: method)
                                    .id(method.id) // Add ID for ScrollViewReader
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, -4)
                    .onAppear {
                        // Scroll to selected method when view appears
                        if let selectedId = selectedMethod?.id {
                            withAnimation {
                                proxy.scrollTo(selectedId, anchor: .center)
                            }
                        }
                    }
                    .onChangeCompat(of: selectedMethod?.id) { newValue in
                        // Scroll to newly selected method
                        if let methodId = newValue {
                            withAnimation {
                                proxy.scrollTo(methodId, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            if selectedMethod == nil && !isLoadingMethods && !availableMethods.isEmpty {
                Text("Select a method to start your practice session")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private func methodCard(method: GrowthMethod) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(method.title)
                .font(AppTheme.Typography.subheadlineFont())
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                // Stage indicator
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(AppTheme.Typography.captionFont())
                    Text("Stage \(method.stage)")
                        .font(AppTheme.Typography.captionFont())
                }
                .foregroundColor(stageColor(for: method.stage))
                
                Spacer()
                
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(AppTheme.Typography.captionFont())
                    Text("\(method.estimatedDurationMinutes ?? selectedDuration) min")
                        .font(AppTheme.Typography.captionFont())
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(width: 160, height: 80)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedMethod?.id == method.id ? Color("GrowthGreen").opacity(0.2) : Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedMethod?.id == method.id ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            withAnimation(.spring()) {
                selectedMethod = method
            }
        }
    }
    
    private func stageColor(for stage: Int) -> Color {
        switch stage {
        case 1: return Color("GrowthGreen")
        case 2: return Color("BrightTeal")
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }
    
    // MARK: - Method Details Section
    
    private func methodDetailsSection(method: GrowthMethod) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(.primary)
                
                Text(method.methodDescription)
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Safety Notes (if available)
            if let safetyNotes = method.safetyNotes, !safetyNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Safety Notes")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(.primary)
                    }
                    
                    Text(safetyNotes)
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
            
            // Equipment needed
            if !method.equipmentNeeded.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment Needed")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(.primary)
                    
                    ForEach(method.equipmentNeeded, id: \.self) { equipment in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(Color("GrowthGreen"))
                            Text(equipment)
                                .font(AppTheme.Typography.subheadlineFont())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Benefits (if available)
            if let benefits = method.benefits, !benefits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefits")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(.primary)
                    
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(Color("GrowthGreen"))
                                .padding(.top, 2)
                            Text(benefit)
                                .font(AppTheme.Typography.subheadlineFont())
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Step-by-Step Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Step-by-Step Instructions")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(.primary)
                
                // Use structured steps if available, otherwise parse instructionsText
                if let structuredSteps = method.steps, !structuredSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(structuredSteps) { step in
                            QuickTimerStepView(
                                step: step,
                                isLast: step.stepNumber == structuredSteps.count
                            )
                        }
                    }
                } else {
                    // Fallback to parsing instructionsText
                    let steps = parseInstructions(method.instructionsText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            SimpleStepView(
                                stepNumber: index + 1,
                                content: step,
                                isLast: index == steps.count - 1
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var timerProgress: Double {
        guard quickTimerService.state != .stopped else { return 0 }
        
        switch quickTimerService.timerMode {
        case .countdown:
            // For countdown, progress goes from 0 to 1 as time elapses
            // Use targetDurationValue if set, otherwise use selectedDuration
            let totalDuration = quickTimerService.targetDurationValue > 0 ? quickTimerService.targetDurationValue : Double(selectedDuration * 60)
            return totalDuration > 0 ? min(quickTimerService.elapsedTime / totalDuration, 1.0) : 1.0
        case .stopwatch:
            // For stopwatch, show progress based on selected duration
            let targetDuration = Double(selectedDuration * 60)
            return min(quickTimerService.elapsedTime / targetDuration, 1.0)
        case .interval:
            // Use the overall progress for intervals
            return quickTimerService.overallProgress
        }
    }
    
    private var formattedTime: String {
        // If timer is stopped, show the selected duration
        if quickTimerService.state == TimerState.stopped {
            return formatTimeInterval(Double(selectedDuration * 60))
        }
        
        switch quickTimerService.timerMode {
        case .stopwatch:
            return formatTimeInterval(quickTimerService.elapsedTime)
        case .countdown:
            // For countdown, show remaining time
            // Use remainingTime from timer service which is already calculated correctly
            return formatTimeInterval(max(0, quickTimerService.remainingTime))
        case .interval:
            return formatTimeInterval(quickTimerService.remainingTime)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Configuration
    
    private func configureTimer(for method: GrowthMethod) {
        // Set method ID and name for tracking
        quickTimerService.currentMethodId = method.id
        quickTimerService.currentMethodName = method.title
        
        // Use selected duration for countdown timer
        let quickPracticeDuration = selectedDuration * 60 // Convert minutes to seconds
        
        quickTimerService.configure(with: TimerConfiguration(
            recommendedDurationSeconds: quickPracticeDuration,
            isCountdown: true,
            hasIntervals: false,
            intervals: nil,
            maxRecommendedDurationSeconds: nil
        ))
    }
    
    // MARK: - Methods
    
    private func handleOnAppear() {
        // Debug timer state
        // Logger.debug("QuickPracticeTimerView onAppear - quickTimerService.state: \(quickTimerService.state)")
        // Logger.debug("QuickPracticeTimerView onAppear - sharedTimerService.state: \(sharedTimerService.state)")
        
        // IMPORTANT: Check if main timer is running before doing anything
        if sharedTimerService.state != TimerState.stopped {
            // Logger.debug("QuickPracticeTimerView: Main timer is running, not starting quick practice timer")
            // Show alert and dismiss
            showTimerConflictAlert = true
            // Don't restore or start quick practice timer if main timer is active
            return
        }
        
        // Check for active quick practice timer and restore if needed
        // Only restore if there's a saved quick practice state specifically
        if BackgroundTimerTracker.shared.hasActiveBackgroundTimer() && !hasRestoredFromBackground {
            // Mark as restored to prevent multiple restorations
            hasRestoredFromBackground = true
            
            // Get background state info for session tracking BEFORE restoring
            // This prevents the state from being cleared
            if let backgroundState = BackgroundTimerTracker.shared.peekTimerState() {
                // Update selected method and duration from restored state
                if let methodId = backgroundState.methodId {
                    // Will be set once methods load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let method = self.availableMethods.first(where: { $0.id == methodId }) {
                            self.selectedMethod = method
                        }
                    }
                }
                
                // Calculate duration from total duration
                if let totalDuration = backgroundState.totalDuration {
                    selectedDuration = Int(totalDuration / 60)
                }
                
                // Start session tracking immediately for restored timer
                completionViewModel.startSession(
                    type: SessionType.quickPractice,
                    methodId: backgroundState.methodId,
                    methodName: backgroundState.methodName
                )
            }
            
            // Restore timer state from background using TimerService's method
            Logger.debug("QuickPracticeTimerView: Restoring timer from background")
            quickTimerService.restoreFromBackground(isQuickPractice: true)
            
            // Check if timer completed in background (for countdown mode)
            if quickTimerService.timerMode == .countdown && 
               quickTimerService.remainingTime <= 0 && 
               quickTimerService.elapsedTime > 0 {
                Logger.info("QuickPracticeTimerView: Timer completed in background")
                // Timer completed in background - trigger completion
                DispatchQueue.main.async {
                    // Clear background state immediately since timer completed
                    BackgroundTimerTracker.shared.clearSavedState()
                    self.timerCompleted()
                }
            } else {
                // Update glow state based on restored timer state
                DispatchQueue.main.async {
                    self.isTimerRunning = (self.quickTimerService.state == TimerState.running)
                    Logger.debug("QuickPracticeTimerView: Timer restored, state: \(self.quickTimerService.state), isRunning: \(self.isTimerRunning)")
                }
            }
        } else {
            // No saved quick practice state - ensure timer is stopped
            // Reset the restoration flag since there's no active background timer
            hasRestoredFromBackground = false
            
            // This is important - we don't sync with any other timer state
            if quickTimerService.state != TimerState.stopped {
                Logger.debug("QuickPracticeTimerView: Clearing unexpected timer state")
                quickTimerService.stop()
            }
            
            // Initialize glow state to off
            isTimerRunning = false
            
            // Fresh start - initialize session tracking for when timer starts
            completionViewModel.startSession(
                type: SessionType.quickPractice,
                methodId: selectedMethod?.id,
                methodName: selectedMethod?.title
            )
        }
    }
    
    private func loadMethods() {
        isLoadingMethods = true
        
        GrowthMethodService.shared.fetchAllMethods { result in
            DispatchQueue.main.async {
                isLoadingMethods = false
                
                switch result {
                case .success(let methods):
                    // Show all methods, sorted by stage
                    availableMethods = methods.sorted { $0.stage < $1.stage }
                    
                    // Set selected method based on preSelectedMethod or auto-select first
                    if let preSelected = preSelectedMethod,
                       availableMethods.contains(where: { $0.id == preSelected.id }) {
                        selectedMethod = preSelected
                        
                        // Scroll to the pre-selected method after a brief delay to ensure ScrollView is rendered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // The scrolling will be handled by the onChange modifier in methodSelectionSection
                            // Just trigger a small UI update to ensure the ScrollViewReader is ready
                            withAnimation {
                                selectedMethod = preSelected
                            }
                        }
                    } else if let firstMethod = availableMethods.first {
                        selectedMethod = firstMethod
                    }
                    
                case .failure(let error):
                    Logger.error("Error loading methods: \(error.localizedDescription)")
                    // Could show an alert here
                }
            }
        }
    }
    
    // MARK: - Helper Methods for Instructions
    
    private func parseInstructions(_ text: String) -> [String] {
        var steps = [String]()
        let lines = text.components(separatedBy: .newlines)
        var currentStep = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if line starts with a number followed by period or parenthesis
            let startsWithNumber = trimmed.range(of: #"^\d+[.)]"#, options: .regularExpression) != nil
            
            if startsWithNumber && !currentStep.isEmpty {
                // New numbered step found, save current and start new
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                currentStep = trimmed
            } else if trimmed.isEmpty && !currentStep.isEmpty {
                // Empty line might indicate step boundary
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                currentStep = ""
            } else if !trimmed.isEmpty {
                // Continue building current step
                if !currentStep.isEmpty {
                    currentStep += " "
                }
                currentStep += trimmed
            }
        }
        
        // Don't forget the last step
        if !currentStep.isEmpty {
            steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // If no clear steps found, try splitting by double newlines
        if steps.isEmpty || steps.count == 1 {
            steps = text.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        // If still no clear separation, create reasonable chunks
        if steps.count <= 1 {
            let sentences = text.replacingOccurrences(of: "\n", with: " ")
                .components(separatedBy: ". ")
                .filter { !$0.isEmpty }
            
            if sentences.count > 4 {
                // Group sentences into 3-4 steps
                let groupSize = (sentences.count + 3) / 4
                steps = []
                
                for i in stride(from: 0, to: sentences.count, by: groupSize) {
                    let endIndex = min(i + groupSize, sentences.count)
                    let group = sentences[i..<endIndex].joined(separator: ". ")
                    if !group.isEmpty {
                        steps.append(group + (group.hasSuffix(".") ? "" : "."))
                    }
                }
            }
        }
        
        return steps.isEmpty ? [text] : steps
    }
    
    // MARK: - Timer Completion
    
    private func timerCompleted() {
        // Ensure we only handle completion once
        guard quickTimerService.state != .stopped else { return }
        
        // Capture elapsed time before any state changes
        let elapsedTimeAtCompletion = quickTimerService.elapsedTime
        
        // Pause the timer to preserve elapsed time for the completion sheet
        if quickTimerService.state == TimerState.running {
            quickTimerService.pause()
        }
        
        // Update glow state
        withAnimation(.easeInOut(duration: 0.3)) {
            isTimerRunning = false
        }
        
        // Play completion sound/haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Don't clear background timer tracking - preserve state for persistence
        
        // Complete session and show intelligent prompt with captured elapsed time
        completionViewModel.completeSession(
            methodId: selectedMethod?.id,
            duration: elapsedTimeAtCompletion,
            startTime: Date().addingTimeInterval(-elapsedTimeAtCompletion),
            variation: selectedMethod?.title
        )
    }
}

// MARK: - Supporting Step Views

private struct QuickTimerStepView: View {
    let step: MethodStep
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 28, height: 28)
                
                Text("\(step.stepNumber)")
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.semibold)
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(step.description)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Optional duration
                if let duration = step.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(duration) seconds")
                            .font(AppTheme.Typography.captionFont())
                    }
                    .foregroundColor(.secondary)
                    .opacity(0.8)
                }
                
                // Tips if available
                if let tips = step.tips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Tips", systemImage: "lightbulb")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color("BrightTeal"))
                        
                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(Color("BrightTeal"))
                                Text(tip)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("BrightTeal").opacity(0.1))
                    )
                }
                
                // Warnings if available
                if let warnings = step.warnings, !warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Caution", systemImage: "exclamationmark.triangle")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.orange)
                        
                        ForEach(warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text(warning)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

private struct SimpleStepView: View {
    let stepNumber: Int
    let content: String
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 28, height: 28)
                
                Text("\(stepNumber)")
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 6) {
                Text("Step \(stepNumber)")
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.semibold)
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(content)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

// MARK: - Preview

struct QuickPracticeTimerView_Previews: PreviewProvider {
    static var previews: some View {
        QuickPracticeTimerView()
    }
}