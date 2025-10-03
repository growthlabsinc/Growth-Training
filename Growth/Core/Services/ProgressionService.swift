import Foundation
import Combine
import FirebaseAuth

/// Overall readiness status against progression criteria
public enum ReadinessStatus: String, Codable, Equatable {
    case notReady      // Criteria not yet met
    case approaching   // At least one criterion close to completion (>70%)
    case ready         // All mandatory criteria met
    case exceeded      // Ready and well beyond criteria (e.g., 150%+)
}

/// Snapshot containing current progress towards each criterion as well as overall status
public struct ProgressionSnapshot {
    public let currentSessions: Int
    public let requiredSessions: Int?
    public let currentConsecutiveDays: Int
    public let requiredConsecutiveDays: Int?
    public let moodProgress: [String: (current: Int, required: Int)]? // e.g. ["good": (2,3)]
    public let currentMinutes: Int
    public let requiredMinutes: Int?
    public let overallStatus: ReadinessStatus
}

/// Service to evaluate a user's readiness to progress to the next stage for a given Growth Method.
/// The evaluation is based on the structured `ProgressionCriteria` defined on each method (Story 9.1).
final class ProgressionService {
    // MARK: - Singleton
    static let shared = ProgressionService()
    private init() {}

    // MARK: - Dependencies
    private let firestoreService = FirestoreService.shared

