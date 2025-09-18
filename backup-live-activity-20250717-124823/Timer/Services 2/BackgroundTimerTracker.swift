//
//  BackgroundTimerTracker.swift
//  Growth
//
//  Created by Developer on 6/5/25.
//

import Foundation
import UserNotifications
import ActivityKit

/// Manages timer state persistence and notifications when app enters background or view is dismissed
final class BackgroundTimerTracker {
    
    // MARK: - Singleton
    
    static let shared = BackgroundTimerTracker()
    
    // MARK: - Constants
    
    private struct Constants {
        static let backgroundTimerStateKey = "backgroundTimerState"
        static let quickPracticeTimerStateKey = "quickPracticeTimerState"
        static let notificationCategoryIdentifier = "TIMER_CATEGORY"
        static let pauseActionIdentifier = "PAUSE_TIMER"
        static let resumeActionIdentifier = "RESUME_TIMER"
        static let completeActionIdentifier = "COMPLETE_SESSION"
    }
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Timer State Model
    
    struct BackgroundTimerState: Codable {
        let startTime: Date
        let exitTime: Date
        let elapsedTimeAtExit: TimeInterval
        let timerMode: String // Store as String for Codable conformance
        let totalDuration: TimeInterval?
        let intervalDuration: TimeInterval?
        let currentInterval: Int?
        let methodId: String?
        let methodName: String?
        let isRunning: Bool
        
        /// Calculate total elapsed time since start, accounting for background time
        func totalElapsedTime(at date: Date = Date()) -> TimeInterval {
            let backgroundTime = date.timeIntervalSince(exitTime)
            let totalTime: TimeInterval
            
            if isRunning {
                totalTime = elapsedTimeAtExit + backgroundTime
                print("  🧮 Calculating total elapsed time (running):")
                print("    - Elapsed at exit: \(elapsedTimeAtExit)s")
                print("    - Background time: \(backgroundTime)s")
                print("    - Total: \(totalTime)s")
            } else {
                totalTime = elapsedTimeAtExit
                print("  🧮 Calculating total elapsed time (paused):")
                print("    - Using elapsed at exit: \(totalTime)s (no background time added)")
            }
            
            return totalTime
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Public Methods
    
    /// Save timer state when exiting view or entering background
    func saveTimerState(from timerService: TimerService, methodName: String? = nil, isQuickPractice: Bool = false) {
        print("🔶 [BGT-SAVE] BackgroundTimerTracker.saveTimerState() called")
        print("  - Timer state: \(timerService.state)")
        print("  - Is quick practice: \(isQuickPractice)")
        
        guard timerService.state == .running else { 
            print("  ⚠️ Timer not running, skipping save")
            return 
        }
        
        let exitTime = Date()
        let startTime = timerService.startTime ?? Date()
        
        print("  📊 Saving timer state:")
        print("    - Start time: \(startTime)")
        print("    - Exit time: \(exitTime)")
        print("    - Elapsed at exit: \(timerService.elapsedTime)s")
        print("    - Timer mode: \(timerService.timerMode.rawValue)")
        print("    - Method name: \(methodName ?? "nil")")
        
        let state = BackgroundTimerState(
            startTime: startTime,
            exitTime: exitTime,
            elapsedTimeAtExit: timerService.elapsedTime,
            timerMode: timerService.timerMode.rawValue,
            totalDuration: timerService.totalDuration,
            intervalDuration: timerService.intervalDuration,
            currentInterval: timerService.currentInterval,
            methodId: timerService.currentMethodId,
            methodName: methodName,
            isRunning: true
        )
        
        // Save state with appropriate key
        let storageKey = isQuickPractice ? Constants.quickPracticeTimerStateKey : Constants.backgroundTimerStateKey
        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: storageKey)
            print("  ✅ State saved to key: \(storageKey)")
        } else {
            print("  ❌ Failed to encode state")
        }
        
        // Schedule notifications
        scheduleTimerNotifications(for: state)
    }
    
