import Foundation
import UIKit
import FirebaseFunctions
import ActivityKit

/// Service that manages push notification updates for Live Activities
@available(iOS 16.2, *)
class LiveActivityPushUpdateService {
    static let shared = LiveActivityPushUpdateService()
    
    private var updateTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let functions = Functions.functions()
    
    private init() {}
    
    /// Start periodic push updates for a Live Activity
    func startPushUpdates(for activityId: String, updateInterval: TimeInterval = 30.0) {
        print("🔔 LiveActivityPushUpdateService: Starting push updates for activity \(activityId)")
        print("  - Update interval: \(updateInterval)s")
        
        // Cancel any existing timer
        stopPushUpdates()
        
        // Start background task to keep timer running
        startBackgroundTask()
        
        // Send immediate update
        sendPushUpdate(activityId: activityId)
        
        // Schedule periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.sendPushUpdate(activityId: activityId)
        }
        
        // Make sure timer runs in common modes
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
    
    /// Stop push updates
    func stopPushUpdates() {
        print("🛑 LiveActivityPushUpdateService: Stopping push updates")
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        endBackgroundTask()
    }
    
    /// Send a push update for the Live Activity
    private func sendPushUpdate(activityId: String) {
        print("📤 LiveActivityPushUpdateService: Sending push update for activity \(activityId)")
        
        // Check if activity still exists
        guard let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }),
              activity.activityState == .active else {
            print("⚠️ LiveActivityPushUpdateService: Activity not found or not active")
            stopPushUpdates()
            return
        }
        
        // Don't send updates if paused
        if activity.content.state.pausedAt != nil {
            print("⏸ LiveActivityPushUpdateService: Activity is paused, skipping update")
            return
        }
        
        Task {
            do {
                // Calculate end time for countdown timer (always countdown in this app)
                let endTimeDate = activity.content.state.startedAt.addingTimeInterval(activity.content.state.duration)
                let endTime = ISO8601DateFormatter().string(from: endTimeDate)
                
                // Call Firebase function to send push update
                let data: [String: Any] = [
                    "activityId": activityId,
                    "action": "update",
                    "endTime": endTime
                ]
                
                let result = try await functions.httpsCallable("updateLiveActivityTimer").call(data)
                
                if let responseData = result.data as? [String: Any],
                   let success = responseData["success"] as? Bool,
                   success {
                    print("✅ LiveActivityPushUpdateService: Push update sent successfully")
                } else {
                    print("❌ LiveActivityPushUpdateService: Push update failed")
                }
            } catch {
                print("❌ LiveActivityPushUpdateService: Error sending push update - \(error)")
                
                // If we get authentication errors, stop updates
                if (error as NSError).domain == "com.firebase.functions" {
                    stopPushUpdates()
                }
            }
        }
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⚠️ LiveActivityPushUpdateService: Background task expiring")
            self?.endBackgroundTask()
        }
        
        print("✅ LiveActivityPushUpdateService: Background task started")
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        print("✅ LiveActivityPushUpdateService: Background task ended")
    }
}