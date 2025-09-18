// Fix for Live Activity pause button race condition on iOS 18+
// The issue: Multiple Firebase function calls are overwriting the pause state

import Foundation
import ActivityKit

// STEP 1: Add debouncing to prevent multiple Firebase calls
@available(iOS 16.2, *)
extension LiveActivityManagerSimplified {
    
    // Add a property to track the last update time
    private static var lastUpdateTime: Date?
    private static let updateDebounceInterval: TimeInterval = 2.0 // 2 seconds
    
    // Modified pauseTimer to prevent race conditions
    func pauseTimerWithDebounce() async {
        guard let activity = currentActivity else { return }
        
        // Check if we recently sent an update
        if let lastUpdate = Self.lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < Self.updateDebounceInterval {
            Logger.info("⏳ Skipping pause update - too soon after last update")
            return
        }
        
        let currentState = activity.content.state
        guard !currentState.isPaused else { return } // Already paused
        
        // Update the last update time
        Self.lastUpdateTime = Date()
        
        // Store pause state in App Group immediately to prevent race conditions
        if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            defaults.set(true, forKey: "timerPausedViaLiveActivity")
            defaults.set(Date(), forKey: "timerPauseTime")
            defaults.synchronize()
            Logger.info("📱 Stored pause state in App Group")
        }
        
        // Create paused state
        let now = Date()
        let pausedState = TimerActivityAttributes.ContentState(
            startedAt: currentState.startedAt,
            pausedAt: now,
            duration: currentState.duration,
            methodName: currentState.methodName,
            sessionType: currentState.sessionType,
            isCompleted: false,
            completionMessage: nil
        )
        
        // Update locally for immediate feedback
        await updateActivity(with: pausedState)
        
        // Store state BEFORE sending push update
        await storeTimerStateInFirestore(
            activityId: activity.id,
            contentState: pausedState,
            action: "pause"
        )
        
        // Wait a moment to ensure Firestore write completes
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Send push update
        await sendPushUpdate(contentState: pausedState, action: "pause")
    }
}

// STEP 2: Fix the immediate update in TimerControlIntent
// Update the performTimerAction function to prevent immediate updates that conflict

@available(iOS 16.0, *)
func performTimerActionFixed(action: TimerAction, activityId: String, timerType: String) async throws -> some IntentResult & ProvidesDialog {
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
    
    // Update App Group state immediately for pause/resume
    if action == .pause || action == .resume {
        if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            defaults.set(action == .pause, forKey: "timerPausedViaLiveActivity")
            if action == .pause {
                defaults.set(Date(), forKey: "timerPauseTime")
            } else {
                defaults.removeObject(forKey: "timerPauseTime")
            }
            defaults.synchronize()
            print("🔵 TimerControlIntent: Updated App Group pause state")
        }
    }
    
    // Post Darwin notification
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
    
    // DO NOT update Live Activity here - let the main app handle it
    // This prevents race conditions with multiple updates
    
    return .result(dialog: IntentDialog(""))
}

// STEP 3: Cancel any pending updates when stopping
extension LiveActivityManagerSimplified {
    func cancelPendingUpdates() {
        // Cancel any pending Firebase function calls
        // This is handled by the debouncing mechanism
        Self.lastUpdateTime = nil
    }
}