    /// Restore timer state when returning to view
    func restoreTimerState(to timerService: TimerService, isQuickPractice: Bool = false) -> BackgroundTimerState? {
        let timestamp = Date()
        print("🔷 [BGT-RESTORE] BackgroundTimerTracker.restoreTimerState() called at \(timestamp)")
        print("  - Is quick practice: \(isQuickPractice)")
        
        let storageKey = isQuickPractice ? Constants.quickPracticeTimerStateKey : Constants.backgroundTimerStateKey
        guard let data = userDefaults.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(BackgroundTimerState.self, from: data) else {
            print("  ❌ No saved state found for key: \(storageKey)")
            return nil
        }
        
        print("  ✅ Found saved state:")
        print("    - Start time: \(state.startTime)")
        print("    - Exit time: \(state.exitTime)")
        print("    - Elapsed at exit: \(state.elapsedTimeAtExit)s")
        print("    - Was running: \(state.isRunning)")
        print("    - Timer mode: \(state.timerMode)")
        
        // Calculate time spent in background
        let timeInBackground = timestamp.timeIntervalSince(state.exitTime)
        print("  ⏱️ Time spent in background: \(timeInBackground)s")
        
        // Check if timer was paused in Live Activity before calculating elapsed time
        var totalElapsed: TimeInterval
        var shouldUseLiveActivityTime = false
        
        if #available(iOS 16.1, *) {
            // If there's a Live Activity, always prefer its time data
            if let activity = Activity<TimerActivityAttributes>.activities.first {
                let liveActivityState = activity.content.state
                print("  📱 Found Live Activity:")
                print("    - isPaused: \(liveActivityState.isPaused)")
                print("    - currentElapsedTime: \(liveActivityState.currentElapsedTime)")
                print("    - startedAt: \(liveActivityState.startedAt)")
                
                if liveActivityState.isPaused {
                    // Use the current elapsed time (calculated from pausedAt)
                    totalElapsed = liveActivityState.currentElapsedTime
                    timerService.timerState = .paused
                    shouldUseLiveActivityTime = true
                    print("  🛑 Using paused Live Activity time: \(totalElapsed)s")
                } else {
                    // Use the current elapsed time (calculated from startedAt)
                    totalElapsed = liveActivityState.currentElapsedTime
                    
                    // Check if the elapsed time is reasonable (within the last year)
                    let oneYearInSeconds: TimeInterval = 365 * 24 * 60 * 60
                    if totalElapsed > oneYearInSeconds {
                        // Elapsed time is unreasonable, use saved state instead
                        print("  ⚠️ Live Activity elapsed time is unreasonable (\(totalElapsed)s), using saved state")
                        totalElapsed = state.totalElapsedTime()
                        shouldUseLiveActivityTime = false
                    } else {
                        shouldUseLiveActivityTime = true
                        print("  🏃 Using running Live Activity time: \(totalElapsed)s")
                    }
                }
            } else {
                // No Live Activity, calculate normally
                totalElapsed = state.totalElapsedTime()
                print("  📊 No Live Activity found, calculating from saved state:")
                print("    - Elapsed at exit: \(state.elapsedTimeAtExit)s")
                print("    - Time in background: \(timeInBackground)s")
                print("    - Total elapsed: \(totalElapsed)s")
            }
        } else {
            // No Live Activity support, calculate normally
            totalElapsed = state.totalElapsedTime()
        }
        
        // For countdown timers, cap elapsed time at the target duration
        if state.timerMode == "countdown", let totalDuration = state.totalDuration {
            let cappedElapsed = min(totalElapsed, totalDuration)
            if cappedElapsed != totalElapsed {
                print("  ⚠️ Capping elapsed time for countdown: \(totalElapsed)s -> \(cappedElapsed)s")
            }
            totalElapsed = cappedElapsed
        }
        
        print("  🔄 Updating timer service:")
        print("    - Setting elapsed time to: \(totalElapsed)s")
        print("    - Setting start time to: \(state.startTime)")
        
        // Update timer service with restored state
        timerService.elapsedTime = totalElapsed
        // CRITICAL: Do NOT set startTime here when restoring from a paused state
        // The timer service will maintain the correct startTime when resuming
        if state.isRunning && !shouldUseLiveActivityTime {
            // Only set startTime if timer was running and we're not using Live Activity time
            timerService.startTime = state.startTime
        }
        timerService.currentIntervalIndex = state.currentInterval
        timerService.currentMethodId = state.methodId
        
