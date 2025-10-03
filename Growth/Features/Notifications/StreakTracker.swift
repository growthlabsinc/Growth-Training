import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Service for tracking and managing user practice streaks
class StreakTracker {
    // MARK: - Shared instance
    
    static let shared = StreakTracker()
    
    // MARK: - Properties
    
    /// Hours considered as end of day cutoff
    private let endOfDayCutoffHour = 23
    
    /// FirestoreService instance
    private let firestoreService = FirestoreService.shared
    
    /// NotificationSchedulerService instance
    private let notificationScheduler = NotificationSchedulerService.shared
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    private init() {
        // Set up listeners for session logs when user logs in
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                // Add a small delay to ensure authentication is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.setupSessionLogListener(for: user.uid)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Record a practice session and update streak
    /// - Parameters:
    ///   - duration: The duration of the session in minutes
    ///   - completion: Completion handler with success flag and optional error
    func recordPracticeSession(duration: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "StreakTracker", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        // Create session log
        let sessionLog = SessionLog(
            id: UUID().uuidString,
            userId: userId,
            duration: duration,
            startTime: Date().addingTimeInterval(-Double(duration * 60)),
            endTime: Date(),
            userNotes: "Session logged for streak maintenance",
            methodId: nil,
            sessionIndex: nil,
            moodBefore: .neutral,
            moodAfter: .neutral
        )
        
        // Save session log to Firestore
        firestoreService.saveSessionLog(sessionLog) { [weak self] error in
            if let error = error {
                completion(false, error)
                return
            }
            
            // Update streak data
            self?.updateStreakData(userId: userId) { success, error in
                completion(success, error)
            }
        }
    }
    
    /// Check if user is at risk of breaking their streak
    /// - Parameter completion: Completion handler with hours remaining (if at risk) and optional error
    func checkStreakRisk(completion: @escaping (Int?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "StreakTracker", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        // Get user's streak data
        getUserStreakData(userId: userId) { [weak self] streakData, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let streakData = streakData,
                  let lastPracticeDate = streakData["lastPracticeDate"] as? Timestamp else {
                completion(nil, NSError(domain: "StreakTracker", code: 404, userInfo: [NSLocalizedDescriptionKey: "Streak data not found"]))
                return
            }
            
            let lastPractice = lastPracticeDate.dateValue()
            let now = Date()
            
            // Calculate hours since last practice
            let hoursSinceLastPractice = Int(now.timeIntervalSince(lastPractice) / 3600)
            
            // Calculate hours until end of day (23:59)
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = self.endOfDayCutoffHour
            components.minute = 59
            components.second = 59
            
            guard let endOfDay = calendar.date(from: components) else {
                completion(nil, NSError(domain: "StreakTracker", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day"]))
                return
            }
            
            let hoursUntilEndOfDay = Int(endOfDay.timeIntervalSince(now) / 3600) + 1
            
            // If user hasn't practiced today and there are less than 8 hours left in the day
            if hoursSinceLastPractice >= 24 - hoursUntilEndOfDay && hoursUntilEndOfDay <= 8 {
                completion(hoursUntilEndOfDay, nil)
            } else {
                completion(nil, nil) // Not at risk
            }
        }
    }
    
    /// Refresh streak data for the current user
    /// - Parameter completion: Completion handler with success flag and optional error
    func refreshStreakData(completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "StreakTracker", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        updateStreakData(userId: userId, completion: completion)
    }
    
    /// Get the current streak count for the user
    /// - Parameter completion: Completion handler with streak count and optional error
    func getCurrentStreak(completion: @escaping (Int, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0, NSError(domain: "StreakTracker", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        getUserStreakData(userId: userId) { streakData, error in
            if let error = error {
                completion(0, error)
                return
            }
            
            let streakCount = streakData?["currentStreak"] as? Int ?? 0
            completion(streakCount, nil)
        }
    }
    
    /// Get user's streak data from Firestore
    /// - Parameters:
    ///   - userId: The user ID
    ///   - completion: Completion handler with streak data and optional error
    func getUserStreakData(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        Firestore.firestore().collection("users").document(userId)
            .collection("stats").document("streak")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    // No streak data yet
                    completion([:], nil)
                    return
                }
                
                completion(snapshot.data(), nil)
            }
    }
    
    // MARK: - Private Methods
    
    /// Set up a listener for session logs to update streaks automatically
    /// - Parameter userId: The user ID to monitor
    private func setupSessionLogListener(for userId: String) {
        // Ensure we have a valid authenticated user
        guard Auth.auth().currentUser?.uid == userId else {
            Logger.warning("StreakTracker: Attempted to set up listener for different user or unauthenticated user")
            return
        }
        
        // Listen for new session logs
        Firestore.firestore().collection("sessionLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "endTime", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    // Check if it's a permission error and log appropriately
                    if error.localizedDescription.contains("Missing or insufficient permissions") {
                        Logger.warning("StreakTracker: Permission denied for sessionLogs. User may not have any logs yet.")
                    } else {
                        Logger.error("StreakTracker: Error listening for session logs: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let _ = SessionLog(document: document) else {
                    return
                }
                
                // Update streak data when a new session log is detected
                self?.updateStreakData(userId: userId) { success, error in
                    if let error = error {
                        Logger.error("Error updating streak data: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    /// Update streak data based on session logs
    /// - Parameters:
    ///   - userId: The user ID
    ///   - completion: Completion handler with success flag and optional error
    private func updateStreakData(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Get the most recent session logs
        firestoreService.getSessionLogsForUser(userId: userId, limit: 30) { [weak self] logs, error in
            if let error = error {
                completion(false, error)
                return
            }

            guard !logs.isEmpty else {
                // No logs, create initial streak data
                let streakData: [String: Any] = [
                    "currentStreak": 0,
                    "longestStreak": 0,
                    "lastPracticeDate": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]

                self?.saveStreakData(userId: userId, data: streakData, completion: completion)
                return
            }

            // Sort logs by end time (most recent first)
            let sortedLogs = logs.sorted { $0.endTime > $1.endTime }

            // Calculate streak from session logs
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Group sessions by day
            var sessionDays = Set<Date>()
            for log in sortedLogs {
                let logDay = calendar.startOfDay(for: log.endTime)
                sessionDays.insert(logDay)
            }

            // Convert to sorted array (most recent first)
            let sortedSessionDays = Array(sessionDays).sorted(by: >)

            // Calculate current streak
            var currentStreak = 0
            var checkDate = today

            for sessionDay in sortedSessionDays {
                // If we have a session on the check date, increment streak
                if sessionDay == checkDate {
                    currentStreak += 1
                    // Move to previous day
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = previousDay
                } else if sessionDay < checkDate {
                    // Check if it's the previous day (streak continues)
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    if sessionDay == previousDay {
                        currentStreak += 1
                        checkDate = previousDay
                    } else {
                        // Gap in dates, streak is broken
                        break
                    }
                }
            }

            // If we didn't have a session today or yesterday, streak is 0
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let mostRecentDay = sortedSessionDays.first ?? Date.distantPast
            if mostRecentDay < yesterday {
                currentStreak = 0
            }

            // Get the most recent log for lastPracticeDate
            guard let mostRecentLog = sortedLogs.first else {
                completion(false, NSError(domain: "StreakTracker", code: 404, userInfo: [NSLocalizedDescriptionKey: "No recent logs found"]))
                return
            }

            // Get current streak data for longest streak comparison
            self?.getUserStreakData(userId: userId) { [weak self] streakData, error in
                guard let self = self else { return }

                let oldStreak = streakData?["currentStreak"] as? Int ?? 0
                let longestStreak = streakData?["longestStreak"] as? Int ?? 0
                
                // Update streak data
                let updatedStreakData: [String: Any] = [
                    "currentStreak": currentStreak,
                    "longestStreak": max(longestStreak, currentStreak),
                    "lastPracticeDate": mostRecentLog.endTime,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                self.saveStreakData(userId: userId, data: updatedStreakData) { success, error in
                    // Schedule streak alert if needed
                    self.checkStreakRisk { hoursRemaining, _ in
                        if let hoursRemaining = hoursRemaining {
                            self.notificationScheduler.scheduleStreakAlert(hoursRemaining: hoursRemaining) { _, _ in
                                // Alert scheduled or failed, no action needed
                            }
                        }
                    }
                    
                    // Check for streak milestones and send achievement notifications
                    self.checkStreakMilestones(oldStreak: oldStreak, newStreak: currentStreak)
                    
                    completion(success, error)
                }
            }
        }
    }
    
    /// Check for streak milestones and send achievement notifications when reached
    /// - Parameters:
    ///   - oldStreak: Previous streak count
    ///   - newStreak: New streak count
    private func checkStreakMilestones(oldStreak: Int, newStreak: Int) {
        let milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365]
        
        for milestone in milestones {
            // Check if we've crossed a milestone
            if oldStreak < milestone && newStreak >= milestone {
                // Send achievement notification
                let title = "\(milestone) Day Streak!"
                let description = "Congratulations! You've maintained your practice streak for \(milestone) days. Keep up the great work!"
                
                notificationScheduler.scheduleAchievementNotification(
                    title: title,
                    description: description
                ) { _, _ in
                    // Notification scheduled or failed, no action needed
                    Logger.debug("Scheduled milestone notification for \(milestone) day streak")
                }
                
                // Story 8.5: Trigger affirmation banner for streak maintenance
                _ = AffirmationService.shared.randomAffirmation(for: .streakMaintenance)
                
                // Only process the first milestone crossed in this update
                break
            }
        }
    }
    
    /// Save streak data to Firestore
    /// - Parameters:
    ///   - userId: The user ID
    ///   - data: The streak data to save
    ///   - completion: Completion handler with success flag and optional error
    private func saveStreakData(userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        Firestore.firestore().collection("users").document(userId)
            .collection("stats").document("streak")
            .setData(data, merge: true) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
    }
} 