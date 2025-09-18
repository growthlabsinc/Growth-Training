import ActivityKit
import Foundation
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import FirebaseAppCheck
// No need to import widget module - TimerActivityAttributes is in the main app target

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published private(set) var currentActivity: Activity<TimerActivityAttributes>?
    private var isShowingCompletion = false
    private var lastUpdateTime: Date?
    private let minimumUpdateInterval: TimeInterval = 0.5 // Minimum 0.5 seconds between updates
    
    private init() {}
    
    /// Check if Live Activity is showing completion state
    var isActivityShowingCompletion: Bool {
        return isShowingCompletion
    }
    
    func startTimerActivity(
        methodId: String,
        methodName: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        sessionType: TimerActivityAttributes.ContentState.SessionType,
        timerType: String = "main"
    ) {
        print("🔵 LiveActivityManager: startTimerActivity called")
        print("  - Method: \(methodName) (ID: \(methodId))")
        print("  - Duration: \(duration)s, Type: \(sessionType)")
        print("  - Start: \(startTime), End: \(endTime)")
        
        // Clear completion flag when starting new activity
        isShowingCompletion = false
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ LiveActivityManager: Live Activities are NOT enabled in system settings")
            return
        }
        print("✅ LiveActivityManager: Live Activities are enabled")
        
        Task {
            await self.endCurrentActivity()
            
            // Ensure duration is valid - use actual duration or calculate from times
            let validDuration: TimeInterval
            if duration > 0 {
                validDuration = duration
            } else if endTime > startTime {
                validDuration = endTime.timeIntervalSince(startTime)
            } else {
                // Default to 5 minutes if no valid duration
                validDuration = 300
            }
            
            let attributes = TimerActivityAttributes(
                methodId: methodId,
                totalDuration: validDuration,
                timerType: timerType
            )
            
            let now = Date()
            
            // CRITICAL: Ensure all dates are properly initialized to prevent 1994 issue
            let validStartTime = startTime.timeIntervalSince1970 > 1000000000 ? startTime : now
            let validEndTime = endTime.timeIntervalSince1970 > 1000000000 ? endTime : now.addingTimeInterval(duration)
            
            // Use new simplified content state
            let contentState = TimerActivityAttributes.ContentState(
                startedAt: validStartTime,
                pausedAt: nil, // Not paused when starting
                duration: validDuration,
                methodName: methodName,
                sessionType: sessionType,
                isCompleted: false,
                completionMessage: nil
            )
            
            print("🔍 LiveActivityManager: Creating Live Activity with simplified state:")
            print("  - Duration: \(validDuration) seconds (\(validDuration/60) minutes)")
            print("  - Started at: \(contentState.startedAt)")
            print("  - Session type: \(sessionType)")
            print("  - Expected end: \(contentState.endTime)")
            
            do {
                print("🔵 LiveActivityManager: Creating Live Activity")
                
                // Calculate appropriate stale date
                let staleDate: Date
                if sessionType == .countdown {
                    // For countdown timers, stale date is end time + 10 seconds buffer
                    staleDate = validEndTime.addingTimeInterval(10)
                } else {
                    // For countup timers, stale date is 60 seconds from now
                    staleDate = Date().addingTimeInterval(60)
                }
                print("  - Stale date set to: \(staleDate)")
                
                // Check if running on simulator
                #if targetEnvironment(simulator)
                print("⚠️ LiveActivityManager: Running on simulator - push tokens not available")
                print("⚠️ Live Activity will have limited updates without push notifications")
                #else
                print("✅ LiveActivityManager: Running on device - push tokens should be available")
                #endif
                
                // Enable push updates for Live Activity
                let activity: Activity<TimerActivityAttributes>
                if #available(iOS 16.2, *) {
                    print("🔵 LiveActivityManager: Requesting Live Activity with push token support")
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        content: ActivityContent(state: contentState, staleDate: staleDate),
                        pushType: .token
                    )
                    print("✅ LiveActivityManager: Live Activity created with push token support")
                } else {
                    print("⚠️ LiveActivityManager: iOS 16.2+ required for push tokens, creating without")
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        content: ActivityContent(state: contentState, staleDate: staleDate)
                    )
                }
                
                await MainActor.run {
                    self.currentActivity = activity
                }
                
                print("✅ LiveActivityManager: Started Live Activity with ID: \(activity.id)")
                // pushType is only available in iOS 16.2+
                // print("  - Push token enabled: \(activity.pushType == .token)")
                
                // Store timer state in App Group for widget access
                AppGroupConstants.storeTimerState(
                    startTime: startTime,
                    endTime: endTime,
                    elapsedTime: 0,
                    isPaused: false,
                    methodName: methodName,
                    sessionType: sessionType.rawValue,
                    activityId: activity.id,
                    isCompleted: false,
                    completionMessage: nil
                )
                print("✅ LiveActivityManager: Stored timer state in App Group")
                
                // Start monitoring the activity
                LiveActivityMonitor.shared.startMonitoring(activity: activity)
                
                // Start server-side push updates (no local updates)
                LiveActivityPushService.shared.startPushUpdates(for: activity)
                
                // Register for push token updates
                Task {
                    await registerForPushUpdates(activity: activity)
                }
            } catch {
                print("❌ LiveActivityManager: Failed to start Live Activity")
                print("  - Error: \(error)")
                print("  - Description: \(error.localizedDescription)")
            }
        }
    }
    
    func updateActivity(isPaused: Bool, newEndTime: Date? = nil) {
        Task {
            guard let activity = currentActivity else { return }
            
            // Don't update if activity is already completed
            if activity.content.state.isCompleted {
                print("⚠️ LiveActivityManager: Activity is completed, skipping update")
                return
            }
            
            // Don't update if state hasn't changed
            if activity.content.state.isPaused == isPaused && newEndTime == nil {
                return
            }
            
            // Debounce updates to prevent flooding
            if let lastUpdate = lastUpdateTime {
                let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
                if timeSinceLastUpdate < minimumUpdateInterval {
                    return
                }
            }
            lastUpdateTime = Date()
            
            let now = Date()
            let currentState = activity.content.state
            var newState: TimerActivityAttributes.ContentState
            
            if isPaused && !currentState.isPaused {
                // Pausing: Create new state with pausedAt set
                newState = TimerActivityAttributes.ContentState(
                    startedAt: currentState.startedAt,
                    pausedAt: now,
                    duration: currentState.duration,
                    methodName: currentState.methodName,
                    sessionType: currentState.sessionType,
                    isCompleted: currentState.isCompleted,
                    completionMessage: currentState.completionMessage
                )
                
                print("🔄 LiveActivityManager: Pausing timer")
                print("  - Paused at: \(now)")
                print("  - Elapsed time: \(newState.currentElapsedTime)s")
                
                // Sync pause state to Firebase
                TimerStateSync.shared.updatePauseState(
                    isPaused: true,
                    pausedAt: now
                )
            } else if !isPaused && currentState.isPaused {
                // Resuming: Adjust startedAt by the pause duration
                if let pausedAt = currentState.pausedAt {
                    let pauseDuration = now.timeIntervalSince(pausedAt)
                    
                    // Create resumed state with adjusted startedAt
                    newState = TimerActivityAttributes.ContentState(
                        startedAt: currentState.startedAt.addingTimeInterval(pauseDuration),
                        pausedAt: nil, // Clear pausedAt
                        duration: currentState.duration,
                        methodName: currentState.methodName,
                        sessionType: currentState.sessionType,
                        isCompleted: currentState.isCompleted,
                        completionMessage: currentState.completionMessage
                    )
                    
                    print("🔄 LiveActivityManager: Resuming timer")
                    print("  - Pause duration: \(pauseDuration)s")
                    print("  - Original startedAt: \(currentState.startedAt)")
                    print("  - Adjusted startedAt: \(newState.startedAt)")
                    
                    // Sync resume state to Firebase with adjusted time
                    TimerStateSync.shared.updatePauseState(
                        isPaused: false,
                        pausedAt: nil,
                        adjustedStartedAt: newState.startedAt
                    )
                } else {
                    print("⚠️ LiveActivityManager: Resume called but pausedAt is nil")
                    return
                }
            } else {
                // No pause/resume change, but might have newEndTime
                newState = currentState
            }
            
            // Handle duration adjustment for countdown timers
            if let newEndTime = newEndTime, newState.sessionType == .countdown {
                // Calculate new duration based on the new end time
                let newDuration = newEndTime.timeIntervalSince(newState.startedAt)
                newState = TimerActivityAttributes.ContentState(
                    startedAt: newState.startedAt,
                    pausedAt: newState.pausedAt,
                    duration: newDuration,
                    methodName: newState.methodName,
                    sessionType: newState.sessionType,
                    isCompleted: newState.isCompleted,
                    completionMessage: newState.completionMessage
                )
                print("🔄 LiveActivityManager: Adjusting timer duration")
                print("  - New duration: \(newDuration)s")
            }
            
            print("🔄 LiveActivityManager: Sending update to Live Activity...")
            print("  - Is paused: \(newState.isPaused)")
            print("  - Started at: \(newState.startedAt)")
            print("  - Paused at: \(String(describing: newState.pausedAt))")
            print("  - Duration: \(newState.duration)s")
            
            // Store updated timer state in App Group using legacy format
            AppGroupConstants.storeTimerState(
                startTime: newState.startedAt,
                endTime: newState.endTime,
                elapsedTime: newState.currentElapsedTime,
                isPaused: newState.isPaused,
                methodName: newState.methodName,
                sessionType: newState.sessionType.rawValue,
                activityId: activity.id,
                isCompleted: newState.isCompleted,
                completionMessage: newState.completionMessage
            )
            print("✅ LiveActivityManager: Updated timer state in App Group")
            
            // Update the Live Activity locally for immediate feedback
            let staleDate = Date().addingTimeInterval(10) // Activity becomes stale after 10 seconds
            await activity.update(
                ActivityContent(state: newState, staleDate: staleDate)
            )
            print("✅ LiveActivityManager: Updated Live Activity locally for immediate feedback")
            
            // Send push update with the new state we just created
            await LiveActivityPushService.shared.sendStateChangeUpdate(
                for: activity,
                isPaused: isPaused,
                updatedState: newState
            )
            print("✅ LiveActivityManager: Push update request sent for \(activity.id)")
        }
    }
    
    func endCurrentActivity(immediately: Bool = false) async {
        guard let activity = currentActivity else { return }
        
        print("🔴 LiveActivityManager: Ending current activity \(activity.id) (immediately: \(immediately))")
        
        // Clear completion flag
        isShowingCompletion = false
        
        // Stop monitoring
        LiveActivityMonitor.shared.stopMonitoring(activityId: activity.id)
        
        // Stop push updates
        LiveActivityPushService.shared.stopPushUpdates()
        
        let now = Date()
        _ = activity.content.state.currentElapsedTime
        
        // Check if activity is showing completion state
        if activity.content.state.isCompleted {
            // Activity is already ended with completion state, just clear reference
            print("⚠️ LiveActivityManager: Activity is already completed, clearing reference only")
            await MainActor.run {
                self.currentActivity = nil
            }
            // Clear App Group data
            AppGroupConstants.clearTimerState()
            return
        }
        
        // Create final state with simplified structure
        let finalState = TimerActivityAttributes.ContentState(
            startedAt: activity.content.state.startedAt,
            pausedAt: nil, // Not paused when ending
            duration: activity.content.state.duration,
            methodName: activity.content.state.methodName,
            sessionType: activity.content.state.sessionType,
            isCompleted: false,
            completionMessage: nil
        )
        
        if immediately {
            // Dismiss immediately when stop is pressed from Live Activity
            await activity.end(
                ActivityContent(state: finalState, staleDate: now),
                dismissalPolicy: .immediate
            )
            print("✅ LiveActivityManager: Activity dismissed immediately")
        } else {
            // Use dismissal policy with a 2 second delay for smoother UX
            let dismissalDate = now.addingTimeInterval(2)
            await activity.end(
                ActivityContent(state: finalState, staleDate: dismissalDate),
                dismissalPolicy: .after(dismissalDate)
            )
            print("✅ LiveActivityManager: Activity scheduled for dismissal at \(dismissalDate)")
        }
        
        await MainActor.run {
            self.currentActivity = nil
        }
        
        // Clear App Group data
        AppGroupConstants.clearTimerState()
        print("✅ LiveActivityManager: Cleared timer state from App Group")
    }
    
    func completeActivity(withMessage message: String? = nil) async {
        guard let activity = currentActivity else { return }
        
        print("✅ LiveActivityManager: Completing activity \(activity.id)")
        
        // Clear completion flag
        isShowingCompletion = false
        
        // Stop monitoring and push updates
        LiveActivityMonitor.shared.stopMonitoring(activityId: activity.id)
        LiveActivityPushService.shared.stopPushUpdates()
        
        let now = Date()
        _ = activity.content.state.currentElapsedTime
        
        // Create final state (not a completion state, just a normal ended state)
        // Create final state with simplified structure
        let finalState = TimerActivityAttributes.ContentState(
            startedAt: activity.content.state.startedAt,
            pausedAt: nil, // Not paused when ending
            duration: activity.content.state.duration,
            methodName: activity.content.state.methodName,
            sessionType: activity.content.state.sessionType,
            isCompleted: false,
            completionMessage: nil
        )
        
        // End the activity immediately
        await activity.end(
            ActivityContent(state: finalState, staleDate: now),
            dismissalPolicy: .immediate
        )
        print("✅ LiveActivityManager: Activity ended immediately")
        
        // Clear the current activity reference
        await MainActor.run {
            self.currentActivity = nil
        }
        
        // Clear App Group data
        AppGroupConstants.clearTimerState()
        print("✅ LiveActivityManager: Cleared timer state from App Group")
    }
    
    func endAllActivities() async {
        for activity in Activity<TimerActivityAttributes>.activities {
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: activity.content.state.startedAt,
                pausedAt: nil,
                duration: activity.content.state.duration,
                methodName: activity.content.state.methodName,
                sessionType: activity.content.state.sessionType,
                isCompleted: false,
                completionMessage: nil
            )
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        
        await MainActor.run {
            self.currentActivity = nil
        }
    }
    
    /// End any Live Activities with invalid timestamps
    func endCorruptedActivities() async {
        let now = Date()
        let maxReasonableAge: TimeInterval = 24 * 60 * 60 // 24 hours
        
        for activity in Activity<TimerActivityAttributes>.activities {
            let timeSinceStart = now.timeIntervalSince(activity.content.state.startedAt)
            
            if timeSinceStart > maxReasonableAge {
                print("🔧 LiveActivityManager: Ending corrupted activity")
                print("  - Activity ID: \(activity.id)")
                print("  - Invalid start time: \(activity.content.state.startedAt)")
                print("  - Time since start: \(timeSinceStart)s")
                
                let finalState = TimerActivityAttributes.ContentState(
                    startedAt: now.addingTimeInterval(-60), // Use a reasonable recent time
                    pausedAt: nil,
                    duration: 60, // Use 1 minute as a reasonable default
                    methodName: activity.content.state.methodName,
                    sessionType: activity.content.state.sessionType,
                    isCompleted: true,
                    completionMessage: "Session ended due to data corruption"
                )
                
                await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
                
                if activity.id == currentActivity?.id {
                    await MainActor.run {
                        self.currentActivity = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Push Notification Support
    
    private func registerForPushUpdates(activity: Activity<TimerActivityAttributes>) async {
        print("🔔 LiveActivityManager: Starting push token registration for activity \(activity.id)")
        print("🔔 LiveActivityManager: Activity state = \(activity.activityState)")
        
        // Check if app has notification permissions
        let notificationCenter = UNUserNotificationCenter.current()
        let settings = await notificationCenter.notificationSettings()
        print("🔔 LiveActivityManager: Notification auth status = \(settings.authorizationStatus.rawValue)")
        print("🔔 LiveActivityManager: Alert setting = \(settings.alertSetting.rawValue)")
        
        // Add timeout to prevent hanging if token never arrives
        let tokenTask = Task {
            var tokenReceived = false
            
            // First check notification permissions
            let notificationCenter = UNUserNotificationCenter.current()
            let settings = await notificationCenter.notificationSettings()
            print("📱 Notification auth status: \(settings.authorizationStatus.rawValue)")
            print("📱 Alert setting: \(settings.alertSetting.rawValue)")
            await MainActor.run {
                print("📱 iOS Version: \(UIDevice.current.systemVersion)")
                print("📱 Device Model: \(UIDevice.current.model)")
            }
            
            // Wait for push tokens
            if #available(iOS 16.2, *) {
                print("🔔 LiveActivityManager: Starting pushTokenUpdates async sequence...")
                print("🔔 Activity ID: \(activity.id)")
                print("🔔 Activity state: \(activity.activityState)")
                
                for await pushToken in activity.pushTokenUpdates {
                    tokenReceived = true
                    let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                    print("🎉 PUSH TOKEN RECEIVED! 🎉")
                    print("✅ Live Activity push token received: \(tokenString)")
                    print("✅ Token length: \(tokenString.count) characters")
                    print("✅ Activity ID: \(activity.id)")
                    print("✅ Timestamp: \(Date())")
                    
                    // Store the push token in Firestore
                    await storeLiveActivityPushToken(
                        activityId: activity.id,
                        pushToken: tokenString,
                        methodId: activity.attributes.methodId
                    )
                    
                    // Log success
                    print("🔔 Push token stored - push updates should begin shortly")
                    
                    // Continue listening for token updates (they can change)
                }
                print("ℹ️ LiveActivityManager: Push token updates stream ended for activity \(activity.id)")
                print("ℹ️ Token received: \(tokenReceived)")
            } else {
                print("⚠️ LiveActivityManager: Push token updates require iOS 16.2+")
                print("⚠️ Live Activity will have limited functionality without push updates")
            }
        }
        
        // Log if no token received after 5 seconds (informational only)
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if tokenTask.isCancelled == false {
                print("⚠️ LiveActivityManager: No push token received yet after 5 seconds")
                print("⚠️ This may be normal on simulator or if notifications are disabled")
                print("⚠️ Check that:")
                print("⚠️ - App has notification permissions")
                print("⚠️ - Live Activities are enabled in Settings")
                print("⚠️ - Not running on simulator (push tokens not available)")
                // Continue listening - token may arrive later
            }
        }
    }
    
    func storeLiveActivityPushToken(activityId: String, pushToken: String, methodId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user to store Live Activity push token")
            return
        }
        
        let db = Firestore.firestore()
        
        // Detect current environment to help with APNs routing
        // TEMPORARY: Force development environment for development APNs key
        let environment = FirebaseEnvironment.development // EnvironmentDetector.detectEnvironment()
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let widgetBundleId = "\(bundleId).GrowthTimerWidget"
        
        print("📦 Bundle IDs:")
        print("  - Main app: \(bundleId)")
        print("  - Widget: \(widgetBundleId)")
        print("  - Environment: \(environment.rawValue)")
        
        let data: [String: Any] = [
            "activityId": activityId,
            "pushToken": pushToken,
            "methodId": methodId,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "platform": "ios",
            "environment": environment.rawValue,
            "bundleId": bundleId,
            "widgetBundleId": widgetBundleId
        ]
        
        do {
            print("🔵 LiveActivityManager: Attempting to write to Firestore...")
            try await db.collection("liveActivityTokens").document(activityId).setData(data)
            print("✅ LiveActivityManager: Successfully stored Live Activity push token")
            print("  - Collection: liveActivityTokens")
            print("  - Document ID: \(activityId)")
            print("  - Data stored: \(data)")
            
            // Notify that push token is ready
            NotificationCenter.default.post(
                name: Notification.Name("LiveActivityPushTokenReady"),
                object: nil,
                userInfo: ["activityId": activityId, "userId": userId]
            )
        } catch {
            print("❌ LiveActivityManager: Failed to store Live Activity push token")
            print("  - Error: \(error)")
            print("  - Error details: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("  - Error code: \(firestoreError.code)")
                print("  - Error domain: \(firestoreError.domain)")
                
                // Check for App Check errors specifically
                if firestoreError.domain == "FIRFirestoreErrorDomain" && firestoreError.code == 7 {
                    print("  ⚠️ This appears to be an App Check error")
                    print("  ⚠️ The app may not be registered in Firebase Console")
                    print("  ⚠️ See FIREBASE_APP_CHECK_COMPLETE_FIX.md for instructions")
                    
                    #if DEBUG
                    // In debug, try to refresh the token
                    AppCheckDebugHelper.shared.refreshDebugToken()
                    #endif
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func debugPrintCurrentState() {
        print("🔍 ==== LIVE ACTIVITY DEBUG STATE =====")
        print("🔵 Current Activities:")
        
        let activities = Activity<TimerActivityAttributes>.activities
        print("  - Total activities: \(activities.count)")
        
        for (index, activity) in activities.enumerated() {
            print("\n  Activity \(index + 1):")
            print("    - ID: \(activity.id)")
            print("    - State: \(activity.activityState)")
            // pushType is only available in iOS 16.2+
            // if #available(iOS 16.2, *) {
            //     print("    - Push Type: \(String(describing: activity.pushType))")
            // }
            print("    - Content State:")
            print("      - isPaused: \(activity.content.state.isPaused)")
            print("      - sessionType: \(activity.content.state.sessionType)")
            print("      - methodName: \(activity.content.state.methodName)")
            print("      - startTime: \(activity.content.state.startTime)")
            print("      - endTime: \(activity.content.state.endTime)")
            let remaining = activity.content.state.endTime.timeIntervalSince(Date())
            print("      - remaining time: \(remaining)s")
        }
        
        if currentActivity != nil {
            print("\n✅ Current activity is set")
        } else {
            print("\n⚠️ No current activity set")
        }
        print("=====================================\n")
    }
    
    // Handle push notification actions
    func handlePushAction(_ action: String) {
        guard currentActivity != nil else { return }
        
        switch action {
        case "pause":
            updateActivity(isPaused: true)
        case "resume":
            updateActivity(isPaused: false)
        case "stop":
            Task {
                await endCurrentActivity()
            }
        default:
            break
        }
    }
    
}