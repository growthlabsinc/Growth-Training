import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseAuth
import Combine
import UIKit

/// Types of notifications in the app
public enum NotificationType: String {
    case reminder = "reminder"
    case weeklyProgress = "weeklyProgress"
    case streakAlert = "streakAlert"
    case achievement = "achievement"
    case sessionComplete = "sessionComplete"
}

/// NotificationsManager is a singleton service that handles all push notification operations including:
/// - Permission requesting
/// - Device token registration and storage
/// - Notification handling for different app states
/// - Exposing notification preferences
class NotificationsManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationsManager()
    
    // MARK: - Properties
    
    /// Publisher indicating whether notifications are authorized
    @Published private(set) var isAuthorized = false
    
    /// Publisher for notification settings
    @Published private(set) var settings: UNNotificationSettings?
    
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Check current authorization status on creation
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request permission to show notifications to the user
    /// - Parameter completion: Callback with result of the permission request
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.isAuthorized = true
                    
                    // Register for remote notifications after getting permission
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    // Also request necessary additional permissions
                    self?.registerForNotificationCategories()
                } else if let error = error {
                    Logger.error("Error requesting notification permissions: \(error.localizedDescription)")
                }
                
                completion(granted)
            }
        }
    }
    
    /// Updates the current user's device token in Firebase
    /// - Parameter deviceToken: The device token data provided by APNs
    func updateDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.debug("Device token: \(tokenString)")
        
        // Store the token in Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Also save to Firestore if a user is logged in
        if let currentUser = Auth.auth().currentUser {
            storeTokenInFirestore(userId: currentUser.uid, token: tokenString)
        }
    }
    
    /// Updates notification preferences in Firestore
    /// - Parameters:
    ///   - preferences: The user's notification preferences
    ///   - completion: Completion handler called when the update is complete
    func updateNotificationPreferences(_ preferences: NotificationPreferences, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "NotificationsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        FirestoreService.shared.updateNotificationPreferences(userId: userId, preferences: preferences) { error in
            completion(error)
        }
    }
    
    /// Fetches the current user's notification preferences
    /// - Parameter completion: Completion handler with the fetched preferences or error
    func fetchNotificationPreferences(completion: @escaping (NotificationPreferences?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "NotificationsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        FirestoreService.shared.fetchNotificationPreferences(userId: userId) { preferences, error in
            completion(preferences, error)
        }
    }
    
    /// Stores a device token in Firestore
    /// - Parameters:
    ///   - userId: The user ID
    ///   - token: The token to store
    func storeTokenInFirestore(userId: String, token: String) {
        FirestoreService.shared.storeDeviceToken(userId: userId, token: token) { error in
            if let error = error {
                Logger.error("Error storing device token: \(error.localizedDescription)")
            } else {
                Logger.info("Device token successfully stored in Firestore")
            }
        }
    }
    
    /// Handle notification response
    /// - Parameter response: The notification response from UNUserNotificationCenter
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        // Handle different notification categories
        switch categoryIdentifier {
        case "DAILY_REMINDER":
            if response.actionIdentifier == "PRACTICE_NOW_ACTION" {
                navigateToPracticeScreen(userInfo: userInfo)
            } else {
                navigateToHomeScreen(userInfo: userInfo)
            }
            
        case "STREAK_ALERT":
            if response.actionIdentifier == "CONTINUE_STREAK_ACTION" {
                navigateToPracticeScreen(userInfo: userInfo)
            } else {
                navigateToHomeScreen(userInfo: userInfo)
            }
            
        case "WEEKLY_PROGRESS":
            if response.actionIdentifier == "VIEW_PROGRESS_ACTION" {
                navigateToProgressScreen(userInfo: userInfo)
            } else {
                navigateToProgressScreen(userInfo: userInfo)
            }
            
        case "ACHIEVEMENT":
            if response.actionIdentifier == "VIEW_DETAILS_ACTION" {
                navigateToAchievementScreen(userInfo: userInfo)
            } else {
                navigateToAchievementScreen(userInfo: userInfo)
            }
            
        case "SESSION_REMINDER":
            navigateToSessionReminder(userInfo: userInfo)
            
        case "TIMER_CATEGORY":
            handleTimerNotificationAction(response)
            
        default:
            handleGenericNotification(userInfo: userInfo)
        }
    }
    
    /// Log a received notification for analytics
    /// - Parameter userInfo: The notification's user info
    func logNotificationReceived(userInfo: [AnyHashable: Any]) {
        // Log analytics event for notification received
        // This could use Firebase Analytics or custom analytics service
    }
    
    /// Log a tapped notification for analytics
    /// - Parameter userInfo: The notification's user info
    func logNotificationTapped(userInfo: [AnyHashable: Any]) {
        // Log analytics event for notification tapped
        // This could use Firebase Analytics or custom analytics service
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.settings = settings
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForNotificationCategories() {
        // Create custom actions and categories
        
        // PRACTICE_REMINDER category with "Practice Now" action
        let practiceNowAction = UNNotificationAction(
            identifier: "PRACTICE_NOW_ACTION",
            title: "Practice Now",
            options: .foreground
        )
        
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [practiceNowAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // STREAK_ALERT category with "Continue Streak" action
        let continueStreakAction = UNNotificationAction(
            identifier: "CONTINUE_STREAK_ACTION",
            title: "Continue Streak",
            options: .foreground
        )
        
        let streakAlertCategory = UNNotificationCategory(
            identifier: "STREAK_ALERT",
            actions: [continueStreakAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // WEEKLY_PROGRESS category with "View Progress" action
        let viewProgressAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS_ACTION",
            title: "View Progress",
            options: .foreground
        )
        
        let weeklyProgressCategory = UNNotificationCategory(
            identifier: "WEEKLY_PROGRESS",
            actions: [viewProgressAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // ACHIEVEMENT category with "View Details" action
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // SESSION_REMINDER category (from Story 8.1)
        let sessionReminderCategory = UNNotificationCategory(
            identifier: "SESSION_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register all notification categories
        UNUserNotificationCenter.current().setNotificationCategories([
            dailyReminderCategory,
            streakAlertCategory,
            weeklyProgressCategory,
            achievementCategory,
            sessionReminderCategory
        ])
    }
    
    private func navigateToSessionReminder(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToSessionReminder"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func navigateToPracticeScreen(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToPracticeScreen"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func navigateToHomeScreen(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToHomeScreen"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func navigateToProgressScreen(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToProgressScreen"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func navigateToAchievementScreen(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToAchievementScreen"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleGenericNotification(userInfo: [AnyHashable: Any]) {
        // Handle other notification types or generic navigation
        NotificationCenter.default.post(name: Notification.Name("HandleGenericNotification"), object: nil, userInfo: userInfo)
    }
    
    private func handleTimerNotificationAction(_ response: UNNotificationResponse) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "PAUSE_TIMER":
            // Handle pause action
            if let timerState = BackgroundTimerTracker.shared.peekTimerState(), timerState.state == .running {
                // Update the saved state to paused
                BackgroundTimerTracker.shared.clearSavedState()
                // Post notification to update UI if needed
                NotificationCenter.default.post(
                    name: Notification.Name("TimerPausedFromNotification"),
                    object: nil
                )
            }
            
        case "COMPLETE_SESSION":
            // Navigate to timer view to complete session
            navigateToTimerScreen()
            
        default:
            // Default action (tap on notification)
            navigateToTimerScreen()
        }
    }
    
    private func navigateToTimerScreen() {
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToTimerScreen"),
            object: nil,
            userInfo: ["hasBackgroundTimer": true]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationsManager: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Extract notification data
        let userInfo = notification.request.content.userInfo
        
        // If it's a Firebase message, let FCM handle it
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Log analytics data
        logNotificationReceived(userInfo: userInfo)
        
        // Show the notification to the user when app is in foreground
        // In iOS 14+, we use .banner and .list options instead of deprecated .alert
        completionHandler([.banner, .badge, .sound])
    }
    
    /// Called when a user responds to a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract notification data
        let userInfo = response.notification.request.content.userInfo
        
        // Log that the user interacted with the notification
        logNotificationTapped(userInfo: userInfo)
        
        // Handle specific notification types
        handleNotificationResponse(response)
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension NotificationsManager: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.debug("Firebase registration token: \(fcmToken ?? "nil")")
        
        // Store this token in Firestore
        if let token = fcmToken, let userId = Auth.auth().currentUser?.uid {
            storeTokenInFirestore(userId: userId, token: token)
        }
    }
} 