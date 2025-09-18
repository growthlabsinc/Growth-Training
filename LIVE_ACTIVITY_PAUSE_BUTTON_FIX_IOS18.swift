// Complete fix for iOS 18+ Live Activity pause button issue
// The problem: Pause action is received but Live Activity UI doesn't update

// STEP 1: Update TimerControlIntent to force immediate UI update
// In GrowthTimerWidget/AppIntents/TimerControlIntent.swift, modify performTimerAction:

@available(iOS 16.0, *)
func performTimerAction(action: TimerAction, activityId: String, timerType: String) async throws -> some IntentResult & ProvidesDialog {
    print("🔵 TimerControlIntent: Performing action \(action.rawValue) for activity \(activityId)")
    
    // Store action for the main app
    let fileSuccess = AppGroupFileManager.shared.writeTimerAction(action.rawValue, activityId: activityId, timerType: timerType)
    
    if fileSuccess {
        print("✅ TimerControlIntent: Successfully wrote action to file")
    } else {
        print("❌ TimerControlIntent: Failed to write action to file")
        // Try UserDefaults as fallback
        if let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            sharedDefaults.set(action.rawValue, forKey: "lastTimerAction")
            sharedDefaults.set(Date(), forKey: "lastActionTime")
            sharedDefaults.set(activityId, forKey: "lastActivityId")
            sharedDefaults.set(timerType, forKey: "lastTimerType")
            sharedDefaults.synchronize()
            print("🔵 TimerControlIntent: Fallback to UserDefaults")
        }
    }
    
    // NEW: Update App Group state immediately for pause/resume
    if action == .pause || action == .resume {
        if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            defaults.set(action == .pause, forKey: "timerPausedViaLiveActivity")
            if action == .pause {
                defaults.set(Date(), forKey: "timerPauseTime")
            } else {
                defaults.removeObject(forKey: "timerPauseTime")
            }
            defaults.synchronize()
        }
    }
    
    // Post Darwin notification with timer type suffix
    let timerTypeSuffix = timerType == "quick" ? ".quick" : ".main"
    let notificationName: CFString
    switch action {
    case .stop:
        notificationName = "com.growthlabs.growthmethod.liveactivity\(timerTypeSuffix).stop" as CFString
    case .pause:
        notificationName = "com.growthlabs.growthmethod.liveactivity\(timerTypeSuffix).pause" as CFString
    case .resume:
        notificationName = "com.growthlabs.growthmethod.liveactivity\(timerTypeSuffix).resume" as CFString
    }
    
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(notificationName),
        nil,
        nil,
        true
    )
    
    print("🔵 TimerControlIntent: Posted Darwin notification: \(notificationName as String)")
    
    // NEW: For iOS 17+, try to update the Live Activity content immediately
    if #available(iOS 17.0, *) {
        // Find the current activity and update its content
        if let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) {
            let currentState = activity.content.state
            
            // Create updated state based on action
            let updatedState: TimerActivityAttributes.ContentState
            
            switch action {
            case .pause:
                updatedState = TimerActivityAttributes.ContentState(
                    startedAt: currentState.startedAt,
                    pausedAt: Date(),
                    duration: currentState.duration,
                    methodName: currentState.methodName,
                    sessionType: currentState.sessionType,
                    isCompleted: false,
                    completionMessage: nil
                )
            case .resume:
                updatedState = TimerActivityAttributes.ContentState(
                    startedAt: currentState.startedAt,
                    pausedAt: nil,
                    duration: currentState.duration,
                    methodName: currentState.methodName,
                    sessionType: currentState.sessionType,
                    isCompleted: false,
                    completionMessage: nil
                )
            case .stop:
                updatedState = TimerActivityAttributes.ContentState(
                    startedAt: currentState.startedAt,
                    pausedAt: currentState.pausedAt,
                    duration: currentState.duration,
                    methodName: currentState.methodName,
                    sessionType: currentState.sessionType,
                    isCompleted: true,
                    completionMessage: "Session Complete!"
                )
            }
            
            // Update the activity immediately
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(60)
                )
            )
            
            print("🔵 TimerControlIntent: Updated Live Activity content immediately")
        }
    }
    
    return .result(dialog: IntentDialog(""))
}

// STEP 2: Ensure the main app processes the action and updates Live Activity
// Add this to TimerService.swift where Darwin notifications are handled:

@MainActor
private func handleDarwinNotification(name: CFNotificationName?) async {
    guard let name = name else { return }
    let nameString = name.rawValue as String
    
    Logger.info("🔔 TimerService: Received Darwin notification: \(nameString)")
    
    // Extract action from notification name
    let action: String
    if nameString.contains(".pause") {
        action = "pause"
    } else if nameString.contains(".resume") {
        action = "resume"
    } else if nameString.contains(".stop") {
        action = "stop"
    } else {
        Logger.info("  - Unknown notification type, ignoring")
        return
    }
    
    Logger.info("  - Extracted action: \(action)")
    Logger.info("  - Current timer state: \(timerState)")
    
    switch action {
    case "pause":
        if timerState == .running {
            Logger.info("  - Executing pause action")
            self.pause()
            
            // Ensure Live Activity is updated
            if #available(iOS 16.2, *) {
                await LiveActivityManagerSimplified.shared.pauseTimer()
            }
        }
    case "resume":
        if timerState == .paused {
            Logger.info("  - Executing resume action")
            self.resume()
            
            // Ensure Live Activity is updated
            if #available(iOS 16.2, *) {
                await LiveActivityManagerSimplified.shared.resumeTimer()
            }
        }
    case "stop":
        if timerState != .stopped {
            Logger.info("  - Executing stop action")
            self.stop()
        }
    default:
        Logger.info("  - Unknown action: \(action)")
    }
    
    Logger.info("  - Timer state after action: \(timerState)")
}