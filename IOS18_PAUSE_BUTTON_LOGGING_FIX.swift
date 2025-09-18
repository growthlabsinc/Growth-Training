// Enhanced logging to debug iOS 18+ Live Activity pause button issue
// Add this to LiveActivityManagerSimplified.swift

import Foundation
import ActivityKit
import Firebase

// Update the pauseTimer method with enhanced logging
func pauseTimer() async {
    guard let activity = currentActivity else { 
        Logger.error("❌ pauseTimer: No current activity")
        return 
    }
    
    let currentState = activity.content.state
    Logger.info("📱 pauseTimer: Current state - isPaused: \(currentState.isPaused), pausedAt: \(String(describing: currentState.pausedAt))")
    
    guard !currentState.isPaused else { 
        Logger.info("⚠️ pauseTimer: Already paused, skipping")
        return 
    }
    
    // Store pause state in App Group immediately to prevent race conditions
    if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
        defaults.set(true, forKey: "timerPausedViaLiveActivity")
        defaults.set(Date(), forKey: "timerPauseTime")
        defaults.synchronize()
        Logger.info("📱 pauseTimer: Stored pause state in App Group")
    }
    
    // Create paused state
    let now = Date()
    let pausedState = TimerActivityAttributes.ContentState(
        startedAt: currentState.startedAt,
        pausedAt: now,
        duration: currentState.duration,
        methodName: currentState.methodName,
        sessionType: currentState.sessionType,
        isCompleted: false,
        completionMessage: nil
    )
    
    Logger.info("📱 pauseTimer: Created pausedState with pausedAt: \(now)")
    
    // Update locally for immediate feedback
    Logger.info("📱 pauseTimer: Updating activity locally...")
    await updateActivity(with: pausedState)
    Logger.info("📱 pauseTimer: Local update complete")
    
    // Log state before sending to Firebase
    Logger.info("📱 pauseTimer: Sending to Firebase - pausedAt: \(String(describing: pausedState.pausedAt))")
    
    // Send push update
    await sendPushUpdate(contentState: pausedState, action: "pause")
    Logger.info("📱 pauseTimer: Push update sent")
}

// Update the storeTimerStateInFirestore method with logging
private func storeTimerStateInFirestore(
    activityId: String,
    contentState: TimerActivityAttributes.ContentState,
    action: String
) async {
    guard let userId = Auth.auth().currentUser?.uid else { 
        Logger.error("❌ storeTimerStateInFirestore: No user ID")
        return 
    }
    
    Logger.info("📱 storeTimerStateInFirestore: Storing state for action '\(action)'")
    Logger.info("   - pausedAt: \(String(describing: contentState.pausedAt))")
    Logger.info("   - isPaused: \(contentState.isPaused)")
    
    let stateData: [String: Any] = [
        "startedAt": Timestamp(date: contentState.startedAt),
        "pausedAt": contentState.pausedAt != nil ? Timestamp(date: contentState.pausedAt!) : NSNull(),
        "duration": contentState.duration,
        "methodName": contentState.methodName,
        "sessionType": contentState.sessionType.rawValue,
        "isCompleted": contentState.isCompleted
    ]
    
    // Log the actual data being stored
    Logger.info("   - Firestore pausedAt value: \(contentState.pausedAt != nil ? "Timestamp(\(contentState.pausedAt!))" : "NSNull")")
    
    let data: [String: Any] = [
        "activityId": activityId,
        "userId": userId,
        "contentState": stateData,
        "action": action,
        "updatedAt": FieldValue.serverTimestamp()
    ]
    
    do {
        try await Firestore.firestore()
            .collection("liveActivityTimerStates")
            .document(activityId)
            .setData(data)
        Logger.info("✅ storeTimerStateInFirestore: Successfully stored state")
    } catch {
        Logger.error("❌ storeTimerStateInFirestore: Failed to store timer state: \(error)")
    }
}

// Add a method to check Live Activity state
func debugCurrentActivityState() {
    guard let activity = currentActivity else {
        Logger.info("🔍 Debug: No current activity")
        return
    }
    
    let state = activity.content.state
    Logger.info("🔍 Debug Live Activity State:")
    Logger.info("   - Activity ID: \(activity.id)")
    Logger.info("   - isPaused: \(state.isPaused)")
    Logger.info("   - pausedAt: \(String(describing: state.pausedAt))")
    Logger.info("   - startedAt: \(state.startedAt)")
    Logger.info("   - duration: \(state.duration)")
    Logger.info("   - methodName: \(state.methodName)")
    Logger.info("   - sessionType: \(state.sessionType)")
}

// Call this method periodically or after pause to debug
// Example: Add to TimerService after pause() is called:
// if #available(iOS 16.2, *) {
//     LiveActivityManagerSimplified.shared.debugCurrentActivityState()
// }