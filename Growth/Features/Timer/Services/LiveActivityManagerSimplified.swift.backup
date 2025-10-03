//
//  LiveActivityManagerSimplified.swift
//  Growth
//
//  Simplified Live Activity manager following Apple best practices
//

import Foundation
import ActivityKit
import Combine

@available(iOS 16.2, *)
class LiveActivityManagerSimplified: ObservableObject {
    static let shared = LiveActivityManagerSimplified()
    
    @Published private(set) var currentActivity: Activity<TimerActivityAttributes>?
    private var pushTokenTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startTimerActivity(methodId: String, methodName: String, 
                          duration: TimeInterval, sessionType: SessionType,
                          timerType: String = "main") async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity
        await endCurrentActivity()
        
        let attributes = TimerActivityAttributes(
            methodId: methodId,
            timerType: timerType
        )
        
        let contentState = TimerActivityAttributes.ContentState(
            startedAt: Date(),
            pausedAt: nil,
            duration: duration,
            methodName: methodName,
            sessionType: sessionType
        )
        
        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: staleDate),
                pushType: .token
            )
            
            self.currentActivity = activity
            
            // Register push token
            pushTokenTask = Task {
                await registerPushToken(for: activity)
            }
            
            // Store in App Group for widget access
            storeStateInAppGroup(contentState: contentState, activityId: activity.id)
            
            print("Started Live Activity with ID: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func pauseTimer() async {
        guard let activity = currentActivity else { return }
        
        let currentState = activity.content.state
        let now = Date()
        
        // Calculate elapsed time (not used directly but logged)
        _ = now.timeIntervalSince(currentState.startedAt)
        
        // Create paused state
        let pausedState = TimerActivityAttributes.ContentState(
            startedAt: currentState.startedAt,
            pausedAt: now,
            duration: currentState.duration,
            methodName: currentState.methodName,
            sessionType: currentState.sessionType
        )
        
        // Update immediately via App Group
        storeStateInAppGroup(contentState: pausedState, activityId: activity.id)
        
        // Update Live Activity
        await updateActivity(with: pausedState)
    }
    
    func resumeTimer() async {
        guard let activity = currentActivity else { return }
        
        let currentState = activity.content.state
        guard let pausedAt = currentState.pausedAt else { return }
        
        // Calculate pause duration
        let pauseDuration = Date().timeIntervalSince(pausedAt)
        
        // Adjust start time to account for pause
        let adjustedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
        
        // Create resumed state
        let resumedState = TimerActivityAttributes.ContentState(
            startedAt: adjustedStartTime,
            pausedAt: nil,
            duration: currentState.duration,
            methodName: currentState.methodName,
            sessionType: currentState.sessionType
        )
        
        // Update immediately via App Group
        storeStateInAppGroup(contentState: resumedState, activityId: activity.id)
        
        // Update Live Activity
        await updateActivity(with: resumedState)
    }
    
    func stopTimer() async {
        await endCurrentActivity()
    }
    
    func updateProgress(_ progress: Double) async {
        // Not needed - native timer APIs handle progress automatically
    }
    
    func completeTimer() async {
        guard let activity = currentActivity else { return }
        
        let currentState = activity.content.state
        
        // Mark as completed
        let completedState = TimerActivityAttributes.ContentState(
            startedAt: currentState.startedAt,
            pausedAt: Date(), // Pause at completion
            duration: currentState.duration,
            methodName: currentState.methodName,
            sessionType: currentState.sessionType
        )
        
        // Update with completion state
        await updateActivity(with: completedState)
        
        // Dismiss after delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await endCurrentActivity()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateActivity(with contentState: TimerActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }
        
        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        
        await activity.update(
            ActivityContent(state: contentState, staleDate: staleDate)
        )
    }
    
    private func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        // Clean up App Group storage
        if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            defaults.removeObject(forKey: "timerActivityState_\(activity.id)")
            defaults.removeObject(forKey: "currentTimerActivityId")
        }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        self.currentActivity = nil
        
        // Cancel push token task
        pushTokenTask?.cancel()
        pushTokenTask = nil
    }
    
    private func registerPushToken(for activity: Activity<TimerActivityAttributes>) async {
        for await pushToken in activity.pushTokenUpdates {
            let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
            
            // Update Firestore with push token
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                await updatePushTokenInFirestore(
                    userId: userId,
                    activityId: activity.id,
                    pushToken: tokenString,
                    timerType: activity.attributes.timerType
                )
            }
        }
    }
    
    private func updatePushTokenInFirestore(userId: String, activityId: String, 
                                          pushToken: String, timerType: String) async {
        // This would be implemented using FirebaseService
        // For now, just log
        print("Would update push token in Firestore:")
        print("  User ID: \(userId)")
        print("  Activity ID: \(activityId)")
        print("  Push Token: \(pushToken)")
        print("  Timer Type: \(timerType)")
    }
    
    private func storeStateInAppGroup(contentState: TimerActivityAttributes.ContentState, 
                                    activityId: String) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) else {
            return
        }
        
        // Store current activity ID
        defaults.set(activityId, forKey: "currentTimerActivityId")
        
        // Store state data
        let stateData: [String: Any] = [
            "startedAt": contentState.startedAt.timeIntervalSince1970,
            "pausedAt": contentState.pausedAt?.timeIntervalSince1970 as Any,
            "duration": contentState.duration,
            "methodName": contentState.methodName,
            "sessionType": contentState.sessionType.rawValue,
            "isPaused": contentState.isPaused
        ]
        
        defaults.set(stateData, forKey: "timerActivityState_\(activityId)")
        
        // Store recent pause state for race condition prevention
        if contentState.isPaused {
            defaults.set(true, forKey: "timerPausedViaLiveActivity")
            defaults.set(Date(), forKey: "timerPauseTime")
        } else {
            defaults.removeObject(forKey: "timerPausedViaLiveActivity")
            defaults.removeObject(forKey: "timerPauseTime")
        }
    }
    
    // MARK: - Helper Methods
    
    func hasActiveTimer() -> Bool {
        currentActivity != nil
    }
    
    func getCurrentState() -> TimerActivityAttributes.ContentState? {
        currentActivity?.content.state
    }
    
    func getElapsedTime() -> TimeInterval {
        guard let state = getCurrentState() else { return 0 }
        
        if let pausedAt = state.pausedAt {
            return pausedAt.timeIntervalSince(state.startedAt)
        } else {
            return Date().timeIntervalSince(state.startedAt)
        }
    }
    
    func getRemainingTime() -> TimeInterval {
        guard let state = getCurrentState() else { return 0 }
        
        if state.sessionType == .countdown {
            return max(0, state.duration - getElapsedTime())
        }
        return 0
    }
}