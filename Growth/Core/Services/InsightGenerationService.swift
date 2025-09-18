//
//  InsightGenerationService.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

class InsightGenerationService {
    static let shared = InsightGenerationService()
    
    private init() {}
    
    func generateInsights(
        from overviewData: ProgressOverviewData,
        sessionLogs: [SessionLog],
        dailyMinutes: [Date: Int],
        adherenceData: RoutineAdherenceData?
    ) -> [ProgressInsight] {
        var insights: [ProgressInsight] = []
        
        // Streak insights
        if let streakInsight = generateStreakInsight(from: dailyMinutes) {
            insights.append(streakInsight)
        }
        
        // Consistency insights
        if let consistencyInsight = generateConsistencyInsight(from: sessionLogs) {
            insights.append(consistencyInsight)
        }
        
        // Progress insights
        if let progressInsight = generateProgressInsight(from: sessionLogs) {
            insights.append(progressInsight)
        }
        
        // Adherence insights
        if let adherenceData = adherenceData,
           let adherenceInsight = generateAdherenceInsight(from: adherenceData) {
            insights.append(adherenceInsight)
        }
        
        // Time of day insights
        if let timeInsight = generateTimeOfDayInsight(from: sessionLogs) {
            insights.append(timeInsight)
        }
        
        // Sort by priority and limit to top 5
        return Array(insights.sorted { $0.priority > $1.priority }.prefix(5))
    }
    
    private func generateStreakInsight(from dailyMinutes: [Date: Int]) -> ProgressInsight? {
        let currentStreak = calculateCurrentStreak(from: dailyMinutes)
        let longestStreak = calculateLongestStreak(from: dailyMinutes)
        
        if currentStreak >= 7 {
            return ProgressInsight(
                type: .streakMilestone,
                title: "Great Streak!",
                message: "You're on a \(currentStreak)-day streak! Keep it going!",
                icon: "flame.fill",
                priority: 10
            )
        } else if currentStreak == 0 && longestStreak > 3 {
            return ProgressInsight(
                type: .trendNegative,
                title: "Get Back on Track",
                message: "Your longest streak was \(longestStreak) days. Start a new one today!",
                icon: "arrow.clockwise",
                priority: 8
            )
        }
        
        return nil
    }
    
    private func generateConsistencyInsight(from sessionLogs: [SessionLog]) -> ProgressInsight? {
        let lastWeekLogs = sessionLogs.filter { 
            $0.startTime > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
        
        if lastWeekLogs.count >= 5 {
            return ProgressInsight(
                type: .consistencyPattern,
                title: "Consistent Practice",
                message: "You've practiced \(lastWeekLogs.count) times this week. Excellent consistency!",
                icon: "calendar.badge.checkmark",
                priority: 7
            )
        } else if lastWeekLogs.count <= 2 {
            return ProgressInsight(
                type: .adherenceLow,
                title: "Increase Frequency",
                message: "Try to practice at least 3-4 times per week for optimal results.",
                icon: "calendar.badge.exclamationmark",
                priority: 6
            )
        }
        
        return nil
    }
    
    private func generateProgressInsight(from sessionLogs: [SessionLog]) -> ProgressInsight? {
        let recentLogs = sessionLogs.filter {
            $0.startTime > Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        }
        
        if recentLogs.isEmpty { return nil }
        
        let averageDuration = recentLogs.map { $0.duration }.reduce(0, +) / recentLogs.count
        let averageIntensity = recentLogs.compactMap { $0.intensity }.reduce(0, +) / max(1, recentLogs.compactMap { $0.intensity }.count)
        
        if averageDuration > 20 * 60 { // 20 minutes
            return ProgressInsight(
                type: .trendPositive,
                title: "Strong Sessions",
                message: "Your average session duration is \(averageDuration / 60) minutes. Great endurance!",
                icon: "timer.circle.fill",
                priority: 5
            )
        } else if averageIntensity < 4 && !recentLogs.compactMap({ $0.intensity }).isEmpty {
            return ProgressInsight(
                type: .adherenceLow,
                title: "Challenge Yourself",
                message: "Your sessions feel easy. Consider advancing to more challenging methods.",
                icon: "gauge.with.needle.fill",
                priority: 6
            )
        }
        
        return nil
    }
    
    private func generateAdherenceInsight(from adherenceData: RoutineAdherenceData) -> ProgressInsight? {
        let percentage = adherenceData.adherencePercentage
        
        if percentage >= 80 {
            return ProgressInsight(
                type: .adherenceHigh,
                title: "Excellent Adherence",
                message: "You're following your routine at \(Int(percentage))%. Keep up the great work!",
                icon: "checkmark.circle.fill",
                priority: 9
            )
        } else if percentage < 50 {
            return ProgressInsight(
                type: .adherenceLow,
                title: "Routine Adjustment",
                message: "You're completing \(Int(percentage))% of your routine. Consider adjusting it to better fit your schedule.",
                icon: "exclamationmark.triangle.fill",
                priority: 7
            )
        }
        
        return nil
    }
    
    private func generateTimeOfDayInsight(from sessionLogs: [SessionLog]) -> ProgressInsight? {
        let calendar = Calendar.current
        var morningCount = 0
        var eveningCount = 0
        
        for log in sessionLogs {
            let hour = calendar.component(.hour, from: log.startTime)
            if hour < 12 {
                morningCount += 1
            } else if hour >= 18 {
                eveningCount += 1
            }
        }
        
        if morningCount > sessionLogs.count * 2 / 3 {
            return ProgressInsight(
                type: .consistencyPattern,
                title: "Morning Routine",
                message: "You prefer morning sessions. This consistency helps build strong habits!",
                icon: "sunrise.fill",
                priority: 4
            )
        } else if eveningCount > sessionLogs.count * 2 / 3 {
            return ProgressInsight(
                type: .consistencyPattern,
                title: "Evening Practice",
                message: "Evening sessions work well for you. Maintain this consistent schedule!",
                icon: "moon.fill",
                priority: 4
            )
        }
        
        return nil
    }
    
    private func calculateCurrentStreak(from dailyMinutes: [Date: Int]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        // Check if user practiced today or yesterday
        let todayMinutes = dailyMinutes[today] ?? 0
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let yesterdayMinutes = dailyMinutes[yesterday] ?? 0
        
        if todayMinutes > 0 {
            // Start from today
        } else if yesterdayMinutes > 0 {
            // Start from yesterday
            currentDate = yesterday
        } else {
            return 0
        }
        
        // Count backwards
        while dailyMinutes[currentDate] ?? 0 > 0 {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }
        
        return streak
    }
    
    private func calculateLongestStreak(from dailyMinutes: [Date: Int]) -> Int {
        let sortedDates = dailyMinutes.keys.sorted()
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for date in sortedDates {
            if let last = lastDate,
               Calendar.current.dateComponents([.day], from: last, to: date).day == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            
            longestStreak = max(longestStreak, currentStreak)
            lastDate = date
        }
        
        return longestStreak
    }
}