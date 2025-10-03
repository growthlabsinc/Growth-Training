import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class StreakStatsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Loading state indicator
    @Published var isLoading = true
    
    /// Current streak count
    @Published var currentStreak = 0
    
    /// Longest streak achieved
    @Published var longestStreak = 0
    
    /// Date of last practice session
    @Published var lastPracticeDate: Date?
    
    /// Formatted date of last practice session
    @Published var lastPracticeFormatted = "Never"
    
    /// Whether the streak is at risk of being broken
    @Published var isStreakAtRisk = false
    
    /// Flag to show alert
    @Published var showAlert = false
    
    /// Alert title
    @Published var alertTitle = ""
    
    /// Alert message
    @Published var alertMessage = ""
    
    /// Whether the view model is recording a practice session
    @Published var isRecordingPractice = false
    
    /// Calendar data for the last 30 days (startOfDay -> total minutes practiced)
    @Published var calendarData: [Date: Int] = [:]
    
    // MARK: - Private Properties
    
    /// Streak tracker service
    private let streakTracker = StreakTracker.shared
    
    /// Set of cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Date formatter for display
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Initialization
    
    init() {
        setupTimer()
    }
    
    // MARK: - Public Methods
    
    /// Load streak data from the streak tracker
    func loadStreakData() {
        isLoading = true
        
        // Get current streak
        streakTracker.getCurrentStreak { [weak self] streak, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError(title: "Error Loading Streak", message: error.localizedDescription)
                    self?.isLoading = false
                    return
                }
                
                self?.currentStreak = streak
                
                // Get full streak data
                self?.loadStreakDetails()
                
                // Load calendar visualization data
                self?.loadCalendarData()
            }
        }
        
        // Check if streak is at risk
        checkStreakRisk()
    }
    
    /// Record a quick practice session (5 minutes)
    func recordQuickPractice() {
        guard !isRecordingPractice else { return }
        
        isRecordingPractice = true
        
        // Record a 5-minute practice session
        streakTracker.recordPracticeSession(duration: 5) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isRecordingPractice = false
                
                if let error = error {
                    self?.handleError(title: "Error Recording Practice", message: error.localizedDescription)
                    return
                }
                
                if success {
                    self?.showSuccess(title: "Practice Recorded", message: "Your 5-minute practice session has been logged and your streak has been updated.")
                    self?.loadStreakData()
                    
                    // Check for streak-based badges
                    self?.checkForStreakBadges()
                } else {
                    self?.handleError(title: "Failed to Record Practice", message: "Please try again later.")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Set up a timer to periodically check if the streak is at risk
    private func setupTimer() {
        // Check every 30 minutes if the streak is at risk
        Timer.publish(every: 1800, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkStreakRisk()
            }
            .store(in: &cancellables)
    }
    
    /// Load detailed streak information
    private func loadStreakDetails() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        streakTracker.getUserStreakData(userId: userId) { [weak self] streakData, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError(title: "Error Loading Streak Details", message: error.localizedDescription)
                    return
                }
                
                if let streakData = streakData {
                    // Update longest streak
                    self?.longestStreak = streakData["longestStreak"] as? Int ?? 0
                    
                    // Update last practice date
                    if let lastPracticeTimestamp = streakData["lastPracticeDate"] as? Timestamp {
                        let date = lastPracticeTimestamp.dateValue()
                        self?.lastPracticeDate = date
                        self?.lastPracticeFormatted = self?.dateFormatter.string(from: date) ?? "Unknown"
                    } else {
                        self?.lastPracticeFormatted = "Never"
                    }
                }
            }
        }
    }
    
    /// Check if the user's streak is at risk of breaking
    private func checkStreakRisk() {
        streakTracker.checkStreakRisk { [weak self] hoursRemaining, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.debug("Error checking streak risk: \(error.localizedDescription)")
                    return
                }
                
                self?.isStreakAtRisk = hoursRemaining != nil
            }
        }
    }
    
    /// Check for streak-based badges and award them if criteria are met
    private func checkForStreakBadges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get the user's streak data
        streakTracker.getUserStreakData(userId: userId) { [weak self] streakData, error in
            if let error = error {
                Logger.debug("Error loading streak data for badge check: \(error.localizedDescription)")
                return
            }
            
            guard let streakData = streakData else {
                return
            }
            
            // Get current streak
            let currentStreak = streakData["currentStreak"] as? Int ?? 0
            
            // Get all badges
            FirestoreService.shared.getAllBadges { badges, error in
                if let error = error {
                    Logger.debug("Error loading badges: \(error.localizedDescription)")
                    return
                }
                
                // Filter for streak badges
                let streakBadges = badges.filter { badge in
                    for (key, _) in badge.criteria {
                        if key == BadgeCriteriaType.streakReached.rawValue {
                            return true
                        }
                    }
                    return false
                }
                
                // Check each badge
                for badge in streakBadges {
                    if let requiredStreak = badge.criteria[BadgeCriteriaType.streakReached.rawValue] as? Int,
                       currentStreak == requiredStreak {
                        // User has just reached this streak milestone
                        // Check if they've already earned this badge
                        FirestoreService.shared.hasUserEarnedBadge(userId: userId, badgeId: badge.id) { hasEarned, error in
                            if let error = error {
                                Logger.debug("Error checking badge status: \(error.localizedDescription)")
                                return
                            }
                            
                            if !hasEarned {
                                // Award the badge
                                FirestoreService.shared.awardBadgeToUser(userId: userId, badgeId: badge.id) { error in
                                    if let error = error {
                                        Logger.debug("Error awarding badge: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    // Schedule notification
                                    NotificationSchedulerService.shared.scheduleAchievementNotification(
                                        title: "\(badge.name) Badge Earned!",
                                        description: badge.description
                                    ) { _, _ in
                                        // Notification scheduled or failed, no action needed
                                    }
                                    
                                    // Show success alert in UI
                                    DispatchQueue.main.async {
                                        self?.showSuccess(
                                            title: "New Badge Earned!",
                                            message: "You've earned the \(badge.name) badge! Keep up the good work."
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Handle errors by showing an alert
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    private func handleError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    /// Show success message
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    /// Load practice data for the last 30 days to power the streak calendar view.
    private func loadCalendarData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86399) // end of today
        let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-29 * 86400)) // 29 days ago start

        FirestoreService.shared.getSessionLogsForDateRange(userId: userId, startDate: startDate, endDate: endDate) { [weak self] logs, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.debug("Error loading calendar data: \(error.localizedDescription)")
                    return
                }

                var dict: [Date: Int] = [:]
                for log in logs {
                    let dayStart = calendar.startOfDay(for: log.endTime)
                    let current = dict[dayStart] ?? 0
                    dict[dayStart] = current + log.duration
                }
                self?.calendarData = dict
            }
        }
    }
}

// MARK: - Extension for Streak Tracker Access

extension StreakStatsViewModel {
    /// Access the user's streak data
    /// - Parameter userId: The user ID
    /// - Parameter completion: Completion handler with streak data and optional error
    func getUserStreakData(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        streakTracker.getUserStreakData(userId: userId, completion: completion)
    }
} 