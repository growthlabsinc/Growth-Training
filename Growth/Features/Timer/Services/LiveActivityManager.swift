//
//  LiveActivityManager.swift
//  Growth
//
//  Built from scratch based on research from:
//  - expo-live-activity-timer architecture
//  - Apple Live Activity best practices
//  - startedAt/pausedAt pattern research
//

import Foundation
import ActivityKit
import UIKit
import FirebaseFunctions

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<TimerActivityAttributes>?
    private var currentPushToken: String?
    private var pushTokenObservationTask: Task<Void, Never>?
    private let functions = Functions.functions()
    private var frequentPushesEnabled: Bool = true
    private var frequentPushesObservationTask: Task<Void, Never>?
    private var isProcessingAction: Bool = false  // Prevent duplicate action processing
    
    private init() {
        setupNotificationObservers()
        
        // Start observing push-to-start tokens if available
        if #available(iOS 17.2, *) {
            observePushToStartTokenUpdates()
        }
        
        // Start observing frequent push updates setting
        if #available(iOS 16.2, *) {
            observeFrequentPushesSettings()
        }
    }
    
    // MARK: - Core Functionality (Based on Research)
    
    /// Check if Live Activities are available - from Apple documentation
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    /// Start a new Live Activity - must be called from foreground
    func startActivity(methodId: String, methodName: String, duration: TimeInterval = 1800, sessionType: SessionType = .countdown) {
        Logger.info("🚀 LiveActivityManager.startActivity called:", logger: AppLoggers.liveActivity)
        Logger.debug("methodId: \(methodId)", logger: AppLoggers.liveActivity)
        Logger.debug("methodName: \(methodName)", logger: AppLoggers.liveActivity)
        Logger.debug("duration: \(duration)", logger: AppLoggers.liveActivity)
        Logger.debug("sessionType: \(sessionType)", logger: AppLoggers.liveActivity)
        Logger.debug("Thread: \(Thread.current)", logger: AppLoggers.liveActivity)
        Logger.debug("areActivitiesEnabled: \(areActivitiesEnabled)", logger: AppLoggers.liveActivity)
        
        guard areActivitiesEnabled else {
            Logger.error("❌ Live Activities not enabled by user", logger: AppLoggers.liveActivity)
            Logger.error("Please go to Settings > Privacy & Security > Live Activities and enable them", logger: AppLoggers.liveActivity)
            Logger.error("Also check that Live Activities are enabled for this app specifically", logger: AppLoggers.liveActivity)
            
            // Post notification for UI to handle
            NotificationCenter.default.post(
                name: Notification.Name("LiveActivitiesNotEnabled"),
                object: nil,
                userInfo: ["reason": "User has not enabled Live Activities in Settings"]
            )
            return
        }
        
        // Check if we're at the activity limit (iOS limits activities per app)
        let activeCount = Activity<TimerActivityAttributes>.activities.count
        if activeCount >= 2 {
            Logger.warning("⚠️ Already at Live Activity limit (\(activeCount)), cleaning up old activities", logger: AppLoggers.liveActivity)
            Task {
                await cleanupAllActivities()
            }
        }
        
        Logger.info("✅ Activities are enabled, proceeding with Live Activity creation...", logger: AppLoggers.liveActivity)
        Logger.debug("Current available activities: \(Activity<TimerActivityAttributes>.activities)", logger: AppLoggers.liveActivity)
        Logger.debug("Device time: \(Date())", logger: AppLoggers.liveActivity)
        Logger.debug("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")", logger: AppLoggers.liveActivity)
        
        Task {
            do {
                Logger.debug("🔄 Ending any existing activities first...", logger: AppLoggers.liveActivity)
                // End any existing activity first
                await endCurrentActivity()
                
                // Clean up any additional stale activities
                await cleanupAllActivities()
                
                Logger.debug("🏗️ Creating TimerActivityAttributes...", logger: AppLoggers.liveActivity)
                // Create attributes and initial state - based on research pattern
                let attributes = TimerActivityAttributes(
                    methodId: methodId,
                    timerType: "main"
                )
                
                Logger.debug("🏗️ Creating initial ContentState...", logger: AppLoggers.liveActivity)
                let startTime = Date()
                let initialState = TimerActivityAttributes.ContentState(
                    startedAt: startTime,
                    pausedAt: nil,
                    duration: duration,
                    methodName: methodName,
                    sessionType: sessionType  // totalPausedDuration defaults to 0
                )
                
                Logger.info("📱 Requesting Live Activity from ActivityKit...", logger: AppLoggers.liveActivity)
                Logger.debug("Using attributes: methodId='\(attributes.methodId)', timerType='\(attributes.timerType)'", logger: AppLoggers.liveActivity)
                Logger.debug("Using initialState: startedAt=\(initialState.startedAt), duration=\(initialState.duration)s", logger: AppLoggers.liveActivity)
                Logger.debug("SessionType: \(initialState.sessionType)", logger: AppLoggers.liveActivity)
                Logger.debug("Calculated endTime: \(initialState.endTime)", logger: AppLoggers.liveActivity)
                Logger.debug("Time until end: \(initialState.endTime.timeIntervalSince(startTime))s", logger: AppLoggers.liveActivity)
                
                // Request activity with push token support
                let activity: Activity<TimerActivityAttributes>
                if #available(iOS 16.2, *) {
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        content: .init(
                            state: initialState,
                            staleDate: Date().addingTimeInterval(28800), // 8 hours - from research
                            relevanceScore: 100.0 // Highest priority when starting
                        ),
                        pushType: .token // Request push token for updates
                    )
                } else {
                    // iOS 16.1 fallback - use the basic request method without content wrapper
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        contentState: initialState,
                        pushType: .token
                    )
                }
                
                self.currentActivity = activity
                
                // Store initial state in shared UserDefaults for widget synchronization
                let appGroupIdentifier = "group.com.growthlabs.growthmethod"
                if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                    sharedDefaults.set(initialState.startedAt, forKey: "timerStartedAt")
                    sharedDefaults.set(false, forKey: "timerIsPaused")
                    sharedDefaults.removeObject(forKey: "timerPausedAt")
                    sharedDefaults.set(duration, forKey: "timerDuration")
                    sharedDefaults.set(methodName, forKey: "timerMethodName")
                    sharedDefaults.set(activity.id, forKey: "currentActivityId")
                    sharedDefaults.synchronize()
                    Logger.debug("📝 Stored initial timer state in shared UserDefaults", logger: AppLoggers.liveActivity)
                }
                
                Logger.info("✅ Live Activity started successfully!", logger: AppLoggers.liveActivity)
                Logger.debug("Activity ID: \(activity.id)", logger: AppLoggers.liveActivity)
                Logger.debug("Activity State: \(activity.activityState)", logger: AppLoggers.liveActivity)
                
                // Observe push token updates for this activity
                if #available(iOS 16.2, *) {
                    Task {
                        await self.observePushTokenUpdates(for: activity)
                    }
                    
                    // Also observe frequent pushes setting for this activity
                    Task {
                        await self.observeFrequentPushesForActivity(activity)
                    }
                }
                if #available(iOS 16.2, *) {
                    Logger.verbose("Content State startedAt: \(activity.content.state.startedAt)", logger: AppLoggers.liveActivity)
                    Logger.verbose("Content State methodName: \(activity.content.state.methodName)", logger: AppLoggers.liveActivity)
                    Logger.verbose("Content State duration: \(activity.content.state.duration)", logger: AppLoggers.liveActivity)
                    Logger.verbose("Content State sessionType: \(activity.content.state.sessionType)", logger: AppLoggers.liveActivity)
                    Logger.verbose("Content State isPaused: \(activity.content.state.isPaused)", logger: AppLoggers.liveActivity)
                } else {
                    Logger.verbose("Content State details: [iOS 16.2+ required]", logger: AppLoggers.liveActivity)
                }
                Logger.verbose("Total activities now: \(Activity<TimerActivityAttributes>.activities.count)", logger: AppLoggers.liveActivity)
                
                // Give the system time to register the activity
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                Logger.info("📱 Live Activity should now be visible on Lock Screen/Dynamic Island", logger: AppLoggers.liveActivity)
                
            } catch {
                Logger.error("Failed to start Live Activity: \(error)", logger: AppLoggers.liveActivity)
                Logger.error("Error type: \(type(of: error))", logger: AppLoggers.liveActivity)
                if let nsError = error as NSError? {
                    Logger.error("Error code: \(nsError.code)", logger: AppLoggers.liveActivity)
                    Logger.error("Error domain: \(nsError.domain)", logger: AppLoggers.liveActivity)
                    Logger.error("Error description: \(nsError.localizedDescription)", logger: AppLoggers.liveActivity)
                }
            }
        }
    }
    
    /// Pause the timer - using startedAt/pausedAt pattern from research
    @MainActor
    public func pauseTimer() async {
        Logger.info("⏸️ [LIVE_ACTIVITY_BUTTON] pauseTimer() called", logger: AppLoggers.liveActivity)
        guard let activity = currentActivity else { 
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] No current activity to pause", logger: AppLoggers.liveActivity)
            return 
        }
        
        // Pause the actual timer in the main app
        let appGroupState = AppGroupConstants.getTimerState()
        let timerType = appGroupState.sessionType == "quick" ? "quick" : "main"
        
        Logger.info("📱 Pausing \(timerType) timer in main app", logger: AppLoggers.liveActivity)
        if timerType == "quick" {
            QuickPracticeTimerService.shared.pause()
        } else {
            TimerService.shared.pause()
        }
        
        if #available(iOS 16.2, *) {
            Logger.debug("📝 [LIVE_ACTIVITY_BUTTON] Setting pausedAt to current time", logger: AppLoggers.liveActivity)
            // Based on expo-live-activity-timer pattern - just set pausedAt
            var updatedState = activity.content.state
            updatedState.pausedAt = Date()
            
            Logger.debug("🔄 [LIVE_ACTIVITY_BUTTON] Updating Live Activity with paused state", logger: AppLoggers.liveActivity)
            await updateActivity(with: updatedState)
            
            Logger.info("📤 Sending Firebase push update for pause action", logger: AppLoggers.liveActivity)
            await sendPushUpdate(for: activity, with: updatedState, action: "pause")
            
            Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer paused in Live Activity", logger: AppLoggers.liveActivity)
        } else {
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] Timer pause requires iOS 16.2+", logger: AppLoggers.liveActivity)
        }
    }
    
    /// Resume the timer - adjust startedAt to account for pause duration
    @MainActor
    public func resumeTimer() async {
        Logger.info("▶️ [LIVE_ACTIVITY_BUTTON] resumeTimer() called", logger: AppLoggers.liveActivity)
        guard let activity = currentActivity else { 
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] No current activity to resume", logger: AppLoggers.liveActivity)
            return 
        }
        
        // Resume the actual timer in the main app
        let appGroupState = AppGroupConstants.getTimerState()
        let timerType = appGroupState.sessionType == "quick" ? "quick" : "main"
        
        Logger.info("📱 Resuming \(timerType) timer in main app", logger: AppLoggers.liveActivity)
        if timerType == "quick" {
            QuickPracticeTimerService.shared.resume()
        } else {
            TimerService.shared.resume()
        }
        
        if #available(iOS 16.2, *) {
            var updatedState = activity.content.state
            
            // Adjust startedAt to account for pause duration
            // This is necessary for the timer to show correct remaining time
            if let pausedAt = updatedState.pausedAt {
                let now = Date()
                
                // Validate timestamps are within reasonable bounds (2000-2100)
                let yearFormatter = DateFormatter()
                yearFormatter.dateFormat = "yyyy"
                let startYear = Int(yearFormatter.string(from: updatedState.startedAt)) ?? 0
                let pauseYear = Int(yearFormatter.string(from: pausedAt)) ?? 0
                
                if startYear < 2000 || startYear > 2100 {
                    Logger.error("❌ Invalid startedAt year: \(startYear), date: \(updatedState.startedAt)", logger: AppLoggers.liveActivity)
                    // Reset to current time minus elapsed time from App Group
                    let appGroupState = AppGroupConstants.getTimerState()
                    updatedState.startedAt = Date().addingTimeInterval(-appGroupState.elapsedTime)
                    Logger.info("🔧 Reset startedAt to: \(updatedState.startedAt)", logger: AppLoggers.liveActivity)
                }
                
                if pauseYear < 2000 || pauseYear > 2100 {
                    Logger.error("❌ Invalid pausedAt year: \(pauseYear), date: \(pausedAt)", logger: AppLoggers.liveActivity)
                    // Use current time as pause time
                    updatedState.pausedAt = now
                    Logger.info("🔧 Reset pausedAt to: \(updatedState.pausedAt ?? now)", logger: AppLoggers.liveActivity)
                }
                
                // Recalculate with validated timestamps
                let validPausedAt = updatedState.pausedAt ?? now
                let pauseDuration = now.timeIntervalSince(validPausedAt)
                
                // Additional sanity check: pause duration should be positive and reasonable
                if pauseDuration < 0 || pauseDuration > 86400 { // More than 24 hours is unreasonable
                    Logger.error("❌ Invalid pause duration: \(pauseDuration)s", logger: AppLoggers.liveActivity)
                    Logger.info("🔧 Using App Group state for recovery", logger: AppLoggers.liveActivity)
                    
                    // Fall back to App Group state
                    let appGroupState = AppGroupConstants.getTimerState()
                    updatedState.startedAt = Date().addingTimeInterval(-appGroupState.elapsedTime)
                    updatedState.pausedAt = nil
                } else {
                    Logger.debug("📊 [LIVE_ACTIVITY_BUTTON] Pause duration: \(pauseDuration)s", logger: AppLoggers.liveActivity)
                    Logger.debug("  - Current time: \(now)", logger: AppLoggers.liveActivity)
                    Logger.debug("  - Paused at: \(validPausedAt)", logger: AppLoggers.liveActivity)
                    Logger.debug("  - Original startedAt: \(updatedState.startedAt)", logger: AppLoggers.liveActivity)
                    Logger.debug("  - Previous total paused: \(updatedState.totalPausedDuration)s", logger: AppLoggers.liveActivity)
                    
                    // CRITICAL FIX: Accumulate pause duration instead of modifying startedAt
                    // Keep startedAt constant and track total pause time
                    updatedState.totalPausedDuration += pauseDuration
                    updatedState.pausedAt = nil // Clear the pause
                    
                    Logger.debug("  - New total paused duration: \(updatedState.totalPausedDuration)s", logger: AppLoggers.liveActivity)
                    Logger.debug("  - Keeping original startedAt: \(updatedState.startedAt)", logger: AppLoggers.liveActivity)
                }
            }
            
            await updateActivity(with: updatedState)
            
            Logger.info("📤 Sending Firebase push update for resume action", logger: AppLoggers.liveActivity)
            await sendPushUpdate(for: activity, with: updatedState, action: "resume")
            
            Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer resumed in Live Activity", logger: AppLoggers.liveActivity)
        } else {
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] Timer resume requires iOS 16.2+", logger: AppLoggers.liveActivity)
        }
    }
    
    /// Pause quick timer - using startedAt/pausedAt pattern
    @MainActor
    public func pauseQuickTimer() async {
        Logger.info("⏸️ [LIVE_ACTIVITY_BUTTON] pauseQuickTimer() called", logger: AppLoggers.liveActivity)
        guard let activity = currentActivity else { 
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] No current activity to pause", logger: AppLoggers.liveActivity)
            return 
        }
        
        // Pause the quick timer
        QuickPracticeTimerService.shared.pause()
        
        if #available(iOS 16.2, *) {
            var updatedState = activity.content.state
            
            // Set pausedAt to current time
            updatedState.pausedAt = Date()
            
            Logger.info("📤 Sending push update for pause action", logger: AppLoggers.liveActivity)
            await sendPushUpdate(for: activity, with: updatedState, action: "pause")
        }
    }
    
    /// Resume quick timer - adjust startedAt to account for pause duration
    @MainActor
    public func resumeQuickTimer() async {
        Logger.info("▶️ [LIVE_ACTIVITY_BUTTON] resumeQuickTimer() called", logger: AppLoggers.liveActivity)
        guard let activity = currentActivity else { 
            Logger.warning("⚠️ [LIVE_ACTIVITY_BUTTON] No current activity to resume", logger: AppLoggers.liveActivity)
            return 
        }
        
        // Resume the quick timer
        QuickPracticeTimerService.shared.resume()
        
        if #available(iOS 16.2, *) {
            var updatedState = activity.content.state
            
            // Adjust startedAt to account for pause duration
            if let pausedAt = updatedState.pausedAt {
                let now = Date()
                
                // Validate timestamps are within reasonable bounds (2000-2100)
                let yearFormatter = DateFormatter()
                yearFormatter.dateFormat = "yyyy"
                let startYear = Int(yearFormatter.string(from: updatedState.startedAt)) ?? 0
                let pauseYear = Int(yearFormatter.string(from: pausedAt)) ?? 0
                
                if startYear < 2000 || startYear > 2100 || pauseYear < 2000 || pauseYear > 2100 {
                    Logger.error("❌ Invalid timestamps detected - startYear: \(startYear), pauseYear: \(pauseYear)", logger: AppLoggers.liveActivity)
                    // Reset using App Group state
                    let appGroupState = AppGroupConstants.getTimerState()
                    updatedState.startedAt = Date().addingTimeInterval(-appGroupState.elapsedTime)
                    updatedState.pausedAt = nil
                    Logger.info("🔧 Reset to App Group state", logger: AppLoggers.liveActivity)
                } else {
                    let pauseDuration = now.timeIntervalSince(pausedAt)
                    
                    // Sanity check pause duration
                    if pauseDuration < 0 || pauseDuration > 86400 { // More than 24 hours
                        Logger.error("❌ Invalid pause duration: \(pauseDuration) seconds", logger: AppLoggers.liveActivity)
                        // Use App Group state
                        let appGroupState = AppGroupConstants.getTimerState()
                        updatedState.startedAt = Date().addingTimeInterval(-appGroupState.elapsedTime)
                        updatedState.pausedAt = nil
                    } else {
                        Logger.info("📊 Pause duration: \(pauseDuration) seconds", logger: AppLoggers.liveActivity)
                        Logger.info("  - Previous total paused: \(updatedState.totalPausedDuration)s", logger: AppLoggers.liveActivity)
                        
                        // CRITICAL FIX: Accumulate pause duration instead of modifying startedAt
                        // Keep startedAt constant and track total pause time
                        updatedState.totalPausedDuration += pauseDuration
                        updatedState.pausedAt = nil // Clear the pause
                        
                        Logger.info("  - New total paused duration: \(updatedState.totalPausedDuration)s", logger: AppLoggers.liveActivity)
                        Logger.info("📊 Keeping original startedAt (no adjustment needed)", logger: AppLoggers.liveActivity)
                    }
                }
            }
            
            Logger.info("📤 Sending push update for resume action", logger: AppLoggers.liveActivity)
            await sendPushUpdate(for: activity, with: updatedState, action: "resume")
        }
    }
    
    /// Stop and end quick timer
    @MainActor
    public func stopQuickTimer() async {
        Logger.info("⏹️ [LIVE_ACTIVITY_BUTTON] stopQuickTimer() called", logger: AppLoggers.liveActivity)
        
        guard currentActivity != nil else {
            Logger.debug("No activity to stop, returning early", logger: AppLoggers.liveActivity)
            return
        }
        
        // Stop the quick timer
        QuickPracticeTimerService.shared.stop()
        
        // End the Live Activity
        endTimerActivity()
    }
    
    /// Update Live Activity for current timer state
    @MainActor
    public func updateActivityForCurrentTimer() async {
        guard let activity = currentActivity else {
            Logger.warning("No current activity to update", logger: AppLoggers.liveActivity)
            return
        }
        
        if #available(iOS 16.2, *) {
            // Get current timer state
            let appGroupState = AppGroupConstants.getTimerState()
            var updatedState = activity.content.state
            
            // Update state based on current timer
            if appGroupState.isPaused {
                updatedState.pausedAt = Date()
            } else {
                updatedState.pausedAt = nil
            }
            
            // Send push update via Firebase
            await sendPushUpdate(for: activity, with: updatedState, action: appGroupState.isPaused ? "pause" : "resume")
        }
    }
    
    /// Stop and end the timer - called from Live Activity button
    @MainActor
    public func stopTimer() async {
        Logger.info("⏹️ [LIVE_ACTIVITY_BUTTON] stopTimer() called", logger: AppLoggers.liveActivity)
        
        // Guard against circular calls
        guard currentActivity != nil else {
            Logger.debug("No activity to stop, returning early", logger: AppLoggers.liveActivity)
            return
        }
        
        // Get timer type before stopping
        let appGroupState = AppGroupConstants.getTimerState()
        let timerType = appGroupState.sessionType == "quick" ? "quick" : "main"
        
        // Stop the actual timer in the main app
        Logger.info("📱 Stopping \(timerType) timer in main app", logger: AppLoggers.liveActivity)
        if timerType == "quick" {
            QuickPracticeTimerService.shared.stop()
        } else {
            TimerService.shared.stop()
        }
        
        // Clear App Group state
        AppGroupConstants.clearTimerState()
        
        Logger.debug("🛑 [LIVE_ACTIVITY_BUTTON] Ending current activity", logger: AppLoggers.liveActivity)
        await endCurrentActivity()
        Logger.info("✅ [LIVE_ACTIVITY_BUTTON] Timer stopped and Live Activity ended", logger: AppLoggers.liveActivity)
    }
    // updateTimerActivity method moved to line 416 to avoid duplication
    
    // MARK: - Internal Methods (Based on Research Patterns)
    
    private func updateActivity(with state: TimerActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }
        
        if #available(iOS 16.2, *) {
            // Validate timestamps before updating
            var validatedState = state
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            
            // Check startedAt
            let startYear = Int(yearFormatter.string(from: state.startedAt)) ?? 0
            if startYear < 2000 || startYear > 2100 {
                Logger.error("❌ Invalid startedAt in updateActivity: \(state.startedAt)", logger: AppLoggers.liveActivity)
                // Use current time minus elapsed from App Group as fallback
                let appGroupState = AppGroupConstants.getTimerState()
                validatedState.startedAt = Date().addingTimeInterval(-appGroupState.elapsedTime)
                Logger.info("🔧 Reset startedAt to: \(validatedState.startedAt)", logger: AppLoggers.liveActivity)
            }
            
            // Check pausedAt if present
            if let pausedAt = state.pausedAt {
                let pauseYear = Int(yearFormatter.string(from: pausedAt)) ?? 0
                if pauseYear < 2000 || pauseYear > 2100 {
                    Logger.error("❌ Invalid pausedAt in updateActivity: \(pausedAt)", logger: AppLoggers.liveActivity)
                    validatedState.pausedAt = Date()
                    Logger.info("🔧 Reset pausedAt to: \(validatedState.pausedAt ?? Date())", logger: AppLoggers.liveActivity)
                }
            }
            
            // Update with validated state and long stale date - from research on performance
            await activity.update(ActivityContent(
                state: validatedState,
                staleDate: Date().addingTimeInterval(28800), // 8 hours
                relevanceScore: validatedState.isRunning ? 100.0 : 50.0
            ))
        } else {
            print("⚠️ Activity updates require iOS 16.2+")
        }
    }
    
    private func endCurrentActivity() async {
        guard let activity = currentActivity else {
            print("⚠️ No current activity to end")
            return
        }
        
        print("🛑 Ending Live Activity: \(activity.id)")
        
        if #available(iOS 16.2, *) {
            // Create final "completed" state using iOS 16.2+ content property
            let currentState = activity.content.state
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: currentState.startedAt,
                pausedAt: Date(), // Mark as stopped
                duration: currentState.duration,
                methodName: currentState.methodName,
                sessionType: .completed, // Use completed session type
                totalPausedDuration: currentState.totalPausedDuration
            )
            
            print("🛑 Ending activity with immediate dismissal policy")
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate // Use immediate dismissal
            )
            print("✅ Live Activity ended successfully")
        } else {
            // iOS 16.1 fallback - create basic completed state
            print("⚠️ Using iOS 16.1 fallback for activity ending")
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: Date(), // Use current time as we can't access content.state
                pausedAt: Date(), // Mark as stopped
                duration: 0, // Default duration
                methodName: "Timer", // Default name
                sessionType: .completed // Use completed session type - totalPausedDuration defaults to 0
            )
            
            // iOS 16.1 uses the basic end method without dismissalPolicy
            await activity.end(using: finalState)
        }
        
        await MainActor.run {
            self.currentActivity = nil
        }
        
        // Clear App Group state to prevent stale activity ID from persisting
        AppGroupConstants.clearTimerState()
        Logger.info("🧹 Cleared App Group timer state", logger: AppLoggers.liveActivity)
        
        print("🛑 Live Activity reference cleared")
    }
    
    /// Clean up stale activities on app launch - from research recommendations
    func cleanupStaleActivities() {
        Task {
            await cleanupAllActivities()
        }
    }
    
    /// Clean up all activities immediately
    private func cleanupAllActivities() async {
        let allActivities = Activity<TimerActivityAttributes>.activities
        // print("🧹 Cleaning up all activities (found \(allActivities.count) activities)")
        
        for activity in allActivities {
            // print("🧹 Ending activity: \(activity.id)")
            
            if #available(iOS 16.2, *) {
                let currentState = activity.content.state
                await activity.end(
                    ActivityContent(state: currentState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                // iOS 16.1 fallback - use basic end method without dismissalPolicy
                let completedState = TimerActivityAttributes.ContentState(
                    startedAt: Date(),
                    pausedAt: Date(),
                    duration: 0,
                    methodName: "Timer",
                    sessionType: .completed,
                    totalPausedDuration: 0
                )
                await activity.end(using: completedState)
            }
        }
        // print("🧹 Cleaned up \(allActivities.count) activities)")
        
        await MainActor.run {
            currentActivity = nil
        }
    }
    
    // MARK: - Widget Interaction (Based on expo-live-activity-timer pattern)
    
    private func setupNotificationObservers() {
        // Based on expo-live-activity-timer pattern using NotificationCenter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWidgetAction),
            name: Notification.Name("timerControlFromWidget"),
            object: nil
        )
        
        // Darwin notifications not needed when using LiveActivityIntent properly
        
        // Start monitoring for LiveActivityIntent actions
        startMonitoringIntentActions()
    }
    
    private func startMonitoringIntentActions() {
        // Monitor for LiveActivityIntent actions via UserDefaults
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Skip if already processing an action
            guard !self.isProcessingAction else { return }
            
            let appGroupIdentifier = "group.com.growthlabs.growthmethod"
            guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
            
            // Check if there's a pending action
            guard let actionTime = sharedDefaults.object(forKey: "lastActionTime") as? Date,
                  Date().timeIntervalSince(actionTime) < 1.0, // Process actions from last second
                  let actionRawValue = sharedDefaults.string(forKey: "lastTimerAction"),
                  let timerType = sharedDefaults.string(forKey: "lastTimerType") else {
                return
            }
            
            // Set processing flag and clear ALL action keys immediately to prevent reprocessing
            self.isProcessingAction = true
            sharedDefaults.removeObject(forKey: "lastActionTime")
            sharedDefaults.removeObject(forKey: "lastTimerAction")
            sharedDefaults.removeObject(forKey: "lastTimerType")
            sharedDefaults.synchronize()
            
            // Process the action
            Task { @MainActor in
                switch actionRawValue {
                case "pause":
                    Logger.info("⏸️ Processing pause from LiveActivityIntent", logger: AppLoggers.liveActivity)
                    if timerType == "quick" {
                        await self.pauseQuickTimer()
                    } else {
                        await self.pauseTimer()
                    }
                    
                case "resume":
                    Logger.info("▶️ Processing resume from LiveActivityIntent", logger: AppLoggers.liveActivity)
                    if timerType == "quick" {
                        await self.resumeQuickTimer()
                    } else {
                        await self.resumeTimer()
                    }
                    
                case "stop":
                    Logger.info("⏹️ Processing stop from LiveActivityIntent", logger: AppLoggers.liveActivity)
                    if timerType == "quick" {
                        await self.stopQuickTimer()
                    } else {
                        await self.stopTimer()
                    }
                    
                default:
                    Logger.warning("Unknown action: \(actionRawValue)", logger: AppLoggers.liveActivity)
                }
                
                // Reset processing flag after action is complete
                self.isProcessingAction = false
            }
        }
    }
    
    private func setupDarwinNotificationObservers() {
        // Register for Darwin notifications from widget extension
        // Using push notifications for all environments for consistency
        
        let pushUpdateNotification = "com.growthlabs.growthmethod.liveactivity.push.update" as CFString
        
        // Observer for push notification updates
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, name, _, _ in
                guard let name = name else { return }
                
                if name.rawValue as String == "com.growthlabs.growthmethod.liveactivity.push.update" {
                    Logger.info("🔔 Received Darwin notification - Push update requested", logger: AppLoggers.liveActivity)
                    
                    // Handle the update on main thread
                    DispatchQueue.main.async {
                        Task {
                            if #available(iOS 16.2, *) {
                                await LiveActivityManager.shared.handlePushUpdateRequest()
                            } else {
                                Logger.warning("Push updates require iOS 16.2+", logger: AppLoggers.liveActivity)
                            }
                        }
                    }
                }
            },
            pushUpdateNotification,
            nil,
            .deliverImmediately
        )
        
        Logger.info("✅ Darwin notification observers registered", logger: AppLoggers.liveActivity)
    }
    
    @objc private func handleWidgetAction(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? String else { return }
        
        Task { @MainActor in
            switch action {
            case "pause":
                await pauseTimer()
            case "resume":
                await resumeTimer()
            case "stop":
                await stopTimer()
            default:
                break
            }
        }
    }
    
    // MARK: - Push-based Live Activity Updates
    
    /// Handle Live Activity update request via push notifications
    /// Simplified based on expo-live-activity-timer best practices
    @available(iOS 16.2, *)
    func handlePushUpdateRequest() async {
        Logger.info("🚀 Handling push update request", logger: AppLoggers.liveActivity)
        
        // Read the action from shared UserDefaults
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let actionRawValue = sharedDefaults.string(forKey: "lastTimerAction"),
              let activityId = sharedDefaults.string(forKey: "lastActivityId") else {
            Logger.error("Could not read action from shared defaults", logger: AppLoggers.liveActivity)
            return
        }
        
        let timerType = sharedDefaults.string(forKey: "lastTimerType") ?? "main"
        Logger.debug("🎯 Processing action: \(actionRawValue) for timer: \(timerType)", logger: AppLoggers.liveActivity)
        
        // Find the Live Activity to update
        guard let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            Logger.error("❌ Could not find activity with ID: \(activityId)", logger: AppLoggers.liveActivity)
            return
        }
        
        let currentState = activity.content.state
        
        // Update the actual timer service based on action
        await MainActor.run {
            switch actionRawValue {
            case "pause":
                Logger.info("⏸️ Processing pause action", logger: AppLoggers.liveActivity)
                if timerType == "quick" {
                    QuickPracticeTimerService.shared.timerService.pause()
                } else {
                    TimerService.shared.pause()
                }
                
            case "resume":  
                Logger.info("▶️ Processing resume action", logger: AppLoggers.liveActivity)
                if timerType == "quick" {
                    QuickPracticeTimerService.shared.timerService.resume()
                } else {
                    TimerService.shared.resume()
                }
                
            case "stop":
                Logger.info("⏹️ Processing stop action", logger: AppLoggers.liveActivity)
                if timerType == "quick" {
                    QuickPracticeTimerService.shared.timerService.stop()
                } else {
                    TimerService.shared.stop()
                }
                
            default:
                Logger.warning("Unknown action: \(actionRawValue)", logger: AppLoggers.liveActivity)
            }
        }
        
        // Prepare updated state for Live Activity
        var updatedState = currentState
        
        // Now update Live Activity state
        switch actionRawValue {
        case "pause":
            Logger.info("⏸️ Preparing pause state for push update", logger: AppLoggers.liveActivity)
            let pauseTime = Date()
            updatedState.pausedAt = pauseTime
            
            // Log pause timing details
            let elapsedSincStart = pauseTime.timeIntervalSince(currentState.startedAt)
            let remainingTime = currentState.duration - elapsedSincStart
            Logger.debug("📊 Pause timing:", logger: AppLoggers.liveActivity)
            Logger.debug("  - Pause time: \(pauseTime)", logger: AppLoggers.liveActivity)
            Logger.debug("  - Elapsed since start: \(elapsedSincStart)s", logger: AppLoggers.liveActivity)
            Logger.debug("  - Remaining time: \(remainingTime)s", logger: AppLoggers.liveActivity)
            Logger.debug("  - Original startedAt: \(currentState.startedAt)", logger: AppLoggers.liveActivity)
            Logger.debug("  - Original duration: \(currentState.duration)s", logger: AppLoggers.liveActivity)
            
        case "resume":
            Logger.info("▶️ Preparing resume state for push update", logger: AppLoggers.liveActivity)
            
            // When resuming, we need to adjust startedAt to account for the pause duration
            // This ensures the countdown timer shows the correct remaining time
            if let pausedAt = currentState.pausedAt {
                let now = Date()
                let pauseDuration = now.timeIntervalSince(pausedAt)
                
                // Calculate adjusted start time
                let calculatedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
                
                // Apply the calculated adjustment
                let adjustedStartTime = calculatedStartTime
                
                // Create completely new state with adjusted time
                updatedState = TimerActivityAttributes.ContentState(
                    startedAt: adjustedStartTime,
                    pausedAt: nil,
                    duration: currentState.duration,
                    methodName: currentState.methodName,
                    sessionType: currentState.sessionType
                )
                // Update the total paused duration
                updatedState.totalPausedDuration = (currentState.totalPausedDuration ) + pauseDuration
                
                Logger.debug("📊 Resume timing - Pause duration: \(pauseDuration)s", logger: AppLoggers.liveActivity)
                print("🔍 [PUSH_UPDATE_RESUME] Adjusting timer for resume:")
                print("  - Original startedAt: \(currentState.startedAt)")
                print("  - Pause duration: \(pauseDuration)s")
                print("  - Adjusted startedAt: \(adjustedStartTime)")
                print("  - This shifts the timer forward by \(pauseDuration)s")
            } else {
                updatedState.pausedAt = nil
            }
            
        case "stop":
            Logger.info("⏹️ Preparing stop state for push update", logger: AppLoggers.liveActivity)
            updatedState.pausedAt = Date()
            updatedState.sessionType = .completed
            
        default:
            Logger.warning("Unknown action: \(actionRawValue)", logger: AppLoggers.liveActivity)
            return
        }
        
        // Per Apple's best practices: Use ONLY push notifications for Live Activity updates
        // DO NOT update locally - this causes conflicts and race conditions
        // The TimerControlIntent already notified us via Darwin notification
        // Now we send push notification for the actual Live Activity update
        Logger.info("📤 Sending push notification for Live Activity update", logger: AppLoggers.liveActivity)
        await sendPushUpdate(for: activity, with: updatedState, action: actionRawValue)
        
        // If stopping, clean up local reference
        if actionRawValue == "stop" {
            await MainActor.run {
                self.currentActivity = nil
            }
        }
    }
    
    /// Send push update for current activity without local update (used when widget already updated locally)
    @available(iOS 16.2, *)
    func sendPushUpdateForCurrentActivity(action: String) async {
        guard let activity = currentActivity else {
            Logger.warning("No current activity to send push update for", logger: AppLoggers.liveActivity)
            return
        }
        
        // Get current state and prepare updated state based on action
        var updatedState = activity.content.state
        
        switch action {
        case "pause":
            updatedState.pausedAt = Date()
        case "resume":
            // For countdown timers, adjust startedAt
            if activity.content.state.sessionType == .countdown,
               let pausedAt = activity.content.state.pausedAt {
                let now = Date()
                let pauseDuration = now.timeIntervalSince(pausedAt)
                let calculatedStartTime = activity.content.state.startedAt.addingTimeInterval(pauseDuration)
                
                // Apply the calculated adjustment
                updatedState.startedAt = calculatedStartTime
            }
            updatedState.pausedAt = nil
        case "stop":
            updatedState.pausedAt = Date()
            updatedState.sessionType = .completed
        default:
            Logger.warning("Unknown action for push update: \(action)", logger: AppLoggers.liveActivity)
            return
        }
        
        // Send push update only (no local update since widget already did it)
        await sendPushUpdate(for: activity, with: updatedState, action: action)
    }
    
    /// Send push update via Firebase Functions
    @available(iOS 16.2, *)
    private func sendPushUpdate(for activity: Activity<TimerActivityAttributes>, with state: TimerActivityAttributes.ContentState, action: String) async {
        Logger.info("📤 Sending push update via Firebase", logger: AppLoggers.liveActivity)
        
        // Prepare content state data for Firebase function
        // Using the correct startedAt/pausedAt pattern from expo-live-activity-timer
        var contentStateData: [String: Any] = [
            "startedAt": ISO8601DateFormatter().string(from: state.startedAt),
            "duration": state.duration,
            "methodName": state.methodName,
            "sessionType": state.sessionType.rawValue
        ]
        
        // Only include pausedAt if the timer is actually paused
        if let pausedAt = state.pausedAt {
            contentStateData["pausedAt"] = ISO8601DateFormatter().string(from: pausedAt)
        }
        
        // IMPORTANT: Do NOT include event in contentStateData - it should be at the top level only
        // The event field goes in the main data object, not in contentState
        
        // Fetch the push token from multiple sources if not available in memory
        var tokenToUse = currentPushToken
        if tokenToUse == nil {
            Logger.warning("⚠️ Push token not in memory, checking UserDefaults", logger: AppLoggers.liveActivity)
            
            // Try to get from UserDefaults first (faster)
            let appGroupIdentifier = "group.com.growthlabs.growthmethod"
            if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
               let storedToken = sharedDefaults.string(forKey: "liveActivityPushToken_\(activity.id)") {
                tokenToUse = storedToken
                Logger.info("✅ Retrieved push token from UserDefaults", logger: AppLoggers.liveActivity)
                // Update local cache
                self.currentPushToken = storedToken
            } else {
                // Fall back to Firebase if not in UserDefaults
                Logger.warning("⚠️ Push token not in UserDefaults, fetching from Firebase", logger: AppLoggers.liveActivity)
                tokenToUse = await fetchPushTokenFromFirebase(activityId: activity.id)
            }
        }
        
        let data: [String: Any] = [
            "activityId": activity.id,
            "contentState": contentStateData,
            "action": action,
            "event": action == "stop" ? "end" : "update",  // Event goes here, not in contentState
            "pushToken": tokenToUse as Any,
            "frequentPushesEnabled": self.frequentPushesEnabled  // Include setting for server-side priority adjustment
        ]
        
        do {
            Logger.debug("Calling updateLiveActivity Firebase function", logger: AppLoggers.liveActivity)
            Logger.debug("Content state fields: \(contentStateData.keys.joined(separator: ", "))", logger: AppLoggers.liveActivity)
            _ = try await functions.httpsCallable("updateLiveActivity").call(data)
            Logger.info("✅ Push update sent successfully", logger: AppLoggers.liveActivity)
        } catch {
            Logger.error("Failed to send push update: \(error)", logger: AppLoggers.liveActivity)
            
            // Per Apple's best practices: DO NOT fallback to local updates
            // Local updates conflict with push notifications and cause race conditions
            // The user will need to tap the Live Activity to see the latest state
            Logger.warning("Push update failed - Live Activity may show stale data until user interacts", logger: AppLoggers.liveActivity)
        }
    }
    
    // MARK: - State Properties
    
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
    
    var currentActivityId: String? {
        return currentActivity?.id
    }
    
    /// Public accessor for current activity's timer type
    var currentActivityTimerType: String? {
        guard #available(iOS 16.1, *) else { return nil }
        return currentActivity?.attributes.timerType
    }
    
    /// Check if a specific activity ID matches the current activity
    func isCurrentActivity(id: String) -> Bool {
        return currentActivity?.id == id
    }
    
    /// Check if frequent push updates are enabled by the user
    @available(iOS 16.2, *)
    var isFrequentPushesEnabled: Bool {
        // Return the stored value
        // The actual check would require ActivityAuthorizationInfo API
        // which may not be available in current SDK
        return self.frequentPushesEnabled
    }
    
    /// Show alert to prompt user to enable frequent pushes if disabled
    @available(iOS 16.2, *)
    func promptForFrequentPushesIfNeeded() {
        // Check using ActivityAuthorizationInfo if available
        guard !self.frequentPushesEnabled else { return }
        
        Logger.warning("⚠️ Frequent pushes may be disabled", logger: AppLoggers.liveActivity)
        
        // This should be shown in the UI
        NotificationCenter.default.post(
            name: Notification.Name("ShowFrequentPushesAlert"),
            object: nil,
            userInfo: ["message": "Enable frequent Live Activity updates in Settings for the best timer experience"]
        )
    }
    
    // MARK: - Push Token Management
    
    /// Observe push token updates for a Live Activity
    @available(iOS 16.2, *)
    private func observePushTokenUpdates(for activity: Activity<TimerActivityAttributes>) async {
        // Only cancel if we have a different activity
        if let existingTask = pushTokenObservationTask,
           currentActivity?.id != activity.id {
            existingTask.cancel()
            Logger.debug("Cancelled previous token observation task", logger: AppLoggers.liveActivity)
        }
        
        // Start new observation
        pushTokenObservationTask = Task {
            for await pushToken in activity.pushTokenUpdates {
                let tokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
                
                await MainActor.run {
                    self.currentPushToken = tokenString
                }
                
                Logger.info("📱 New Live Activity push token received", logger: AppLoggers.liveActivity)
                Logger.debug("Token: \(tokenString)", logger: AppLoggers.liveActivity)
                Logger.debug("Activity ID: \(activity.id)", logger: AppLoggers.liveActivity)
                
                // Send token to Firebase with activity ID for better tracking
                await self.syncPushTokenWithFirebase(
                    token: tokenString,
                    activityId: activity.id
                )
                
                // Store token in UserDefaults as backup
                let appGroupIdentifier = "group.com.growthlabs.growthmethod"
                if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                    sharedDefaults.set(tokenString, forKey: "liveActivityPushToken_\(activity.id)")
                    sharedDefaults.synchronize()
                    Logger.debug("Stored push token in UserDefaults for backup", logger: AppLoggers.liveActivity)
                }
            }
        }
    }
    
    /// Observe push-to-start token updates
    @available(iOS 17.2, *)
    private func observePushToStartTokenUpdates() {
        Task {
            for await pushToken in Activity<TimerActivityAttributes>.pushToStartTokenUpdates {
                let tokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
                
                Logger.info("🚀 New push-to-start token received", logger: AppLoggers.liveActivity)
                Logger.debug("Token: \(tokenString)", logger: AppLoggers.liveActivity)
                
                // Send push-to-start token to Firebase
                await self.syncPushToStartTokenWithFirebase(token: tokenString)
            }
        }
    }
    
    /// Observe frequent push updates setting changes
    @available(iOS 16.2, *)
    private func observeFrequentPushesSettings() {
        // Default to enabled
        // The NSSupportsLiveActivitiesFrequentUpdates Info.plist key handles the actual behavior
        self.frequentPushesEnabled = true
        Logger.info("📱 Frequent pushes enabled via Info.plist configuration", logger: AppLoggers.liveActivity)
        
        // Store in UserDefaults for quick access
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            sharedDefaults.set(self.frequentPushesEnabled, forKey: "frequentPushesEnabled")
            sharedDefaults.synchronize()
        }
        
        // Note: The frequentPushesEnabled and frequentPushEnablementUpdates APIs
        // require ActivityAuthorizationInfo which may not be available in current SDK
        // The Info.plist key NSSupportsLiveActivitiesFrequentUpdates is sufficient
    }
    
    /// Observe frequent pushes setting for a specific activity
    @available(iOS 16.2, *)
    private func observeFrequentPushesForActivity(_ activity: Activity<TimerActivityAttributes>) async {
        // For now, we assume frequent pushes are enabled when the Info.plist key is set
        // The actual runtime API would require ActivityAuthorizationInfo
        self.frequentPushesEnabled = true
        Logger.info("📱 Frequent pushes assumed enabled for activity", logger: AppLoggers.liveActivity)
        
        // Store in UserDefaults for consistency
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            sharedDefaults.set(true, forKey: "frequentPushesEnabled")
            sharedDefaults.synchronize()
        }
        
        // Note: When ActivityAuthorizationInfo becomes available:
        // - Check activity.authorizationInfo?.frequentPushesEnabled
        // - Observe activity.authorizationInfo?.frequentPushEnablementUpdates
    }
    
    /// Sync frequent pushes setting with Firebase
    @available(iOS 16.2, *)
    private func syncFrequentPushesSettingWithFirebase(enabled: Bool) async {
        do {
            let data: [String: Any] = [
                "frequentPushesEnabled": enabled,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            _ = try await functions.httpsCallable("updateFrequentPushesSettings").call(data)
            
            Logger.info("✅ Frequent pushes setting synced with Firebase", logger: AppLoggers.liveActivity)
        } catch {
            Logger.error("❌ Failed to sync frequent pushes setting: \(error)", logger: AppLoggers.liveActivity)
        }
    }
    
    /// Sync push token with Firebase for Live Activity updates
    @available(iOS 16.2, *)
    private func syncPushTokenWithFirebase(token: String, activityId: String) async {
        do {
            let data: [String: Any] = [
                "token": token,
                "activityId": activityId,
                "platform": "ios",
                "timestamp": Date().timeIntervalSince1970,
                "environment": getCurrentAPNSEnvironment()
            ]
            
            _ = try await functions.httpsCallable("registerLiveActivityPushToken").call(data)
            
            Logger.info("✅ Push token synced with Firebase", logger: AppLoggers.liveActivity)
        } catch {
            Logger.error("❌ Failed to sync push token: \(error)", logger: AppLoggers.liveActivity)
        }
    }
    
    /// Fetch push token from Firebase when not available in memory
    @available(iOS 16.2, *)
    private func fetchPushTokenFromFirebase(activityId: String) async -> String? {
        do {
            let data: [String: Any] = [
                "activityId": activityId
            ]
            
            let result = try await functions.httpsCallable("getLiveActivityPushToken").call(data)
            if let resultData = result.data as? [String: Any],
               let token = resultData["token"] as? String {
                Logger.info("✅ Retrieved push token from Firebase", logger: AppLoggers.liveActivity)
                // Update local cache
                await MainActor.run {
                    self.currentPushToken = token
                }
                return token
            }
        } catch {
            Logger.error("❌ Failed to fetch push token from Firebase: \(error)", logger: AppLoggers.liveActivity)
        }
        return nil
    }
    
    /// Sync push-to-start token with Firebase
    @available(iOS 17.2, *)
    private func syncPushToStartTokenWithFirebase(token: String) async {
        do {
            let data: [String: Any] = [
                "token": token,
                "isPushToStart": true,
                "platform": "ios",
                "timestamp": Date().timeIntervalSince1970,
                "environment": getCurrentAPNSEnvironment()
            ]
            
            _ = try await functions.httpsCallable("registerPushToStartToken").call(data)
            
            Logger.info("✅ Push-to-start token synced with Firebase", logger: AppLoggers.liveActivity)
        } catch {
            Logger.error("❌ Failed to sync push-to-start token: \(error)", logger: AppLoggers.liveActivity)
        }
    }
    
    /// Determine current APNS environment based on build configuration
    private func getCurrentAPNSEnvironment() -> String {
        #if DEBUG
        return "development"
        #else
        // Check if it's a TestFlight build
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return "sandbox"
        } else {
            return "production"
        }
        #endif
    }
    
    // MARK: - Compatibility Methods (for existing TimerService integration)
    
    /// Compatibility method for TimerService integration
    func startTimerActivity(
        methodId: String,
        methodName: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        sessionType: SessionType,
        timerType: String
    ) {
        print("🚀 LiveActivityManager.startTimerActivity called:")
        print("  - methodId: '\(methodId)'")
        print("  - methodName: '\(methodName)'")
        print("  - startTime: \(startTime)")
        print("  - endTime: \(endTime)")
        print("  - duration: \(duration)")
        print("  - sessionType: \(sessionType)")
        print("  - timerType: '\(timerType)'")
        print("  - Thread: \(Thread.current)")
        print("  - App State: \(UIApplication.shared.applicationState.rawValue)")
        
        // Check prerequisite conditions
        print("🔍 Pre-flight checks:")
        print("  - areActivitiesEnabled: \(areActivitiesEnabled)")
        print("  - Current activities count: \(Activity<TimerActivityAttributes>.activities.count)")
        
        // Use our simplified startActivity method based on research
        // Default to countdown
        let timerSessionType: SessionType = .countdown
        print("📱 Delegating to startActivity with sessionType: \(timerSessionType)")
        startActivity(methodId: methodId, methodName: methodName, duration: duration, sessionType: timerSessionType)
    }
    
    /// Compatibility method for TimerService integration
    func updateTimerActivity(elapsedTime: TimeInterval, isRunning: Bool, isPaused: Bool) {
        guard let activity = currentActivity else { 
            Logger.error("❌ No current activity to update", logger: AppLoggers.liveActivity)
            return 
        }
        
        // Use high priority task for immediate updates
        Task(priority: .high) {
            if #available(iOS 16.2, *) {
                // Log current state for debugging
                print("🔍 [LIVE_ACTIVITY_UPDATE] Called with:")
                print("  - elapsedTime: \(elapsedTime)s")
                print("  - isRunning: \(isRunning)")
                print("  - isPaused: \(isPaused)")
                print("  - Current startedAt: \(activity.content.state.startedAt)")
                print("  - Current pausedAt: \(String(describing: activity.content.state.pausedAt))")
                print("  - Current duration: \(activity.content.state.duration)s")
                
                let currentState = activity.content.state
                let currentlyPaused = currentState.pausedAt != nil
                
                var updatedState = currentState
                var needsUpdate = false
                
                // Handle state transitions
                if isPaused && !currentlyPaused {
                    // Timer just got paused - set pausedAt
                    let pauseTime = Date()
                    updatedState.pausedAt = pauseTime
                    needsUpdate = true
                    
                    // Calculate and log timing details
                    let elapsedSinceStart = pauseTime.timeIntervalSince(currentState.startedAt)
                    let remainingTime = currentState.duration - elapsedSinceStart
                    
                    Logger.info("⏸️ Setting pausedAt to pause Live Activity", logger: AppLoggers.liveActivity)
                    print("🔍 [PAUSE] Live Activity pause details:")
                    print("  - Pause time: \(pauseTime)")
                    print("  - Elapsed since start: \(elapsedSinceStart)s")
                    print("  - Remaining time: \(remainingTime)s")
                    print("  - Will show in widget: \(Int(remainingTime/60)):\(String(format: "%02d", Int(remainingTime) % 60))")
                    
                } else if isRunning && currentlyPaused {
                    // Timer just got resumed - need to adjust for pause duration
                    if let pausedAt = currentState.pausedAt {
                        let now = Date()
                        let pauseDuration = now.timeIntervalSince(pausedAt)
                        let actualElapsed = elapsedTime // From TimerService
                        
                        // Adjust startedAt to account for the pause duration
                        // This ensures the countdown timer shows the correct remaining time
                        let calculatedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
                        // Apply the calculated adjustment
                        let adjustedStartTime = calculatedStartTime
                        
                        updatedState = TimerActivityAttributes.ContentState(
                            startedAt: adjustedStartTime,
                            pausedAt: nil,
                            duration: currentState.duration,
                            methodName: currentState.methodName,
                            sessionType: currentState.sessionType
                        )
                        // Preserve the total paused duration
                        updatedState.totalPausedDuration = currentState.totalPausedDuration
                        needsUpdate = true
                        
                        Logger.info("▶️ Resuming Live Activity with adjusted time", logger: AppLoggers.liveActivity)
                        print("🔍 [RESUME] Live Activity resume details:")
                        print("  - Resume time: \(Date())")
                        print("  - Pause duration: \(pauseDuration)s")
                        print("  - Original startedAt: \(currentState.startedAt)")
                        print("  - Adjusted startedAt: \(adjustedStartTime)")
                        print("  - Actual elapsed (from timer): \(actualElapsed)s")
                        print("  - Remaining time: \(currentState.duration - actualElapsed)s")
                    } else {
                        updatedState.pausedAt = nil
                        needsUpdate = true
                    }
                } else if isRunning && !currentlyPaused {
                    // Timer is running - sync elapsed time if needed
                    let currentElapsed = Date().timeIntervalSince(currentState.startedAt)
                    let difference = abs(currentElapsed - elapsedTime)
                    
                    // Only update if there's a significant difference (>1 second)
                    if difference > 1.0 {
                        let newStartedAt = Date().addingTimeInterval(-elapsedTime)
                        updatedState = TimerActivityAttributes.ContentState(
                            startedAt: newStartedAt,
                            pausedAt: nil,
                            duration: currentState.duration,
                            methodName: currentState.methodName,
                            sessionType: currentState.sessionType
                        )
                        // Preserve the total paused duration
                        updatedState.totalPausedDuration = currentState.totalPausedDuration
                        needsUpdate = true
                        Logger.debug("📱 Syncing Live Activity with elapsed time difference: \(difference)s", logger: AppLoggers.liveActivity)
                    }
                } else if isPaused && currentlyPaused {
                    // Already paused - skip update to avoid interfering with paused display
                    Logger.debug("⏸️ Skipping update - Live Activity already paused", logger: AppLoggers.liveActivity)
                    return
                }
                
                // Only update if state actually changed
                if needsUpdate {
                    await activity.update(ActivityContent(
                        state: updatedState,
                        staleDate: Date().addingTimeInterval(3600), // 1 hour
                        relevanceScore: isRunning ? 100.0 : 50.0
                    ))
                    Logger.info("✅ Live Activity updated successfully", logger: AppLoggers.liveActivity)
                }
            } else {
                Logger.warning("⚠️ Activity state checking requires iOS 16.2+", logger: AppLoggers.liveActivity)
            }
        }
    }
    
    /// Compatibility method for TimerService integration
    /// This is called FROM TimerService.stop(), so we only end the activity, not stop the timer
    func endTimerActivity() {
        // Don't call stopTimer() here as that would create a circular dependency
        // Just end the Live Activity directly
        Task {
            await endCurrentActivity()
        }
    }
    
    // MARK: - Debug Methods
    
    /// Test method to verify Live Activity system works independently
    func testLiveActivitySystem() {
        print("🧪 Testing Live Activity System...")
        print("🧪 iOS Version: \(UIDevice.current.systemVersion)")
        print("🧪 areActivitiesEnabled: \(areActivitiesEnabled)")
        
        guard areActivitiesEnabled else {
            print("❌ Live Activities are not enabled. Cannot test.")
            print("❌ Go to Settings > Privacy & Security > Live Activities")
            return
        }
        
        // Test starting a simple Live Activity
        print("🧪 Attempting to start test Live Activity...")
        startActivity(
            methodId: "test-\(UUID().uuidString.prefix(8))",
            methodName: "Test Timer",
            duration: 300, // 5 minutes
            sessionType: .countdown
        )
    }
    
    /// Debug method to print current Live Activity state
    func debugPrintCurrentState() {
        print("🔍 LiveActivityManager Debug State:")
        print("  - areActivitiesEnabled: \(areActivitiesEnabled)")
        print("  - hasActiveActivity: \(hasActiveActivity)")
        print("  - currentActivityId: \(currentActivityId ?? "none")")
        
        if let activity = currentActivity {
            print("  - Activity State: \(activity.activityState)")
            if #available(iOS 16.2, *) {
                print("  - Content State: \(activity.content.state)")
            } else {
                print("  - Content State: [iOS 16.2+ required]")
            }
            print("  - Attributes: methodId=\(activity.attributes.methodId), timerType=\(activity.attributes.timerType)")
        } else {
            print("  - No active Live Activity")
        }
        
        if #available(iOS 16.2, *) {
            let allActivities = Activity<TimerActivityAttributes>.activities
            print("  - Total activities: \(allActivities.count)")
            for (index, activity) in allActivities.enumerated() {
                print("    Activity \(index): \(activity.id) - \(activity.activityState)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}