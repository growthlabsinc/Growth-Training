// Fix for Live Activity pause button on iOS 18+
// Add this extension to handle Live Activity updates when pause/resume actions are received

import Foundation
import ActivityKit

@available(iOS 16.2, *)
extension TimerService {
    
    /// Handle pause action and update Live Activity
    public func pauseWithLiveActivityUpdate() {
        // First pause the timer
        pause()
        
        // Then update the Live Activity UI
        Task {
            await LiveActivityManagerSimplified.shared.pauseTimer()
        }
    }
    
    /// Handle resume action and update Live Activity  
    public func resumeWithLiveActivityUpdate() {
        // First resume the timer
        resume()
        
        // Then update the Live Activity UI
        Task {
            await LiveActivityManagerSimplified.shared.resumeTimer()
        }
    }
}

// Update the notification observers to use these new methods
// In AppSceneDelegate.swift, update the pause/resume handling:

/*
Replace:
case "pause":
    if timerState == .running {
        Logger.info("  - Processing pause action")
        pause()
    }
case "resume":
    if timerState == .paused {
        Logger.info("  - Processing resume action")
        resume()
    }

With:
case "pause":
    if timerState == .running {
        Logger.info("  - Processing pause action")
        if #available(iOS 16.2, *) {
            pauseWithLiveActivityUpdate()
        } else {
            pause()
        }
    }
case "resume":
    if timerState == .paused {
        Logger.info("  - Processing resume action")
        if #available(iOS 16.2, *) {
            resumeWithLiveActivityUpdate()
        } else {
            resume()
        }
    }
*/