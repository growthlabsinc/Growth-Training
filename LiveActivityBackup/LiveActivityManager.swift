//
//  LiveActivityManager.swift  
//  Growth
//
//  Simplified Live Activity Manager implementation
//  Replaces complex implementation with Apple best practices
//

import Foundation
import ActivityKit

/// Simplified Live Activity Manager following Apple best practices
/// This replaces the previous complex implementation with a clean, simple approach
@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if Live Activities are available and authorized
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    /// Start a new Live Activity (must be called from foreground)
    func startTimerActivity(
        methodId: String,
        methodName: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        sessionType: TimerActivityAttributes.ContentState.SessionType,
        timerType: String
    ) {
        print("🚀 ============ LIVE ACTIVITY START ATTEMPT ============")
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        print("📋 Method: \(methodName) (ID: \(methodId))")
        print("⏰ Start Time: \(startTime)")
        print("🔢 Duration: \(duration)s")
        print("🏷️ Timer Type: \(timerType)")
        
        guard areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            print("   - ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
            print("   - Device may not support Live Activities or user denied permission")
            return
        }
        
        print("✅ Live Activities are enabled - proceeding...")
        
        Task {
            do {
                print("🧹 Ending any existing activity first...")
                await endCurrentActivity()
                
                print("🏗️ Creating new Live Activity attributes...")
                let attributes = TimerActivityAttributes(
                    methodId: methodId,
                    totalDuration: duration,
                    timerType: timerType
                )
                print("   - Attributes created: \(attributes)")
                
                print("🔧 Creating initial content state...")
                let initialState = TimerActivityAttributes.ContentState(
                    startedAt: startTime,
                    pausedAt: nil,
                    duration: duration,
                    methodName: methodName,
                    sessionType: sessionType
                )
                print("   - Initial state created: \(initialState)")
                
                let activity: Activity<TimerActivityAttributes>
                
                if #available(iOS 16.2, *) {
                    print("📱 Using iOS 16.2+ API with ActivityContent...")
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        content: ActivityContent(
                            state: initialState,
                            staleDate: Date().addingTimeInterval(28800) // 8 hours
                        ),
                        pushType: nil // Local updates only for simplicity
                    )
                    print("   - Activity requested successfully with ActivityContent")
                } else {
                    print("📱 Using iOS 16.1 fallback API...")
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        contentState: initialState
                    )
                    print("   - Activity requested successfully with contentState")
                }
                
                self.currentActivity = activity
                print("✅ Activity stored in manager: \(activity.id)")
                print("🔍 Activity state: \(activity.activityState)")
                
                if #available(iOS 16.2, *) {
                    print("📊 Activity content: \(activity.content)")
                }
                
                // Store in app group for widget access
                print("💾 Storing timer state in app group...")
                AppGroupConstants.storeTimerState(
                    startTime: startTime,
                    endTime: endTime,
                    elapsedTime: 0,
                    isPaused: false,
                    methodName: methodName,
                    sessionType: "countup", // Use string directly since GrowthTimerActivityAttributes doesn't have sessionType
                    activityId: activity.id
                )
                print("   - App group state stored successfully")
                
                // Verify the activity is actually running
                print("🔍 Final verification:")
                print("   - Activity ID: \(activity.id)")
                print("   - Activity State: \(activity.activityState)")
                print("   - Current activities count: \(Activity<TimerActivityAttributes>.activities.count)")
                print("   - Is activity active: \(activity.activityState == .active)")
                
                print("✅ ============ LIVE ACTIVITY STARTED SUCCESSFULLY ============")
                print("🎯 Activity ID: \(activity.id)")
                print("📱 Should now appear in Dynamic Island and Lock Screen")
                
            } catch {
                print("❌ ============ LIVE ACTIVITY START FAILED ============")
                print("💥 Error: \(error)")
                print("🔍 Error details:")
                if let activityError = error as? ActivityKit.ActivityError {
                    print("   - ActivityKit Error: \(activityError)")
                }
                if let nsError = error as NSError? {
                    print("   - Domain: \(nsError.domain)")
                    print("   - Code: \(nsError.code)")
                    print("   - User Info: \(nsError.userInfo)")
                }
                print("📋 Possible causes:")
                print("   - App is in background (Live Activities must start from foreground)")
                print("   - Device doesn't support Live Activities (iOS 16.1+ required)")
                print("   - User denied Live Activity permissions")
                print("   - Widget extension target is not properly configured")
                print("   - ActivityAttributes not properly imported from widget target")
                print("================================================================")
            }
        }
    }
    
    /// Update the current Live Activity state
    func updateTimerActivity(
        elapsedTime: TimeInterval,
        isRunning: Bool,
        isPaused: Bool
    ) {
        guard let activity = currentActivity else { return }
        
        Task {
            if #available(iOS 16.2, *) {
                var updatedState = activity.content.state
                let now = Date()
                
                if isPaused && activity.content.state.pausedAt == nil {
                    // Pausing - record pause time
                    updatedState.pausedAt = now
                } else if !isPaused && activity.content.state.pausedAt != nil {
                    // Resuming - adjust startedAt to maintain correct elapsed time
                    if let pausedAt = activity.content.state.pausedAt {
                        let pauseDuration = now.timeIntervalSince(pausedAt)
                        updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
                    }
                    updatedState.pausedAt = nil
                }
                
                // Update with long stale date to prevent freezing
                await activity.update(ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(28800), // 8 hours
                    relevanceScore: isPaused ? 50.0 : 100.0
                ))
                
                // Update app group storage  
                AppGroupConstants.storeTimerState(
                    startTime: updatedState.startedAt,
                    endTime: Date().addingTimeInterval(86400),
                    elapsedTime: elapsedTime,
                    isPaused: isPaused,
                    methodName: updatedState.methodName,
                    sessionType: "countup",
                    activityId: activity.id
                )
            } else {
                // iOS 16.1 fallback - activity updates not supported, only store in app group
                print("⚠️ iOS 16.1 detected - Live Activity updates not supported, using app group only")
                
                // Store minimal state in app group for iOS 16.1
                // Get method name from stored app group data or use fallback
                let storedData = AppGroupConstants.getTimerState()
                let methodName = storedData.methodName ?? "Timer"
                
                AppGroupConstants.storeTimerState(
                    startTime: Date(), // Use current time as fallback
                    endTime: Date().addingTimeInterval(86400),
                    elapsedTime: elapsedTime,
                    isPaused: isPaused,
                    methodName: methodName,
                    sessionType: "countup",
                    activityId: activity.id
                )
            }
        }
    }
    
    /// End the current Live Activity
    func endTimerActivity() {
        Task {
            await endCurrentActivity()
        }
    }
    
    /// Get the current activity ID if any
    var currentActivityId: String? {
        return currentActivity?.id
    }
    
    /// Check if there's an active Live Activity
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
    
    /// Debug method to print current Live Activity state
    func debugPrintCurrentState() {
        print("🔍 ============ LIVE ACTIVITY DEBUG STATE ============")
        print("📱 Device Info:")
        print("   - iOS Version: \(UIDevice.current.systemVersion)")
        print("   - Device Model: \(UIDevice.current.model)")
        print("   - System Name: \(UIDevice.current.systemName)")
        
        print("🔐 Permissions:")
        print("   - Activities enabled: \(areActivitiesEnabled)")
        print("   - Authorization info: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        print("📊 Current State:")
        print("   - Has active activity: \(hasActiveActivity)")
        print("   - Current activity ID: \(currentActivityId ?? "None")")
        print("   - Total activities: \(Activity<TimerActivityAttributes>.activities.count)")
        
        if let activity = currentActivity {
            print("🎯 Active Activity Details:")
            print("   - ID: \(activity.id)")
            print("   - State: \(activity.activityState)")
            if #available(iOS 16.2, *) {
                print("   - Content: \(activity.content)")
                print("   - Method Name: \(activity.attributes.methodName)")
                print("   - Method ID: \(activity.attributes.methodId)")
            } else {
                print("   - Attributes: \(activity.attributes)")
            }
        }
        
        print("📋 All Activities:")
        let allActivities = Activity<TimerActivityAttributes>.activities
        for (index, activity) in allActivities.enumerated() {
            print("   [\(index)] ID: \(activity.id) | State: \(activity.activityState)")
        }
        
        print("💾 App Group State:")
        let timerState = AppGroupConstants.getTimerState()
        print("   - Method Name: \(timerState.methodName ?? "None")")
        print("   - Activity ID: \(timerState.activityId ?? "None")")
        print("   - Is Paused: \(timerState.isPaused)")
        print("   - Elapsed Time: \(timerState.elapsedTime)s")
        
        print("================================================")
    }
    
    /// Test method to start a simple Live Activity for debugging
    func testStartLiveActivity() {
        print("🧪 ============ TESTING LIVE ACTIVITY START ============")
        startTimerActivity(
            methodId: "test-method",
            methodName: "Test Method",
            startTime: Date(),
            endTime: Date().addingTimeInterval(300), // 5 minutes
            duration: 300,
            sessionType: .countup,
            timerType: "test"
        )
    }
    
    // MARK: - Private Methods
    
    private func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        if #available(iOS 16.2, *) {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: ActivityUIDismissalPolicy.immediate
            )
        } else {
            // iOS 16.1 fallback - create minimal final state
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: Date(),
                pausedAt: nil,
                duration: 0,
                methodName: "Timer",
                sessionType: .countup
            )
            await activity.end(using: finalState, dismissalPolicy: ActivityUIDismissalPolicy.immediate)
        }
        
        self.currentActivity = nil
        
        // Clear app group storage
        AppGroupConstants.clearTimerState()
        
        print("✅ Live Activity ended")
    }
    
    /// Clean up any stale activities on app launch
    func cleanupStaleActivities() {
        Task {
            for activity in Activity<TimerActivityAttributes>.activities {
                // End activities that might be left over from crashes
                if #available(iOS 16.2, *) {
                    await activity.end(
                        ActivityContent(state: activity.content.state, staleDate: nil),
                        dismissalPolicy: ActivityUIDismissalPolicy.immediate
                    )
                } else {
                    // iOS 16.1 fallback - create minimal final state
                    let finalState = TimerActivityAttributes.ContentState(
                        startedAt: Date(),
                        pausedAt: nil,
                        duration: 0,
                        methodName: "Timer",
                        sessionType: .countup
                    )
                    await activity.end(using: finalState, dismissalPolicy: ActivityUIDismissalPolicy.immediate)
                }
            }
            currentActivity = nil
            print("🧹 Cleaned up stale Live Activities")
        }
    }
    
    /// Resume tracking of existing activity (useful after app restart)
    func resumeExistingActivity() {
        let activities = Activity<TimerActivityAttributes>.activities
        if let latestActivity = activities.first {
            self.currentActivity = latestActivity
            
            if #available(iOS 16.2, *) {
                // Update app group with current state from activity
                AppGroupConstants.storeTimerState(
                    startTime: latestActivity.content.state.startedAt,
                    endTime: Date().addingTimeInterval(86400),
                    elapsedTime: latestActivity.content.state.currentElapsedTime,
                    isPaused: latestActivity.content.state.pausedAt != nil,
                    methodName: latestActivity.content.state.methodName,
                    sessionType: "countup",
                    activityId: latestActivity.id
                )
            } else {
                // iOS 16.1 fallback - store minimal state
                // Cannot access content.state on iOS 16.1, use fallback values
                AppGroupConstants.storeTimerState(
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(86400),
                    elapsedTime: 0,
                    isPaused: false,
                    methodName: "Timer", // Fallback since we can't access content.state
                    sessionType: "countup",
                    activityId: latestActivity.id
                )
            }
            
            print("🔄 Resumed existing Live Activity: \(latestActivity.id)")
        }
    }
}

