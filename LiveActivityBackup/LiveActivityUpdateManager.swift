//
//  LiveActivityUpdateManager.swift
//  GrowthTimerWidget
//
//  Created by Developer on 6/20/25.
//

import Foundation
import ActivityKit

/// Manages Live Activity updates from the widget side
@available(iOS 16.2, *)
class LiveActivityUpdateManager {
    static let shared = LiveActivityUpdateManager()
    
    private init() {}
    
    /// Update the Live Activity state locally
    func updateActivityState(activityId: String, isPaused: Bool) async {
        print("🟣 WIDGET DEBUG: updateActivityState called")
        print("  - activityId: \(activityId)")
        print("  - isPaused: \(isPaused)")
        print("  - Total activities: \(Activity<TimerActivityAttributes>.activities.count)")
        
        // Find the activity with matching ID
        for activity in Activity<TimerActivityAttributes>.activities {
            if activity.id == activityId {
                print("🟣 WIDGET DEBUG: Found matching activity")
                print("  - Current pausedAt: \(String(describing: activity.content.state.pausedAt))")
                print("  - Activity state: \(activity.activityState)")
                
                var updatedState = activity.content.state
                let now = Date()
                
                if isPaused && activity.content.state.pausedAt == nil {
                    // Pausing: Just set pausedAt timestamp
                    print("🟡 WIDGET DEBUG: PAUSING from widget")
                    print("  - Setting pausedAt to: \(now)")
                    updatedState.pausedAt = now
                } else if !isPaused && activity.content.state.pausedAt != nil {
                    // Resuming: Adjust startedAt by pause duration (key insight from expo-live-activity-timer)
                    print("🟢 WIDGET DEBUG: RESUMING from widget")
                    if let pausedAt = activity.content.state.pausedAt {
                        // Calculate how long we were paused
                        let pauseDuration = now.timeIntervalSince(pausedAt)
                        // Add the pause duration to startedAt so the timer continues from where it was paused
                        updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
                        print("  - Pause duration: \(pauseDuration)s")
                        print("  - Adjusted startedAt: \(updatedState.startedAt)")
                        print("  - This ensures the timer continues from the paused elapsed time")
                    }
                    updatedState.pausedAt = nil
                }
                
                // Calculate appropriate stale date based on state
                // Use very long stale dates to prevent Live Activity freezing when screen locks
                // Using 8 hours consistently to match main app behavior
                let staleDate = Date().addingTimeInterval(28800) // 8 hours from now
                
                print("🎯 Widget: Updating activity with stale date: \(staleDate) (in \(staleDate.timeIntervalSinceNow) seconds)")
                print("🟣 WIDGET DEBUG: Final state before update:")
                print("  - pausedAt: \(String(describing: updatedState.pausedAt))")
                print("  - startedAt: \(updatedState.startedAt)")
                
                // Update the activity locally for immediate feedback
                await activity.update(ActivityContent(
                    state: updatedState, 
                    staleDate: staleDate,
                    relevanceScore: updatedState.pausedAt != nil ? 50.0 : 100.0
                ))
                
                print("✅ WIDGET DEBUG: Update completed")
                print("  - Post-update activity state: \(activity.activityState)")
                if activity.activityState == .stale {
                    print("⚠️ WIDGET WARNING: Activity is STALE! This causes freezing")
                }
                
                // Store the updated state in App Group (simplified for GrowthTimerActivityAttributes)
                let endTime = Date().addingTimeInterval(86400) // 24 hours placeholder
                
                AppGroupConstants.storeTimerState(
                    startTime: updatedState.startedAt,
                    endTime: endTime,
                    elapsedTime: updatedState.pausedAt?.timeIntervalSince(updatedState.startedAt) ?? Date().timeIntervalSince(updatedState.startedAt),
                    isPaused: updatedState.pausedAt != nil,
                    methodName: updatedState.methodName, // Get from state
                    sessionType: updatedState.sessionType.rawValue, // Use actual session type
                    activityId: activityId
                )
                
                break
            }
        }
    }
    
    /// End the Live Activity
    func endActivity(activityId: String) async {
        print("🔴 LiveActivityUpdateManager: endActivity called for \(activityId)")
        print("🔴 LiveActivityUpdateManager: Total activities: \(Activity<TimerActivityAttributes>.activities.count)")
        
        for activity in Activity<TimerActivityAttributes>.activities {
            print("🔴 LiveActivityUpdateManager: Checking activity \(activity.id)")
            if activity.id == activityId {
                print("🔴 LiveActivityUpdateManager: Found matching activity!")
                
                // End the activity immediately
                print("🔴 LiveActivityUpdateManager: Calling activity.end() with immediate dismissal")
                await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
                print("✅ LiveActivityUpdateManager: activity.end() completed")
                
                // Clear the stored state
                AppGroupConstants.clearTimerState()
                print("✅ LiveActivityUpdateManager: Cleared timer state")
                
                break
            }
        }
    }
}