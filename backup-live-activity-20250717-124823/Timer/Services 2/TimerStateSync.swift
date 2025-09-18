import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import ActivityKit

/// Service to synchronize timer state with Firestore for Live Activity push updates
class TimerStateSync {
    static let shared = TimerStateSync()
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private var timerStateListener: ListenerRegistration?
    
    private init() {}
    
    /// Start syncing timer state to Firestore with simplified structure
    func startSyncing(
        activityId: String,
        methodId: String,
        methodName: String,
        startedAt: Date,
        duration: TimeInterval,
        sessionType: String,
        isPaused: Bool,
        pausedAt: Date? = nil
    ) {
        print("🔄 TimerStateSync: startSyncing called")
        print("  - Activity ID: \(activityId)")
        print("  - Method: \(methodName) (\(methodId))")
        print("  - Session type: \(sessionType)")
        print("  - Is paused: \(isPaused)")
        print("  - Started at: \(startedAt)")
        print("  - Duration: \(duration)s")
        print("  - Paused at: \(String(describing: pausedAt))")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ TimerStateSync: No authenticated user to sync timer state")
            return
        }
        print("✅ TimerStateSync: User authenticated: \(userId)")
        
        // Use simplified content state format
        let now = Date()
        
        // Create simplified content state for Firebase
        var contentState: [String: Any] = [
            "startedAt": Timestamp(date: startedAt),
            "duration": duration,
            "methodName": methodName,
            "sessionType": sessionType,
            "isPaused": isPaused
        ]
        
        // Include pausedAt if paused
        if let pausedAt = pausedAt {
            contentState["pausedAt"] = Timestamp(date: pausedAt)
        }
        
        // Add legacy fields for backward compatibility  
        contentState["startTime"] = Timestamp(date: startedAt)
        contentState["endTime"] = Timestamp(date: startedAt.addingTimeInterval(duration))
        contentState["lastUpdateTime"] = Timestamp(date: now)
        
        let data: [String: Any] = [
            "activityId": activityId,
            "methodId": methodId,
            "contentState": contentState,
            "userId": userId,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Update timer state in Firestore
        print("🔄 TimerStateSync: Writing to Firestore activeTimers/\(userId)")
        print("  - Data: \(data)")
        
        db.collection("activeTimers").document(userId).setData(data, merge: true) { error in
            if let error = error {
                print("❌ TimerStateSync: Failed to sync timer state")
                print("  - Error: \(error)")
                print("  - Error details: \(error.localizedDescription)")
                if let firestoreError = error as NSError? {
                    print("  - Error code: \(firestoreError.code)")
                    print("  - Error domain: \(firestoreError.domain)")
                }
            } else {
                print("✅ TimerStateSync: Timer state synced successfully to activeTimers/\(userId)")
            }
        }
    }
    
    /// Update timer pause state with simplified approach
    func updatePauseState(isPaused: Bool, pausedAt: Date? = nil, adjustedStartedAt: Date? = nil) {
        print("🔄 TimerStateSync: updatePauseState called with isPaused = \(isPaused)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ TimerStateSync: No authenticated user for pause state update")
            return
        }
        print("✅ TimerStateSync: Updating pause state for user: \(userId)")
        
        // Use setData with merge to ensure document exists
        var updateData: [String: Any] = [
            "contentState.isPaused": isPaused,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if isPaused {
            // When pausing, store pausedAt timestamp
            if let pausedAt = pausedAt {
                updateData["contentState.pausedAt"] = Timestamp(date: pausedAt)
                print("  - Setting pausedAt: \(pausedAt)")
            }
        } else {
            // When resuming, clear pausedAt and update startedAt if adjusted
            updateData["contentState.pausedAt"] = FieldValue.delete()
            
            if let adjustedStartedAt = adjustedStartedAt {
                updateData["contentState.startedAt"] = Timestamp(date: adjustedStartedAt)
                print("  - Updating startedAt to adjusted value: \(adjustedStartedAt)")
                
                // Also update legacy fields for compatibility
                updateData["contentState.startTime"] = Timestamp(date: adjustedStartedAt)
            }
        }
        
        print("🔄 TimerStateSync: Writing pause state to activeTimers/\(userId)")
        print("  - Update data: \(updateData)")
        
        db.collection("activeTimers").document(userId).setData(updateData, merge: true) { error in
            if let error = error {
                print("❌ TimerStateSync: Failed to update pause state")
                print("  - Error: \(error)")
                print("  - Error details: \(error.localizedDescription)")
            } else {
                print("✅ TimerStateSync: Timer pause state updated successfully")
                print("  - isPaused = \(isPaused)")
                print("  - Document: activeTimers/\(userId)")
            }
        }
    }
    
