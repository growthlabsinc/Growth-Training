//
//  TimerControlIntent.swift
//  GrowthTimerWidget
//
//  App Intent for Live Activity timer controls with unique notifications per timer type
//

import AppIntents
import Foundation

@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Control Timer"
    
    // Open app when stopping timer to show completion - like expo-live-activity-timer
    static var openAppWhenRun: Bool = false
    
    var openAppWhenRun: Bool {
        return action == .stop
    }
    
    @Parameter(title: "Action")
    var action: TimerAction
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    @Parameter(title: "Timer Type")
    var timerType: String
    
    init() {
        self.action = .pause
        self.activityId = ""
        self.timerType = "main"
    }
    
    init(action: TimerAction, activityId: String, timerType: String) {
        self.action = action
        self.activityId = activityId
        self.timerType = timerType
    }
    
    func perform() async throws -> some IntentResult {
        print("🎮 TimerControlIntent.perform() called:")
        print("  - Action: \(action.rawValue)")
        print("  - Timer Type: \(timerType)")
        print("  - Activity ID: \(activityId)")
        print("  - Process: \(ProcessInfo.processInfo.processName)")
        print("  - Context: Widget Extension Intent")
        
        // Write to UserDefaults in App Group
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ TimerControlIntent: Failed to access shared defaults")
            return .result()
        }
        
        print("📝 Writing action to shared defaults...")
        sharedDefaults.set(action.rawValue, forKey: "lastTimerAction")
        sharedDefaults.set(timerType, forKey: "lastTimerType")
        sharedDefaults.set(Date(), forKey: "lastActionTime")
        sharedDefaults.set(activityId, forKey: "lastActivityId")
        let success = sharedDefaults.synchronize()
        print("📝 Shared defaults write success: \(success)")
        
        // Verify the write
        if let writtenAction = sharedDefaults.string(forKey: "lastTimerAction") {
            print("✅ Verified action written: '\(writtenAction)'")
        } else {
            print("❌ Failed to verify written action")
        }
        
        // Post generic Darwin notification that TimerService listens for
        let notificationName = "com.growthlabs.growthmethod.liveactivity.action"
        print("📡 Posting Darwin notification: \(notificationName)")
        
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
        
        print("✅ Darwin notification posted successfully")
        
        // For stop action, add a small delay to ensure the main app has time to process
        if action == .stop {
            print("⏹️ Stop action - adding processing delay...")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return .result()
    }
}