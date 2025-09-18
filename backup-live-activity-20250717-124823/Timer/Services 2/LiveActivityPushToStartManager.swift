//
//  LiveActivityPushToStartManager.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import ActivityKit
import FirebaseFirestore
import FirebaseAuth

/// Manages push-to-start tokens for Live Activities (iOS 17.2+)
@available(iOS 17.2, *)
class LiveActivityPushToStartManager {
    static let shared = LiveActivityPushToStartManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Register for push-to-start token
    func registerForPushToStart() async {
        // Note: Push-to-start requires iOS 17.2+ and specific API that may not be available yet
        // Commenting out for now until proper API is available
        
        print("ℹ️ LiveActivityPushToStartManager: Push-to-start registration is not yet implemented")
        print("   This feature requires iOS 17.2+ and ActivityKit push-to-start API")
        
        // TODO: Implement when push-to-start API is properly documented
        /*
        do {
            // Request push-to-start token
            let pushToStartTokenData = try await Activity<TimerActivityAttributes>.pushToStartToken
            let tokenString = pushToStartTokenData.map { String(format: "%02x", $0) }.joined()
            
            print("✅ LiveActivityPushToStartManager: Push-to-start token received: \(tokenString)")
            
            // Store the token in Firestore
            await storePushToStartToken(tokenString)
            
            // Monitor for token updates
            Task {
                for await pushTokenData in Activity<TimerActivityAttributes>.pushToStartTokenUpdates {
                    let updatedTokenString = pushTokenData.map { String(format: "%02x", $0) }.joined()
                    print("🔄 LiveActivityPushToStartManager: Push-to-start token updated: \(updatedTokenString)")
                    await storePushToStartToken(updatedTokenString)
                }
            }
        } catch {
            print("❌ LiveActivityPushToStartManager: Failed to get push-to-start token - \(error)")
            
            // If the error is because the user hasn't enabled Live Activities, we should inform them
            if error.localizedDescription.contains("not enabled") {
                print("ℹ️ User needs to enable Live Activities in Settings")
            }
        }
        */
    }
    
    /// Store push-to-start token in Firestore
    private func storePushToStartToken(_ token: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ LiveActivityPushToStartManager: No authenticated user")
            return
        }
        
        let data: [String: Any] = [
            "liveActivityPushToStartToken": token,
            "tokenUpdatedAt": FieldValue.serverTimestamp(),
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        do {
            try await db.collection("users").document(userId).setData(data, merge: true)
            print("✅ LiveActivityPushToStartManager: Push-to-start token stored successfully")
        } catch {
            print("❌ LiveActivityPushToStartManager: Failed to store push-to-start token - \(error)")
        }
    }
    
    /// Remove push-to-start token (when user signs out or disables feature)
    func removePushToStartToken() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "liveActivityPushToStartToken": FieldValue.delete(),
            "tokenUpdatedAt": FieldValue.delete()
        ]
        
        do {
            try await db.collection("users").document(userId).updateData(data)
            print("✅ LiveActivityPushToStartManager: Push-to-start token removed")
        } catch {
            print("❌ LiveActivityPushToStartManager: Failed to remove push-to-start token - \(error)")
        }
    }
    
    /// Check if push-to-start is available
    static var isPushToStartAvailable: Bool {
        if #available(iOS 17.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
    
    /// Request Live Activities permission if needed
    static func requestLiveActivitiesPermission() {
        // Live Activities don't have a direct permission request API
        // Users must enable them in Settings
        // We can show an alert directing them to Settings if needed
        print("ℹ️ LiveActivityPushToStartManager: Live Activities must be enabled in Settings > [App Name]")
    }
}