        // Restore timer mode from saved state
        if let mode = TimerMode(rawValue: state.timerMode) {
            timerService.currentTimerMode = mode
        }
        
        // Update timer state - if it was running, mark it as paused temporarily
        // The calling code will handle resuming the timer with proper tick mechanism
        if state.isRunning {
            timerService.timerState = .paused
            print("  📌 Timer was running, setting state to paused (will be resumed by caller)")
        }
        
        // Update remaining time for countdown/interval modes
        if state.timerMode == "countdown", let totalDuration = state.totalDuration {
            timerService.targetDurationValue = totalDuration
            timerService.remainingTime = max(0, totalDuration - totalElapsed)
            print("  ⏰ Countdown timer - remaining: \(timerService.remainingTime)s")
            
            // Check if timer should have completed while in background
            // Only trigger completion if there was actual time remaining when we went to background
            // This prevents false completions due to timing precision issues
            if timerService.remainingTime == 0 && state.isRunning && (totalDuration - state.elapsedTimeAtExit) > 0.1 {
                // Timer completed while in background
                // Don't call handleTimerCompletion here - let the view handle it
                // This prevents auto-progression when returning from notification
                print("  🏁 Timer completed in background, will be handled by view")
                // Send a notification that timer completed
                scheduleImmediateCompletionNotification(methodName: state.methodName)
            }
        } else if state.timerMode == "interval", let intervalDuration = state.intervalDuration {
            // For interval timers, calculate current interval elapsed time
            let intervalElapsed = totalElapsed.truncatingRemainder(dividingBy: intervalDuration)
            timerService.remainingTime = max(0, intervalDuration - intervalElapsed)
            print("  🔄 Interval timer - interval elapsed: \(intervalElapsed)s, remaining: \(timerService.remainingTime)s")
        }
        
        // Clear saved state
        clearSavedState(isQuickPractice: isQuickPractice)
        
        // Cancel notifications since user is back
        cancelAllTimerNotifications()
        
        print("🔷 [END] BackgroundTimerTracker.restoreTimerState() completed")
        print("  - Final elapsed: \(timerService.elapsedTime)s")
        print("  - Final remaining: \(timerService.remainingTime)s")
        print("  - Final state: \(timerService.timerState)")
        
