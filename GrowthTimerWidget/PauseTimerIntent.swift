//
//  PauseTimerIntent.swift
//  GrowthTimerWidget
//
//  App Intent for pausing the timer from Live Activity
//  Following Apple's EmojiRangers pattern - direct action, no Darwin notifications
//

import AppIntents
import ActivityKit
import Foundation
import WidgetKit
import os

private let logger = os.Logger(subsystem: "com.growthlabs.growthmethod.widget", category: "PauseTimerIntent")

@available(iOS 17.0, *)
public struct PauseTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Pause Timer"
    public static var description = IntentDescription("Pause the current timer session")
    
    // Don't open app for pause action
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Parameter(title: "Activity ID")
    public var activityId: String
    
    @Parameter(title: "Timer Type")
    public var timerType: String
    
    public init() {
        self.activityId = ""
        self.timerType = "main"
    }
    
    public init(activityId: String, timerType: String = "main") {
        self.activityId = activityId
        self.timerType = timerType
    }
    
    public func perform() async throws -> some IntentResult {
        logger.info("⏸️ PauseTimerIntent performing for activity: \(activityId)")
        
        // Update timer state directly
        await pauseTimer()
        
        return .result()
    }
    
    @MainActor
    private func pauseTimer() async {
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            logger.error("Failed to access app group UserDefaults")
            return
        }
        
        // Find and update the Live Activity
        guard let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            logger.error("Could not find Live Activity with ID: \(activityId)")
            return
        }
        
        let now = Date()
        var updatedState = activity.content.state
        
        // Already paused, no action needed
        if updatedState.pausedAt != nil {
            logger.info("Timer already paused")
            return
        }
        
        // Update state to paused
        updatedState.pausedAt = now
        
        // Store pause state in shared defaults for app sync
        sharedDefaults.set(true, forKey: "timerIsPaused")
        sharedDefaults.set(now, forKey: "timerPausedAt")
        sharedDefaults.set("pause", forKey: "lastTimerAction")
        sharedDefaults.set(now.timeIntervalSince1970, forKey: "lastActionTime") // Store as TimeInterval for consistency
        sharedDefaults.set(activityId, forKey: "lastActivityId")
        sharedDefaults.set(timerType, forKey: "lastTimerType")
        sharedDefaults.synchronize()
        
        // Update the Live Activity
        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(300) // 5 minutes stale time
            )
        )
        
        logger.info("✅ Timer paused successfully")
    }
}