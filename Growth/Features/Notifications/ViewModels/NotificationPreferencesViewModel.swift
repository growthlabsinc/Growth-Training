import SwiftUI
import UserNotifications
import Combine
import UIKit

/// Alert item for displaying errors or messages
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

class NotificationPreferencesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Loading state for the view
    @Published var isLoading = true
    
    /// The user's notification preferences
    @Published var preferences = NotificationPreferences()
    
    /// Notification settings from the system
    @Published var notificationSettings: UNNotificationSettings?
    
    /// Whether notifications are authorized
    @Published var isNotificationsAuthorized = false
    
    /// Error alerts
    @Published var alertItem: AlertItem?
    
    // MARK: - Scheduled Notification Properties
    
    /// Whether daily reminders are enabled
    @Published var dailyReminderEnabled = false
    
    /// Time preference for daily reminders
    @Published var timePreference: NotificationTimePreference = .evening
    
    /// Whether weekly progress summaries are enabled
    @Published var weeklyProgressEnabled = false
    
    /// Custom hour for reminders (when custom time is selected)
    @Published var customHour: Int = 19
    
    /// Custom minute for reminders (when custom time is selected)
    @Published var customMinute: Int = 0
    
    /// Whether to show custom time settings
    @Published var showCustomTimeSettings = false
    
    // MARK: - Private Properties
    
    /// Set of Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Scheduler service
    private let scheduler = NotificationSchedulerService.shared
    
    // MARK: - Initialization
    
    init() {
        // Subscribe to NotificationsManager's authorization status
        NotificationsManager.shared.$isAuthorized
            .sink { [weak self] isAuthorized in
                self?.isNotificationsAuthorized = isAuthorized
            }
            .store(in: &cancellables)
        
        // Subscribe to NotificationsManager's settings
        NotificationsManager.shared.$settings
            .compactMap { $0 }
            .sink { [weak self] settings in
                self?.notificationSettings = settings
            }
            .store(in: &cancellables)
            
        // Monitor time preference changes
        $timePreference
            .sink { [weak self] newValue in
                self?.showCustomTimeSettings = newValue == .custom
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load the user's notification preferences from Firestore
    func loadPreferences() {
        isLoading = true
        
        NotificationsManager.shared.fetchNotificationPreferences { [weak self] preferences, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.alertItem = AlertItem(
                        title: "Error Loading Preferences",
                        message: error.localizedDescription
                    )
                    return
                }
                
                if let preferences = preferences {
                    self?.preferences = preferences
                } else {
                    // Use default preferences if none are saved
                    self?.preferences = NotificationPreferences()
                }
            }
        }
    }
    
    /// Load scheduled notification preferences from Firestore
    func loadSchedulePreferences() {
        guard let userId = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }
        
        FirestoreService.shared.fetchNotificationSchedulePreferences(userId: userId) { [weak self] preferences, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.debug("Error loading schedule preferences: \(error.localizedDescription)")
                    return
                }
                
                guard let preferences = preferences else { return }
                
                // Set daily reminder preferences
                if let dailyPrefs = preferences[NotificationType.reminder.rawValue] {
                    self?.dailyReminderEnabled = dailyPrefs["enabled"] as? Bool ?? false
                    
                    if let timePreferenceString = dailyPrefs["timePreference"] as? String,
                       let timePreference = NotificationTimePreference(rawValue: timePreferenceString) {
                        self?.timePreference = timePreference
                        
                        if timePreference == .custom {
                            self?.customHour = dailyPrefs["customHour"] as? Int ?? 19
                            self?.customMinute = dailyPrefs["customMinute"] as? Int ?? 0
                        }
                    }
                }
                
                // Set weekly progress preferences
                if let weeklyPrefs = preferences[NotificationType.weeklyProgress.rawValue] {
                    self?.weeklyProgressEnabled = weeklyPrefs["enabled"] as? Bool ?? false
                }
            }
        }
    }
    
    /// Save the user's notification preferences to Firestore
    func savePreferences() {
        NotificationsManager.shared.updateNotificationPreferences(preferences) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.alertItem = AlertItem(
                        title: "Error Saving Preferences",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    /// Check the current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationSettings = settings
                self?.isNotificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Open the settings app to allow the user to enable notifications
    func openSettingsApp() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Request notification permissions if not already granted
    func requestNotificationPermissions() {
        NotificationsManager.shared.requestPermissions { [weak self] granted in
            DispatchQueue.main.async {
                self?.isNotificationsAuthorized = granted
                
                if granted {
                    self?.loadPreferences()
                } else {
                    self?.alertItem = AlertItem(
                        title: "Notifications Disabled",
                        message: "Please enable notifications in Settings to receive updates about your progress."
                    )
                }
            }
        }
    }
    
    // MARK: - Scheduled Notification Methods
    
    /// Update daily reminder enabled state
    /// - Parameter enabled: Whether daily reminders should be enabled
    func updateDailyReminderEnabled(_ enabled: Bool) {
        dailyReminderEnabled = enabled
        
        if enabled {
            scheduleDailyReminder()
        } else {
            cancelDailyReminders()
        }
    }
    
    /// Update time preference for daily reminders
    /// - Parameter preference: The new time preference
    func updateTimePreference(_ preference: NotificationTimePreference) {
        timePreference = preference
        
        if preference != .custom {
            scheduleDailyReminder()
        }
    }
    
    /// Save custom time for daily reminder
    func saveCustomTime() {
        if timePreference == .custom {
            scheduleDailyReminder()
        }
    }
    
    /// Update weekly progress enabled state
    /// - Parameter enabled: Whether weekly progress should be enabled
    func updateWeeklyProgressEnabled(_ enabled: Bool) {
        weeklyProgressEnabled = enabled
        
        if enabled {
            scheduleWeeklyProgressSummary()
        } else {
            cancelWeeklyProgressSummaries()
        }
    }
    
    // MARK: - Private Methods
    
    /// Schedule a daily reminder based on current preferences
    private func scheduleDailyReminder() {
        scheduler.scheduleDailyReminder(
            timePreference: timePreference,
            customHour: timePreference == .custom ? customHour : nil,
            customMinute: timePreference == .custom ? customMinute : nil
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alertItem = AlertItem(
                        title: "Error Scheduling Reminder",
                        message: error.localizedDescription
                    )
                } else if success {
                    Logger.debug("Daily reminder scheduled successfully")
                }
            }
        }
    }
    
    /// Cancel all daily reminders
    private func cancelDailyReminders() {
        scheduler.cancelNotifications(of: .reminder) { [weak self] success in
            if !success {
                DispatchQueue.main.async {
                    self?.alertItem = AlertItem(
                        title: "Error Canceling Reminders",
                        message: "Could not cancel the scheduled reminders. Please try again."
                    )
                }
            }
        }
    }
    
    /// Schedule a weekly progress summary
    private func scheduleWeeklyProgressSummary() {
        scheduler.scheduleWeeklyProgressSummary { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alertItem = AlertItem(
                        title: "Error Scheduling Weekly Summary",
                        message: error.localizedDescription
                    )
                } else if success {
                    Logger.debug("Weekly progress summary scheduled successfully")
                }
            }
        }
    }
    
    /// Cancel all weekly progress summaries
    private func cancelWeeklyProgressSummaries() {
        scheduler.cancelNotifications(of: .weeklyProgress) { [weak self] success in
            if !success {
                DispatchQueue.main.async {
                    self?.alertItem = AlertItem(
                        title: "Error Canceling Weekly Summaries",
                        message: "Could not cancel the scheduled summaries. Please try again."
                    )
                }
            }
        }
    }
} 