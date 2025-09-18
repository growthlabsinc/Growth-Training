//
//  LiveActivityUpdateManager.swift
//  GrowthTimerWidget
//
//  Created by Developer on 6/20/25.
//

import Foundation
import ActivityKit

/// Manages Live Activity state from the widget side
/// Following Apple's guidelines: Widget does NOT update Live Activity directly
@available(iOS 16.1, *)
class LiveActivityUpdateManager {
    static let shared = LiveActivityUpdateManager()
    
    private init() {}
    
    /// Store the updated state for main app to process
    /// Widget should NOT update Live Activity directly per Apple guidelines
    func storeActivityState(activityId: String, isPaused: Bool) {
        print("🔵 LiveActivityUpdateManager: Storing state for \(activityId), isPaused: \(isPaused)")
        
        // Find the activity with matching ID
        for activity in Activity<TimerActivityAttributes>.activities {
            if activity.id == activityId {
                let state = activity.content.state
                
                // Use computed property for current elapsed time
                let currentElapsedTime = state.currentElapsedTime
                
                // Store the state in App Group for main app to process
                AppGroupConstants.storeTimerState(
                    startTime: state.startTime,
                    endTime: state.endTime,
                    elapsedTime: currentElapsedTime,
                    isPaused: isPaused,
                    methodName: state.methodName,
                    sessionType: state.sessionType.rawValue,
                    activityId: activityId,
                    isCompleted: false,
                    completionMessage: nil
                )
                
                print("✅ LiveActivityUpdateManager: State stored in App Group")
                break
            }
        }
    }
    
    /// Store end state for main app to process
    /// Widget should NOT end Live Activity directly per Apple guidelines
    func storeEndState(activityId: String) {
        print("🔴 LiveActivityUpdateManager: Storing end state for \(activityId)")
        print("🔴 LiveActivityUpdateManager: Total activities: \(Activity<TimerActivityAttributes>.activities.count)")
        
        for activity in Activity<TimerActivityAttributes>.activities {
            print("🔴 LiveActivityUpdateManager: Checking activity \(activity.id)")
            if activity.id == activityId {
                print("🔴 LiveActivityUpdateManager: Found matching activity!")
                
                // Clear the stored state to signal end
                AppGroupConstants.clearTimerState()
                
                // Store a special "stop" action for main app to process
                _ = AppGroupFileManager.shared.writeTimerAction("stop", activityId: activityId)
                
                print("✅ LiveActivityUpdateManager: End state stored for main app to process")
                break
            }
        }
    }
}