    /// Update timer end time (for countdown adjustments)
    func updateEndTime(newEndTime: Date) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Use setData with merge to ensure document exists
        db.collection("activeTimers").document(userId).setData([
            "contentState.endTime": Timestamp(date: newEndTime),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Failed to update end time: \(error)")
            } else {
                print("Timer end time updated")
            }
        }
    }
    
    /// Force a sync update to trigger push notification
    func forceSyncUpdate(activityId: String) {
        print("🔄 TimerStateSync: forceSyncUpdate called for activity: \(activityId)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ TimerStateSync: No authenticated user for force sync")
            return
        }
        
        // Update the timestamp to trigger Firestore change and push notification
        let updateData: [String: Any] = [
            "forcedUpdate": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        print("🔄 TimerStateSync: Writing forced update to activeTimers/\(userId)")
        db.collection("activeTimers").document(userId).setData(updateData, merge: true) { error in
            if let error = error {
                print("❌ TimerStateSync: Failed to force sync update: \(error)")
            } else {
                print("✅ TimerStateSync: Forced sync update completed successfully")
                
                // Also trigger a cloud function call for immediate push
                self.sendLiveActivityUpdate(activityId: activityId, action: "update")
            }
        }
    }
    
    /// Stop syncing and clean up
    func stopSyncing() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove the active timer document
        db.collection("activeTimers").document(userId).delete { error in
            if let error = error {
                print("Failed to delete timer state: \(error)")
            }
        }
        
        // Remove any listeners
        timerStateListener?.remove()
        timerStateListener = nil
    }
    
    /// Call cloud function to update Live Activity via push
    func sendLiveActivityUpdate(activityId: String, action: String, endTime: Date? = nil) {
        var data: [String: Any] = [
            "activityId": activityId,
            "action": action
        ]
        
        if let endTime = endTime {
            data["endTime"] = endTime.timeIntervalSince1970 * 1000 // Convert to milliseconds
        }
        
        functions.httpsCallable("updateLiveActivityTimer").call(data) { result, error in
            if let error = error {
                print("Failed to send Live Activity update: \(error)")
            } else {
                print("Live Activity update sent successfully: \(String(describing: result?.data))")
            }
        }
    }
    
    /// Listen for external timer state changes (e.g., from other devices)
    func startListeningForStateChanges(completion: @escaping (TimerActivityAttributes.ContentState?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        timerStateListener = db.collection("activeTimers").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot,
                      document.exists,
                      let data = document.data(),
                      let contentStateData = data["contentState"] as? [String: Any] else {
                    completion(nil)
                    return
                }
                
                // Parse content state
                if let startTimeStamp = contentStateData["startTime"] as? Timestamp,
                   let endTimeStamp = contentStateData["endTime"] as? Timestamp,
                   let methodName = contentStateData["methodName"] as? String,
                   let sessionTypeStr = contentStateData["sessionType"] as? String,
                   let isPaused = contentStateData["isPaused"] as? Bool {
                    
                    let sessionType = TimerActivityAttributes.ContentState.SessionType(rawValue: sessionTypeStr) ?? .countup
                    
                    let contentState = TimerActivityAttributes.ContentState(
                        startTime: startTimeStamp.dateValue(),
                        endTime: endTimeStamp.dateValue(),
                        methodName: methodName,
                        sessionType: sessionType,
                        isPaused: isPaused
                    )
                    
                    completion(contentState)
                }
            }
    }
}