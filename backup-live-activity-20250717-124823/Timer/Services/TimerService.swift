//
//  TimerService.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>.
//

import Foundation
import UIKit // For background task
import Combine
import AVFoundation // For sound feedback
import ActivityKit
import FirebaseAuth
import FirebaseFirestore


// Enum to define different timer modes based on configuration
enum TimerMode: String {
    case stopwatch = "stopwatch"
    case countdown = "countdown"
    case interval = "interval"
}


class TimerService: ObservableObject {
    // MARK: - Singleton (optional - for shared timer across views)
    static let shared = TimerService()
    
    // MARK: - Debug Speed Multiplier
    #if DEBUG
    static var debugSpeedMultiplier: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(debugSpeedMultiplier, forKey: "timerService.debugSpeedMultiplier")
        }
    }
    #endif
    
    // MARK: - Published Properties for UI
    @Published var elapsedTime: TimeInterval = 0 // For stopwatch: counts up; For countdown: represents time passed; For interval: time passed in current interval
    @Published var remainingTime: TimeInterval = 0 // For countdown: counts down; For interval: remaining in current interval
    @Published var timerState: TimerState = .stopped
    @Published var currentTimerMode: TimerMode = .stopwatch
    @Published var currentIntervalName: String? = nil
    @Published var currentIntervalIndex: Int? = nil
    @Published var totalIntervals: Int? = nil
    @Published var currentIntervalProgress: Double = 0 // 0.0 to 1.0
    @Published var overallProgress: Double = 0 // 0.0 to 1.0 for multi-interval timers
    @Published var playSoundFeedback: Bool = true // User configurable for alerts
    @Published var isOverexertionWarningActive: Bool = false // Added for Story 7.3
    @Published var overexertionAlertSoundName: String? = "overexertion_warning.caf" // Added for Story 7.3, assign actual sound file name
    
    // Debug mode indicator
    #if DEBUG
    var isDebugSpeedActive: Bool {
        TimerService.debugSpeedMultiplier > 1.0
    }
    #endif

    // MARK: - Internal State
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    internal var startTime: Date? // Actual Date when timer (or current interval) started or resumed
    private var pausedElapsedTime: TimeInterval = 0 // Track elapsed time when paused
    private var lastResumeTime: Date? // Track when we last resumed
    private var lastBackgroundRestoreTime: Date? // Track when we last restored from background
    
    // Track actual elapsed time for accurate logging
    private var actualElapsedTime: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?

    // Configuration for the current timer session
    internal var activeTimerConfig: TimerConfiguration?
    private var targetDuration: TimeInterval = 0 // For countdown or total interval duration
    private var currentIntervalTargetDuration: TimeInterval = 0
    
    // Properties for BackgroundTimerTracker integration
    var currentMethodId: String?
    var currentMethodName: String?
    
    // Flag to control state persistence (disabled for quick practice timer)
    internal var enableStatePersistence: Bool
    
    // Flag to track if this is a quick practice timer
    internal var isQuickPracticeTimer: Bool = false
    
    // Flag to prevent immediate completion after restoration
    private var justRestoredFromBackground = false
    var timerMode: TimerMode {
        return currentTimerMode
    }
    var state: TimerState {
        return timerState
    }
    var totalDuration: TimeInterval? {
        return currentTimerMode == .countdown ? targetDuration : nil
    }
    var intervalDuration: TimeInterval? {
        return currentTimerMode == .interval ? currentIntervalTargetDuration : nil
    }
    var currentInterval: Int? {
        return currentIntervalIndex
    }
    
    // Public access to targetDuration for BackgroundTimerTracker
    var targetDurationValue: TimeInterval {
        get { return targetDuration }
        set { targetDuration = newValue }
    }

    // Added for Story 7.3
    private var maxRecommendedDuration: TimeInterval? = nil
    private var overexertionWarningAcknowledged: Bool = false

    // UserDefaults Keys
    private enum DefaultsKeys {
        static let savedElapsedTime = "timerService.savedElapsedTime"
        static let savedTimerState = "timerService.savedTimerStateRawValue"
        static let savedBackgroundTimestamp = "timerService.savedBackgroundTimestamp"
        static let savedTimerMode = "timerService.savedTimerModeRawValue"
        static let savedTargetDuration = "timerService.savedTargetDuration"
        static let savedCurrentIntervalIndex = "timerService.savedCurrentIntervalIndex"
        // activeTimerConfig itself might be too complex to save directly in UserDefaults easily,
        // so we save key components and re-apply config if method is available on restore.

        // Added for Story 7.3
        static let savedIsOverexertionWarningActive = "timerService.savedIsOverexertionWarningActive"
        static let savedOverexertionWarningAcknowledged = "timerService.savedOverexertionWarningAcknowledged"
        static let savedMaxRecommendedDuration = "timerService.savedMaxRecommendedDuration"
    }

    init(skipStateRestore: Bool = false, isQuickPractice: Bool = false) {
        // Enable state persistence only for the main timer
        self.enableStatePersistence = !skipStateRestore
        self.isQuickPracticeTimer = isQuickPractice
        
        // Initialize pause tracking properties
        self.pausedElapsedTime = 0
        self.lastResumeTime = nil
        
        // Initialize debug speed multiplier from UserDefaults
        #if DEBUG
        if !skipStateRestore {
            TimerService.debugSpeedMultiplier = UserDefaults.standard.double(forKey: "timerService.debugSpeedMultiplier")
            if TimerService.debugSpeedMultiplier < 1.0 {
                TimerService.debugSpeedMultiplier = 1.0
            }
        }
        #endif
        
        if !skipStateRestore {
            restoreState()
        }
        setupAudioPlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTimerActionFromWidget), name: Notification.Name("TimerActionFromWidget"), object: nil)
        
        // Clean up any corrupted Live Activities on startup
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endCorruptedActivities()
            }
        }
        
        // Register for Darwin notifications from widget
        registerForDarwinNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        unregisterFromDarwinNotifications()
    }

    // MARK: - Configuration
    func configure(with config: TimerConfiguration?) {
        print("TimerService.configure: Starting configuration")
        print("TimerService.configure: Current remainingTime before reset: \(remainingTime)")
        
        resetInternalState() // Reset before applying new config
        activeTimerConfig = config

        print("TimerService.configure: After reset, remainingTime: \(remainingTime)")

        if let config = config {
            if config.hasIntervals == true, let intervals = config.intervals, !intervals.isEmpty {
                currentTimerMode = .interval
                totalIntervals = intervals.count
                currentIntervalIndex = 0 // Start with the first interval
                targetDuration = intervals.reduce(0) { $0 + Double($1.durationSeconds) } // Total duration of all intervals
                // remainingTime will be set when the first interval starts
                // Story 7.3: Set max recommended duration if available
                if let maxDuration = config.maxRecommendedDurationSeconds, maxDuration > 0 {
                    self.maxRecommendedDuration = TimeInterval(maxDuration)
                } else {
                    self.maxRecommendedDuration = nil
                }
            } else if config.isCountdown == true, let duration = config.recommendedDurationSeconds, duration > 0 {
                currentTimerMode = .countdown
                targetDuration = TimeInterval(duration)
                remainingTime = targetDuration
                elapsedTime = 0 // For countdown, elapsed time starts at 0 and counts up to target
                print("TimerService.configure: Set countdown mode - targetDuration: \(targetDuration), remainingTime: \(remainingTime)")
            } else {
                currentTimerMode = .stopwatch
                // elapsedTime will count up from 0
                // remainingTime is not used
            }
        } else {
            currentTimerMode = .stopwatch // Default to stopwatch if no config
            self.maxRecommendedDuration = nil // Story 7.3
        }
        // Update UI-bound properties based on initial config
        updateIntervalDisplay(forIndex: currentIntervalIndex)
        #if DEBUG
        #endif
    }
    
    private func resetInternalState() {
        // Stop timer if running but don't reset values yet
        timer?.invalidate()
        timer = nil
        timerState = .stopped
        startTime = nil
        pausedElapsedTime = 0
        lastResumeTime = nil
        
        // Clear configuration
        activeTimerConfig = nil
        
        // Reset all values to defaults
        currentTimerMode = .stopwatch
        elapsedTime = 0
        remainingTime = 0
        targetDuration = 0
        currentIntervalName = nil
        currentIntervalIndex = nil
        totalIntervals = nil
        currentIntervalProgress = 0
        overallProgress = 0
        
        // Added for Story 7.3
        isOverexertionWarningActive = false
        overexertionWarningAcknowledged = false
        maxRecommendedDuration = nil
        
        // Clear any saved state to prevent restoration issues
        clearSavedState()
    }

    // MARK: - Public Timer Controls
    func start() {
        let timestamp = Date()
        print("🔴 [START] TimerService.start() called at \(timestamp)")
        print("  - Current state: \(timerState)")
        print("  - Current mode: \(currentTimerMode)")
        print("  - Elapsed time before: \(elapsedTime)")
        print("  - Remaining time before: \(remainingTime)")
        
        guard timerState != .running else { 
            print("  ⚠️ Timer already running, returning")
            return 
        }
        
        // Track the previous state before changing it
        let wasStoppedState = timerState == .stopped
        let wasPausedState = timerState == .paused
        
        print("  - Was stopped: \(wasStoppedState)")
        print("  - Was paused: \(wasPausedState)")
        
        // Clear the restoration flag when starting normally
        justRestoredFromBackground = false

        if timerState == .stopped {
            print("  📝 Timer was stopped, resetting values")
            switch currentTimerMode {
            case .stopwatch:
                elapsedTime = 0
                print("    - Stopwatch mode: elapsed reset to 0")
            case .countdown:
                elapsedTime = 0 // Counts how much has passed from the countdown
                remainingTime = targetDuration
                print("    - Countdown mode: elapsed=0, remaining=\(remainingTime)")
            case .interval:
                elapsedTime = 0 // Time within the current interval
                if currentIntervalIndex == nil { currentIntervalIndex = 0 } // Ensure we have an index
                guard let idx = currentIntervalIndex, let config = activeTimerConfig, let intervals = config.intervals, idx < intervals.count else {
                    print("    ❌ Interval config error on start.")
                    stop() // Or handle error appropriately
                    return
                }
                currentIntervalTargetDuration = TimeInterval(intervals[idx].durationSeconds)
                remainingTime = currentIntervalTargetDuration
                updateIntervalDisplay(forIndex: idx)
                print("    - Interval mode: elapsed=0, remaining=\(remainingTime)")
                // Overall progress handled in tick
            }
        }
        
        // For all modes, when starting or resuming:
        // Calculate startTime based on current elapsed time to maintain consistency
        let now = Date()
        
        // CRITICAL FIX: Handle pause/resume properly
        if wasStoppedState {
            // Fresh start - reset everything
            startTime = now
            pausedElapsedTime = 0
            lastResumeTime = now
            print("  🚀 CRITICAL: Fresh start - reset all timing")
        } else if wasPausedState {
            // Resuming from pause - store the elapsed time and set new resume time
            pausedElapsedTime = elapsedTime
            lastResumeTime = now
            print("  🚀 CRITICAL: Resuming from pause")
            print("    - Paused elapsed time: \(pausedElapsedTime)")
        }
        
        timerState = .running
        
        print("    - Current time (now): \(now)")
        print("    - Elapsed time: \(elapsedTime)")
        print("    - StartTime: \(startTime ?? Date())")
        print("    - Paused elapsed: \(pausedElapsedTime)")
        print("    - Last resume time: \(lastResumeTime ?? Date())")
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // Ensure timer is added to the current run loop
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        registerBackgroundTask()
        
        // Story 7.3: Reset acknowledged state if timer is restarted from stopped state
        if wasStoppedState {
             overexertionWarningAcknowledged = false
             isOverexertionWarningActive = false
        }
        
        // Start Live Activity
        if #available(iOS 16.1, *) {
            // If we're resuming from paused, just update the existing activity
            if wasPausedState && LiveActivityManager.shared.currentActivity != nil {
                print("  📱 Updating existing Live Activity to running state")
                LiveActivityManager.shared.updateActivity(isPaused: false)
                
                // Sync resume state to Firestore
                TimerStateSync.shared.updatePauseState(isPaused: false)
            } else {
                // Otherwise start a new Live Activity
                print("  📱 Starting new Live Activity with running state")
                startLiveActivity()
            }
        }
        
        print("🔴 [END] TimerService.start() completed")
        print("  - Final state: \(timerState)")
        print("  - Final elapsed: \(elapsedTime)")
        print("  - Final remaining: \(remainingTime)")
        print("  - Timer active: \(timer != nil)")
    }
    
    private func tick() {
        guard let resumeTime = lastResumeTime, timerState == .running else { 
            // Log why tick is not processing
            if lastResumeTime == nil {
                print("⏱️ [TICK] Skipped - lastResumeTime is nil")
            }
            if timerState != .running {
                print("⏱️ [TICK] Skipped - state is \(timerState), not running")
            }
            return 
        }
        
        let now = Date()
        
        // CRITICAL FIX: Calculate elapsed time as pausedElapsedTime + time since last resume
        let timeSinceResume = now.timeIntervalSince(resumeTime)
        actualElapsedTime = pausedElapsedTime + timeSinceResume
        
        // Apply debug speed multiplier if active
        #if DEBUG
        let previousElapsed = elapsedTime
        elapsedTime = actualElapsedTime * TimerService.debugSpeedMultiplier
        #else
        let previousElapsed = elapsedTime
        elapsedTime = actualElapsedTime
        #endif
        
        // Log every 10th tick (1 second) to avoid spam
        let shouldLog = Int(elapsedTime * 10) % 10 == 0
        if shouldLog {
            let modeStr = currentTimerMode == .countdown ? "countdown" : "stopwatch"
            let remainingStr = currentTimerMode == .countdown ? String(format: "%.1fs", remainingTime) : "N/A"
            print("⏱️ [TICK] \(modeStr) - elapsed: \(String(format: "%.1fs", elapsedTime)), remaining: \(remainingStr)")
        }
        
        // Live Activity updates are now handled entirely by push notifications
        // Send update every second to keep Live Activity in sync
        // IMPORTANT: Don't send updates during tick - only on state changes
        // The server-side push updates handle periodic updates

        switch currentTimerMode {
        case .stopwatch:
            // elapsedTime is the primary display
            // Story 7.3: Check for overexertion in stopwatch mode
            if let maxDuration = maxRecommendedDuration, elapsedTime > maxDuration, !isOverexertionWarningActive, !overexertionWarningAcknowledged {
                isOverexertionWarningActive = true
                playOverexertionAlertSound() // Distinct sound for overexertion
                // Timer continues running, UI shows alert
            }
            // Clear the flag after first tick for stopwatch too
            justRestoredFromBackground = false
            break // No specific completion
        case .countdown:
            let previousRemaining = remainingTime
            remainingTime = max(0, targetDuration - elapsedTime)
            
            if shouldLog {
                print("  - Mode: Countdown")
                print("  - Target duration: \(targetDuration)s")
                print("  - Previous remaining: \(previousRemaining)s")
                print("  - New remaining: \(remainingTime)s")
            }
            
            if remainingTime == 0 && !justRestoredFromBackground {
                print("  🏁 Countdown completed!")
                handleTimerCompletion()
            }
            // Clear the flag after a few ticks to ensure we don't trigger completion immediately
            if justRestoredFromBackground {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.justRestoredFromBackground = false
                }
            }
        case .interval:
            guard let config = activeTimerConfig, let intervals = config.intervals, let idx = currentIntervalIndex, idx < intervals.count else { return }
            let previousRemaining = remainingTime
            remainingTime = max(0, currentIntervalTargetDuration - elapsedTime)
            currentIntervalProgress = remainingTime == 0 ? 1.0 : (elapsedTime / currentIntervalTargetDuration)
            currentIntervalProgress = min(1.0, max(0, currentIntervalProgress)) // Clamp to 0-1

            if shouldLog {
                print("  - Mode: Interval")
                print("  - Current interval: \(idx) of \(intervals.count)")
                print("  - Interval duration: \(currentIntervalTargetDuration)s")
                print("  - Previous remaining: \(previousRemaining)s")
                print("  - New remaining: \(remainingTime)s")
                print("  - Progress: \(currentIntervalProgress)")
            }

            // Calculate overall progress
            var timePassedInPreviousIntervals: TimeInterval = 0
            if idx > 0 {
                for i in 0..<idx {
                    timePassedInPreviousIntervals += TimeInterval(intervals[i].durationSeconds)
                }
            }
            let totalTimePassedOverall = timePassedInPreviousIntervals + elapsedTime
            if targetDuration > 0 {
                overallProgress = min(1.0, max(0, totalTimePassedOverall / targetDuration))
            }

            if remainingTime == 0 && !justRestoredFromBackground {
                handleIntervalCompletion()
            }
            // Clear the flag after first tick for intervals too
            justRestoredFromBackground = false
        }
    }
    
    private func handleIntervalCompletion() {
        playAlertSound()
        guard var idx = currentIntervalIndex, let config = activeTimerConfig, let intervals = config.intervals else {
            stop() // Should not happen
            return
        }
        
        idx += 1
        if idx < intervals.count {
            currentIntervalIndex = idx
            elapsedTime = 0 // Reset for the new interval
            startTime = Date() // Reset start time for the new interval
            currentIntervalTargetDuration = TimeInterval(intervals[idx].durationSeconds)
            remainingTime = currentIntervalTargetDuration
            updateIntervalDisplay(forIndex: idx)
            // The timer continues running for the next interval
        } else {
            // All intervals completed
            handleTimerCompletion()
        }
    }

    func handleTimerCompletion() {
        playAlertSound()
        
        // Cancel all timer notifications since the timer has completed
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        }
        
        // For countdown and interval modes, when finished:
        if currentTimerMode == .countdown {
            elapsedTime = targetDuration // Ensure elapsedTime reflects full duration
            #if DEBUG
            actualElapsedTime = targetDuration / TimerService.debugSpeedMultiplier
            #endif
            remainingTime = 0
        } else if currentTimerMode == .interval {
            // Ensure final progress is 1.0
            currentIntervalProgress = 1.0 
            overallProgress = 1.0
            // elapsedTime for the last interval is already at its target
        }
        
        // Set timer state to stopped BEFORE Live Activity updates
        timerState = .stopped
        timer?.invalidate()
        timer = nil
        
        // End Live Activity immediately and show notification
        if #available(iOS 16.1, *) {
            Task { @MainActor in
                // First, update the Live Activity push state to stop
                if let activity = LiveActivityManager.shared.currentActivity {
                    await LiveActivityPushService.shared.storeTimerStateInFirestore(for: activity, action: .stop)
                }
                
                // End the Live Activity immediately
                await LiveActivityManager.shared.completeActivity()
                
                // Show session completion notification
                let methodName = currentMethodName ?? "Training"
                let duration = elapsedTime
                NotificationService.shared.showSessionCompletionNotification(
                    methodName: methodName,
                    duration: duration
                )
                
                // Stop syncing timer state
                TimerStateSync.shared.stopSyncing()
                
                // Cancel background tasks
                LiveActivityBackgroundTaskManager.shared.cancelAllTasks()
            }
        } else {
            // For iOS versions that don't support Live Activities
            let methodName = currentMethodName ?? "Training"
            let duration = elapsedTime
            NotificationService.shared.showSessionCompletionNotification(
                methodName: methodName,
                duration: duration
            )
        } 
        // Optionally, could change state to a specific .completed state if needed
        // For now, .paused signifies completion for countdown/interval
        #if DEBUG
        #endif
    }
    
    private func updateIntervalDisplay(forIndex index: Int?) {
        guard let idx = index, let config = activeTimerConfig, let intervals = config.intervals, idx < intervals.count else {
            currentIntervalName = nil
            // currentIntervalProgress = 0 // Reset if no valid interval
            return
        }
        currentIntervalName = intervals[idx].name
    }

    func pause() {
        let timestamp = Date()
        print("🟡 [PAUSE] TimerService.pause() called at \(timestamp)")
        print("  - Current state: \(timerState)")
        print("  - Elapsed time: \(elapsedTime)")
        print("  - Remaining time: \(remainingTime)")
        print("  - Start time: \(String(describing: startTime))")
        
        guard timerState == .running else { 
            print("  ⚠️ Timer not running, cannot pause")
            return 
        }
        
        // Calculate exact elapsed time at pause moment
        if let startTime = startTime {
            let exactElapsed = Date().timeIntervalSince(startTime)
            print("  - Exact elapsed at pause: \(exactElapsed)s")
            print("  - Stored elapsed: \(elapsedTime)s")
            print("  - Difference: \(abs(exactElapsed - elapsedTime))s")
        }
        
        timerState = .paused
        timer?.invalidate()
        timer = nil
        
        print("  - State changed to: \(timerState)")
        print("  - Timer invalidated")
        
        saveStateOnPauseOrBackground()
        endBackgroundTask()
        
        // Update Live Activity (only if not showing completion)
        if #available(iOS 16.1, *) {
            // Check if the activity is showing completion state
            if !LiveActivityManager.shared.isActivityShowingCompletion {
                print("  📱 Updating Live Activity to paused state")
                LiveActivityManager.shared.updateActivity(isPaused: true)
                
                // Sync pause state to Firestore
                TimerStateSync.shared.updatePauseState(isPaused: true, pausedAt: Date())
            } else {
                print("  ℹ️ Skipping Live Activity update (activity is showing completion)")
            }
        }
        
        print("🟡 [END] TimerService.pause() completed")
    }
    
    // MARK: - Background Timer Tracking
    
    /// Save state when view disappears with active timer
    func saveStateForBackground(methodName: String? = nil, isQuickPractice: Bool = false) {
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.saveTimerState(from: self, methodName: methodName ?? currentMethodName, isQuickPractice: isQuickPractice)
        }
    }
    
    /// Restore state when view reappears
    func restoreFromBackground(isQuickPractice: Bool = false) {
        let timestamp = Date()
        print("🔵 [RESTORE] TimerService.restoreFromBackground() called at \(timestamp)")
        print("  - isQuickPractice: \(isQuickPractice)")
        print("  - Current state before restore: \(timerState)")
        print("  - Current elapsed before restore: \(elapsedTime)")
        print("  - Current remaining before restore: \(remainingTime)")
        
        // Don't restore if timer is already stopped
        guard timerState != .stopped else {
            print("  ⚠️ Timer is already stopped, skipping restoration")
            return
        }
        
        if let restoredState = BackgroundTimerTracker.shared.restoreTimerState(to: self, isQuickPractice: isQuickPractice) {
            print("  ✅ Background state found and restored:")
            print("    - Was running: \(restoredState.isRunning)")
            print("    - Elapsed after restore: \(elapsedTime)")
            print("    - Remaining after restore: \(remainingTime)")
            print("    - Total elapsed time calculated: \(restoredState.totalElapsedTime())")
            
            // Set flag to prevent immediate completion on first tick
            justRestoredFromBackground = true
            
            // Timer has been restored with correct elapsed time and state
            // Check if we should resume the timer
            // Only resume if:
            // 1. It was running when backgrounded (restoredState.isRunning)
            // 2. The current state is still paused (not stopped or already running)
            // 3. It's not completed (remainingTime > 0 for countdown)
            var shouldResume = restoredState.isRunning && timerState == .paused && 
                              !(currentTimerMode == .countdown && remainingTime <= 0)
            
            print("  📊 Resume decision:")
            print("    - Was running: \(restoredState.isRunning)")
            print("    - Is paused: \(timerState == .paused)")
            print("    - Not completed: \(!(currentTimerMode == .countdown && remainingTime <= 0))")
            print("    - Should resume: \(shouldResume)")
            
            if shouldResume {
                // Check App Group state to see if it was paused while in background
                if #available(iOS 16.1, *) {
                    // Check App Group state first (more reliable than Live Activity state)
                    let appGroupState = AppGroupConstants.getTimerState()
                    if let activityId = appGroupState.activityId,
                       appGroupState.isPaused {
                        print("  📱 App Group state check:")
                        print("    - Activity ID: \(activityId)")
                        print("    - Is paused in App Group: true")
                        print("  🛑 Timer was paused via Live Activity, keeping it paused")
                        
                        // Use the stored elapsed time from App Group
                        let pausedElapsed = appGroupState.elapsedTime
                        self.elapsedTime = pausedElapsed
                        self.remainingTime = max(0, targetDuration - pausedElapsed)
                        print("    - App Group elapsed: \(pausedElapsed)")
                        print("    - App Group remaining: \(self.remainingTime)")
                        
                        shouldResume = false
                    } else if let activity = LiveActivityManager.shared.currentActivity {
                        // Fallback to Live Activity state if App Group doesn't indicate pause
                        let isPausedInLiveActivity = activity.content.state.isPaused
                        print("  📱 Live Activity state check:")
                        print("    - Activity ID: \(activity.id)")
                        print("    - Is paused in Live Activity: \(isPausedInLiveActivity)")
                        
                        if isPausedInLiveActivity {
                            print("  🛑 Timer was paused via Live Activity, keeping it paused")
                            
                            // Use the Live Activity's computed elapsed time
                            let liveActivityElapsed = activity.content.state.currentElapsedTime
                            let liveActivityRemaining = activity.content.state.currentRemainingTime
                            
                            print("  📱 Using Live Activity times:")
                            print("    - Live Activity elapsed: \(liveActivityElapsed)")
                            print("    - Live Activity remaining: \(liveActivityRemaining)")
                            
                            // Update our state to match Live Activity
                            elapsedTime = liveActivityElapsed
                            if currentTimerMode == .countdown {
                                remainingTime = liveActivityRemaining
                            }
                            
                            print("  📊 Updated state from Live Activity:")
                            print("    - New elapsed: \(elapsedTime)")
                            print("    - New remaining: \(remainingTime)")
                            
                            // Update Live Activity with current state
                            LiveActivityManager.shared.updateActivity(isPaused: true)
                            return
                        }
                    } else {
                        print("  ⚠️ No Live Activity found")
                    }
                }
                
                // Ensure timing is set correctly for continuous timing
                let now = Date()
                startTime = restoredState.startTime
                pausedElapsedTime = elapsedTime
                lastResumeTime = now
                
                print("  🚀 CRITICAL: Resuming timer from background")
                print("    - Current time (now): \(now)")
                print("    - Elapsed time: \(elapsedTime)")
                print("    - Start time: \(startTime!)")
                print("    - Paused elapsed: \(pausedElapsedTime)")
                print("    - Last resume time: \(lastResumeTime!)")
                
                // Set state to running
                timerState = .running
                
                // Start the timer tick mechanism
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.tick()
                }
                
                // Ensure timer is added to the current run loop
                if let timer = timer {
                    RunLoop.current.add(timer, forMode: .common)
                }
                
                // Register background task for continued execution
                registerBackgroundTask()
                
                // Update Live Activity to show running state
                if #available(iOS 16.1, *) {
                    print("  📱 Updating Live Activity after background restoration")
                    LiveActivityManager.shared.updateActivity(isPaused: false)
                    
                    // Sync resume state to Firestore
                    TimerStateSync.shared.updatePauseState(isPaused: false)
                }
                
                print("  ✅ Timer resumed successfully")
                print("    - Final state: \(timerState)")
                print("    - Timer active: \(timer != nil)")
            } else {
                print("  ⏸️ Timer was not running or already in correct state, not resuming")
                
                // If timer is completed (countdown with 0 remaining), ensure it stays paused
                if currentTimerMode == .countdown && remainingTime <= 0 && elapsedTime > 0 {
                    print("  🏁 Timer is completed, keeping it paused")
                    timerState = .paused
                }
            }
        } else {
            print("  ❌ No background state to restore")
        }
        
        // Track restore time to prevent race conditions
        lastBackgroundRestoreTime = Date()
        
        print("🔵 [END] TimerService.restoreFromBackground() completed")
        print("  - Final state: \(timerState)")
        print("  - Final elapsed: \(elapsedTime)")
        print("  - Final remaining: \(remainingTime)")
    }
    
    /// Check if there's an active background timer
    func hasActiveBackgroundTimer(isQuickPractice: Bool = false) -> Bool {
        if #available(iOS 16.1, *) {
            return BackgroundTimerTracker.shared.hasActiveBackgroundTimer(isQuickPractice: isQuickPractice)
        }
        return false
    }

    func resume() {
        let timestamp = Date()
        print("🟢 [RESUME] TimerService.resume() called at \(timestamp)")
        print("  - Current state: \(timerState)")
        print("  - Elapsed time before resume: \(elapsedTime)")
        print("  - Remaining time before resume: \(remainingTime)")
        print("  - Start time before resume: \(String(describing: startTime))")
        
        guard timerState == .paused else { 
            print("  ⚠️ Timer not paused, cannot resume (state: \(timerState))")
            return 
        }
        
        print("  📋 Calling start() to resume...")
        
        // Resume from paused state
        start()
        
        print("  - State after start(): \(timerState)")
        print("  - Elapsed time after start(): \(elapsedTime)")
        print("  - Start time after start(): \(String(describing: startTime))")
        
        // Update Live Activity to unpause
        if #available(iOS 16.1, *) {
            print("  📱 Updating Live Activity to running state")
            LiveActivityManager.shared.updateActivity(isPaused: false)
            
            // Also update in the TimerStateSync (done in start() method via updatePauseState)
        }
        
        print("🟢 [END] TimerService.resume() completed")
    }
    
    /// Check Live Activity state when app becomes active
    func checkStateOnAppBecomeActive() {
        print("🔄 TimerService: App became active, checking Live Activity state")
        
        // Skip sync if we just restored from background (within 2 seconds)
        if let lastRestore = lastBackgroundRestoreTime,
           abs(lastRestore.timeIntervalSinceNow) < 2.0 {
            print("  - Skipping sync, just restored from background \(abs(lastRestore.timeIntervalSinceNow))s ago")
            return
        }
        
        // First check for any unprocessed timer actions (higher priority)
        if let timerAction = AppGroupFileManager.shared.readTimerAction() {
            print("  - Found unprocessed action: \(timerAction.action)")
            
            // Only process if it's for the main timer
            if timerAction.timerType == "main" {
                // Process based on current time to avoid stale actions
                if abs(timerAction.timestamp.timeIntervalSinceNow) < 30 {
                    switch timerAction.action {
                    case "pause":
                        if timerState == .running {
                            print("  - Processing pause action")
                            pause()
                        }
                    case "resume":
                        if timerState == .paused {
                            print("  - Processing resume action")
                            resume()
                        }
                    case "stop":
                        if timerState != .stopped {
                            print("  - Processing stop action")
                            stop()
                        }
                    default:
                        break
                    }
                } else {
                    print("  - Action is too old (> 30s), ignoring")
                }
                
                // Clear the processed action
                AppGroupFileManager.shared.clearTimerAction()
                
                // Don't sync with Live Activity state after processing an action
                // to avoid undoing what we just did
                return
            }
        }
        
        // Only sync with App Group state if no actions were processed
        syncWithLiveActivityState()
    }

    func stop() {
        timerState = .stopped
        timer?.invalidate()
        timer = nil
        
        // Cancel all timer notifications since the timer has been stopped
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        }
        
        // End Live Activity and stop syncing
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endCurrentActivity(immediately: true)
            }
            
            // Stop syncing timer state
            TimerStateSync.shared.stopSyncing()
            
            // Cancel background tasks
            LiveActivityBackgroundTaskManager.shared.cancelAllTasks()
        }
        
        // Reset all relevant properties based on mode or to default
        elapsedTime = 0
        pausedElapsedTime = 0
        lastResumeTime = nil
        if currentTimerMode == .countdown || currentTimerMode == .interval {
            remainingTime = targetDuration // Reset to full duration if applicable, or 0 if stopwatch
        } else {
            remainingTime = 0
        }
        if currentTimerMode == .interval {
             currentIntervalIndex = activeTimerConfig?.intervals?.isEmpty == false ? 0 : nil
             updateIntervalDisplay(forIndex: currentIntervalIndex)
             currentIntervalProgress = 0
             overallProgress = 0
             if let config = activeTimerConfig, let intervals = config.intervals, !intervals.isEmpty {
                currentIntervalTargetDuration = TimeInterval(intervals[0].durationSeconds)
                remainingTime = currentIntervalTargetDuration
             } else {
                currentIntervalTargetDuration = 0
             }
        } else if currentTimerMode == .countdown {
            remainingTime = targetDuration
        }
        
        startTime = nil
        clearSavedState()
        endBackgroundTask()
        #if DEBUG
        #endif
        // Re-apply initial config to reset display for countdown/interval, but keep mode
        // configure(with: activeTimerConfig) // This might be too much, let's simplify reset of display fields
    }

    // MARK: - Time Formatting
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var displayFormattedTime: String {
        switch currentTimerMode {
        case .stopwatch:
            return formattedTime(elapsedTime)
        case .countdown, .interval: // Interval mode also shows remaining time for current interval
            return formattedTime(remainingTime)
        }
    }

    // MARK: - Background Task Management & State Persistence (Simplified)
    // ... (registerBackgroundTask, endBackgroundTask are mostly the same)
    // ... (applicationDidEnterBackground, applicationWillEnterForeground are mostly the same)
    // ... Save/Restore/Clear state methods need to be updated for new properties
    private func registerBackgroundTask() {
        if backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TimerServiceBackgroundTask") {
                // Don't pause the timer when background task expires
                // The Live Activity will continue via push notifications
                self.saveStateOnPauseOrBackground()
                self.endBackgroundTask()
            }
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    @objc private func applicationDidEnterBackground() {
        
        // Background timer tracking is handled by the view's onDisappear for quick practice timer
        // Only handle automatic background tracking for the main timer
        guard enableStatePersistence else { 
            return 
        }
        
        // If timer is running, save state for background tracking with notifications
        // This should be done BEFORE the regular state save to capture the running state
        if timerState == .running {
            let methodName = currentMethodName ?? "Practice Session"
            BackgroundTimerTracker.shared.saveTimerState(from: self, methodName: methodName, isQuickPractice: isQuickPracticeTimer)
        }
        
        // Then save the regular state (which may pause the timer)
        saveStateOnPauseOrBackground()
    }

    @objc private func applicationWillEnterForeground() {
        
        // Only restore state if persistence is enabled
        guard enableStatePersistence else { 
            return 
        }
        
        // Check if there's an active background timer for THIS specific timer type
        if BackgroundTimerTracker.shared.hasActiveBackgroundTimer(isQuickPractice: isQuickPracticeTimer) {
            // Use the proper restore method that handles timer restart
            restoreFromBackground(isQuickPractice: isQuickPracticeTimer)
        } else if !isQuickPracticeTimer {
            // Only attempt regular state restoration for main timer
            // Quick practice timer state is managed by the view
            restoreState()
        }
        
        // Clear any background timer notifications since app is back in foreground
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        }
    }
    
    @objc private func handleTimerActionFromWidget(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? String else {
            return
        }
        
        
        switch action {
        case "pause":
            if timerState == .running {
                pause()
            }
        case "resume":
            if timerState == .paused {
                start()
            }
        case "stop":
            stop()
        default:
            break
        }
    }
    
    // MARK: - Darwin Notifications
    
    private func registerForDarwinNotifications() {
        let notificationName = "com.growthlabs.growthmethod.liveactivity.action" as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { center, observer, name, object, userInfo in
                // This is called from a C callback, so we need to get back to our instance
                guard let observer = observer else { return }
                let timerService = Unmanaged<TimerService>.fromOpaque(observer).takeUnretainedValue()
                timerService.handleDarwinNotification()
            },
            notificationName,
            nil,
            .deliverImmediately
        )
    }
    
    private func unregisterFromDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }
    
    private func handleDarwinNotification() {
        // Check shared defaults for the action
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod"),
              let action = sharedDefaults.string(forKey: "lastTimerAction"),
              let lastActionTime = sharedDefaults.object(forKey: "lastActionTime") as? Date else {
            return
        }
        
        // Only process if action was recent (within 5 seconds)
        guard Date().timeIntervalSince(lastActionTime) < 5 else {
            return
        }
        
        
        // Process on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch action {
            case "pause":
                if self.timerState == .running {
                    self.pause()
                }
            case "resume":
                if self.timerState == .paused {
                    self.start()
                }
            case "stop":
                self.stop()
            default:
                break
            }
            
            // Clear the action
            sharedDefaults.removeObject(forKey: "lastTimerAction")
            sharedDefaults.removeObject(forKey: "lastActionTime")
            sharedDefaults.removeObject(forKey: "lastActivityId")
        }
    }
    
    private func saveStateOnPauseOrBackground() {
        print("💾 [SAVE] saveStateOnPauseOrBackground() called")
        print("  - Enable state persistence: \(enableStatePersistence)")
        
        // Skip if state persistence is disabled
        guard enableStatePersistence else { 
            print("  ⚠️ State persistence disabled, skipping save")
            return 
        }
        
        let defaults = UserDefaults.standard
        let shouldSave = timerState == .running || (timerState == .paused && (elapsedTime > 0 || (currentTimerMode != .stopwatch && remainingTime < targetDuration) ))
        
        print("  - Current state: \(timerState)")
        print("  - Elapsed time: \(elapsedTime)")
        print("  - Remaining time: \(remainingTime)")
        print("  - Target duration: \(targetDuration)")
        print("  - Should save: \(shouldSave)")
        
        if shouldSave {
            // Save actual elapsed time (not multiplied) for accurate background restoration
            // Validate elapsed time before saving to prevent corruption
            let maxReasonableElapsedTime: TimeInterval = 24 * 60 * 60 // 24 hours
            
            #if DEBUG
            let rawTimeToSave = actualElapsedTime > 0 ? actualElapsedTime : elapsedTime / TimerService.debugSpeedMultiplier
            let timeToSave = min(rawTimeToSave, maxReasonableElapsedTime)
            if rawTimeToSave > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Not saving unreasonably large elapsed time: \(rawTimeToSave)s, clamping to \(timeToSave)s")
            }
            print("  - DEBUG: Actual elapsed: \(actualElapsedTime), Time to save: \(timeToSave)")
            defaults.set(timeToSave, forKey: DefaultsKeys.savedElapsedTime)
            #else
            let elapsedToSave = min(elapsedTime, maxReasonableElapsedTime)
            if elapsedTime > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Not saving unreasonably large elapsed time: \(elapsedTime)s, clamping to \(elapsedToSave)s")
            }
            defaults.set(elapsedToSave, forKey: DefaultsKeys.savedElapsedTime)
            #endif
            
            defaults.set(timerState.rawValue, forKey: DefaultsKeys.savedTimerState)
            defaults.set(currentTimerMode.rawValue, forKey: DefaultsKeys.savedTimerMode)
            defaults.set(targetDuration, forKey: DefaultsKeys.savedTargetDuration)
            
            if let idx = currentIntervalIndex { 
                defaults.set(idx, forKey: DefaultsKeys.savedCurrentIntervalIndex)
                print("  - Saved interval index: \(idx)")
            } else { 
                defaults.removeObject(forKey: DefaultsKeys.savedCurrentIntervalIndex) 
            }
            
            if timerState == .running {
                let backgroundTimestamp = Date().timeIntervalSince1970
                defaults.set(backgroundTimestamp, forKey: DefaultsKeys.savedBackgroundTimestamp)
                print("  - Saved background timestamp: \(Date(timeIntervalSince1970: backgroundTimestamp))")
            } else {
                defaults.removeObject(forKey: DefaultsKeys.savedBackgroundTimestamp)
                print("  - Removed background timestamp (not running)")
            }
            
            print("  ✅ State saved successfully:")
            print("    - Mode: \(currentTimerMode)")
            print("    - State: \(timerState)")
            print("    - Elapsed: \(elapsedTime)s")
            print("    - Remaining: \(remainingTime)s")
        } else {
            print("  🗑️ Clearing saved state (conditions not met for saving)")
            clearSavedState()
        }
    }

    private func restoreState() {
        // Skip if state persistence is disabled
        guard enableStatePersistence else { return }
        
        // Skip if BackgroundTimerTracker has an active timer (it takes precedence)
        if #available(iOS 16.1, *) {
            if BackgroundTimerTracker.shared.hasActiveBackgroundTimer(isQuickPractice: isQuickPracticeTimer) {
                return
            }
        }
        
        let defaults = UserDefaults.standard
        guard let savedStateRaw = defaults.string(forKey: DefaultsKeys.savedTimerState),
              let sState = TimerState(rawValue: savedStateRaw),
              let savedModeRaw = defaults.string(forKey: DefaultsKeys.savedTimerMode),
              let sMode = TimerMode(rawValue: savedModeRaw)
        else {
            return
        }

        let sElapsedTime = defaults.double(forKey: DefaultsKeys.savedElapsedTime)
        let sTargetDuration = defaults.double(forKey: DefaultsKeys.savedTargetDuration)
        let sCurrentIntervalIndex = defaults.object(forKey: DefaultsKeys.savedCurrentIntervalIndex) as? Int

        // Validate elapsed time to prevent loading corrupted values
        let maxReasonableElapsedTime: TimeInterval = 24 * 60 * 60 // 24 hours
        let validatedElapsedTime = min(sElapsedTime, maxReasonableElapsedTime)
        
        if sElapsedTime > maxReasonableElapsedTime {
            print("⚠️ WARNING: Loaded unreasonably large elapsed time: \(sElapsedTime)s, clamping to \(validatedElapsedTime)s")
            print("  - This may indicate corrupted state data")
            // Clear the corrupted state
            clearSavedState()
            return
        }

        self.currentTimerMode = sMode
        self.timerState = sState
        
        // Restore elapsed time and apply multiplier if debug mode is active
        #if DEBUG
        self.actualElapsedTime = validatedElapsedTime
        self.elapsedTime = validatedElapsedTime * TimerService.debugSpeedMultiplier
        #else
        self.elapsedTime = validatedElapsedTime
        #endif
        self.targetDuration = sTargetDuration
        self.currentIntervalIndex = sCurrentIntervalIndex
        
        // Calculate remaining time based on restored mode and elapsed/target
        if sMode == .countdown {
            self.remainingTime = max(0, sTargetDuration - sElapsedTime)
            
            // Check if timer completed while app was terminated
            // Only trigger completion if there was actual time remaining when saved
            if self.remainingTime == 0 && sState == .running && (sTargetDuration - sElapsedTime) > 0.1 {
                // Don't set to paused - let handleTimerCompletion handle the state
                handleTimerCompletion()
            }
        } else if sMode == .interval {
            updateIntervalDisplay(forIndex: sCurrentIntervalIndex)
        }

        if sState == .running {
            if let backgroundTimestamp = defaults.object(forKey: DefaultsKeys.savedBackgroundTimestamp) as? Double {
                let timeInBackground = Date().timeIntervalSince1970 - backgroundTimestamp
                
                // Apply speed multiplier to background time
                #if DEBUG
                let adjustedBackgroundTime = max(0, timeInBackground) * TimerService.debugSpeedMultiplier
                self.actualElapsedTime += max(0, timeInBackground)
                self.elapsedTime += adjustedBackgroundTime
                #else
                self.elapsedTime += max(0, timeInBackground)
                #endif
                
                // For countdown timers, cap elapsed time at target duration
                if sMode == .countdown {
                    self.elapsedTime = min(self.elapsedTime, self.targetDuration)
                    #if DEBUG
                    self.actualElapsedTime = min(self.actualElapsedTime, self.targetDuration / TimerService.debugSpeedMultiplier)
                    #endif
                    self.remainingTime = max(0, self.targetDuration - self.elapsedTime)
                    
                    // Check if timer completed while in background
                    // Only trigger completion if there was actual time remaining when we went to background
                    let timeWhenBackgrounded = sTargetDuration - sElapsedTime
                    if self.remainingTime == 0 && timeWhenBackgrounded > 0.1 {
                        // Don't set to paused - let handleTimerCompletion handle the state
                        handleTimerCompletion()
                        return
                    }
                }
            }
            
            // Set startTime based on actual elapsed time for accurate timing
            // Validate elapsed time to prevent creating dates in the far past
            let maxReasonableElapsedTime: TimeInterval = 24 * 60 * 60 // 24 hours
            let validatedElapsedTime: TimeInterval
            
            #if DEBUG
            validatedElapsedTime = min(self.actualElapsedTime, maxReasonableElapsedTime)
            if self.actualElapsedTime > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Actual elapsed time unreasonably large: \(self.actualElapsedTime)s, clamping to \(maxReasonableElapsedTime)s")
            }
            #else
            validatedElapsedTime = min(self.elapsedTime, maxReasonableElapsedTime)
            if self.elapsedTime > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Elapsed time unreasonably large: \(self.elapsedTime)s, clamping to \(maxReasonableElapsedTime)s")
            }
            #endif
            
            self.startTime = Date() - validatedElapsedTime
            
            // Set flag to prevent immediate completion after restoration
            self.justRestoredFromBackground = true
            
            // Check Live Activity state before starting
            syncWithLiveActivityState()
            
            // Only start if not paused by Live Activity
            if timerState != .paused {
                self.start() // Restart the timer mechanism
            }
        } else if sState == .paused {
            self.startTime = nil
        }
        
        if sState == .running || sState == .paused {
             defaults.removeObject(forKey: DefaultsKeys.savedBackgroundTimestamp)
        }

        // Story 7.3
        self.isOverexertionWarningActive = defaults.bool(forKey: DefaultsKeys.savedIsOverexertionWarningActive)
        self.overexertionWarningAcknowledged = defaults.bool(forKey: DefaultsKeys.savedOverexertionWarningAcknowledged)
        self.maxRecommendedDuration = defaults.object(forKey: DefaultsKeys.savedMaxRecommendedDuration) as? TimeInterval
    }

    private func clearSavedState() {
        // Skip if state persistence is disabled
        guard enableStatePersistence else { return }
        
        let defaults = UserDefaults.standard
        [DefaultsKeys.savedElapsedTime, DefaultsKeys.savedTimerState, DefaultsKeys.savedBackgroundTimestamp, DefaultsKeys.savedTimerMode, DefaultsKeys.savedTargetDuration, DefaultsKeys.savedCurrentIntervalIndex].forEach { defaults.removeObject(forKey: $0) }
        
        // Also clear background timer tracker state
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.clearSavedState(isQuickPractice: isQuickPracticeTimer)
        }
        
    }
    
    // MARK: - App Group State Synchronization
    
    /// Check and sync timer state with Live Activity state stored in App Group
    func syncWithLiveActivityState() {
        print("🔄 TimerService: Checking Live Activity state in App Group")
        
        let appGroupState = AppGroupConstants.getTimerState()
        guard let activityId = appGroupState.activityId,
              appGroupState.startTime != nil else {
            print("  - No active Live Activity state found in App Group")
            return
        }
        
        print("  - Found Live Activity state:")
        print("    - Activity ID: \(activityId)")
        print("    - Is paused: \(appGroupState.isPaused)")
        print("    - Current timer state: \(timerState)")
        
        // Check if states are out of sync
        // Don't sync if timer is already stopped (completed)
        if timerState == .stopped {
            print("  ℹ️ Timer is stopped, skipping sync")
            return
        }
        
        if appGroupState.isPaused && timerState == .running {
            print("  ⚠️ State mismatch: Live Activity is paused but timer is running")
            print("  - Pausing timer to match Live Activity")
            pause()
        } else if !appGroupState.isPaused && timerState == .paused {
            print("  ⚠️ State mismatch: Live Activity is running but timer is paused")
            print("  - Resuming timer to match Live Activity")
            resume()
        } else {
            print("  ✅ States are in sync")
        }
    }
    
    /// Start listening for Firestore state changes
    func startListeningForRemoteStateChanges() {
        guard #available(iOS 16.1, *) else { return }
        
        print("🔄 TimerService: Starting Firestore state listener")
        
        TimerStateSync.shared.startListeningForStateChanges { [weak self] contentState in
            guard let self = self,
                  let contentState = contentState else { return }
            
            DispatchQueue.main.async {
                print("🔄 TimerService: Received Firestore state update")
                print("  - Is paused: \(contentState.isPaused)")
                print("  - Current state: \(self.timerState)")
                
                // Don't sync if timer is already stopped (completed)
                guard self.timerState != .stopped else {
                    print("  ℹ️ Timer is stopped, ignoring remote state update")
                    return
                }
                
                // Sync with remote pause state
                if contentState.isPaused && self.timerState == .running {
                    print("  - Remote pause detected, pausing local timer")
                    self.pause()
                } else if !contentState.isPaused && self.timerState == .paused {
                    print("  - Remote resume detected, resuming local timer")
                    self.resume()
                }
            }
        }
    }
    
    // MARK: - Sound Feedback
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "timer_alert", withExtension: "wav") else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
        }
    }

    private func playAlertSound() {
        guard playSoundFeedback else { return }
        // Ensure this is not an overexertion alert, which has its own sound
        guard !isOverexertionWarningActive else { return }
        
        // Prepare and play the standard interval/completion sound
        guard let soundURL = Bundle.main.url(forResource: "timer_alert_soft", withExtension: "caf") else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
        }
    }
    
    // Added for Story 7.3
    private func playOverexertionAlertSound() {
        guard playSoundFeedback else { return }
        guard let soundName = overexertionAlertSoundName, !soundName.isEmpty else {
            // Optionally play a default system sound as fallback
            // For now, just logs and returns
            return
        }

        guard let soundURL = Bundle.main.url(forResource: soundName.components(separatedBy: ".").first, withExtension: soundName.components(separatedBy: ".").last) else {
            return
        }
        
        do {
            // Stop any currently playing sound
            if audioPlayer?.isPlaying == true {
                audioPlayer?.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play() // Play the distinct overexertion sound
        } catch {
        }
    }
    
    func toggleSoundFeedback(isOn: Bool) {
        playSoundFeedback = isOn
        // Persist this setting if needed (e.g., in UserDefaults)
    }
    
    // MARK: - Debug Methods
    
    func performLiveActivityDebugCheck() {
        print("🔍 TimerService: Initiating Live Activity debug check...")
        print("  - Current state: \(timerState)")
        print("  - Mode: \(currentTimerMode)")
        print("  - Elapsed: \(elapsedTime)s")
        print("  - Remaining: \(remainingTime)s")
        
        Task {
            await LiveActivityDebugger.shared.performDebugCheck()
        }
    }
    
    func testManualPushUpdate() {
        print("🔄 TimerService: Testing manual push update to Live Activity...")
        
        // Check if we have an active Live Activity
        guard #available(iOS 16.1, *) else {
            print("  ❌ Live Activities not available on this iOS version")
            return
        }
        
        guard let activity = LiveActivityManager.shared.currentActivity else {
            print("  ❌ No active Live Activity found")
            return
        }
        
        print("  ✅ Found active Live Activity: \(activity.id)")
        print("  - Activity state: \(activity.activityState)")
        
        // Trigger a manual push update through the Live Activity manager
        Task {
            // Update the activity with current timer state
            let isPaused = timerState == .paused
            print("  📤 Sending push update with isPaused: \(isPaused)")
            
            LiveActivityManager.shared.updateActivity(isPaused: isPaused)
            
            // Also force a sync to Firestore which triggers the push
            TimerStateSync.shared.forceSyncUpdate(activityId: activity.id)
            
            print("  ✅ Push update sent successfully")
        }
    }
    
    // Public method to restore from background for non-persistent timers
    func manuallyRestoreFromBackground(isQuickPractice: Bool = false) -> Bool {
        // This method can be called manually by views that manage their own background state
        if #available(iOS 16.1, *) {
            if BackgroundTimerTracker.shared.restoreTimerState(to: self, isQuickPractice: isQuickPractice) != nil {
                return true
            }
        }
        return false
    }
    
    // MARK: - Live Activity Support
    
    /// Start a timer remotely via push notification
    func startRemoteTimer(methodId: String, methodName: String, duration: TimeInterval, sessionType: TimerMode) {
        guard timerState == .stopped else {
            return
        }
        
        // Configure timer with remote parameters
        let config = TimerConfiguration(
            recommendedDurationSeconds: Int(duration),
            isCountdown: sessionType == .countdown,
            intervals: nil
        )
        
        // Store method info
        currentMethodId = methodId
        currentMethodName = methodName
        
        // Configure timer
        configure(with: config)
        
        // Start the timer
        start()
        
        print("✅ TimerService: Remote timer started - \(methodName) for \(duration)s")
    }
    
    
    @available(iOS 16.1, *)
    private func startLiveActivity() {
        guard let startTime = startTime else { return }
        
        let methodName = currentMethodName ?? "Timer"
        let sessionType: TimerActivityAttributes.ContentState.SessionType
        let endTime: Date
        
        switch currentTimerMode {
        case .countdown:
            sessionType = .countdown
            endTime = startTime.addingTimeInterval(targetDuration)
        case .stopwatch:
            sessionType = .countup
            // For stopwatch, use a far future date as we don't know when it will end
            endTime = Date().addingTimeInterval(60 * 60 * 8) // 8 hours max
        case .interval:
            sessionType = .interval
            // For intervals, use the total duration
            endTime = startTime.addingTimeInterval(targetDuration)
        }
        
        LiveActivityManager.shared.startTimerActivity(
            methodId: currentMethodId ?? "",
            methodName: methodName,
            startTime: startTime,
            endTime: endTime,
            duration: targetDuration,
            sessionType: sessionType,
            timerType: isQuickPracticeTimer ? "quick" : "main"
        )
        
        // Schedule background tasks for Live Activity updates
        LiveActivityBackgroundTaskManager.shared.scheduleAppRefresh()
        if sessionType == .countdown || sessionType == .interval {
            LiveActivityBackgroundTaskManager.shared.scheduleProcessingTask(duration: targetDuration)
        }
        
        // Wait a bit for the activity to be fully initialized before syncing
        let workItem = DispatchWorkItem {
            // Sync timer state with Firestore for push updates
            if let activityId = LiveActivityManager.shared.currentActivity?.id {
                TimerStateSync.shared.startSyncing(
                    activityId: activityId,
                    methodId: self.currentMethodId ?? "",
                    methodName: methodName,
                    startedAt: startTime,
                    duration: self.targetDuration,
                    sessionType: sessionType.rawValue,
                    isPaused: false
                )
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
}

// Make TimerState and TimerMode RawRepresentable
extension TimerState: RawRepresentable {
    public typealias RawValue = String
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "running": self = .running
        case "paused": self = .paused
        case "stopped": self = .stopped
        case "completed": self = .completed
        default: return nil
        }
    }
    public var rawValue: RawValue {
        switch self {
        case .running: return "running"
        case .paused: return "paused"
        case .stopped: return "stopped"
        case .completed: return "completed"
        }
    }
}

// Story 7.3: Ensured TimerMode also uses String for RawValue for consistency 
// and to match usage in restoreState.
extension TimerMode: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "stopwatch": self = .stopwatch
        case "countdown": self = .countdown
        case "interval": self = .interval
        default: return nil
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .stopwatch: return "stopwatch"
        case .countdown: return "countdown"
        case .interval: return "interval"
        }
    }
}

// MARK: - Story 7.3 Public Methods
extension TimerService {
    func acknowledgeOverexertionWarning() {
        if isOverexertionWarningActive {
            overexertionWarningAcknowledged = true
            isOverexertionWarningActive = false // Warning is dismissed from UI, but timer continues
            // We keep 'overexertionWarningAcknowledged' true so it doesn't re-trigger immediately
            // unless the timer is reset/restarted.
        }
    }

    // Call this when the timer is fully reset or a new configuration is applied
    // to allow the warning to trigger again if conditions are met.
    func resetOverexertionState() {
        isOverexertionWarningActive = false
        overexertionWarningAcknowledged = false
        // maxRecommendedDuration is reset via configure(with:)
    }
}