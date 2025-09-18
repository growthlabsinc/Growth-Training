import Foundation
import ActivityKit
import FirebaseFirestore
import FirebaseAuth

/// Manages Live Activity updates through Firestore triggers
@available(iOS 16.1, *)
class LiveActivityPushManager {
    static let shared = LiveActivityPushManager()
    
    private let db = Firestore.firestore()
    private var updateTimer: Timer?
    
    private init() {}
    
    /// Start periodic updates by writing to Firestore
    /// This triggers the onTimerStateChange function which sends push notifications
    func startPeriodicUpdates(for activityId: String, interval: TimeInterval = 30.0) {
        print("🔔 LiveActivityPushManager: Starting periodic Firestore updates")
        print("  - Activity ID: \(activityId)")
        print("  - Update interval: \(interval)s")
        
        // Stop any existing timer
        stopPeriodicUpdates()
        
        // Start periodic timer to update Firestore
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerFirestoreUpdate(activityId: activityId)
        }
        
        // Trigger immediate update
        triggerFirestoreUpdate(activityId: activityId)
    }
    
    /// Stop periodic updates
    func stopPeriodicUpdates() {
        print("🛑 LiveActivityPushManager: Stopping periodic updates")
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Trigger a Firestore update which will cause push notification
    private func triggerFirestoreUpdate(activityId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ LiveActivityPushManager: No authenticated user")
            return
        }
        
        // Check if activity still exists
        guard let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }),
              activity.activityState == .active else {
            print("⚠️ LiveActivityPushManager: Activity not found or not active")
            stopPeriodicUpdates()
            return
        }
        
        print("📤 LiveActivityPushManager: Triggering Firestore update")
        
        // Update a timestamp field to trigger onTimerStateChange
        let updateData: [String: Any] = [
            "lastPushUpdate": FieldValue.serverTimestamp(),
            "pushUpdateCount": FieldValue.increment(Int64(1))
        ]
        
        // Use setData with merge to ensure document exists
        db.collection("activeTimers").document(userId).setData(updateData, merge: true) { error in
            if let error = error {
                print("❌ LiveActivityPushManager: Failed to update Firestore - \(error)")
            } else {
                print("✅ LiveActivityPushManager: Firestore updated, push notification will be triggered")
            }
        }
    }
}