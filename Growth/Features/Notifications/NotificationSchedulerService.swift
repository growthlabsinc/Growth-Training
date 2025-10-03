import Foundation
import UserNotifications
import FirebaseAuth
import Combine

/// Time preference for notifications
enum NotificationTimePreference: String, Codable {
    case morning = "MORNING" // 8:00 AM
    case afternoon = "AFTERNOON" // 1:00 PM
    case evening = "EVENING" // 7:00 PM
    case custom = "CUSTOM" // User-defined time
}

/// Service responsible for scheduling and managing local notifications
class NotificationSchedulerService {
    // MARK: - Shared instance
    
    static let shared = NotificationSchedulerService()
    
    // MARK: - Properties
    
    /// Publisher for notification authorization status
    @Published private(set) var isAuthorized = false
    
    /// Publisher for notification settings
    @Published private(set) var settings: UNNotificationSettings?
    
    /// Manager instance for delegate methods
    private let notificationsManager = NotificationsManager.shared
    
    /// Notification center
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Default time configurations
    
    private let morningHour = 8
    private let afternoonHour = 13
    private let eveningHour = 19
    
    // MARK: - Initialization
    
    private init() {
        // Check current authorization status
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Schedule a daily reminder notification
    /// - Parameters:
    ///   - timePreference: The time preference for the notification
    ///   - customHour: Custom hour (if timePreference is .custom)
    ///   - customMinute: Custom minute (if timePreference is .custom)
    ///   - completion: Completion handler with success flag and optional error
    func scheduleDailyReminder(timePreference: NotificationTimePreference, 
                               customHour: Int? = nil, 
                               customMinute: Int? = nil,
                               completion: @escaping (Bool, Error?) -> Void) {
        
        // Ensure notifications are authorized
        guard isAuthorized else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]))
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Practice"
        content.body = "Maintain your streak by practicing today. Just a few minutes can make a difference!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationType.reminder.rawValue
        
        // Configure date components based on time preference
        var dateComponents = DateComponents()
        
        switch timePreference {
        case .morning:
            dateComponents.hour = morningHour
            dateComponents.minute = 0
        case .afternoon:
            dateComponents.hour = afternoonHour
            dateComponents.minute = 0
        case .evening:
            dateComponents.hour = eveningHour
            dateComponents.minute = 0
        case .custom:
            if let hour = customHour, let minute = customMinute,
               hour >= 0 && hour < 24 && minute >= 0 && minute < 60 {
                dateComponents.hour = hour
                dateComponents.minute = minute
            } else {
                completion(false, NSError(domain: "NotificationSchedulerService", code: 400, 
                                         userInfo: [NSLocalizedDescriptionKey: "Invalid custom time"]))
                return
            }
        }
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling daily reminder: \(error.localizedDescription)")
                completion(false, error)
            } else {
                Logger.info("Daily reminder scheduled successfully for \(timePreference.rawValue)")
                
                // Save preferences to Firestore if user is logged in
                if let userId = Auth.auth().currentUser?.uid {
                    self.saveNotificationPreference(
                        userId: userId,
                        type: .reminder,
                        timePreference: timePreference,
                        customHour: customHour,
                        customMinute: customMinute
                    ) { success, error in
                        completion(success, error)
                    }
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Schedule a weekly progress summary notification (Sunday at 9:00 AM)
    /// - Parameter completion: Completion handler with success flag and optional error
    /// Schedule a streak alert notification when at risk of breaking streak
    /// - Parameters:
    ///   - hoursRemaining: Hours remaining until streak resets
    ///   - completion: Completion handler with success flag and optional error
    func scheduleStreakAlert(hoursRemaining: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthorized else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]))
            return
        }
        
        // Check if user has enabled streak maintenance notifications
        if Auth.auth().currentUser?.uid != nil {
            notificationsManager.fetchNotificationPreferences { [weak self] preferences, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(false, error)
                    return
                }
                
                // Respect user preferences
                if let preferences = preferences, !preferences.streakMaintenance {
                    completion(false, nil)
                    return
                }
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "Don't Break Your Streak!"
                
                if hoursRemaining == 0 {
                    content.body = "Your practice streak will reset tonight if you don't practice. Take a few minutes now!"
                } else if hoursRemaining == 1 {
                    content.body = "Only 1 hour left to maintain your practice streak today. Don't break it!"
                } else {
                    content.body = "Only \(hoursRemaining) hours left to maintain your practice streak today."
                }
                
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = NotificationType.streakAlert.rawValue
                
                // Add actions
                let practiceAction = UNNotificationAction(
                    identifier: "CONTINUE_STREAK_ACTION",
                    title: "Practice Now",
                    options: .foreground
                )
                
                let category = UNNotificationCategory(
                    identifier: NotificationType.streakAlert.rawValue,
                    actions: [practiceAction],
                    intentIdentifiers: [],
                    options: [.customDismissAction]
                )
                
                // Register the category
                self.center.setNotificationCategories([category])
                
                // Configure time trigger (show immediately)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                // Create request with unique identifier
                let request = UNNotificationRequest(
                    identifier: "streak-alert-\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )
                
                // Schedule notification
                self.center.add(request) { error in
                    if let error = error {
                        Logger.error("Error scheduling streak alert: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        Logger.info("Streak alert scheduled successfully")
                        completion(true, nil)
                    }
                }
            }
        } else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
        }
    }
    
    /// Schedule an achievement notification when a badge is earned
    /// - Parameters:
    ///   - title: The notification title
    ///   - description: The notification description
    ///   - completion: Completion handler with success flag and optional error
    func scheduleAchievementNotification(title: String, description: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthorized else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]))
            return
        }
        
        // Check if user has enabled achievement notifications
        if Auth.auth().currentUser?.uid != nil {
            notificationsManager.fetchNotificationPreferences { [weak self] preferences, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(false, error)
                    return
                }
                
                // Respect user preferences
                if let preferences = preferences, !preferences.achievements {
                    completion(false, nil)
                    return
                }
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = description
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = NotificationType.achievement.rawValue
                
                // Add actions
                let viewDetailsAction = UNNotificationAction(
                    identifier: "VIEW_DETAILS_ACTION",
                    title: "View Details",
                    options: .foreground
                )
                
                let category = UNNotificationCategory(
                    identifier: NotificationType.achievement.rawValue,
                    actions: [viewDetailsAction],
                    intentIdentifiers: [],
                    options: [.customDismissAction]
                )
                
                // Register the category
                self.center.setNotificationCategories([category])
                
                // Configure time trigger (show after a short delay)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                
                // Create request with unique identifier
                let request = UNNotificationRequest(
                    identifier: "achievement-\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )
                
                // Schedule notification
                self.center.add(request) { error in
                    if let error = error {
                        Logger.error("Error scheduling achievement notification: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        Logger.info("Achievement notification scheduled successfully")
                        completion(true, nil)

                        // Story 8.5: Trigger badge earned affirmation
                        _ = AffirmationService.shared.randomAffirmation(for: .badgeEarned)
                    }
                }
            }
        } else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
        }
    }
    
    func scheduleWeeklyProgressSummary(completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthorized else {
            completion(false, NSError(domain: "NotificationSchedulerService", code: 401, 
                                     userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]))
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress Summary"
        content.body = "Check out how you did this week! See your stats and achievements."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationType.weeklyProgress.rawValue
        
        // Configure for Sunday at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "weekly-progress",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling weekly progress: \(error.localizedDescription)")
                completion(false, error)
            } else {
                Logger.info("Weekly progress summary scheduled successfully")
                
                // Save preference to Firestore if user is logged in
                if let userId = Auth.auth().currentUser?.uid {
                    self.saveNotificationPreference(
                        userId: userId,
                        type: .weeklyProgress,
                        enabled: true
                    ) { success, error in
                        completion(success, error)
                    }
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Cancel all scheduled notifications of a specific type
    /// - Parameters:
    ///   - type: The notification type to cancel
    ///   - completion: Completion handler with success flag
    func cancelNotifications(of type: NotificationType, completion: @escaping (Bool) -> Void) {
        center.getPendingNotificationRequests { requests in
            let identifiers = requests.filter { request in
                return request.content.categoryIdentifier == type.rawValue
            }.map { $0.identifier }
            
            if !identifiers.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
                Logger.info("Cancelled \(identifiers.count) notifications of type \(type.rawValue)")
            }
            
            // If user is logged in, update Firestore
            if type == .reminder || type == .weeklyProgress,
               let userId = Auth.auth().currentUser?.uid {
                self.saveNotificationPreference(
                    userId: userId,
                    type: type,
                    enabled: false
                ) { success, _ in
                    completion(success)
                }
            } else {
                completion(true)
            }
        }
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        Logger.info("Cancelled all scheduled notifications")
    }
    
    // MARK: - Private Methods
    
    /// Save notification preference to Firestore
    /// - Parameters:
    ///   - userId: The user ID
    ///   - type: The notification type
    ///   - timePreference: Optional time preference
    ///   - customHour: Optional custom hour
    ///   - customMinute: Optional custom minute
    ///   - enabled: Whether the notification is enabled
    ///   - completion: Completion handler with success flag and optional error
    private func saveNotificationPreference(
        userId: String,
        type: NotificationType,
        timePreference: NotificationTimePreference? = nil,
        customHour: Int? = nil,
        customMinute: Int? = nil,
        enabled: Bool = true,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        var data: [String: Any] = [
            "enabled": enabled,
            "updatedAt": Date()
        ]
        
        if let timePreference = timePreference {
            data["timePreference"] = timePreference.rawValue
            
            if timePreference == .custom {
                if let customHour = customHour, let customMinute = customMinute {
                    data["customHour"] = customHour
                    data["customMinute"] = customMinute
                }
            }
        }
        
        FirestoreService.shared.saveNotificationSchedulePreference(
            userId: userId,
            type: type.rawValue,
            data: data
        ) { error in
            if let error = error {
                Logger.error("Error saving notification preference: \(error.localizedDescription)")
                completion(false, error)
            } else {
                Logger.info("Notification preference saved successfully")
                completion(true, nil)
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.settings = settings
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
} 