// Fix for the race condition causing Live Activity pause state to be overwritten
// The issue: "GTMSessionFetcher...was already running" indicates concurrent updates

import Foundation
import ActivityKit
import Firebase

// SOLUTION 1: Add serial queue for Live Activity updates
@available(iOS 16.2, *)
extension LiveActivityManagerSimplified {
    // Create a serial queue to ensure updates happen one at a time
    private static let updateQueue = DispatchQueue(label: "com.growth.liveactivity.update", qos: .userInitiated)
    private static var pendingUpdate: DispatchWorkItem?
    
    // Modified pauseTimer with serial queue
    func pauseTimerFixed() async {
        // Cancel any pending updates
        Self.pendingUpdate?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task {
                await self.performPauseUpdate()
            }
        }
        
        Self.pendingUpdate = workItem
        
        // Execute on serial queue with small delay to debounce
        Self.updateQueue.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    private func performPauseUpdate() async {
        guard let activity = currentActivity else { return }
        
        let currentState = activity.content.state
        guard !currentState.isPaused else { return }
        
        Logger.info("📱 pauseTimer: Starting pause update")
        
        // Store pause state in App Group
        if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
            defaults.set(true, forKey: "timerPausedViaLiveActivity")
            defaults.set(Date(), forKey: "timerPauseTime")
            defaults.synchronize()
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
        
        // Update locally first
        await updateActivity(with: pausedState)
        
        // CRITICAL: Add delay before Firebase update to ensure local update completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Send push update
        await sendPushUpdate(contentState: pausedState, action: "pause")
    }
}

// SOLUTION 2: Modify sendPushUpdate to prevent concurrent calls
extension LiveActivityManagerSimplified {
    private static var activeUpdateTask: Task<Void, Never>?
    
    private func sendPushUpdateFixed(contentState: TimerActivityAttributes.ContentState, action: String) async {
        // Cancel any existing update task
        Self.activeUpdateTask?.cancel()
        
        // Create new task
        Self.activeUpdateTask = Task {
            // Add small delay to ensure Firestore write completes
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            guard !Task.isCancelled else { 
                Logger.info("⏭️ Update cancelled, skipping Firebase call")
                return 
            }
            
            guard let activity = currentActivity else { return }
            
            // Store state in Firestore
            await storeTimerStateInFirestore(
                activityId: activity.id,
                contentState: contentState,
                action: action
            )
            
            // Wait for Firestore write to complete
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            guard !Task.isCancelled else { 
                Logger.info("⏭️ Update cancelled before Firebase function")
                return 
            }
            
            // Trigger push via Firebase Function
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let functions = Functions.functions()
            let data: [String: Any] = [
                "activityId": activity.id,
                "userId": userId,
                "action": action == "pause" || action == "resume" ? "update" : action
            ]
            
            do {
                _ = try await functions.httpsCallable("updateLiveActivitySimplified").call(data)
                Logger.info("✅ Push update sent for \(action)")
            } catch {
                Logger.error("❌ Failed to send push update: \(error)")
            }
        }
        
        await Self.activeUpdateTask?.value
    }
}

// SOLUTION 3: Check for recent updates before sending
extension LiveActivityManagerSimplified {
    private static var lastUpdateTime: Date?
    private static let minimumUpdateInterval: TimeInterval = 1.0
    
    func shouldAllowUpdate() -> Bool {
        if let lastUpdate = Self.lastUpdateTime {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < Self.minimumUpdateInterval {
                Logger.info("⏳ Skipping update - only \(timeSinceLastUpdate)s since last update")
                return false
            }
        }
        Self.lastUpdateTime = Date()
        return true
    }
}

// SOLUTION 4: Verify state before sending update
extension LiveActivityManagerSimplified {
    private func verifyAndSendPushUpdate(contentState: TimerActivityAttributes.ContentState, action: String) async {
        guard let activity = currentActivity else { return }
        
        // Verify the current state matches what we're trying to update
        let currentActivityState = activity.content.state
        
        if action == "pause" && currentActivityState.pausedAt != nil {
            Logger.info("⚠️ Activity already paused, skipping update")
            return
        }
        
        if action == "resume" && currentActivityState.pausedAt == nil {
            Logger.info("⚠️ Activity not paused, skipping resume update")
            return
        }
        
        // Proceed with update
        await sendPushUpdate(contentState: contentState, action: action)
    }
}