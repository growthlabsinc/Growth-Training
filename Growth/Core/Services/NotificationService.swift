//
//  NotificationService.swift
//  Growth
//
//  Service for managing all notification-related functionality
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Central service for managing local and push notifications
class NotificationService: NSObject, ObservableObject {
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var notificationSettings: UNNotificationSettings?
    
    // MARK: - Private Properties
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Check initial authorization status
        checkAuthorizationStatus { _ in }
        
        // Set up notification center delegate
        userNotificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization from the user
    func requestAuthorization() {
        userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                
                if let error = error {
                    Logger.error("Error requesting notification authorization: \(error.localizedDescription)")
                }
                
                if granted {
                    // Register for remote notifications if needed
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Check current authorization status
    /// - Parameter completion: Completion handler with authorization status
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        userNotificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationSettings = settings
                let isAuthorized = settings.authorizationStatus == .authorized
                self?.isAuthorized = isAuthorized
                completion(isAuthorized)
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// Disable all notifications
    func disableAllNotifications() {
        // Remove all pending notifications
        userNotificationCenter.removeAllPendingNotificationRequests()
        
        // Remove all delivered notifications
        userNotificationCenter.removeAllDeliveredNotifications()
        
        // Update authorization status
        isAuthorized = false
    }
    
    /// Schedule a daily reminder at a specific time
    /// - Parameter date: The time to schedule the daily reminder
    func scheduleDailyReminder(at date: Date) {
        // Remove existing daily reminders
        cancelDailyReminders()
        
        // Create date components for the reminder time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Practice"
        content.body = "Don't forget your daily training session!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        userNotificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling daily reminder: \(error.localizedDescription)")
            } else {
                Logger.info("Daily reminder scheduled successfully")
            }
        }
    }
    
    /// Cancel all daily reminders
    func cancelDailyReminders() {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }
    
    /// Send a test notification
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Growth"
        content.sound = .default
        
        // Trigger notification after 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error sending test notification: \(error.localizedDescription)")
            } else {
                Logger.info("Test notification scheduled")
            }
        }
    }
    
    /// Schedule a session reminder
    /// - Parameters:
    ///   - sessionName: Name of the session
    ///   - date: When to remind the user
    func scheduleSessionReminder(sessionName: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Session Reminder"
        content.body = "Time for your \(sessionName) session"
        content.sound = .default
        content.categoryIdentifier = "SESSION_REMINDER"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "session_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling session reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule a progress update notification
    /// - Parameter progress: The progress information to include
    func scheduleProgressUpdate(progress: String) {
        let content = UNMutableNotificationContent()
        content.title = "Progress Update"
        content.body = progress
        content.sound = .default
        content.categoryIdentifier = "PROGRESS_UPDATE"
        
        // Schedule for 1 hour from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "progress_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling progress update: \(error.localizedDescription)")
            }
        }
    }
    
    /// Show a session completion notification immediately
    /// - Parameters:
    ///   - methodName: Name of the method/session completed
    ///   - duration: Duration of the session in seconds
    func showSessionCompletionNotification(methodName: String, duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Session Completed! 🎉"
        
        // Format duration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = minutes > 0 ? "\(minutes) min \(seconds) sec" : "\(seconds) seconds"
        
        content.body = "Great job completing your \(methodName) session! Duration: \(durationText)"
        content.sound = .default
        content.categoryIdentifier = "SESSION_COMPLETION"
        
        // Show immediately (0.1 second delay to ensure it appears)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "session_completion_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error showing session completion notification: \(error.localizedDescription)")
            } else {
                Logger.info("✅ Session completion notification scheduled")
            }
        }
    }
    
    /// Cancel all pending notifications of a specific type
    /// - Parameter identifierPrefix: The prefix of notification identifiers to cancel
    func cancelNotifications(withIdentifierPrefix prefix: String) {
        userNotificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            
            self.userNotificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    /// Get all pending notifications
    /// - Parameter completion: Completion handler with pending notification requests
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        userNotificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Handle notification response
    /// - Parameter response: The notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        switch categoryIdentifier {
        case "DAILY_REMINDER":
            // Handle daily reminder tap
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToPracticeScreen"),
                object: nil
            )
            
        case "SESSION_REMINDER":
            // Handle session reminder tap
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToSessionScreen"),
                object: nil
            )
            
        case "PROGRESS_UPDATE":
            // Handle progress update tap
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToProgressScreen"),
                object: nil
            )
            
        case "SESSION_COMPLETION":
            // Handle session completion tap - navigate to progress or dashboard
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToProgressScreen"),
                object: nil
            )
            
        default:
            // Handle other notifications
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    /// Handle notification response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
}

// MARK: - Notification Categories

extension NotificationService {
    /// Register notification categories with actions
    func registerNotificationCategories() {
        // Daily reminder category
        let practiceNowAction = UNNotificationAction(
            identifier: "PRACTICE_NOW",
            title: "Practice Now",
            options: .foreground
        )
        
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [practiceNowAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Session reminder category
        let startSessionAction = UNNotificationAction(
            identifier: "START_SESSION",
            title: "Start Session",
            options: .foreground
        )
        
        let sessionReminderCategory = UNNotificationCategory(
            identifier: "SESSION_REMINDER",
            actions: [startSessionAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Progress update category
        let viewProgressAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS",
            title: "View Progress",
            options: .foreground
        )
        
        let progressUpdateCategory = UNNotificationCategory(
            identifier: "PROGRESS_UPDATE",
            actions: [viewProgressAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register categories
        userNotificationCenter.setNotificationCategories([
            dailyReminderCategory,
            sessionReminderCategory,
            progressUpdateCategory
        ])
    }
}