// MARK: - Integration Helper

@available(iOS 16.1, *)
extension LiveActivityManager {
    /// Handle timer control actions from widget intents
    func handleWidgetAction(_ action: String, activityId: String) {
        Task {
            switch action {
            case "pause":
                if #available(iOS 16.2, *) {
                    updateTimerActivity(elapsedTime: currentActivity?.content.state.currentElapsedTime ?? 0, isRunning: false, isPaused: true)
                } else {
                    updateTimerActivity(elapsedTime: 0, isRunning: false, isPaused: true)
                }
            case "resume":
                if #available(iOS 16.2, *) {
                    updateTimerActivity(elapsedTime: currentActivity?.content.state.currentElapsedTime ?? 0, isRunning: true, isPaused: false)
                } else {
                    updateTimerActivity(elapsedTime: 0, isRunning: true, isPaused: false)
                }
            case "stop":
                await endCurrentActivity()
            default:
                break
            }
        }
    }
    
    /// Sync with main app timer state - simplified interface
    func syncWithTimerService(timerService: TimerService) {
        guard let methodName = timerService.currentMethodName,
              let methodId = timerService.currentMethodId else { return }
        
        let isRunning = timerService.timerState == .running
        let isPaused = timerService.timerState == .paused
        let elapsedTime = timerService.elapsedTime
        
        if hasActiveActivity {
            updateTimerActivity(elapsedTime: elapsedTime, isRunning: isRunning, isPaused: isPaused)
        } else if isRunning {
            // Start new activity if timer is running but no activity exists
            // Note: Using existing sessionType parameter from TimerActivityAttributes
            let sessionType: TimerActivityAttributes.ContentState.SessionType = 
                timerService.currentTimerMode == .countdown ? .countdown : .countup
                
            startTimerActivity(
                methodId: methodId,
                methodName: methodName,
                startTime: timerService.startTime ?? Date(),
                endTime: Date().addingTimeInterval(86400), // 24 hours placeholder
                duration: timerService.totalDuration ?? 0,
                sessionType: sessionType, // This parameter will be ignored in the simplified implementation
                timerType: timerService.isQuickPracticeTimer ? "quick" : "main"
            )
        }
    }
}