        return state
    }
    
    /// Clear saved timer state
    func clearSavedState(isQuickPractice: Bool = false) {
        let storageKey = isQuickPractice ? Constants.quickPracticeTimerStateKey : Constants.backgroundTimerStateKey
        userDefaults.removeObject(forKey: storageKey)
        cancelAllTimerNotifications()
    }
    
    /// Cancel all timer notifications (public method)
    func cancelAllTimerNotifications() {
        // Get all pending notifications
        notificationCenter.getPendingNotificationRequests { requests in
            let timerNotificationIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("timer_") || $0.hasPrefix("interval_") }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: timerNotificationIds)
            
            // Also remove delivered notifications to clear badges
            self.notificationCenter.removeDeliveredNotifications(withIdentifiers: timerNotificationIds)
        }
    }
    
    /// Check if there's a background timer running
    func hasActiveBackgroundTimer(isQuickPractice: Bool = false) -> Bool {
        let storageKey = isQuickPractice ? Constants.quickPracticeTimerStateKey : Constants.backgroundTimerStateKey
        return userDefaults.data(forKey: storageKey) != nil
    }
    
    /// Get current background timer state without clearing it
    func peekTimerState(isQuickPractice: Bool = false) -> BackgroundTimerState? {
        let storageKey = isQuickPractice ? Constants.quickPracticeTimerStateKey : Constants.backgroundTimerStateKey
        guard let data = userDefaults.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(BackgroundTimerState.self, from: data) else {
            return nil
        }
        return state
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        let pauseAction = UNNotificationAction(
            identifier: Constants.pauseActionIdentifier,
            title: "Pause",
            options: []
        )
        
        let completeAction = UNNotificationAction(
            identifier: Constants.completeActionIdentifier,
            title: "Complete Session",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: Constants.notificationCategoryIdentifier,
            actions: [pauseAction, completeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    private func scheduleTimerNotifications(for state: BackgroundTimerState) {
        // Cancel existing notifications
        cancelAllTimerNotifications()
        
        // Request notification permissions if not already granted
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else {
                print("BackgroundTimerTracker: Notifications not authorized")
                return
            }
            
            // Calculate remaining time for countdown timers
            let remainingTimeForCountdown: TimeInterval?
            if state.timerMode == "countdown", let totalDuration = state.totalDuration {
                remainingTimeForCountdown = totalDuration - state.elapsedTimeAtExit
            } else {
                remainingTimeForCountdown = nil
            }
            
            // Schedule completion notification for countdown timers
            if let remainingTime = remainingTimeForCountdown, remainingTime > 0 {
                self?.scheduleNotification(
                    identifier: "timer_countdown_complete",
                    title: "Timer Complete!",
                    body: state.methodName != nil ? "Your \(state.methodName!) timer has finished" : "Your countdown timer has finished",
                    timeInterval: remainingTime,
                    repeats: false,
                    sound: .defaultCritical
                )
            }
            
            // Only schedule reminder notifications if timer hasn't completed
            let shouldScheduleReminders = remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > 3
            
            if shouldScheduleReminders {
                // Immediate notification (3 seconds after exit)
                if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > 3 {
                    self?.scheduleNotification(
                        identifier: "timer_running_immediate",
                        title: "Timer Still Running",
                        body: state.methodName != nil ? "Your \(state.methodName!) session is still active" : "Your practice session is still active",
                        timeInterval: 3,
                        repeats: false,
                        sound: .defaultCritical
                    )
                }
                
                // Quick follow-up at 30 seconds for immediate awareness
                if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > 30 {
                    self?.scheduleNotification(
                        identifier: "timer_running_30sec",
                        title: "Timer Active",
                        body: "Your session continues in the background",
                        timeInterval: 30,
                        repeats: false
                    )
                }
                
                // Regular reminders every 2 minutes for first 10 minutes
                for i in 1...5 {
                    let minutes = i * 2
                    let notificationTime = TimeInterval(minutes * 60)
                    
                    // Only schedule if timer won't complete before this notification
                    if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > notificationTime {
                        let notificationTitle: String
                        if let totalDuration = state.totalDuration, state.timerMode == "countdown" {
                            // For countdown timers, show remaining time
                            let elapsed = state.totalElapsedTime(at: Date().addingTimeInterval(notificationTime))
                            let remaining = max(0, totalDuration - elapsed)
                            let remainingFormatted = self?.formatTime(remaining) ?? "0:00"
                            notificationTitle = "Timer \(remainingFormatted) remaining"
                        } else {
                            // For stopwatch timers, show elapsed time
                            let elapsed = state.totalElapsedTime(at: Date().addingTimeInterval(notificationTime))
                            let elapsedFormatted = self?.formatTime(elapsed) ?? "0:00"
                            notificationTitle = "Timer \(elapsedFormatted) elapsed"
                        }
                        
                        self?.scheduleNotification(
                            identifier: "timer_running_\(minutes)min",
                            title: notificationTitle,
                            body: "Tap to return to your session",
                            timeInterval: notificationTime,
                            repeats: false,
                            sound: .default
                        )
                    }
                }
            }
            
            // Then every 5 minutes for the next 50 minutes
            for i in 3...12 {
                let minutes = i * 5
                let notificationTime = TimeInterval(minutes * 60)
                
                // Only schedule if timer won't complete before this notification
                if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > notificationTime {
                    let notificationTitle: String
                    if let totalDuration = state.totalDuration, state.timerMode == "countdown" {
                        // For countdown timers, show remaining time
                        let elapsed = state.totalElapsedTime(at: Date().addingTimeInterval(notificationTime))
                        let remaining = max(0, totalDuration - elapsed)
                        let remainingFormatted = self?.formatTime(remaining) ?? "0:00"
                        notificationTitle = "Timer \(remainingFormatted) remaining"
                    } else {
                        // For stopwatch timers, show elapsed time
                        let elapsed = state.totalElapsedTime(at: Date().addingTimeInterval(notificationTime))
                        let elapsedFormatted = self?.formatTime(elapsed) ?? "0:00"
                        notificationTitle = "Timer \(elapsedFormatted) elapsed"
                    }
                    
                    self?.scheduleNotification(
                        identifier: "timer_running_\(minutes)min_long",
                        title: notificationTitle,
                        body: "Your session is still running",
                        timeInterval: notificationTime,
                        repeats: false
                    )
                }
            }
            
            // Interval notifications for interval mode
            if state.timerMode == "interval",
               let intervalDuration = state.intervalDuration {
                self?.scheduleIntervalNotifications(for: state, intervalDuration: intervalDuration)
            }
            
            // Schedule a final notification at 1 hour
            let oneHourInterval: TimeInterval = 3600
            if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > oneHourInterval {
                self?.scheduleNotification(
                    identifier: "timer_running_1hour",
                    title: "Long Session Alert",
                    body: "Your timer has been running for over an hour. Tap to check your progress.",
                    timeInterval: oneHourInterval,
                    repeats: false,
                    sound: .defaultCritical
                )
            }
        }
    }
    
    private func scheduleIntervalNotifications(for state: BackgroundTimerState, intervalDuration: TimeInterval) {
        let currentInterval = state.currentInterval ?? 1
        let elapsedInCurrentInterval = state.elapsedTimeAtExit.truncatingRemainder(dividingBy: intervalDuration)
        let timeToNextInterval = intervalDuration - elapsedInCurrentInterval
        
        // For countdown timers with intervals, check against total remaining time
        let remainingTimeForCountdown: TimeInterval?
        if state.timerMode == "countdown", let totalDuration = state.totalDuration {
            remainingTimeForCountdown = totalDuration - state.elapsedTimeAtExit
        } else {
            remainingTimeForCountdown = nil
        }
        
        // Schedule next few interval completions
        for i in 0..<5 {
            let intervalNumber = currentInterval + i + 1
            let timeInterval = timeToNextInterval + (TimeInterval(i) * intervalDuration)
            
            // Only schedule if timer won't complete before this interval
            if remainingTimeForCountdown == nil || (remainingTimeForCountdown ?? 0) > timeInterval {
                scheduleNotification(
                    identifier: "interval_\(intervalNumber)",
                    title: "Interval \(intervalNumber) Complete",
                    body: "Time to switch! Tap to continue your session.",
                    timeInterval: timeInterval,
                    repeats: false,
                    sound: .default
                )
            }
        }
    }
    
    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool,
        sound: UNNotificationSound? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Constants.notificationCategoryIdentifier
        content.sound = sound ?? .default
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        // Add thread identifier for grouping
        content.threadIdentifier = "timer_notifications"
        
        // Add user info for analytics
        content.userInfo = [
            "type": "timer_background",
            "identifier": identifier
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("BackgroundTimerTracker: Error scheduling notification '\(identifier)': \(error.localizedDescription)")
            } else {
                print("BackgroundTimerTracker: Successfully scheduled notification '\(identifier)' for \(timeInterval) seconds")
            }
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
    
    private func scheduleImmediateCompletionNotification(methodName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = methodName != nil ? "Your \(methodName!) session finished while you were away" : "Your practice session finished while you were away"
        content.categoryIdentifier = Constants.notificationCategoryIdentifier
        content.sound = .defaultCritical
        content.badge = 0 // Clear badge
        content.interruptionLevel = .timeSensitive
        
        // Add thread identifier for grouping
        content.threadIdentifier = "timer_notifications"
        
        // Add user info for analytics
        content.userInfo = [
            "type": "timer_completion",
            "completed_in_background": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.1, // Almost immediate
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer_completion_background",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("BackgroundTimerTracker: Error scheduling completion notification: \(error.localizedDescription)")
            } else {
                print("BackgroundTimerTracker: Successfully scheduled completion notification")
            }
        }
    }
}

