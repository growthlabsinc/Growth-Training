import Foundation
import ActivityKit
import Firebase
import FirebaseFunctions

/// Handles actions triggered from Live Activity buttons via push notifications
@available(iOS 16.2, *)
class LiveActivityActionHandler {
    static let shared = LiveActivityActionHandler()
    
    private let functions = Functions.functions()
    
    private init() {}
    
    /// Handle action from Live Activity button tap
    /// This is called when the app launches from a Live Activity button
    func handleAction(from url: URL) {
        guard url.scheme == "growth",
              url.host == "timer",
              let action = url.pathComponents.last else {
            print("Invalid Live Activity action URL: \(url)")
            return
        }
        
        // Get the current activity ID
        guard let activityId = LiveActivityManager.shared.currentActivityId else {
            print("No active Live Activity to handle action")
            return
        }
        
        // Instead of handling locally, send to cloud function for push update
        sendActionToCloud(activityId: activityId, action: action)
    }
    
    /// Send action to Firebase Cloud Function for push-based update
    private func sendActionToCloud(activityId: String, action: String) {
        let data: [String: Any] = [
            "activityId": activityId,
            "action": action
        ]
        
        functions.httpsCallable("updateLiveActivityTimer").call(data) { result, error in
            if let error = error {
                print("Failed to send Live Activity action to cloud: \(error)")
                
                // Fallback to local handling
                self.handleActionLocally(action: action)
            } else {
                print("Live Activity action sent to cloud successfully: \(action)")
            }
        }
    }
    
    /// Fallback to handle action locally if cloud function fails
    private func handleActionLocally(action: String) {
        // For Live Activity actions, we're handling the main timer
        let userInfo = [Notification.Name.TimerUserInfoKey.timerType: Notification.Name.TimerType.main.rawValue]
        
        switch action {
        case "pause", "resume":
            NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
        case "stop":
            NotificationCenter.default.post(name: .timerStopRequested, object: nil, userInfo: userInfo)
        default:
            break
        }
    }
    
    /// Register for Live Activity push token updates
    static func registerForPushTokenUpdates() {
        Task {
            // Iterate through all active Live Activities
            for activity in Activity<TimerActivityAttributes>.activities {
                // Listen for push token updates
                for await pushToken in activity.pushTokenUpdates {
                    let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                    print("Live Activity push token: \(tokenString)")
                    
                    // Store or update the token as needed
                    await storePushToken(for: activity.id, token: tokenString)
                }
            }
        }
    }
    
    private static func storePushToken(for activityId: String, token: String) async {
        // This is already handled in LiveActivityManager
        // But we can add additional logic here if needed
    }
}