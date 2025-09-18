//
//  AppDelegate.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import UserNotifications
import FirebaseAuth
import GoogleSignIn
import SwiftUI
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    // Configure Firebase as early as possible
    override init() {
        super.init()
        // Configure Firebase immediately on AppDelegate init
        if FirebaseApp.app() == nil {
            let environment = EnvironmentDetector.detectEnvironment()
            _ = FirebaseClient.shared.configure(for: environment)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase should already be configured in init()
        // This is a safety check
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.info("⚠️ Firebase configured in didFinishLaunchingWithOptions (should have been done in init)")
        }

        // Set up Firebase Messaging delegate after Firebase is configured
        Messaging.messaging().delegate = self
        
        // Initialize Firebase-dependent services
        _ = NotificationsManager.shared
        _ = StreakTracker.shared
        
        // Initialize TimerIntentObserver to listen for Darwin notifications from Live Activity
        _ = TimerIntentObserver.shared
        
        // Clean up any stale pending timer completion data on app launch
        if let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") {
            if let completionData = sharedDefaults.dictionary(forKey: "pendingTimerCompletion"),
               let timestamp = completionData["timestamp"] as? TimeInterval {
                let dataAge = Date().timeIntervalSince1970 - timestamp
                // Clear data older than 60 seconds on app launch
                if dataAge > 60 {
                    Logger.info("🧹 AppDelegate: Clearing stale pending timer completion data (age: \(dataAge)s)")
                    sharedDefaults.removeObject(forKey: "pendingTimerCompletion")
                    sharedDefaults.synchronize()
                }
            }
        }
        
        // Load compliance configuration
        ComplianceConfigurationService.shared.loadComplianceConfiguration()
        
        // Register for remote notifications - required for FCM
        application.registerForRemoteNotifications()
        
        // Set up UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization (This will prompt the user)
        requestNotificationAuthorization(application)
        
        // Register background tasks for Live Activity updates
        if #available(iOS 16.2, *) {
            LiveActivityBackgroundTaskManager.shared.registerBackgroundTasks()
        }
        
        // Register for push-to-start if available
        if #available(iOS 17.2, *) {
            Task {
                await LiveActivityPushToStartManager.shared.registerForPushToStart()
            }
        }
        
        return true
    }
    
    // MARK: - Google Sign-In
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Remote Notification Handling
    
    // This function is called when a new FCM token is generated
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.debug("Firebase registration token: \(String(describing: fcmToken))")
        
        // Forward to NotificationsManager
        if let token = fcmToken, let userId = Auth.auth().currentUser?.uid {
            NotificationsManager.shared.storeTokenInFirestore(userId: userId, token: token)
        }
        
        // If you want to use the FCM token for custom notifications, you can save it here
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    // This function is called when the app receives a notification when it's in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Extract notification data
        let userInfo = notification.request.content.userInfo
        
        // If it's a Firebase message, let FCM handle it
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Log analytics data
        NotificationsManager.shared.logNotificationReceived(userInfo: userInfo)
        
        // We recommend showing the notification alert even when the app is in the foreground
        completionHandler([[.banner, .sound]])
    }
    
    // This function is called when a user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Logger.debug("Notification tapped with user info: \(userInfo)")
        
        // Log that the user interacted with the notification
        NotificationsManager.shared.logNotificationTapped(userInfo: userInfo)
        
        // Handle the notification's action here
        NotificationsManager.shared.handleNotificationResponse(response)
        
        completionHandler()
    }
    
    // This function is called when a remote notification is received
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the FCM message
        Logger.debug("Remote notification received: \(userInfo)")
        
        // Let FCM handle the message for analytics and features like auto-init
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        completionHandler(.newData)
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward the token to FCM for registration
        Messaging.messaging().apnsToken = deviceToken
        
        // Also pass device token to NotificationsManager
        NotificationsManager.shared.updateDeviceToken(deviceToken)
    }
    
    // Called if registration for remote notifications fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.error("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Private Helpers
    
    private func requestNotificationAuthorization(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                Logger.debug("Notification authorization granted")
            } else {
                Logger.debug("Notification authorization denied")
            }
            
            if let error = error {
                Logger.error("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    // MARK: - Firebase Diagnosis
    
    private func diagnoseFacebookConfigurationIssue() {
        // Check bundle identifier
        let bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
        Logger.debug("App Bundle ID: \(bundleID)")
        
        // Check Firebase configuration files
        let configFiles = [
            "dev.GoogleService-Info.plist",
            "staging.GoogleService-Info.plist",
            "GoogleService-Info.plist"
        ]
        
        for configFile in configFiles {
            if let path = Bundle.main.path(forResource: configFile, ofType: nil) {
                Logger.debug("Found configuration file: \(configFile)")
                
                // Try to check bundle ID in the config file
                if let dict = NSDictionary(contentsOfFile: path),
                   let fileBundleID = dict["BUNDLE_ID"] as? String {
                    Logger.debug("  - Bundle ID in \(configFile): \(fileBundleID)")
                    if fileBundleID != bundleID {
                        Logger.warning("  - WARNING: Bundle ID mismatch!")
                    }
                }
            } else {
                Logger.debug("Configuration file not found: \(configFile)")
            }
        }
        
        // Use the more comprehensive diagnostics
        _ = FirebaseClient.shared.diagnoseConnectionIssues()
    }
    
    // MARK: - Firebase Messaging Setup
    
    private func setupFirebaseMessaging() {
        // Set messaging delegate for FCM token refresh and other events
        Messaging.messaging().delegate = self
        
        // Manually enable auto initialization of FCM
        Messaging.messaging().isAutoInitEnabled = true
        
        // Print FCM token if already available
        if let token = Messaging.messaging().fcmToken {
            Logger.debug("FCM token is already available: \(token)")
        }
    }
} 