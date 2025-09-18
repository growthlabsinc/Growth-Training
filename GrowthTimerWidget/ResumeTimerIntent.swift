//
//  ResumeTimerIntent.swift
//  GrowthTimerWidget
//
//  App Intent for resuming the timer from Live Activity
//  Following Apple's EmojiRangers pattern - direct action, no Darwin notifications
//

import AppIntents
import ActivityKit
import Foundation
import WidgetKit
import os

private let logger = os.Logger(subsystem: "com.growthlabs.growthmethod.widget", category: "ResumeTimerIntent")

@available(iOS 17.0, *)
public struct ResumeTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Resume Timer"
    public static var description = IntentDescription("Resume the paused timer session")
    
    // Don't open app for resume action
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
        logger.info("▶️ ResumeTimerIntent performing for activity: \(activityId)")
        
        // Update timer state directly
        await resumeTimer()
        
        return .result()
    }
    
    @MainActor
    private func resumeTimer() async {
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
        
        // Not paused, no action needed
        guard let pausedAt = updatedState.pausedAt else {
            logger.info("Timer not paused, cannot resume")
            return
        }
        
        // Calculate pause duration and adjust start time
        let pauseDuration = now.timeIntervalSince(pausedAt)
        updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
        updatedState.pausedAt = nil
        
        // Store resume state in shared defaults for app sync
        sharedDefaults.set(false, forKey: "timerIsPaused")
        sharedDefaults.removeObject(forKey: "timerPausedAt")
        sharedDefaults.set("resume", forKey: "lastTimerAction")
        sharedDefaults.set(now.timeIntervalSince1970, forKey: "lastActionTime") // Store as TimeInterval for consistency
        sharedDefaults.set(activityId, forKey: "lastActivityId")
        sharedDefaults.set(timerType, forKey: "lastTimerType")
        sharedDefaults.set(updatedState.startedAt, forKey: "timerStartedAt")
        sharedDefaults.synchronize()
        
        // Update the Live Activity
        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(300) // 5 minutes stale time
            )
        )
        
        logger.info("✅ Timer resumed successfully with pause duration: \(pauseDuration)s")
    }
}