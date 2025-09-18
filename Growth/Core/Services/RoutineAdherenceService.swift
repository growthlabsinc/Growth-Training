//
//  RoutineAdherenceService.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service responsible for calculating routine adherence metrics
class RoutineAdherenceService: ObservableObject {
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Calculate routine adherence for a given time range
    /// - Parameters:
    ///   - routine: The routine to calculate adherence for
    ///   - timeRange: The time range for calculation (week, month, quarter, year)
    ///   - userId: The user ID for fetching session logs
    /// - Returns: RoutineAdherenceData containing adherence metrics
    @MainActor
    func calculateAdherence(
        for routine: Routine,
        timeRange: TimeRange,
        userId: String
    ) async throws -> RoutineAdherenceData {
        Logger.debug("[RoutineAdherenceService] Calculating adherence for routine: \(routine.name), timeRange: \(timeRange.rawValue)")
        
        // Get date range
        let dateRange = getDateRange(for: timeRange)
        Logger.debug("[RoutineAdherenceService] Date range: \(dateRange.start) to \(dateRange.end)")
        
        // Fetch routine progress to get the actual start date
        let routineProgress = try await fetchRoutineProgress(userId: userId, routineId: routine.id)
        let routineStartDate = routineProgress?.startDate ?? dateRange.start
        Logger.debug("[RoutineAdherenceService] Routine start date: \(routineStartDate)")
        Logger.debug("[RoutineAdherenceService] Routine type: \(routine.schedulingType?.rawValue ?? "sequential")")
        Logger.debug("[RoutineAdherenceService] Routine schedule count: \(routine.schedule.count)")
        Logger.debug("[RoutineAdherenceService] Current progress day: \(routineProgress?.currentDayNumber ?? 0)")
        
        // Fetch session logs for the date range
        let sessionLogs = try await fetchSessionLogs(
            userId: userId,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        Logger.debug("[RoutineAdherenceService] Found \(sessionLogs.count) session logs")
        
        // Calculate expected sessions
        let expectedSessions = calculateExpectedSessions(
            routine: routine,
            startDate: dateRange.start,
            endDate: dateRange.end,
            routineStartDate: routineStartDate
        )
        Logger.debug("[RoutineAdherenceService] Expected sessions: \(expectedSessions)")
        
        // Match sessions to routine schedule
        let sessionDetails = matchSessionsToSchedule(
            sessions: sessionLogs,
            routine: routine,
            dateRange: dateRange,
            routineStartDate: routineStartDate
        )
        Logger.debug("[RoutineAdherenceService] Session details count: \(sessionDetails.count)")
        
        // Calculate completed sessions by counting actual completed methods
        let completedSessions = calculateCompletedMethodCount(
            sessions: sessionLogs,
            routine: routine,
            dateRange: dateRange,
            routineStartDate: routineStartDate
        )
        
        Logger.debug("[RoutineAdherenceService] Completed sessions: \(completedSessions)")
        Logger.debug("[RoutineAdherenceService] Session details: \(sessionDetails)")
        
        // Calculate adherence percentage
        let adherencePercentage = expectedSessions > 0 
            ? Double(completedSessions) / Double(expectedSessions) * 100.0 
            : 0.0
        
        Logger.debug("[RoutineAdherenceService] Adherence percentage: \(adherencePercentage)%")
        
        return RoutineAdherenceData(
            adherencePercentage: adherencePercentage,
            completedSessions: completedSessions,
            expectedSessions: expectedSessions,
            timeRange: timeRange,
            sessionDetails: sessionDetails
        )
    }
    
    // MARK: - Private Methods
    
    /// Fetch routine progress from Firestore
    private func fetchRoutineProgress(userId: String, routineId: String) async throws -> RoutineProgress? {
        return try await withCheckedThrowingContinuation { continuation in
            RoutineProgressService.shared.fetchProgress(userId: userId, routineId: routineId) { progress in
                continuation.resume(returning: progress)
            }
        }
    }
    
    /// Fetch session logs for a date range
    private func fetchSessionLogs(
        userId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [SessionLog] {
        // Fetching session logs
        
        // Adjust endDate to include the entire day
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        let snapshot = try await db.collection("sessionLogs")
            .whereField("userId", isEqualTo: userId)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: endOfDay))
            .getDocuments()
        
        Logger.debug("[RoutineAdherenceService] Found \(snapshot.documents.count) session documents")
        
        let sessionLogs = snapshot.documents.compactMap { document -> SessionLog? in
            // Try manual parsing first to debug
            _ = document.data()
            Logger.debug("[RoutineAdherenceService] Processing document: \(document.documentID)")
            
            // Try using the document initializer
            if let sessionLog = SessionLog(document: document) {
                Logger.debug("[RoutineAdherenceService] Session found - methodId: \(sessionLog.methodId ?? "nil"), date: \(sessionLog.startTime)")
                return sessionLog
            }
            
            // Fallback to Codable
            if let sessionLog = try? document.data(as: SessionLog.self) {
                Logger.debug("[RoutineAdherenceService] Session found (Codable) - methodId: \(sessionLog.methodId ?? "nil")")
                return sessionLog
            }
            
            Logger.debug("[RoutineAdherenceService] Failed to parse session log document: \(document.documentID)")
            return nil
        }
        
        return sessionLogs
    }
    
