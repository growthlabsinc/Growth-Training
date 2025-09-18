//
//  TimerControlIntent_Fixed.swift
//  GrowthTimerWidget
//
//  A simplified version following Apple's best practices for Live Activity App Intents
//

import AppIntents
import Foundation
import ActivityKit
import WidgetKit

@available(iOS 16.0, *)
struct TimerControlIntentFixed: AppIntent {
    static var title: LocalizedStringResource = "Control Timer"
    static var description = IntentDescription("Control the timer from Live Activity")
    
    // CRITICAL: This prevents the app from launching when the intent runs
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
        print("🔵 TimerControlIntentFixed: Performing action \(action.rawValue) for activity \(activityId)")
        
        // According to Apple's documentation:
        // 1. DO NOT update the Live Activity directly from the widget
        // 2. Instead, communicate with the main app
        // 3. The main app handles the actual update via push notifications
        
        // Store the action for the main app to process
        print("🎯 TimerControlIntentFixed: Storing action for main app")
        let fileSuccess = AppGroupFileManager.shared.writeTimerAction(
            action.rawValue,
            activityId: activityId,
            timerType: timerType
        )
        
        if fileSuccess {
            print("✅ TimerControlIntentFixed: Action stored successfully")
        } else {
            print("❌ TimerControlIntentFixed: Failed to store action")
        }
        
        // Send Darwin notification to wake up the main app
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
        
        print("🔵 TimerControlIntentFixed: Posted Darwin notification: \(notificationName as String)")
        
        // Return empty dialog (no UI feedback needed)
        return .result(dialog: IntentDialog(""))
    }
}