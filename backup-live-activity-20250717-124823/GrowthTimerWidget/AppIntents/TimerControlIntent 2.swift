//
//  TimerControlIntent.swift
//  GrowthTimerWidget
//
//  Created by Developer on 6/20/25.
//

import AppIntents
import Foundation
import ActivityKit
import WidgetKit

// AppIntent for controlling timer from Live Activity
// Following Apple's guidelines: Don't update Live Activity directly from widget
// Uses synchronized TimerActivityAttributes structure

@available(iOS 16.0, *)
enum TimerAction: String, AppEnum {
    case pause = "pause"
    case resume = "resume"
    case stop = "stop"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Timer Action"
    
    static var caseDisplayRepresentations: [TimerAction: DisplayRepresentation] = [
        .pause: "Pause",
        .resume: "Resume",
        .stop: "Stop"
    ]
}

@available(iOS 16.0, *)
enum IntentError: Error {
    case generic
}

// iOS 17+ version using LiveActivityIntent
@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Control Timer"
    static var description = IntentDescription("Control the timer from Live Activity")
    
    // Prevent the app from opening when the intent runs
    static var openAppWhenRun: Bool = false
    
    // Hide from Shortcuts app - only available through Live Activity buttons
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "Action")
    var action: TimerAction
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    @Parameter(title: "Timer Type", default: "main")
    var timerType: String
    
    init() {}
    
    init(action: TimerAction, activityId: String, timerType: String = "main") {
        self.action = action
        self.activityId = activityId
        self.timerType = timerType
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return try await performTimerAction(action: action, activityId: activityId, timerType: timerType)
    }
}

// iOS 16 fallback version using AppIntent
@available(iOS 16.0, *)
struct TimerControlIntentLegacy: AppIntent {
    static var title: LocalizedStringResource = "Control Timer"
    static var description = IntentDescription("Control the timer from Live Activity")
    
    // Prevent the app from opening when the intent runs
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Action")
    var action: TimerAction
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    @Parameter(title: "Timer Type", default: "main")
    var timerType: String
    
    init() {}
    
    init(action: TimerAction, activityId: String, timerType: String = "main") {
        self.action = action
        self.activityId = activityId
        self.timerType = timerType
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return try await performTimerAction(action: action, activityId: activityId, timerType: timerType)
    }
}

// Shared implementation for both versions
@available(iOS 16.0, *)
func performTimerAction(action: TimerAction, activityId: String, timerType: String) async throws -> some IntentResult & ProvidesDialog {
    print("🔵 TimerControlIntent: Performing action \(action.rawValue) for activity \(activityId)")
    
    // According to Apple's best practices for LiveActivityIntent:
    // 1. The perform() method should be minimal - even empty is fine
    // 2. Just waking the app is often sufficient
    // 3. Use Darwin notifications for cross-process communication
    // 4. Don't update Live Activities directly from the widget
    
    // Use file-based communication instead of UserDefaults
    print("🎯 TimerControlIntent: About to write action '\(action.rawValue)' with activityId '\(activityId)' and timerType '\(timerType)'")
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
    
    // Post a Darwin notification with the action type
    let notificationName: CFString
    switch action {
    case .stop:
        notificationName = "com.growthlabs.growthmethod.liveactivity.stop" as CFString
    case .pause:
        notificationName = "com.growthlabs.growthmethod.liveactivity.pause" as CFString
    case .resume:
        notificationName = "com.growthlabs.growthmethod.liveactivity.resume" as CFString
    }
    
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(notificationName),
        nil,
        nil,
        true
    )
    
    print("🔵 TimerControlIntent: Posted Darwin notification: \(notificationName as String)")
    
    // Return result with a silent dialog (no UI feedback needed)
    return .result(dialog: IntentDialog(""))
}

// Notification names extension
extension Notification.Name {
    static let timerPauseRequested = Notification.Name("timerPauseRequested")
    static let timerStopRequested = Notification.Name("timerStopRequested")
}