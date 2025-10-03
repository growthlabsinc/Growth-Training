//
//  AppSceneDelegate.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import UIKit
import SwiftUI
import GoogleSignIn
import UserNotifications
import Foundation  // For Logger

class AppSceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Handle deep links if any
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(windowScene, continue: userActivity)
        }
        
        // Handle any URL contexts from connectionOptions
        if !connectionOptions.urlContexts.isEmpty {
            self.scene(windowScene, openURLContexts: connectionOptions.urlContexts)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // Check for any pending Live Activity actions (pause/resume/stop)
        TimerIntentObserver.shared.checkPendingActions()
        
        // CRITICAL: Check for widget timer actions FIRST (from StopTimerAndOpenAppIntent)
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let widgetAction = sharedDefaults.string(forKey: "widgetTimerAction"),
           let actionTime = sharedDefaults.object(forKey: "widgetActionTime") as? Date,
           abs(actionTime.timeIntervalSinceNow) < 10 { // Process if recent (within 10 seconds)
            
            Logger.debug("🎯 AppSceneDelegate: Found widget timer action: \(widgetAction)")
            
            let timerType = sharedDefaults.string(forKey: "widgetTimerType") ?? "main"
            
            // Clear the widget action
            sharedDefaults.removeObject(forKey: "widgetTimerAction")
            sharedDefaults.removeObject(forKey: "widgetTimerType")
            sharedDefaults.removeObject(forKey: "widgetActionTime")
            sharedDefaults.removeObject(forKey: "widgetActivityId")
            sharedDefaults.synchronize()
            
            // Process the action
            if widgetAction == "stop" {
                Logger.debug("🛑 Processing stop action from widget for \(timerType) timer")
                TimerIntentObserver.shared.handleStopAction(timerType: timerType)
                
                // Post notification to trigger pending completion check
                // This ensures the completion sheet shows when returning from Live Activity stop
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Logger.debug("📮 Posting app became active notification to trigger completion check")
                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                }
                
                // Check for navigation intent
                if let pendingNavigation = sharedDefaults.string(forKey: "pendingTimerNavigation"),
                   pendingNavigation == "practice" {
                    sharedDefaults.removeObject(forKey: "pendingTimerNavigation")
                    sharedDefaults.synchronize()
                    
                    // Navigate to practice view after a short delay
                    // Use "showCompletion" instead of "startGuided" to avoid starting a new timer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(
                            name: .switchToPracticeTab,
                            object: nil,
                            userInfo: ["showCompletion": true]
                        )
                    }
                }
            }
        }
        
        // Check for pending deep links (fallback)
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let pendingDeepLink = sharedDefaults.string(forKey: "pendingDeepLink") {
            Logger.debug("🔗 AppSceneDelegate: Found pending deep link: \(pendingDeepLink)")
            
            // Clear the pending deep link
            sharedDefaults.removeObject(forKey: "pendingDeepLink")
            sharedDefaults.synchronize()
            
            // Process the URL
            if let url = URL(string: pendingDeepLink) {
                handleIncomingURL(url)
            }
        }
        
        // CRITICAL: Check Live Activity state synchronization first
        Growth.TimerService.shared.checkStateOnAppBecomeActive()
        
        // CRITICAL: Process stop actions IMMEDIATELY before any timer restoration can happen
        
        // Check for any pending timer actions from Live Activity (file-based first)
        if let timerAction = AppGroupFileManager.shared.readTimerAction() {
            // Process if action is recent (within 10 seconds)
            if abs(timerAction.timestamp.timeIntervalSinceNow) < 10 {
                Logger.debug("🔔 AppSceneDelegate: Found pending timer action from file: \(timerAction.action)")
                
                if timerAction.action == "stop" {
                    // Process stop action IMMEDIATELY
                    Logger.debug("🛑 AppSceneDelegate: Processing STOP action immediately")
                    TimerIntentObserver.shared.handleStopAction(timerType: timerAction.timerType)
                } else {
                    let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerAction.timerType]
                    
                    switch timerAction.action {
                    case "pause":
                        NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
                    case "resume":
                        NotificationCenter.default.post(name: .timerResumeRequested, object: nil, userInfo: userInfo)
                    default:
                        break
                    }
                }
                
                // Clear after processing
                AppGroupFileManager.shared.clearTimerAction()
            }
        }
        
        // Check for pending navigation from Live Activity stop button
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let pendingNavigation = sharedDefaults.string(forKey: "pendingTimerNavigation"),
           pendingNavigation == "practice" {
            
            Logger.debug("🗺️ AppSceneDelegate: Navigating to practice timer view from Live Activity stop")
            
            // Clear the pending navigation
            sharedDefaults.removeObject(forKey: "pendingTimerNavigation")
            sharedDefaults.synchronize()
            
            // Post notification to trigger navigation to practice timer view
            // Use "showCompletion" to show completion sheet without starting a new timer
            NotificationCenter.default.post(
                name: .switchToPracticeTab, 
                object: nil,
                userInfo: ["showCompletion": true]
            )
        }
        
        // CRITICAL FIX: Removed UserDefaults processing here to avoid race conditions
        // Timer actions from Live Activity are now handled exclusively through:
        // 1. TimerService.checkStateOnAppBecomeActive() for main timer actions
        // 2. Direct calls from LiveActivityManager when buttons are pressed
        // This prevents duplicate processing and state conflicts
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // Check and sync timer state with Live Activity
        Growth.TimerService.shared.syncWithLiveActivityState()
        
        // Clear any timer notifications since app is returning to foreground
        BackgroundTimerTracker.shared.cancelAllTimerNotifications()
        
        // Clear badge when app returns to foreground
        Task {
            await clearBadgeCount()
        }
    }
    
    @MainActor
    private func clearBadgeCount() async {
        if #available(iOS 17.0, *) {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(0)
            } catch {
                Logger.error("Error clearing badge count: \(error)")
            }
        } else {
            // Fallback for iOS 16 and earlier
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Check if any timer is running and schedule notifications
        if Growth.TimerService.shared.state == .running {
            let methodName = Growth.TimerService.shared.currentMethodName ?? "Practice Session"
            BackgroundTimerTracker.shared.saveTimerState(from: Growth.TimerService.shared, methodName: methodName, isQuickPractice: false)
            Logger.debug("AppSceneDelegate: Scheduled background notifications")
        }
        
        // Also check quick practice timer
        if QuickPracticeTimerTracker.shared.isTimerActive {
            Logger.debug("AppSceneDelegate: Quick practice timer is running in background")
        }
    }
    
    // MARK: - Deep Linking
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Handle Universal Links
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }
        
        handleIncomingURL(url)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle URL schemes
        guard let url = URLContexts.first?.url else {
            return
        }
        
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }
        
        handleIncomingURL(url)
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Process incoming URL for deep linking
        Logger.debug("Processing URL: \(url.absoluteString)")
        
        // Handle timer control URLs from Live Activity
        if url.scheme == "growth" && url.host == "timer" {
            let pathComponents = url.pathComponents
            
            // URL format: growth://timer/{action}/{activityId} or growth://timer/practice
            if pathComponents.count >= 2 {
                let action = pathComponents[1]
                
                // Special case for practice navigation
                if action == "practice" {
                    Logger.debug("🔗 Navigating to practice timer view")
                    // Post notification to switch to practice tab
                    // Just navigate to the tab without starting a timer
                    NotificationCenter.default.post(
                        name: .switchToPracticeTab,
                        object: nil,
                        userInfo: nil
                    )
                    return
                }
                
                // Handle timer actions with activity ID
                if pathComponents.count >= 3 {
                    let activityId = pathComponents[2]
                    
                    Logger.debug("🔗 Live Activity Deep Link: action=\(action), activityId=\(activityId)")
                    
                    // Find the timer type from the activity ID
                    var timerType = "main" // default
                    
                    // For iOS 16.2+, check the current Live Activity
                    if #available(iOS 16.2, *) {
                        if LiveActivityManager.shared.isCurrentActivity(id: activityId) {
                            // Get timer type from the activity attributes
                            timerType = LiveActivityManager.shared.currentActivityTimerType ?? "main"
                        }
                    } else {
                        // For older iOS versions, default to main timer
                        timerType = "main"
                    }
                    
                    // Post notification for timer action
                    let userInfo = [Notification.Name.TimerUserInfoKey.timerType: timerType]
                    
                    switch action {
                    case "pause":
                        Logger.debug("🔗 Processing pause action for \(timerType) timer")
                        NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
                    case "resume":
                        Logger.debug("🔗 Processing resume action for \(timerType) timer")
                        NotificationCenter.default.post(name: .timerResumeRequested, object: nil, userInfo: userInfo)
                    case "stop":
                        Logger.debug("🔗 Processing stop action for \(timerType) timer")
                        TimerIntentObserver.shared.handleStopAction(timerType: timerType)
                        
                        // After stopping, navigate to practice view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(
                                name: .switchToPracticeTab,
                                object: nil,
                                userInfo: ["showCompletion": true]
                            )
                        }
                    default:
                        Logger.warning("🔗 Unknown timer action: \(action)")
                    }
                }
            }
        }
    }
} 