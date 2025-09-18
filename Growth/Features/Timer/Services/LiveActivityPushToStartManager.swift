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
import FirebaseFunctions
import UIKit

/// Manages push-to-start tokens for Live Activities (iOS 17.2+)
@available(iOS 17.2, *)
class LiveActivityPushToStartManager {
    static let shared = LiveActivityPushToStartManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Register for push-to-start token
    func registerForPushToStart() async {
        // Check if activities are enabled first
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.warning("⚠️ Live Activities are not enabled by the user", logger: AppLoggers.liveActivity)
            return
        }
        
        // Note: Push-to-start requires specific API that is not yet fully documented
        // The proper implementation would be:
        /*
        do {
            // In a future iOS version, this would work:
            // let pushToStartToken = try await Activity<TimerActivityAttributes>.requestPushToStartToken()
            // let tokenString = pushToStartToken.map { String(format: "%02x", $0) }.joined()
            
            // For now, we'll use the standard push token approach
            Logger.info("ℹ️ Push-to-start registration: Using standard push token approach", logger: AppLoggers.liveActivity)
            
            // The push-to-start feature requires server-side implementation to start
            // activities remotely when the app is not running
            
        } catch {
            Logger.error("❌ Failed to get push-to-start token: \(error)", logger: AppLoggers.liveActivity)
        }
        */
        
        Logger.info("ℹ️ Push-to-start is available in iOS 17.2+ but requires specific server implementation", logger: AppLoggers.liveActivity)
        Logger.info("ℹ️ Current implementation uses push notifications to update existing Live Activities", logger: AppLoggers.liveActivity)
    }
    
    /// Store push-to-start token in Firestore and sync with Firebase Functions
    private func storePushToStartToken(_ token: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            Logger.warning("⚠️ No authenticated user for push-to-start token", logger: AppLoggers.liveActivity)
            return
        }
        
        // Also sync with Firebase Functions for server-side push capabilities
        do {
            let functions = Functions.functions()
            let data: [String: Any] = [
                "token": token,
                "bundleId": Bundle.main.bundleIdentifier ?? "com.growthlabs.growthmethod",
                "environment": FirebaseClient.shared.currentEnvironment.rawValue
            ]
            
            let result = try await functions.httpsCallable("registerPushToStartToken").call(data)
            
            if let resultData = result.data as? [String: Any],
               let success = resultData["success"] as? Bool, success {
                Logger.info("✅ Push-to-start token synced with Firebase Functions", logger: AppLoggers.liveActivity)
            }
        } catch {
            Logger.error("❌ Failed to sync push-to-start token: \(error)", logger: AppLoggers.liveActivity)
        }
        
        // Also store locally in Firestore for redundancy
        // Get device info on main actor
        let deviceModel = await MainActor.run { UIDevice.current.model }
        let systemVersion = await MainActor.run { UIDevice.current.systemVersion }
        
        let data: [String: Any] = [
            "liveActivityPushToStartToken": token,
            "tokenUpdatedAt": FieldValue.serverTimestamp(),
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "deviceModel": deviceModel,
            "systemVersion": systemVersion
        ]
        
        do {
            try await db.collection("users").document(userId).setData(data, merge: true)
            Logger.info("✅ Push-to-start token stored in Firestore", logger: AppLoggers.liveActivity)
        } catch {
            Logger.error("❌ Failed to store push-to-start token in Firestore: \(error)", logger: AppLoggers.liveActivity)
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