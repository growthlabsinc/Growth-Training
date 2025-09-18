// Fix for Live Activity Pause Button on iOS 16.x
// The issue: Deep links from Live Activity aren't being handled

// Add this to AppSceneDelegate.swift, replacing the handleIncomingURL method:

private func handleIncomingURL(_ url: URL) {
    // Process incoming URL for deep linking
    Logger.debug("Processing URL: \(url.absoluteString)")
    
    // Handle timer control URLs from Live Activity
    if url.scheme == "growth" && url.host == "timer" {
        let pathComponents = url.pathComponents
        
        // URL format: growth://timer/{action}/{activityId}
        if pathComponents.count >= 3 {
            let action = pathComponents[1]
            let activityId = pathComponents[2]
            
            Logger.debug("🔗 Live Activity Deep Link: action=\(action), activityId=\(activityId)")
            
            // Find the timer type from the activity ID
            var timerType = "main" // default
            
            // Check main timer
            if let mainActivity = Growth.TimerService.shared.currentActivity,
               mainActivity.id == activityId {
                timerType = "main"
            }
            // Check quick practice timer
            else if let quickActivity = QuickPracticeTimerService.shared.currentActivity,
                    quickActivity.id == activityId {
                timerType = "quickPractice"
            }
            
            // Post notification for timer action
            let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
            
            switch action {
            case "pause":
                Logger.debug("🔗 Processing pause action for \(timerType) timer")
                NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
            case "resume":
                Logger.debug("🔗 Processing resume action for \(timerType) timer")
                NotificationCenter.default.post(name: .timerResumeRequested, object: nil, userInfo: userInfo)
            case "stop":
                Logger.debug("🔗 Processing stop action for \(timerType) timer")
                TimerIntentObserver.shared.handleStopAction(timerType: timerType)
            default:
                Logger.warning("🔗 Unknown timer action: \(action)")
            }
        }
    }
}

// Also ensure the widget's deployment target matches the app's iOS 16.0 requirement
// In GrowthTimerWidget target settings, set:
// - iOS Deployment Target: 16.0
// - Remove any @available(iOS 16.1, *) from the widget file header