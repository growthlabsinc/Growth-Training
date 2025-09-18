import Foundation
import Combine
import ActivityKit

/// Observes timer control actions from Live Activity App Intents
class TimerIntentObserver {
    static let shared = TimerIntentObserver()
    
    private var lastProcessedActionTime: Date?
    
    private init() {
        startObserving()
    }
    
    private func startObserving() {
        // Register for Darwin notifications for each action type
        let notificationNames = [
            "com.growthlabs.growthmethod.liveactivity.stop",
            "com.growthlabs.growthmethod.liveactivity.pause", 
            "com.growthlabs.growthmethod.liveactivity.resume",
            "com.growthlabs.growthmethod.liveactivity.action" // Keep the old one for compatibility
        ]
        
        for name in notificationNames {
            let cfName = name as CFString
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                nil,
                { _, _, name, _, _ in
                    // This callback happens on a background thread
                    guard let name = name else { return }
                    let nameString = name.rawValue as String
                    
                    DispatchQueue.main.async {
                        // Try to determine timer type from active Live Activities
                        Task { @MainActor in
                            var timerType = "main"
                            
                            if #available(iOS 16.1, *) {
                                // Check if there's a quick timer Live Activity
                                let activities = Activity<TimerActivityAttributes>.activities
                                if activities.contains(where: { $0.attributes.timerType == "quick" }) {
                                    timerType = "quick"
                                }
                            }
                            
                            if nameString.hasSuffix(".stop") {
                                TimerIntentObserver.shared.handleStopAction(timerType: timerType)
                            } else if nameString.hasSuffix(".pause") {
                                TimerIntentObserver.shared.handlePauseAction(timerType: timerType)
                            } else if nameString.hasSuffix(".resume") {
                                TimerIntentObserver.shared.handleResumeAction(timerType: timerType)
                            } else {
                                TimerIntentObserver.shared.handleDarwinNotification()
                            }
                            
                            // Also store the action in App Group for later processing
                            // This ensures the action is processed even if app is suspended
                            TimerIntentObserver.shared.storeActionForLaterProcessing(action: nameString, timerType: timerType)
                        }
                    }
                },
                cfName,
                nil,
                .deliverImmediately
            )
        }
    }
    
    private func handleDarwinNotification() {
        print("🔔 TimerIntentObserver: Darwin notification received!")
        
        // First check if any Live Activities are still active
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                let activities = Activity<TimerActivityAttributes>.activities
                print("🔔 TimerIntentObserver: Active Live Activities count: \(activities.count)")
                
                // If no activities, the widget successfully dismissed it
                if activities.isEmpty {
                    print("✅ TimerIntentObserver: No active Live Activities - widget handled dismissal")
                    // Stop the timer in the main app
                    if TimerService.shared.state != .stopped {
                        print("🛑 TimerIntentObserver: Stopping timer in main app")
                        TimerService.shared.stop()
                    }
                    return
                }
            }
        }
        
        // Otherwise check for file/defaults as before
        checkForIntentActions()
    }
    
    private func checkForIntentActions() {
        // First try file-based communication
        if let timerAction = AppGroupFileManager.shared.readTimerAction() {
            print("🔔 TimerIntentObserver: Read action from file:")
            print("  - Action: \(timerAction.action)")
            print("  - Timestamp: \(timerAction.timestamp)")
            print("  - ActivityId: \(timerAction.activityId)")
            print("  - TimerType: \(timerAction.timerType)")
            
            processAction(timerAction.action, timestamp: timerAction.timestamp, timerType: timerAction.timerType)
            
            // Clear the file after processing
            AppGroupFileManager.shared.clearTimerAction()
            return
        }
        
        // Fallback to UserDefaults
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) else {
            print("❌ TimerIntentObserver: Failed to get shared defaults")
            return
        }
        
        // Debug what's in the defaults
        let action = defaults.string(forKey: "lastTimerAction")
        let actionTime = defaults.object(forKey: "lastActionTime") as? Date
        let activityId = defaults.string(forKey: "lastActivityId")
        let timerType = defaults.string(forKey: "lastTimerType") ?? "main"
        
        print("🔔 TimerIntentObserver: Checking shared defaults:")
        print("  - Action: \(action ?? "nil")")
        print("  - ActionTime: \(actionTime?.description ?? "nil")")
        print("  - ActivityId: \(activityId ?? "nil")")
        print("  - TimerType: \(timerType)")
        
        guard let validAction = action,
              let validActionTime = actionTime else {
            print("❌ TimerIntentObserver: Missing required data")
            return
        }
        
        print("🔔 TimerIntentObserver: Found action: \(validAction) at \(validActionTime)")
        
        processAction(validAction, timestamp: validActionTime, timerType: timerType)
        
        // Clear after processing
        defaults.removeObject(forKey: "lastTimerAction")
        defaults.removeObject(forKey: "lastActionTime")
        defaults.removeObject(forKey: "lastTimerType")
        defaults.synchronize()
    }
    
    private func processAction(_ action: String, timestamp: Date, timerType: String = "main") {
        // Don't process the same action twice
        if let lastProcessed = lastProcessedActionTime,
           timestamp <= lastProcessed {
            print("❌ TimerIntentObserver: Action already processed")
            return
        }
        
        // Process the action if it's recent (within 10 seconds)
        if abs(timestamp.timeIntervalSinceNow) < 10 {
            lastProcessedActionTime = timestamp
            
            print("✅ TimerIntentObserver: Processing action: \(action) for timer type: \(timerType)")
            
            // Include timer type in notification
            let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
            
            switch action {
            case "pause", "resume":
                print("📮 TimerIntentObserver: Posting timerPauseRequested")
                NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
            case "stop":
                print("📮 TimerIntentObserver: Posting timerStopRequested")
                NotificationCenter.default.post(name: .timerStopRequested, object: nil, userInfo: userInfo)
            default:
                print("❌ TimerIntentObserver: Unknown action: \(action)")
                break
            }
        } else {
            print("❌ TimerIntentObserver: Action too old (> 10 seconds)")
        }
    }
    
    func handleStopAction(timerType: String = "main") {
        print("🛑 TimerIntentObserver: Stop action received via Darwin notification for timer type: \(timerType)")
        
        Task { @MainActor in
            // Determine which timer to stop
            let isQuickTimer = timerType == "quick"
            
            // CRITICAL: Clear background timer state FIRST to prevent restoration
            if #available(iOS 16.1, *) {
                print("🛑 TimerIntentObserver: Clearing background timer state FIRST")
                BackgroundTimerTracker.shared.clearSavedState(isQuickPractice: isQuickTimer)
                
                // Also clear any UserDefaults saved state
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "timerService.savedElapsedTime")
                defaults.removeObject(forKey: "timerService.savedTimerState")
                defaults.removeObject(forKey: "timerService.savedBackgroundTimestamp")
                defaults.synchronize()
                print("🛑 TimerIntentObserver: Cleared all timer state storage")
            }
            
            // Post notification for the appropriate timer
            let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
            NotificationCenter.default.post(name: .timerStopRequested, object: nil, userInfo: userInfo)
            
            // The TimerViewModel will handle stopping via the notification
            // We don't need to stop TimerService directly here anymore
            
            // The Live Activity should already be dismissed by the widget
            if #available(iOS 16.1, *) {
                let activities = Activity<TimerActivityAttributes>.activities
                print("📊 TimerIntentObserver: Remaining activities after stop: \(activities.count)")
            }
        }
    }
    
    private func handlePauseAction(timerType: String = "main") {
        print("⏸️ TimerIntentObserver: Pause action received via Darwin notification for timer type: \(timerType)")
        
        Task { @MainActor in
            // Post notification for the appropriate timer
            let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
            NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
            
            // Also handle TimerService.shared if it's the main timer
            if timerType == "main" && TimerService.shared.state == .running {
                print("⏸️ TimerIntentObserver: Pausing main timer")
                print("  - Current elapsed time: \(TimerService.shared.elapsedTime)")
                print("  - Current start time: \(String(describing: TimerService.shared.startTime))")
                TimerService.shared.pause()
                print("  - After pause elapsed time: \(TimerService.shared.elapsedTime)")
            }
        }
    }
    
    private func handleResumeAction(timerType: String = "main") {
        print("▶️ TimerIntentObserver: Resume action received via Darwin notification for timer type: \(timerType)")
        
        Task { @MainActor in
            // Post notification for the appropriate timer
            let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
            NotificationCenter.default.post(name: .timerResumeRequested, object: nil, userInfo: userInfo)
            
            // Also handle TimerService.shared if it's the main timer
            if timerType == "main" && TimerService.shared.state == .paused {
                print("▶️ TimerIntentObserver: Resuming main timer")
                print("  - Current elapsed time: \(TimerService.shared.elapsedTime)")
                print("  - Current start time: \(String(describing: TimerService.shared.startTime))")
                TimerService.shared.resume()
                print("  - After resume elapsed time: \(TimerService.shared.elapsedTime)")
                print("  - After resume start time: \(String(describing: TimerService.shared.startTime))")
            }
        }
    }
    
    private func storeActionForLaterProcessing(action: String, timerType: String) {
        // Extract the action type from the notification name
        let actionType: String
        if action.hasSuffix(".stop") {
            actionType = "stop"
        } else if action.hasSuffix(".pause") {
            actionType = "pause"
        } else if action.hasSuffix(".resume") {
            actionType = "resume"
        } else {
            return // Unknown action
        }
        
        // Generate a unique activity ID (in real app, this would come from the Live Activity)
        let activityId = "darwin-notification-\(Date().timeIntervalSince1970)"
        
        // Store in App Group file for later processing
        _ = AppGroupFileManager.shared.writeTimerAction(actionType, activityId: activityId, timerType: timerType)
        print("💾 TimerIntentObserver: Stored action '\(actionType)' for later processing")
    }
    
    deinit {
        // Remove observer when deinitialized
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil
        )
    }
}