    // MARK: - Public API
    /// Evaluate readiness for the supplied method and user.
    /// - Parameters:
    ///   - method: The current GrowthMethod being practised.
    ///   - completion: Callback providing an optional `ProgressionSnapshot`.
    ///                 If criteria is nil for the method, the callback returns nil.
    func evaluateReadiness(for method: GrowthMethod,
                           completion: @escaping (ProgressionSnapshot?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        guard let methodId = method.id else {
            completion(nil)
            return
        }
        guard let criteria = method.progressionCriteria else {
            // No structured criteria — cannot compute readiness.
            completion(nil)
            return
        }

        // Fetch up to the latest 500 session logs for the user to compute stats.
        firestoreService.getSessionLogsForUser(userId: userId, limit: 500) { [weak self] logs, error in
            guard error == nil else {
                if let error = error {
                    Logger.error("ProgressionService: Error fetching session logs – \(error.localizedDescription)")
                }
                completion(nil)
                return
            }
            // Filter to logs for this specific method ID
            let methodLogs = logs.filter { $0.methodId == methodId }
            // Sort logs by startTime ascending for streak calculation
            let sortedLogs = methodLogs.sorted(by: { $0.startTime < $1.startTime })

            // Sessions count
            let sessionCount = methodLogs.count

            // Total minutes practiced
            let totalMinutes = methodLogs.reduce(0) { $0 + $1.duration }

            // Consecutive day streak calculation (within this method)
            var maxConsecutive = 0
            var currentStreak = 0
            var previousDate: Date? = nil
            let calendar = Calendar.current
            for log in sortedLogs {
                let currentDate = calendar.startOfDay(for: log.startTime)
                if let prev = previousDate {
                    if let dayDiff = calendar.dateComponents([.day], from: prev, to: currentDate).day {
                        if dayDiff == 1 {
                            // Consecutive day
                            currentStreak += 1
                        } else if dayDiff == 0 {
                            // Same day; maintain current streak (count only unique days)
                        } else {
                            // Break in streak detected
                            currentStreak = 1
                        }
                    }
                } else {
                    currentStreak = 1
                }
                maxConsecutive = max(maxConsecutive, currentStreak)
                previousDate = currentDate
            }

            // Mood feedback progress
            var moodProgress: [String: (current: Int, required: Int)] = [:]
            if let subjectiveReq = criteria.subjectiveFeedbackRequirement {
                for (moodStr, required) in subjectiveReq {
                    let current = methodLogs.filter { $0.moodAfter.rawValue.lowercased() == moodStr.lowercased() }.count
                    moodProgress[moodStr] = (current, required)
                }
            }

            // Evaluate status
            let status = self?.calculateStatus(criteria: criteria,
                                               sessions: sessionCount,
                                               consecutiveDays: maxConsecutive,
                                               totalMinutes: totalMinutes,
                                               moodProgress: moodProgress) ?? .notReady

            let snapshot = ProgressionSnapshot(
                currentSessions: sessionCount,
                requiredSessions: criteria.minSessionsAtThisStage,
                currentConsecutiveDays: maxConsecutive,
                requiredConsecutiveDays: criteria.minConsecutiveDaysPractice,
                moodProgress: moodProgress.isEmpty ? nil : moodProgress,
                currentMinutes: totalMinutes,
                requiredMinutes: criteria.timeSpentAtStageMinutes,
                overallStatus: status
            )
            completion(snapshot)
        }
    }

    // MARK: - Progress User
    /// Attempt to progress the given user to the next stage for the supplied method.
    /// This will only succeed if the current readiness status is `.ready` or `.exceeded`.
    /// On success, records a ProgressionEvent and invokes completion(true).
    func progressUser(for method: GrowthMethod, latestSnapshot: ProgressionSnapshot?, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "ProgressionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        // Validate readiness
        if let snap = latestSnapshot, snap.overallStatus == .ready || snap.overallStatus == .exceeded {
            let newStage = method.stage + 1
            let event = ProgressionEvent(userId: userId,
                                         methodId: method.id ?? "unknown",
                                         fromStage: method.stage,
                                         toStage: newStage,
                                         timestamp: Date(),
                                         criteria: method.progressionCriteria,
                                         note: nil)
            firestoreService.saveProgressionEvent(event) { error in
                if let error = error {
                    completion(false, error)
                    return
                }
                completion(true, nil)
            }
        } else {
            completion(false, NSError(domain: "ProgressionService", code: 403, userInfo: [NSLocalizedDescriptionKey: "User not ready to progress"]))
        }
    }

    // MARK: - History Retrieval
    /// Retrieve progression history events for the specified method for the current user.
    func fetchHistory(for method: GrowthMethod, completion: @escaping ([ProgressionEvent]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        firestoreService.getProgressionEvents(userId: userId, methodId: method.id) { events, _ in
            // Events already ordered ascending by timestamp
            completion(events)
        }
    }

    // MARK: - Helpers
    private func calculateStatus(criteria: ProgressionCriteria,
                                 sessions: Int,
                                 consecutiveDays: Int,
                                 totalMinutes: Int,
                                 moodProgress: [String: (current: Int, required: Int)]) -> ReadinessStatus {
        var fulfilled = 0
        var totalCriteria = 0
        func pct(_ current: Int, _ required: Int?) -> Double {
            guard let req = required, req > 0 else { return 1.0 }
            return Double(current) / Double(req)
        }

        // Sessions
        if let reqSessions = criteria.minSessionsAtThisStage {
            totalCriteria += 1
            if sessions >= reqSessions { fulfilled += 1 }
        }

        // Consecutive days
        if let reqDays = criteria.minConsecutiveDaysPractice {
            totalCriteria += 1
            if consecutiveDays >= reqDays { fulfilled += 1 }
        }

        // Minutes
        if let reqMinutes = criteria.timeSpentAtStageMinutes {
            totalCriteria += 1
            if totalMinutes >= reqMinutes { fulfilled += 1 }
        }

        // Mood
        if let subjectiveReq = criteria.subjectiveFeedbackRequirement {
            totalCriteria += subjectiveReq.count
            for (k, req) in subjectiveReq {
                let current = moodProgress[k]?.current ?? 0
                if current >= req { fulfilled += 1 }
            }
        }

        // Determine status based on fulfillment ratio
        guard totalCriteria > 0 else { return .notReady }
        let ratio = Double(fulfilled) / Double(totalCriteria)
        if ratio >= 1.0 {
            // Check if significantly exceeded (150% threshold on numeric criteria)
            var exceeded = true
            if let reqSessions = criteria.minSessionsAtThisStage {
                exceeded = exceeded && (sessions >= Int(Double(reqSessions) * 1.5))
            }
            if let reqMinutes = criteria.timeSpentAtStageMinutes {
                exceeded = exceeded && (totalMinutes >= Int(Double(reqMinutes) * 1.5))
            }
            if exceeded {
                return .exceeded
            }
            return .ready
        } else if ratio >= 0.7 {
            return .approaching
        } else {
            return .notReady
        }
    }
} 