    /// Calculate expected sessions based on routine schedule
    private func calculateExpectedSessions(
        routine: Routine,
        startDate: Date,
        endDate: Date,
        routineStartDate: Date
    ) -> Int {
        let calendar = Calendar.current
        var expectedCount = 0
        var currentDate = startDate
        
        // Calculating expected sessions
        
        // Check the scheduling type to determine how to count
        let schedulingType = routine.schedulingType ?? .sequential
        
        if schedulingType == .weekday {
            // For weekday-based routines, match by day of week
            while currentDate <= endDate {
                let weekday = calendar.component(.weekday, from: currentDate)
                // Convert from Calendar weekday (1=Sunday, 2=Monday...) to routine day (1=Monday, 2=Tuesday...)
                // Calendar: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
                // Routine:  1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
                let dayNumber = weekday == 1 ? 7 : weekday - 1
                
                // Processing date
                
                if let daySchedule = routine.schedule.first(where: { $0.day == dayNumber }) {
                    // Only count non-rest days as expected sessions
                    if !daySchedule.isRestDay {
                        // Count the actual number of methods scheduled for this day
                        let methodCount = daySchedule.methodIds?.count ?? 0
                        if methodCount > 0 {
                            expectedCount += methodCount
                            Logger.debug("[RoutineAdherenceService] Expected \(methodCount) weekday sessions on \(currentDate) - Day \(dayNumber)")
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        } else {
            // For sequential routines, calculate based on actual routine start date
            // Use start of day for both dates to get accurate day count
            let startOfRoutineDate = calendar.startOfDay(for: routineStartDate)
            
            // Count scheduled days within the time range
            while currentDate <= endDate {
                // Calculate which day of the routine this date corresponds to
                let startOfCurrentDate = calendar.startOfDay(for: currentDate)
                let daysSinceStart = calendar.dateComponents([.day], from: startOfRoutineDate, to: startOfCurrentDate).day ?? 0

                // For days before routine start, we expect 1 session per day (generic expectation)
                // For days after routine start, use the actual routine schedule
                if daysSinceStart < 0 {
                    // Before routine was selected - expect 1 session per day for adherence
                    // This allows us to give credit for sessions done on previous routines
                    expectedCount += 1
                    Logger.debug("[RoutineAdherenceService] Expected 1 session on \(currentDate) (before routine start)")
                } else {
                    // After routine start - use actual routine schedule
                    let routineDayNumber = (daysSinceStart % routine.duration) + 1

                    // Check if this routine day is in the schedule
                    if let daySchedule = routine.schedule.first(where: { $0.day == routineDayNumber }) {
                        // Only count non-rest days as expected sessions
                        // Rest days are optional and shouldn't count against adherence
                        if !daySchedule.isRestDay {
                            // Count the actual number of methods scheduled for this day
                            let methodCount = daySchedule.methodIds?.count ?? 0
                            if methodCount > 0 {
                                expectedCount += methodCount
                                Logger.debug("[RoutineAdherenceService] Expected \(methodCount) sessions on \(currentDate) - Routine Day \(routineDayNumber)")
                            }
                        } else {
                            Logger.debug("[RoutineAdherenceService] Rest day on \(currentDate) - Routine Day \(routineDayNumber), not counting as expected")
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Total expected sessions calculated
        return expectedCount
    }
    
    /// Calculate the total number of completed methods
    private func calculateCompletedMethodCount(
        sessions: [SessionLog],
        routine: Routine,
        dateRange: (start: Date, end: Date),
        routineStartDate: Date
    ) -> Int {
        let calendar = Calendar.current
        var completedCount = 0
        var currentDate = dateRange.start
        
        let schedulingType = routine.schedulingType ?? .sequential
        
        if schedulingType == .weekday {
            // For weekday-based routines
            while currentDate <= dateRange.end {
                let weekday = calendar.component(.weekday, from: currentDate)
                let dayNumber = weekday == 1 ? 7 : weekday - 1
                
                if let daySchedule = routine.schedule.first(where: { $0.day == dayNumber }) {
                    if !daySchedule.isRestDay {
                        if let scheduledMethodIds = daySchedule.methodIds, !scheduledMethodIds.isEmpty {
                            // Count how many of the scheduled methods were completed
                            for methodId in scheduledMethodIds {
                                let isCompleted = sessions.contains { sessionLog in
                                    calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate) &&
                                    sessionLog.methodId == methodId
                                }
                                if isCompleted {
                                    completedCount += 1
                                }
                            }
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        } else {
            // For sequential routines
            // Use start of day for both dates to get accurate day count
            let startOfRoutineDate = calendar.startOfDay(for: routineStartDate)
            
            while currentDate <= dateRange.end {
                let startOfCurrentDate = calendar.startOfDay(for: currentDate)
                let daysSinceStart = calendar.dateComponents([.day], from: startOfRoutineDate, to: startOfCurrentDate).day ?? 0
                
                // For days before routine start, count ANY completed session
                // For days after routine start, count specific methods from routine
                if daysSinceStart < 0 {
                    // Before routine was selected - count any session as 1 completion
                    let hasAnySession = sessions.contains { sessionLog in
                        calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate)
                    }
                    if hasAnySession {
                        completedCount += 1
                    }
                } else {
                    // After routine start - count specific methods
                    let routineDayNumber = (daysSinceStart % routine.duration) + 1

                    if let daySchedule = routine.schedule.first(where: { $0.day == routineDayNumber }) {
                        if !daySchedule.isRestDay {
                            if let scheduledMethodIds = daySchedule.methodIds, !scheduledMethodIds.isEmpty {
                                // Count how many of the scheduled methods were completed
                                for methodId in scheduledMethodIds {
                                    let isCompleted = sessions.contains { sessionLog in
                                        calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate) &&
                                        sessionLog.methodId == methodId
                                    }
                                    if isCompleted {
                                        completedCount += 1
                                    }
                                }
                            }
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return completedCount
    }
    
    /// Match sessions to routine schedule
    private func matchSessionsToSchedule(
        sessions: [SessionLog],
        routine: Routine,
        dateRange: (start: Date, end: Date),
        routineStartDate: Date
    ) -> [Date: Bool] {
        let calendar = Calendar.current
        var sessionDetails: [Date: Bool] = [:]
        var currentDate = dateRange.start
        
        // Matching sessions to schedule
        
        // Check the scheduling type to determine how to match
        let schedulingType = routine.schedulingType ?? .sequential
        
        if schedulingType == .weekday {
            // For weekday-based routines, match by day of week
            while currentDate <= dateRange.end {
                let startOfDay = calendar.startOfDay(for: currentDate)
                let weekday = calendar.component(.weekday, from: currentDate)
                // Convert from Calendar weekday (1=Sunday, 2=Monday...) to routine day (1=Monday, 2=Tuesday...)
                let dayNumber = weekday == 1 ? 7 : weekday - 1
                
                if let daySchedule = routine.schedule.first(where: { $0.day == dayNumber }) {
                    // Skip rest days - they don't count for adherence
                    if !daySchedule.isRestDay {
                        if let scheduledMethodIds = daySchedule.methodIds, !scheduledMethodIds.isEmpty {
                            // Check if any of the scheduled methods were completed
                            let hasSession = sessions.contains { sessionLog in
                                if calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate),
                                   let methodId = sessionLog.methodId {
                                    return scheduledMethodIds.contains(methodId)
                                }
                                return false
                            }
                            sessionDetails[startOfDay] = hasSession
                            
                            Logger.debug("[RoutineAdherenceService] Weekday \(currentDate), Day \(dayNumber), Has Session: \(hasSession)")
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        } else {
            // For sequential routines, we need to match based on the routine day progression
            // Use start of day for both dates to get accurate day count
            let startOfRoutineDate = calendar.startOfDay(for: routineStartDate)
            
            while currentDate <= dateRange.end {
                let startOfDay = calendar.startOfDay(for: currentDate)

                // Calculate which day of the routine this date corresponds to
                let daysSinceStart = calendar.dateComponents([.day], from: startOfRoutineDate, to: startOfDay).day ?? 0

                // For days BEFORE the routine was selected, we should count ANY session as valid
                // This handles routine changes - we don't retroactively apply new routine requirements
                if daysSinceStart < 0 {
                    // This date is before the routine was selected
                    // Count ANY session as adherence (user may have been on a different routine)
                    let hasSession = sessions.contains { sessionLog in
                        calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate)
                    }

                    if hasSession {
                        // Count this as adherence since user did practice, even if on different routine
                        sessionDetails[startOfDay] = true
                        Logger.debug("[RoutineAdherenceService] Date: \(currentDate) (before routine start), Has ANY Session: true")
                    }
                } else {
                    // Date is after routine start - normal calculation
                    let routineDayNumber = (daysSinceStart % routine.duration) + 1

                    // Check if this routine day is in the schedule
                    if let daySchedule = routine.schedule.first(where: { $0.day == routineDayNumber }) {
                        // Skip rest days - they don't count for adherence
                        if !daySchedule.isRestDay {
                            if let scheduledMethodIds = daySchedule.methodIds, !scheduledMethodIds.isEmpty {
                                // Regular day - check if any of the scheduled methods were completed
                                let hasSession = sessions.contains { sessionLog in
                                    if calendar.isDate(sessionLog.startTime, inSameDayAs: currentDate) {
                                        // If we have a method ID, check if it matches the scheduled methods
                                        if let methodId = sessionLog.methodId {
                                            return scheduledMethodIds.contains(methodId)
                                        }
                                        // If no method ID, count any session as valid
                                        // (for backwards compatibility with older sessions)
                                        return true
                                    }
                                    return false
                                }

                                // Track if session was completed
                                sessionDetails[startOfDay] = hasSession

                                Logger.debug("[RoutineAdherenceService] Date: \(currentDate), Routine Day: \(routineDayNumber), Scheduled Methods: \(daySchedule.methodIds ?? []), Has Session: \(hasSession)")
                            }
                        } else {
                            Logger.debug("[RoutineAdherenceService] Date: \(currentDate), Routine Day: \(routineDayNumber) is a rest day, skipping")
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Session details processed
        return sessionDetails
    }
    
    /// Get date range for a time range
    private func getDateRange(for timeRange: TimeRange) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        switch timeRange {
        case .week:
            // Get start of week (Monday)
            var startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            
            // Ensure we're using Monday as the first day of the week
            if calendar.firstWeekday != 2 { // 2 = Monday
                // Adjust to Monday if needed
                let weekday = calendar.component(.weekday, from: startOfWeek)
                if weekday == 1 { // Sunday
                    startOfWeek = calendar.date(byAdding: .day, value: 1, to: startOfWeek) ?? startOfWeek
                }
            }
            
            // Week range calculated
            return (startOfWeek, today)
            
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            return (startOfMonth, today)
            
        case .quarter:
            // Calculate start of quarter
            let month = calendar.component(.month, from: today)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: today)
            components.month = quarterStartMonth
            components.day = 1
            let startOfQuarter = calendar.date(from: components) ?? today
            return (startOfQuarter, today)
            
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: today)?.start ?? today
            return (startOfYear, today)
            
        case .all:
            // For "all time", go back 10 years
            let startDate = calendar.date(byAdding: .year, value: -10, to: today) ?? today
            return (startDate, today)
        }
    }
}