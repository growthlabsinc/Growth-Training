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


@MainActor
class TimerService: ObservableObject {
    // MARK: - Singleton (optional - for shared timer across views)
    static let shared = TimerService()
    
    
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
    
    #if DEBUG
    @Published var isDebugSpeedActive: Bool = false // Debug flag for 5x speed mode
    #endif

    // MARK: - Internal State
    private var timer: Timer?
    // Background tasks removed - using Darwin notifications instead (30 second limit on background tasks)
    internal var startTime: Date? // Actual Date when timer (or current interval) started or resumed
    private var pausedElapsedTime: TimeInterval = 0 // Track elapsed time when paused
    private var lastResumeTime: Date? // Track when we last resumed
    private var lastPauseTime: Date? // Track when we last paused
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
        
        
        if !skipStateRestore {
            restoreState()
        }
        setupAudioPlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTimerActionFromWidget), name: Notification.Name("TimerActionFromWidget"), object: nil)
        
        // Clean up any corrupted Live Activities on startup
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.cleanupStaleActivities()
        }
        
        // Register for Darwin notifications from widget
        registerForDarwinNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        unregisterFromDarwinNotifications()
        
        // Clean up widget Darwin notification observers
        let actions = ["pause", "resume", "stop"]
        for action in actions {
            let notificationName = "com.growthlabs.growthmethod.timerAction.\(action)" as CFString
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                nil,
                CFNotificationName(notificationName),
                nil
            )
        }
    }

    // MARK: - Configuration
    func configure(with config: TimerConfiguration?) {
        Logger.debug("Starting configuration", logger: AppLoggers.timer)
        Logger.debug("Current remainingTime before reset: \(remainingTime)", logger: AppLoggers.timer)
        
        // Set up Darwin notification observers on first configuration
        if !darwinObserversSetup {
            setupDarwinNotificationObservers()
            darwinObserversSetup = true
        }
        
        resetInternalState() // Reset before applying new config
        activeTimerConfig = config

        Logger.debug("After reset, remainingTime: \(remainingTime)", logger: AppLoggers.timer)

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
                Logger.debug("Set countdown mode - targetDuration: \(targetDuration), remainingTime: \(remainingTime)", logger: AppLoggers.timer)
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
        Logger.info("🔴 [START] TimerService.start() called at \(timestamp)", logger: AppLoggers.timer)
        Logger.debug("Current state: \(timerState)", logger: AppLoggers.timer)
        Logger.debug("Current mode: \(currentTimerMode)", logger: AppLoggers.timer)
        Logger.debug("Elapsed time before: \(elapsedTime)", logger: AppLoggers.timer)
        Logger.debug("Remaining time before: \(remainingTime)", logger: AppLoggers.timer)
        
        // Check if timer is actually running (not just state)
        if timerState == .running && timer != nil {
            Logger.warning("Timer already running, returning", logger: AppLoggers.timer)
            return 
        }
        
        // If state is running but no timer exists, reset state (recovery from inconsistent state)
        if timerState == .running && timer == nil {
            Logger.warning("Timer state was running but no timer exists - resetting state", logger: AppLoggers.timer)
            timerState = .stopped
        }
        
        // Track the previous state before changing it
        let wasStoppedState = timerState == .stopped
        let wasPausedState = timerState == .paused
        
        Logger.debug("Was stopped: \(wasStoppedState)", logger: AppLoggers.timer)
        Logger.debug("Was paused: \(wasPausedState)", logger: AppLoggers.timer)
        
        // Clear the restoration flag when starting normally
        justRestoredFromBackground = false

        if timerState == .stopped {
            Logger.debug("📝 Timer was stopped, resetting values", logger: AppLoggers.timer)
            switch currentTimerMode {
            case .stopwatch:
                elapsedTime = 0
                Logger.debug("Stopwatch mode: elapsed reset to 0", logger: AppLoggers.timer)
            case .countdown:
                elapsedTime = 0 // Counts how much has passed from the countdown
                remainingTime = targetDuration
                Logger.debug("Countdown mode: elapsed=0, remaining=\(remainingTime)", logger: AppLoggers.timer)
            case .interval:
                elapsedTime = 0 // Time within the current interval
                if currentIntervalIndex == nil { currentIntervalIndex = 0 } // Ensure we have an index
                guard let idx = currentIntervalIndex, let config = activeTimerConfig, let intervals = config.intervals, idx < intervals.count else {
                    Logger.error("Interval config error on start", logger: AppLoggers.timer)
                    stop() // Or handle error appropriately
                    return
                }
                currentIntervalTargetDuration = TimeInterval(intervals[idx].durationSeconds)
                remainingTime = currentIntervalTargetDuration
                updateIntervalDisplay(forIndex: idx)
                Logger.debug("Interval mode: elapsed=0, remaining=\(remainingTime)", logger: AppLoggers.timer)
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
            Logger.info("🚀 CRITICAL: Fresh start - reset all timing", logger: AppLoggers.timer)
        } else if wasPausedState {
            // Resuming from pause - store the elapsed time and set new resume time
            pausedElapsedTime = elapsedTime
            lastResumeTime = now
            Logger.info("🚀 CRITICAL: Resuming from pause", logger: AppLoggers.timer)
            Logger.debug("Paused elapsed time: \(pausedElapsedTime)", logger: AppLoggers.timer)
        }
        
        timerState = .running
        
        // Notify TimerCoordinator that this timer has started
        let timerType = isQuickPracticeTimer ? "quick" : "main"
        TimerCoordinator.shared.timerStarted(type: timerType)
        Logger.debug("📱 TimerCoordinator notified: timer '\(timerType)' started", logger: AppLoggers.timer)
        
        Logger.verbose("Current time (now): \(now)", logger: AppLoggers.timer)
        Logger.verbose("Elapsed time: \(elapsedTime)", logger: AppLoggers.timer)
        Logger.verbose("StartTime: \(startTime ?? Date())", logger: AppLoggers.timer)
        Logger.verbose("Paused elapsed: \(pausedElapsedTime)", logger: AppLoggers.timer)
        Logger.verbose("Last resume time: \(lastResumeTime ?? Date())", logger: AppLoggers.timer)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        // Ensure timer is added to the current run loop
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // Background task removed - Live Activity handles background state via Darwin notifications
        
        // Story 7.3: Reset acknowledged state if timer is restarted from stopped state
        if wasStoppedState {
             overexertionWarningAcknowledged = false
             isOverexertionWarningActive = false
        }
        
        // Start Live Activity
        if #available(iOS 16.1, *) {
            Logger.debug("🎯 iOS 16.1+ detected, checking Live Activity state:", logger: AppLoggers.liveActivity)
            Logger.debug("wasPausedState: \(wasPausedState)", logger: AppLoggers.liveActivity)
            Logger.debug("hasActiveActivity: \(LiveActivityManager.shared.hasActiveActivity)", logger: AppLoggers.liveActivity)
            
            // If we're resuming from paused, just update the existing activity
            if wasPausedState && LiveActivityManager.shared.hasActiveActivity {
                Logger.info("📱 Updating existing Live Activity to running state", logger: AppLoggers.liveActivity)
                LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: true, isPaused: false)
                
                // Let Live Activity handle its own state updates through push notifications
                // App Group state should not be used for timer synchronization
            } else {
                // Otherwise start a new Live Activity
                Logger.info("📱 Starting new Live Activity with running state", logger: AppLoggers.liveActivity)
                startLiveActivity()
            }
        } else {
            Logger.debug("iOS 16.1+ not available, Live Activity not supported", logger: AppLoggers.liveActivity)
        }
        
        Logger.info("🔴 [END] TimerService.start() completed", logger: AppLoggers.timer)
        Logger.debug("Final state: \(timerState)", logger: AppLoggers.timer)
        Logger.debug("Final elapsed: \(elapsedTime)", logger: AppLoggers.timer)
        Logger.debug("Final remaining: \(remainingTime)", logger: AppLoggers.timer)
        Logger.debug("Timer active: \(timer != nil)", logger: AppLoggers.timer)
    }
    
    private func tick() {
        guard let resumeTime = lastResumeTime, timerState == .running else { 
            // Log why tick is not processing
            if lastResumeTime == nil {
                Logger.verbose("⏱️ [TICK] Skipped - lastResumeTime is nil", logger: AppLoggers.timer)
            }
            if timerState != .running {
                Logger.verbose("⏱️ [TICK] Skipped - state is \(timerState), not running", logger: AppLoggers.timer)
            }
            return 
        }
        
        let now = Date()
        
        // CRITICAL FIX: Calculate elapsed time as pausedElapsedTime + time since last resume
        let timeSinceResume = now.timeIntervalSince(resumeTime)
        actualElapsedTime = pausedElapsedTime + timeSinceResume
        
        elapsedTime = actualElapsedTime
        
        // Log every 10th tick (1 second) to avoid spam
        let shouldLog = Int(elapsedTime * 10) % 10 == 0
        if shouldLog {
            let modeStr = currentTimerMode == .countdown ? "countdown" : "stopwatch"
            let remainingStr = currentTimerMode == .countdown ? String(format: "%.1fs", remainingTime) : "N/A"
            Logger.verbose("⏱️ [TICK] \(modeStr) - elapsed: \(String(format: "%.1fs", elapsedTime)), remaining: \(remainingStr)", logger: AppLoggers.timer)
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
                Logger.verbose("Mode: Countdown", logger: AppLoggers.timer)
                Logger.verbose("Target duration: \(targetDuration)s", logger: AppLoggers.timer)
                Logger.verbose("Previous remaining: \(previousRemaining)s", logger: AppLoggers.timer)
                Logger.verbose("New remaining: \(remainingTime)s", logger: AppLoggers.timer)
            }
            
            if remainingTime == 0 && !justRestoredFromBackground {
                Logger.info("🏁 Countdown completed!", logger: AppLoggers.timer)
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
                Logger.verbose("Mode: Interval", logger: AppLoggers.timer)
                Logger.verbose("Current interval: \(idx) of \(intervals.count)", logger: AppLoggers.timer)
                Logger.verbose("Interval duration: \(currentIntervalTargetDuration)s", logger: AppLoggers.timer)
                Logger.verbose("Previous remaining: \(previousRemaining)s", logger: AppLoggers.timer)
                Logger.verbose("New remaining: \(remainingTime)s", logger: AppLoggers.timer)
                Logger.verbose("Progress: \(currentIntervalProgress)", logger: AppLoggers.timer)
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
        // Check if we have a valid Live Activity in paused state
        // This prevents dismissing the Live Activity when restoring from background
        if #available(iOS 16.1, *) {
            if LiveActivityManager.shared.hasActiveActivity {
                // If Live Activity exists and timer is paused, don't complete the timer
                // This happens when restoring from background with a paused timer at 0:00
                if timerState == .paused && remainingTime == 0 {
                    Logger.warning("Timer appears completed but is paused - skipping completion", logger: AppLoggers.timer)
                    Logger.debug("This likely means the timer was paused at 0:00", logger: AppLoggers.timer)
                    // Keep the timer in paused state
                    timerState = .paused
                    return
                }
            }
        }
        
        // Store completion data before state changes
        let completedElapsedTime = elapsedTime
        let completedStartTime = startTime ?? Date().addingTimeInterval(-elapsedTime)
        let completedMethodName = currentMethodName
        
        playAlertSound()
        
        // Cancel all timer notifications since the timer has completed
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        }
        
        // For countdown and interval modes, when finished:
        if currentTimerMode == .countdown {
            elapsedTime = targetDuration // Ensure elapsedTime reflects full duration
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
                if let activityId = LiveActivityManager.shared.currentActivityId {
                    // Store timer completion state if needed
                    Logger.info("💾 Timer completed for Live Activity: \(activityId)", logger: AppLoggers.liveActivity)
                }
                
                // End the Live Activity immediately
                LiveActivityManager.shared.endTimerActivity()
                
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
                if #available(iOS 16.2, *) {
                    LiveActivityBackgroundTaskManager.shared.cancelAllTasks()
                }
                
                // Post notification that timer completed with completion data
                NotificationCenter.default.post(
                    name: Notification.Name("timerCompletedAutomatically"),
                    object: nil,
                    userInfo: [
                        "elapsedTime": completedElapsedTime,
                        "startTime": completedStartTime,
                        "methodName": completedMethodName ?? ""
                    ]
                )
            }
        } else {
            // For iOS versions that don't support Live Activities
            let methodName = currentMethodName ?? "Training"
            let duration = elapsedTime
            NotificationService.shared.showSessionCompletionNotification(
                methodName: methodName,
                duration: duration
            )
            
            // Post notification for non-Live Activity devices too
            NotificationCenter.default.post(
                name: Notification.Name("timerCompletedAutomatically"),
                object: nil,
                userInfo: [
                    "elapsedTime": completedElapsedTime,
                    "startTime": completedStartTime,
                    "methodName": completedMethodName ?? ""
                ]
            )
        } 
        // Optionally, could change state to a specific .completed state if needed
        // For now, .paused signifies completion for countdown/interval
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
        Logger.info("🟡 [PAUSE] TimerService.pause() called at \(timestamp)", logger: AppLoggers.timer)
        Logger.debug("Current state: \(timerState)", logger: AppLoggers.timer)
        Logger.debug("Elapsed time: \(elapsedTime)", logger: AppLoggers.timer)
        Logger.debug("Remaining time: \(remainingTime)", logger: AppLoggers.timer)
        Logger.debug("Start time: \(String(describing: startTime))", logger: AppLoggers.timer)
        
        guard timerState == .running else { 
            Logger.warning("Timer not running, cannot pause", logger: AppLoggers.timer)
            return 
        }
        
        // Calculate exact elapsed time at pause moment
        if let startTime = startTime {
            let exactElapsed = Date().timeIntervalSince(startTime)
            Logger.verbose("Exact elapsed at pause: \(exactElapsed)s", logger: AppLoggers.timer)
            Logger.verbose("Stored elapsed: \(elapsedTime)s", logger: AppLoggers.timer)
            Logger.verbose("Difference: \(abs(exactElapsed - elapsedTime))s", logger: AppLoggers.timer)
        }
        
        timerState = .paused
        timer?.invalidate()
        timer = nil
        lastPauseTime = Date() // Track when we paused
        
        // Let Live Activity handle its own state updates through push notifications
        // App Group state should not be used for timer synchronization
        
        Logger.debug("State changed to: \(timerState)", logger: AppLoggers.timer)
        Logger.debug("Timer invalidated", logger: AppLoggers.timer)
        
        saveStateOnPauseOrBackground()
        // Background task removed - Live Activity handles background state
        
        // Update Live Activity (only if not showing completion)
        if #available(iOS 16.1, *) {
            if LiveActivityManager.shared.hasActiveActivity {
                Logger.info("📱 Updating Live Activity to paused state", logger: AppLoggers.liveActivity)
                LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: false, isPaused: true)
            }
        }
        
        Logger.info("🟡 [END] TimerService.pause() completed", logger: AppLoggers.timer)
    }
    
    // MARK: - Background Timer Tracking
    
    /// Save state when view disappears with active timer
    func saveStateForBackground(methodName: String? = nil, isQuickPractice: Bool = false) {
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.saveTimerState(from: self, methodName: methodName ?? currentMethodName ?? "Practice Session", isQuickPractice: isQuickPractice)
        }
    }
    
    /// Restore state when view reappears
    func restoreFromBackground(isQuickPractice: Bool = false) {
        let timestamp = Date()
        Logger.info("🔵 [RESTORE] TimerService.restoreFromBackground() called at \(timestamp)", logger: AppLoggers.timer)
        Logger.debug("isQuickPractice: \(isQuickPractice)", logger: AppLoggers.timer)
        Logger.debug("Current state before restore: \(timerState)", logger: AppLoggers.timer)
        Logger.debug("Current elapsed before restore: \(elapsedTime)", logger: AppLoggers.timer)
        Logger.debug("Current remaining before restore: \(remainingTime)", logger: AppLoggers.timer)
        
        // CRITICAL FIX: Don't restore if timer is already running (e.g., just resumed via Live Activity)
        // This prevents race conditions where Live Activity resumes the timer and then
        // onAppear tries to restore from background, causing incorrect state
        if timerState == .running && timer != nil {
            Logger.info("⚠️ Timer is already running, skipping background restoration to prevent race condition", logger: AppLoggers.timer)
            print("⚠️ Timer is already running, skipping background restoration")
            return
        }
        
        // Don't restore if timer is already stopped
        guard timerState != .stopped else {
            Logger.warning("Timer is already stopped, skipping restoration", logger: AppLoggers.timer)
            return
        }
        
        if let restoredState = BackgroundTimerTracker.shared.restoreTimerState(to: self, isQuickPractice: isQuickPractice) {
            Logger.info("✅ Background state found and restored:", logger: AppLoggers.timer)
            Logger.debug("Was running: \(restoredState.isRunning)", logger: AppLoggers.timer)
            Logger.debug("Elapsed after restore: \(elapsedTime)", logger: AppLoggers.timer)
            Logger.debug("Remaining after restore: \(remainingTime)", logger: AppLoggers.timer)
            Logger.debug("Total elapsed time calculated: \(restoredState.elapsedTime)", logger: AppLoggers.timer)
            
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
            
            Logger.debug("📊 Resume decision:", logger: AppLoggers.timer)
            Logger.debug("Was running: \(restoredState.isRunning)", logger: AppLoggers.timer)
            Logger.debug("Is paused: \(timerState == .paused)", logger: AppLoggers.timer)
            Logger.debug("Not completed: \(!(currentTimerMode == .countdown && remainingTime <= 0))", logger: AppLoggers.timer)
            Logger.debug("Should resume: \(shouldResume)", logger: AppLoggers.timer)
            
            if shouldResume {
                // Check App Group state to see if it was paused while in background
                if #available(iOS 16.1, *) {
                    // Check App Group state first (more reliable than Live Activity state)
                    let appGroupState = AppGroupConstants.getTimerState()
                    if let activityId = appGroupState.activityId,
                       appGroupState.isPaused {
                        print("  📱 App Group state check:")
                        Logger.info("    - Activity ID: \(activityId)", logger: AppLoggers.liveActivity)
                        Logger.info("    - Is paused in App Group: true", logger: AppLoggers.liveActivity)
                        Logger.info("  🛑 Timer was paused via Live Activity, keeping it paused", logger: AppLoggers.liveActivity)
                        
                        // Use the stored elapsed time from App Group
                        let pausedElapsed = appGroupState.elapsedTime
                        self.elapsedTime = pausedElapsed
                        self.remainingTime = max(0, targetDuration - pausedElapsed)
                        print("    - App Group elapsed: \(pausedElapsed)")
                        print("    - App Group remaining: \(self.remainingTime)")
                        
                        shouldResume = false
                    } else if LiveActivityManager.shared.hasActiveActivity {
                        // Check current timer state as fallback
                        Logger.info("  📱 Live Activity exists, checking current timer state", logger: AppLoggers.liveActivity)
                        
                        if timerState == .paused {
                                print("  🛑 Timer was paused, keeping it paused")
                            
                            // Update Live Activity with current state
                            LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: false, isPaused: true)
                            return
                        }
                    } else {
                        Logger.warning("  ⚠️ No Live Activity found", logger: AppLoggers.liveActivity)
                    }
                }
                
                // Ensure timing is set correctly for continuous timing
                let now = Date()
                // startTime is already set during restoration
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
                    Task { @MainActor in
                        self?.tick()
                    }
                }
                
                // Ensure timer is added to the current run loop
                if let timer = timer {
                    RunLoop.current.add(timer, forMode: .common)
                }
                
                // Register background task for continued execution
                // Background task removed - Live Activity handles background state via Darwin notifications
                
                // Update Live Activity to show running state
                if #available(iOS 16.1, *) {
                    Logger.info("  📱 Updating Live Activity after background restoration", logger: AppLoggers.liveActivity)
                    LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: true, isPaused: false)
                }
                
                print("  ✅ Timer resumed successfully")
                print("    - Final state: \(timerState)")
                print("    - Timer active: \(timer != nil)")
            } else {
                print("  ⏸️ Timer was not running or already in correct state, not resuming")
                
                // CRITICAL FIX: Don't force pause on countdown timers that aren't actually complete
                // The condition was too aggressive - checking only remainingTime <= 0 and elapsedTime > 0
                // This would incorrectly pause timers that were resumed from Live Activity
                // Only pause if we're actually at or past the target duration
                // ALSO: Don't interfere if Live Activity is managing the timer state
                let hasLiveActivity = {
                    if #available(iOS 16.1, *) {
                        return LiveActivityManager.shared.hasActiveActivity
                    }
                    return false
                }()
                
                // Only force pause if timer is truly complete AND there's no Live Activity managing it
                // Also ensure we're not using stale elapsed time values
                if currentTimerMode == .countdown && !hasLiveActivity {
                    // Recalculate elapsed time to ensure accuracy
                    let currentElapsed = self.elapsedTime
                    let targetDur = self.targetDuration
                    
                    print("  📊 Checking completion: elapsed=\(currentElapsed), target=\(targetDur)")
                    
                    if currentElapsed >= targetDur && targetDur > 0 {
                        print("  🏁 Timer is actually completed (elapsed >= target), keeping it paused")
                        timerState = .paused
                    }
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
            return BackgroundTimerTracker.shared.hasActiveBackgroundTimer()
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
            Logger.info("  📱 Updating Live Activity to running state", logger: AppLoggers.liveActivity)
            LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: true, isPaused: false)
            
            // Let Live Activity handle its own state updates through push notifications
            // App Group state should not be used for timer synchronization
        }
        
        print("🟢 [END] TimerService.resume() completed")
    }
    
    // Track when this function was last called to prevent duplicate processing
    private var lastStateCheckTime: Date?
    private let stateCheckDebounceInterval: TimeInterval = 0.5
    
    // Darwin notification setup flag
    private var darwinObserversSetup = false
    
    /// Check Live Activity state when app becomes active
    func checkStateOnAppBecomeActive() {
        // CRITICAL FIX: Debounce multiple calls to prevent race conditions
        // This function is called from AppSceneDelegate, GrowthAppApp, and TimerViewModel
        // We need to ensure it only processes once per app activation
        if let lastCheck = lastStateCheckTime,
           abs(lastCheck.timeIntervalSinceNow) < stateCheckDebounceInterval {
            Logger.verbose("⏭️ Skipping checkStateOnAppBecomeActive - already called \(abs(lastCheck.timeIntervalSinceNow))s ago", logger: AppLoggers.timer)
            return
        }
        lastStateCheckTime = Date()
        
        Logger.info("🔄 TimerService: App became active, checking for timer actions", logger: AppLoggers.timer)
        
        // Skip sync if we just restored from background (within 2 seconds)
        if let lastRestore = lastBackgroundRestoreTime,
           abs(lastRestore.timeIntervalSinceNow) < 2.0 {
            Logger.verbose("Skipping sync, just restored from background \(abs(lastRestore.timeIntervalSinceNow))s ago", logger: AppLoggers.timer)
            return
        }
        
        // First check for any unprocessed timer actions (higher priority)
        if let timerAction = AppGroupFileManager.shared.readTimerAction() {
            Logger.info("📥 Found unprocessed action: \(timerAction.action) from \(abs(timerAction.timestamp.timeIntervalSinceNow))s ago", logger: AppLoggers.timer)
            
            // Only process if it's for the main timer
            if timerAction.timerType == "main" {
                // Process based on current time to avoid stale actions
                // Reduced timeout to 5 seconds to avoid processing stale actions
                if abs(timerAction.timestamp.timeIntervalSinceNow) < 5 {
                    switch timerAction.action {
                    case "pause":
                        if timerState == .running {
                            Logger.info("⏸️ Processing pause action from Live Activity", logger: AppLoggers.timer)
                            pause()
                        } else {
                            Logger.debug("Ignoring pause action - timer not running (state: \(timerState))", logger: AppLoggers.timer)
                        }
                    case "resume":
                        if timerState == .paused {
                            Logger.info("▶️ Processing resume action from Live Activity", logger: AppLoggers.timer)
                            resume()
                        } else {
                            Logger.debug("Ignoring resume action - timer not paused (state: \(timerState))", logger: AppLoggers.timer)
                        }
                    case "stop":
                        if timerState != .stopped {
                            Logger.info("⏹️ Processing stop action from Live Activity", logger: AppLoggers.timer)
                            
                            // Capture state before stopping for completion flow
                            let capturedElapsedTime = elapsedTime
                            let capturedStartTime = startTime ?? Date().addingTimeInterval(-capturedElapsedTime)
                            let methodName = currentMethodName ?? "Practice"
                            
                            // Save completion data to UserDefaults for later processing
                            if capturedElapsedTime > 0 {
                                let completionData: [String: Any] = [
                                    "elapsedTime": capturedElapsedTime,
                                    "startTime": capturedStartTime.timeIntervalSince1970,
                                    "methodName": methodName,
                                    "timestamp": Date().timeIntervalSince1970
                                ]
                                if let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") {
                                    sharedDefaults.set(completionData, forKey: "pendingTimerCompletion")
                                    sharedDefaults.synchronize()
                                }
                                Logger.info("💾 Saved pending timer completion data", logger: AppLoggers.timer)
                            }
                            
                            stop()
                        } else {
                            Logger.debug("Ignoring stop action - timer already stopped", logger: AppLoggers.timer)
                        }
                    default:
                        Logger.warning("Unknown timer action: \(timerAction.action)", logger: AppLoggers.timer)
                        break
                    }
                } else {
                    Logger.info("🕐 Action is too old (> 5s), clearing it", logger: AppLoggers.timer)
                }
                
                // CRITICAL: Always clear the action after reading it to prevent re-processing
                AppGroupFileManager.shared.clearTimerAction()
                
                // Don't sync with Live Activity state after processing an action
                // to avoid undoing what we just did
                return
            } else {
                // Clear non-main timer actions to prevent them from accumulating
                Logger.debug("Clearing non-main timer action: \(timerAction.timerType)", logger: AppLoggers.timer)
                AppGroupFileManager.shared.clearTimerAction()
            }
        }
        
        // Only sync with App Group state if no actions were processed
        syncWithLiveActivityState()
    }

    func stop() {
        timerState = .stopped
        timer?.invalidate()
        timer = nil
        
        // Notify TimerCoordinator that this timer has stopped
        let timerType = isQuickPracticeTimer ? "quick" : "main"
        TimerCoordinator.shared.timerStopped(type: timerType)
        print("  📱 TimerCoordinator notified: timer '\(timerType)' stopped")
        
        // Cancel all timer notifications since the timer has been stopped
        if #available(iOS 16.1, *) {
            BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        }
        
        // End Live Activity and stop syncing
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endTimerActivity()
            
            // Cancel background tasks
            if #available(iOS 16.2, *) {
                LiveActivityBackgroundTaskManager.shared.cancelAllTasks()
            }
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
        // Background task removed - Live Activity handles background state
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

    // MARK: - State Persistence (Background tasks removed - using Darwin notifications)
    // Background tasks are limited to 30 seconds, so we rely on Darwin notifications
    // and Live Activity state management instead

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
        if BackgroundTimerTracker.shared.hasActiveBackgroundTimer() {
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
    
    nonisolated private func unregisterFromDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }
    
    nonisolated private func handleDarwinNotification() {
        Logger.info("🔔 [LIVE_ACTIVITY_BUTTON] Darwin notification received", logger: AppLoggers.liveActivity)
        Logger.info("🔔 [LIVE_ACTIVITY_BUTTON] TimerService: Darwin notification received at \(Date())", logger: AppLoggers.liveActivity)
        
        // Check shared defaults for the action
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") else {
            Logger.error("❌ [LIVE_ACTIVITY_BUTTON] Failed to access shared defaults", logger: AppLoggers.liveActivity)
            print("❌ [LIVE_ACTIVITY_BUTTON] Failed to access shared defaults")
            return
        }
        
        guard let action = sharedDefaults.string(forKey: "lastTimerAction") else {
            Logger.error("❌ [LIVE_ACTIVITY_BUTTON] No action found in shared defaults", logger: AppLoggers.liveActivity)
            print("❌ [LIVE_ACTIVITY_BUTTON] No action found in shared defaults")
            
            // Log what keys are available for debugging
            let allKeys = sharedDefaults.dictionaryRepresentation().keys
            print("  Available keys in shared defaults: \(allKeys)")
            return
        }
        
        guard let lastActionTime = sharedDefaults.object(forKey: "lastActionTime") as? Date else {
            Logger.error("❌ [LIVE_ACTIVITY_BUTTON] No lastActionTime found in shared defaults", logger: AppLoggers.liveActivity)
            print("❌ [LIVE_ACTIVITY_BUTTON] No lastActionTime found in shared defaults")
            return
        }
        
        let timerType = sharedDefaults.string(forKey: "lastTimerType") ?? "unknown"
        let activityId = sharedDefaults.string(forKey: "lastActivityId") ?? "unknown"
        let timeSinceAction = Date().timeIntervalSince(lastActionTime)
        
        Logger.info("🔔 [LIVE_ACTIVITY_BUTTON] Found action: '\(action)'", logger: AppLoggers.liveActivity)
        Logger.debug("  - Timer Type: '\(timerType)'", logger: AppLoggers.liveActivity)
        Logger.debug("  - Activity ID: '\(activityId)'", logger: AppLoggers.liveActivity)
        Logger.debug("  - Time since action: \(timeSinceAction)s", logger: AppLoggers.liveActivity)
        
        print("🔔 [LIVE_ACTIVITY_BUTTON] Found action: '\(action)', time since action: \(timeSinceAction)s")
        print("  - Timer Type: '\(timerType)'")
        print("  - Activity ID: '\(activityId)'")
        
        // Only process if action was recent (within 5 seconds)
        guard timeSinceAction < 5 else {
            Logger.warning("⏰ [LIVE_ACTIVITY_BUTTON] Action too old (\(timeSinceAction)s), ignoring", logger: AppLoggers.liveActivity)
            print("⏰ [LIVE_ACTIVITY_BUTTON] Action too old (\(timeSinceAction)s), ignoring")
            return
        }
        
        // Process on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                Logger.error("❌ [LIVE_ACTIVITY_BUTTON] Self deallocated", logger: AppLoggers.liveActivity)
                return 
            }
            
            Logger.info("🔔 [LIVE_ACTIVITY_BUTTON] Processing action: '\(action)' on main queue", logger: AppLoggers.liveActivity)
            Logger.debug("  - Current timer state: \(self.timerState)", logger: AppLoggers.liveActivity)
            Logger.debug("  - Elapsed time: \(self.elapsedTime)s", logger: AppLoggers.liveActivity)
            
            print("🔔 [LIVE_ACTIVITY_BUTTON] Processing action: '\(action)' on main queue")
            print("  - Current timer state: \(self.timerState)")
            
            switch action {
            case "pause":
                Logger.info("⏸️ [LIVE_ACTIVITY_BUTTON] Darwin: Pausing timer (current state: \(self.timerState))", logger: AppLoggers.liveActivity)
                if self.timerState == .running {
                    self.pause()
                    // Update App Group state for persistence
                    AppGroupConstants.storeTimerState(
                        startTime: self.startTime ?? Date(),
                        endTime: Date().addingTimeInterval(self.remainingTime),
                        elapsedTime: self.elapsedTime,
                        isPaused: true,
                        methodName: self.currentMethodName ?? "Timer",
                        sessionType: self.currentTimerMode.rawValue,
                        activityId: activityId
                    )
                    // Note: Live Activity is already updated locally by TimerControlIntent
                    // We only need to send Firebase push for cross-device sync
                    if #available(iOS 16.2, *) {
                        Task {
                            await LiveActivityManager.shared.sendPushUpdateForCurrentActivity(action: "pause")
                        }
                    }
                    Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer paused successfully via Darwin notification", logger: AppLoggers.liveActivity)
                    
                    // Force UI update in production builds
                    self.objectWillChange.send()
                } else {
                    Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] Timer not running (state: \(self.timerState)), ignoring pause", logger: AppLoggers.liveActivity)
                }
                
            case "resume":
                Logger.info("▶️ [LIVE_ACTIVITY_BUTTON] Darwin: Resuming timer (current state: \(self.timerState))", logger: AppLoggers.liveActivity)
                if self.timerState == .paused {
                    self.start() // This will handle the resume since timer is paused
                    // Update App Group state for persistence
                    AppGroupConstants.storeTimerState(
                        startTime: self.startTime ?? Date(),
                        endTime: Date().addingTimeInterval(self.remainingTime),
                        elapsedTime: self.elapsedTime,
                        isPaused: false,
                        methodName: self.currentMethodName ?? "Timer",
                        sessionType: self.currentTimerMode.rawValue,
                        activityId: activityId
                    )
                    // Note: Live Activity is already updated locally by TimerControlIntent
                    // We only need to send Firebase push for cross-device sync
                    if #available(iOS 16.2, *) {
                        Task {
                            await LiveActivityManager.shared.sendPushUpdateForCurrentActivity(action: "resume")
                        }
                    }
                    Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer resumed successfully via Darwin notification", logger: AppLoggers.liveActivity)
                    
                    // Force UI update in production builds
                    self.objectWillChange.send()
                } else {
                    Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] Timer not paused (state: \(self.timerState)), ignoring resume", logger: AppLoggers.liveActivity)
                }
                
            case "stop":
                Logger.info("⏹️ [LIVE_ACTIVITY_BUTTON] Darwin: Stopping timer", logger: AppLoggers.liveActivity)
                
                // Capture timer state before stopping
                let capturedElapsedTime = self.elapsedTime
                let capturedStartTime = self.startTime ?? Date().addingTimeInterval(-capturedElapsedTime)
                let methodName = self.currentMethodName ?? "Practice"
                
                // Post notifications for completion flow
                Task { @MainActor in
                    let userInfo: [String: Any] = [
                        Notification.Name.TimerUserInfoKey.timerType: Notification.Name.TimerType.main.rawValue,
                        "elapsedTime": capturedElapsedTime,
                        "startTime": capturedStartTime,
                        "methodName": methodName
                    ]
                    
                    // Post notifications for TimerViewModel and DailyRoutineView
                    NotificationCenter.default.post(name: Notification.Name("timerStoppedFromLiveActivity"), object: nil, userInfo: userInfo)
                    NotificationCenter.default.post(name: .timerStopRequested, object: nil, userInfo: userInfo)
                }
                
                self.stop()
                
                // Clear App Group state
                AppGroupConstants.clearTimerState()
                
                // End Live Activity immediately
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.endTimerActivity()
                }
                Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer stopped successfully from Live Activity", logger: AppLoggers.liveActivity)
                
            default:
                Logger.error("❓ [LIVE_ACTIVITY_BUTTON] Unknown action: '\(action)'", logger: AppLoggers.liveActivity)
                print("❓ [LIVE_ACTIVITY_BUTTON] Unknown action: '\(action)'")
            }
            
            // Clear the action - access UserDefaults directly to avoid Sendable issues
            if let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") {
                Logger.debug("🧹 [LIVE_ACTIVITY_BUTTON] Clearing action from shared defaults", logger: AppLoggers.liveActivity)
                sharedDefaults.removeObject(forKey: "lastTimerAction")
                sharedDefaults.removeObject(forKey: "lastActionTime")
                sharedDefaults.removeObject(forKey: "lastActivityId")
                sharedDefaults.synchronize()
            }
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
            
            let elapsedToSave = min(elapsedTime, maxReasonableElapsedTime)
            if elapsedTime > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Not saving unreasonably large elapsed time: \(elapsedTime)s, clamping to \(elapsedToSave)s")
            }
            defaults.set(elapsedToSave, forKey: DefaultsKeys.savedElapsedTime)
            
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
            if BackgroundTimerTracker.shared.hasActiveBackgroundTimer() {
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
        
        // Restore elapsed time
        self.elapsedTime = validatedElapsedTime
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
                
                // Apply background time
                self.elapsedTime += max(0, timeInBackground)
                
                // For countdown timers, cap elapsed time at target duration
                if sMode == .countdown {
                    self.elapsedTime = min(self.elapsedTime, self.targetDuration)
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
            
            validatedElapsedTime = min(self.elapsedTime, maxReasonableElapsedTime)
            if self.elapsedTime > maxReasonableElapsedTime {
                print("  ⚠️ WARNING: Elapsed time unreasonably large: \(self.elapsedTime)s, clamping to \(maxReasonableElapsedTime)s")
            }
            
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
            BackgroundTimerTracker.shared.clearSavedState()
        }
        
    }
    
    // MARK: - App Group State Synchronization
    
    /// Check and sync timer state with Live Activity state stored in App Group
    func syncWithLiveActivityState() {
        // DISABLED: This function causes race conditions when app enters foreground
        // The proper flow should be:
        // 1. Widget updates trigger via Darwin notifications or push updates
        // 2. App responds to those specific requests
        // 3. No automatic syncing on app lifecycle events
        
        // Keeping this function empty to prevent race conditions
        // All state updates should flow through explicit pause/resume calls
        return
    }
    
    /// Start listening for Firestore state changes
    func startListeningForRemoteStateChanges() {
        guard #available(iOS 16.1, *) else { return }
        
        // print("🔄 TimerService: Starting Firestore state listener")
        
        TimerStateSync.shared.startListeningForStateChanges { [weak self] contentState in
            guard let self = self,
                  let contentState = contentState else { return }
            
            DispatchQueue.main.async {
                // print("🔄 TimerService: Received Firestore state update")
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
    
    // MARK: - Darwin Notification Observers
    private func setupDarwinNotificationObservers() {
        // Listen for widget timer actions via Darwin notifications
        let actions = ["pause", "resume", "stop"]
        
        for action in actions {
            let notificationName = "com.growthlabs.growthmethod.timerAction.\(action)" as CFString
            
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                nil,
                { _, _, name, _, _ in
                    guard name != nil else { return }
                    
                    // Process the action from UserDefaults
                    DispatchQueue.main.async {
                        TimerService.shared.processWidgetAction()
                    }
                },
                notificationName,
                nil,
                .deliverImmediately
            )
        }
        
        Logger.info("📡 Darwin notification observers set up for widget actions", logger: AppLoggers.timer)
    }
    
    private func processWidgetAction() {
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            Logger.error("Failed to access app group UserDefaults", logger: AppLoggers.timer)
            return
        }
        
        // Read the action from UserDefaults
        guard let action = sharedDefaults.string(forKey: "widgetTimerAction"),
              let actionTime = sharedDefaults.object(forKey: "widgetActionTime") as? Date,
              abs(actionTime.timeIntervalSinceNow) < 5 else {
            // Action is too old or doesn't exist
            return
        }
        
        let timerType = sharedDefaults.string(forKey: "widgetTimerType") ?? "main"
        
        // Only process if it's for the main timer
        guard timerType == "main" else {
            Logger.debug("Widget action for non-main timer: \(timerType)", logger: AppLoggers.timer)
            return
        }
        
        Logger.info("🎯 Processing widget action: \(action)", logger: AppLoggers.timer)
        
        // Process the action
        switch action {
        case "pause":
            if timerState == .running {
                pause()
            }
        case "resume":
            if timerState == .paused {
                resume()
            }
        case "stop":
            if timerState != .stopped {
                // Capture state before stopping for completion flow
                let capturedElapsedTime = elapsedTime
                let capturedStartTime = startTime ?? Date().addingTimeInterval(-capturedElapsedTime)
                let methodName = currentMethodName ?? "Practice"
                
                // Save completion data to UserDefaults for later processing
                if capturedElapsedTime > 0 {
                    let completionData: [String: Any] = [
                        "elapsedTime": capturedElapsedTime,
                        "startTime": capturedStartTime.timeIntervalSince1970,
                        "methodName": methodName,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    if let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") {
                        sharedDefaults.set(completionData, forKey: "pendingTimerCompletion")
                        sharedDefaults.synchronize()
                    }
                    Logger.info("💾 Saved pending timer completion data from processWidgetAction", logger: AppLoggers.timer)
                }
                
                // Stop the timer
                stop()
                
                // Post notification to trigger completion flow in TimerViewModel
                Task { @MainActor in
                    let userInfo: [String: Any] = [
                        "elapsedTime": capturedElapsedTime,
                        "startTime": capturedStartTime,
                        "methodName": methodName
                    ]
                    NotificationCenter.default.post(
                        name: Notification.Name("timerStoppedFromLiveActivity"),
                        object: nil,
                        userInfo: userInfo
                    )
                    Logger.info("📮 Posted timerStoppedFromLiveActivity notification from processWidgetAction", logger: AppLoggers.timer)
                }
            }
        default:
            Logger.warning("Unknown widget action: \(action)", logger: AppLoggers.timer)
        }
        
        // Clear the action after processing
        sharedDefaults.removeObject(forKey: "widgetTimerAction")
        sharedDefaults.removeObject(forKey: "widgetTimerType")
        sharedDefaults.removeObject(forKey: "widgetActionTime")
        sharedDefaults.removeObject(forKey: "widgetActivityId")
        sharedDefaults.synchronize()
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
        Logger.info("🔍 TimerService: Initiating Live Activity debug check...", logger: AppLoggers.liveActivity)
        Logger.info("  - Current state: \(timerState)", logger: AppLoggers.liveActivity)
        Logger.info("  - Mode: \(currentTimerMode)", logger: AppLoggers.liveActivity)
        print("  - Elapsed: \(elapsedTime)s")
        print("  - Remaining: \(remainingTime)s")
        
    }
    
    func testManualPushUpdate() {
        Logger.info("🔄 TimerService: Testing manual push update to Live Activity...", logger: AppLoggers.liveActivity)
        
        // Check if we have an active Live Activity
        guard #available(iOS 16.1, *) else {
            print("  ❌ Live Activities not available on this iOS version")
            return
        }
        
        guard LiveActivityManager.shared.hasActiveActivity else {
            Logger.warning("  ❌ No active Live Activity found", logger: AppLoggers.liveActivity)
            return
        }
        
        guard let activityId = LiveActivityManager.shared.currentActivityId else {
            Logger.error("  ❌ Could not get Live Activity ID", logger: AppLoggers.liveActivity)
            return
        }
        
        Logger.info("  ✅ Found active Live Activity: \(activityId)", logger: AppLoggers.liveActivity)
        
        // Trigger a manual push update through the Live Activity manager
        // Update the activity with current timer state
        let isPaused = timerState == .paused
        print("  📤 Sending push update with isPaused: \(isPaused)")
        
        LiveActivityManager.shared.updateTimerActivity(elapsedTime: elapsedTime, isRunning: !isPaused, isPaused: isPaused)
        
        // Also force a sync to Firestore which triggers the push
        // Activity ID is available in the closure scope
        Logger.info("  💾 Live Activity update completed for: \(activityId)", logger: AppLoggers.liveActivity)
        
        Logger.info("  ✅ Push update sent successfully", logger: AppLoggers.liveActivity)
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
        print("🎯 TimerService.startLiveActivity() called")
        
        guard let startTime = startTime else { 
            Logger.error("❌ startTime is nil, cannot start Live Activity", logger: AppLoggers.liveActivity)
            return 
        }
        
        let methodName = currentMethodName ?? "Timer"
        Logger.info("📱 Starting Live Activity for method: \(methodName)", logger: AppLoggers.liveActivity)
        let sessionType: SessionType
        let endTime: Date
        
        switch currentTimerMode {
        case .countdown:
            sessionType = .countdown
            endTime = startTime.addingTimeInterval(targetDuration)
        case .stopwatch:
            sessionType = .countdown  // Using countdown for stopwatch mode in Live Activity
            // For stopwatch, use a far future date as we don't know when it will end
            endTime = Date().addingTimeInterval(60 * 60 * 8) // 8 hours max
        case .interval:
            sessionType = .interval
            // For intervals, use the total duration
            endTime = startTime.addingTimeInterval(targetDuration)
        }
        
        // Use simplified Live Activity manager
        LiveActivityManager.shared.startTimerActivity(
            methodId: currentMethodId ?? "",
            methodName: methodName,
            startTime: startTime,
            endTime: endTime,
            duration: targetDuration,
            sessionType: sessionType,
            timerType: isQuickPracticeTimer ? "quick" : "main"
        )
        
        // Wait a bit for the activity to be fully initialized before syncing
        let workItem = DispatchWorkItem {
            // Sync timer state with external services if needed
            if let activityId = LiveActivityManager.shared.currentActivityId {
                // Update any external state syncing here if needed
                Logger.info("✅ Live Activity started with ID: \(activityId)", logger: AppLoggers.liveActivity)
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