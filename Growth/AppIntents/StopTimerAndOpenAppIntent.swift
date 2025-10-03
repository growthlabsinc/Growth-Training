//
//  StopTimerAndOpenAppIntent.swift
//  Growth
//
//  LiveActivityIntent that stops timer and opens app
//  IMPORTANT: This file must be included in BOTH the main app target AND widget extension target
//

import AppIntents
import ActivityKit
import Foundation
import WidgetKit
import os

// Logger for intent - use os.Logger
private let logger = os.Logger(subsystem: "com.growthlabs.growthmethod", category: "StopTimerAndOpenAppIntent")

// Separate intent for stop action that opens the app
@available(iOS 17.0, *)
public struct StopTimerAndOpenAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop Timer"
    public static var description = IntentDescription("Stop the timer and open the app")
    
    // Open app when stopping timer
    public static var openAppWhenRun: Bool = true
    
    // Required for proper permission handling
    public static var isDiscoverable: Bool = false
    
    @Parameter(title: "Activity ID")
    public var activityId: String
    
    @Parameter(title: "Timer Type")
    public var timerType: String
    
    public init() {
        self.activityId = ""
        self.timerType = "main"
    }
    
    public init(activityId: String, timerType: String) {
        self.activityId = activityId
        self.timerType = timerType
    }
    
    public func perform() async throws -> some IntentResult {
        // Log the action for debugging  
        logger.info("🎯 StopTimerAndOpenAppIntent performing stop action for activity: \(activityId)")
        
        // Stop timer directly without Darwin notifications
        await stopTimer()
        
        // Return - app will open due to openAppWhenRun = true
        return .result()
    }
    
    @MainActor
    private func stopTimer() async {
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            logger.error("Failed to access app group UserDefaults")
            return
        }
        
        // Save navigation intent to open practice timer view
        sharedDefaults.set("practice", forKey: "pendingTimerNavigation")
        sharedDefaults.set("stop", forKey: "widgetTimerAction")
        sharedDefaults.set(timerType, forKey: "widgetTimerType")
        sharedDefaults.set(Date(), forKey: "widgetActionTime")
        sharedDefaults.set(activityId, forKey: "widgetActivityId")
        
        // Find and update the Live Activity
        if let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) {
            let updatedState = activity.content.state
            
            // Store completion state in SharedUserDefaults
            let now = Date()
            sharedDefaults.set(true, forKey: "timerIsCompleted")
            sharedDefaults.set(now, forKey: "timerCompletedAt")
            sharedDefaults.set("stop", forKey: "lastTimerAction")
            sharedDefaults.set(now.timeIntervalSince1970, forKey: "lastActionTime") // Store as TimeInterval for consistency
            sharedDefaults.set(activityId, forKey: "lastActivityId")
            sharedDefaults.set(timerType, forKey: "lastTimerType")
            
            // Store elapsed time and completion data for the main app to process
            let elapsedTime = updatedState.getElapsedTimeInSeconds()
            sharedDefaults.set(elapsedTime, forKey: "timerElapsedTime")
            
            // Save completion data for the completion sheet
            let completionData: [String: Any] = [
                "elapsedTime": elapsedTime,
                "startTime": updatedState.startedAt.timeIntervalSince1970,
                "methodName": updatedState.methodName,
                "timestamp": now.timeIntervalSince1970
            ]
            sharedDefaults.set(completionData, forKey: "pendingTimerCompletion")
            sharedDefaults.synchronize()
            
            // End the Live Activity with current state
            await activity.end(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                ),
                dismissalPolicy: .after(.now + 5) // Dismiss after 5 seconds
            )
            
            logger.info("✅ Timer stopped and Live Activity ended with elapsed time: \(elapsedTime)s")
        } else {
            // Still save the stop action even if we can't find the activity
            sharedDefaults.set("stop", forKey: "lastTimerAction")
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "lastActionTime") // Store as TimeInterval for consistency
            sharedDefaults.synchronize()
            
            logger.warning("Could not find Live Activity with ID: \(activityId), but saved stop action")
        }
    }
}