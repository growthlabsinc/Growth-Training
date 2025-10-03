//
//  TimerControlIntent.swift
//  GrowthTimerWidget
//
//  App Intent for Live Activity timer controls with unique notifications per timer type
//

import AppIntents
import ActivityKit
import Foundation
import WidgetKit
import os

// Logger for widget extension
private let logger = os.Logger(subsystem: "com.growthlabs.growthmethod.widget", category: "TimerControlIntent")

// StopTimerAndOpenAppIntent is now defined in the main app target
// and shared with the widget extension for LiveActivityIntent to work properly

@available(iOS 17.0, *)
public struct TimerControlIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Control Timer"
    public static var description = IntentDescription("Control the timer from the Live Activity")
    
    // LiveActivityIntent runs in the app's process when included in both targets
    public static var openAppWhenRun: Bool = false
    
    // Required for proper permission handling
    public static var isDiscoverable: Bool = false
    
    @Parameter(title: "Action")
    public var action: TimerAction
    
    @Parameter(title: "Activity ID")
    public var activityId: String
    
    @Parameter(title: "Timer Type")
    public var timerType: String
    
    public init() {
        self.action = .pause
        self.activityId = ""
        self.timerType = "main"
    }
    
    public init(action: TimerAction, activityId: String, timerType: String) {
        self.action = action
        self.activityId = activityId
        self.timerType = timerType
    }
    
    public func perform() async throws -> some IntentResult {
        // Log the action for debugging
        logger.info("🎯 TimerControlIntent performing action: \(action.rawValue) for activity: \(activityId)")
        
        // Directly update shared state and Live Activity
        // Following Apple's EmojiRangers pattern - no Darwin notifications needed
        await performDirectTimerAction()
        
        // Return immediately after performing the action
        return .result()
    }
    
    // Helper method to sync timer state with main app
    private func syncTimerState(with sharedDefaults: UserDefaults) {
        // This method is called from performDirectTimerAction
        // Keeping state synchronization logic separate for clarity
        sharedDefaults.synchronize()
    }
    
    // Direct timer action implementation following Apple's EmojiRangers pattern
    // No Darwin notifications needed - App Intent performs the action directly
    @MainActor
    private func performDirectTimerAction() async {
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            logger.error("Failed to access app group UserDefaults")
            return
        }
        
        // Get current timestamp
        let now = Date()
        
        // Find and update the Live Activity directly
        if let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) {
            
            // Get current state
            var updatedState = activity.content.state
            
            switch action {
            case .pause:
                // Update state to paused
                updatedState.pausedAt = now
                
                // Store pause state in shared defaults
                sharedDefaults.set(true, forKey: "timerIsPaused")
                sharedDefaults.set(now, forKey: "timerPausedAt")
                sharedDefaults.set("pause", forKey: "lastTimerAction")
                
                logger.info("⏸️ Timer paused at \(now)")
                
            case .resume:
                // Calculate adjusted times for resume
                if let pausedAt = updatedState.pausedAt {
                    let pauseDuration = now.timeIntervalSince(pausedAt)
                    
                    // Adjust the start time to account for pause duration
                    updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
                    updatedState.pausedAt = nil
                    
                    // Update shared defaults
                    sharedDefaults.set(false, forKey: "timerIsPaused")
                    sharedDefaults.removeObject(forKey: "timerPausedAt")
                    sharedDefaults.set("resume", forKey: "lastTimerAction")
                    
                    // Store adjusted start time
                    sharedDefaults.set(updatedState.startedAt, forKey: "timerStartedAt")
                    
                    logger.info("▶️ Timer resumed with pause duration: \(pauseDuration)s")
                }
                
            case .stop:
                // Store completion state in SharedUserDefaults
                // Note: isCompleted and completionMessage are computed properties, not settable
                sharedDefaults.set(true, forKey: "timerIsCompleted")
                sharedDefaults.set(now, forKey: "timerCompletedAt")
                sharedDefaults.set("stop", forKey: "lastTimerAction")
                
                // Store elapsed time for completion tracking
                let elapsedTime = updatedState.getElapsedTimeInSeconds()
                sharedDefaults.set(elapsedTime, forKey: "timerElapsedTime")
                
                logger.info("⏹️ Timer stopped with elapsed time: \(elapsedTime)s")
            }
            
            // Store action metadata
            sharedDefaults.set(now, forKey: "lastActionTime")
            sharedDefaults.set(activityId, forKey: "lastActivityId")
            sharedDefaults.set(timerType, forKey: "lastTimerType")
            sharedDefaults.synchronize()
            
            // Update the Live Activity directly
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(60) // 1 minute stale time
                )
            )
            
            // End activity if stopped
            if action == .stop {
                await activity.end(
                    ActivityContent(
                        state: updatedState,
                        staleDate: nil
                    ),
                    dismissalPolicy: .after(.now + 5) // Dismiss after 5 seconds
                )
            }
            
            logger.info("✅ Live Activity updated successfully")
            
        } else {
            logger.error("❌ Could not find Live Activity with ID: \(activityId)")
        }
    }
}