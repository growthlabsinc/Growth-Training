import Foundation
import Combine
import FirebaseAuth // For getting current user ID

class ProgressViewModel: ObservableObject {
    @Published var loggedDates: Set<DateComponents> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Aggregated Data (Story 14.6)
    /// Dictionary keyed by startOfDay date -> total minutes practiced
    @Published var dailyMinutes: [Date: Int] = [:]

    /// Currently selected time range for timeline/heatmap
    @Published var selectedTimeRange: TimeRange = .month {
        didSet {
            // Recalculate adherence when time range changes
            Task { @MainActor in
                await loadRoutineAdherence()
            }
        }
    }

    /// Computed timeline data for selected range (sorted ascending by date)
    var timelineData: [ProgressTimelineData] {
        let calendar = Calendar.current
        let start = selectedTimeRange.startDate
        return (0..<selectedTimeRange.daySpan).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            let minutes = dailyMinutes[startOfDay] ?? 0
            return ProgressTimelineData(date: startOfDay, totalMinutes: minutes)
        }
    }

    // Quick stats
    var totalMinutesInRange: Int {
        timelineData.reduce(0) { $0 + $1.totalMinutes }
    }
    var totalSessionsInRange: Int {
        // each day with >0 minutes counts as at least 1 session; more precise counts require storing session counts.
        timelineData.reduce(0) { $0 + ($1.totalMinutes > 0 ? 1 : 0) }
    }
    var averageSessionMinutes: Int {
        guard totalSessionsInRange > 0 else { return 0 }
        return totalMinutesInRange / totalSessionsInRange
    }

    // Session logs cached for drill-down
    private(set) var sessionLogs: [SessionLog] = []

    // MARK: - Trend calculations
    private var previousPeriodTotals: (minutes: Int, sessions: Int) {
        let calendar = Calendar.current
        let endPrev = selectedTimeRange.startDate.addingTimeInterval(-86400) // day before current period starts
        guard let startPrev = calendar.date(byAdding: .day, value: -selectedTimeRange.daySpan+1, to: endPrev) else { return (0,0) }

        var minutes = 0
        var sessions = 0
        for log in sessionLogs {
            if log.startTime >= startPrev && log.startTime <= endPrev {
                minutes += log.duration
                // count unique days as sessions? Use each log counts as 1 session.
                sessions += 1
            }
        }
        return (minutes, sessions)
    }

    var trendMinutesPercent: Double? {
        let previous = previousPeriodTotals.minutes
        guard previous > 0 else { return nil }
        return (Double(totalMinutesInRange - previous) / Double(previous)) * 100.0
    }

    var trendSessionsPercent: Double? {
        let previous = previousPeriodTotals.sessions
        guard previous > 0 else { return nil }
        return (Double(totalSessionsInRange - previous) / Double(previous)) * 100.0
    }

    var trendAvgDurationPercent: Double? {
        let previousAvg = previousPeriodTotals.sessions > 0 ? Double(previousPeriodTotals.minutes) / Double(previousPeriodTotals.sessions) : 0
        guard previousAvg > 0 else { return nil }
        return (Double(averageSessionMinutes) - previousAvg) / previousAvg * 100.0
    }

    private var firestoreService = FirestoreService.shared
    private let adherenceService = RoutineAdherenceService()
    private let routineService = RoutineService.shared
    private let userService = UserService()
    private let insightService = InsightGenerationService.shared
    @Published var routineAdherenceData: RoutineAdherenceData?
    @Published var dismissedInsightIds: Set<String> = [] {
        didSet {
            saveDismissedInsights()
        }
    }
    @Published var currentRoutine: Routine?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    private var lastFetchTime: Date?
    private let fetchDebounceInterval: TimeInterval = 2.0 // Minimum 2 seconds between fetches
    
    // UserDefaults key for persisting dismissed insights
    private var dismissedInsightsKey: String {
        guard let userId = currentUserID else { return "dismissedInsights" }
        return "dismissedInsights_\(userId)"
    }

    init() {
        loadDismissedInsights()
        fetchLoggedDates()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for session logged notifications to refresh data
        NotificationCenter.default.publisher(for: .sessionLogged)
            .sink { [weak self] _ in
                // Refresh data when a new session is logged
                self?.fetchLoggedDates()
            }
            .store(in: &cancellables)
    }

    func fetchLoggedDates() {
        guard let userID = currentUserID else {
            errorMessage = "User not authenticated."
            return
        }

        // Debounce rapid calls
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < fetchDebounceInterval {
            // Skip this fetch if it's too soon after the last one
            return
        }
        
        lastFetchTime = Date()
        isLoading = true
        errorMessage = nil
        
        // Use a large limit to get all logs for now, or implement pagination later if needed.
        firestoreService.getSessionLogsForUser(userId: userID, limit: 1000) { [weak self] (sessionLogs, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error fetching session logs: \(error.localizedDescription)"
                    Logger.error("[ProgressViewModel] Error fetching session logs: \(error)")
                    return
                }
                
                // Only log in debug builds, and only once
                #if DEBUG
                if sessionLogs.count > 0 && self?.sessionLogs.count != sessionLogs.count {
                    Logger.debug("[ProgressViewModel] Fetched \(sessionLogs.count) session logs")
                }
                #endif
                
                var dates = Set<DateComponents>()
                let calendar = Calendar.current
                
                // Clear existing data first
                self?.dailyMinutes.removeAll()
                
                for log in sessionLogs {
                    // Get year, month, day components to represent a unique day
                    let components = calendar.dateComponents([.year, .month, .day], from: log.startTime)
                    if let date = calendar.date(from: components) {
                        let startOfDay = calendar.startOfDay(for: date)
                        // Add to dictionary
                        self?.dailyMinutes[startOfDay, default: 0] += log.duration
                    }
                    dates.insert(components)
                }
                self?.loggedDates = dates
                self?.sessionLogs = sessionLogs
                
                // Only log in debug builds when data actually changes
                #if DEBUG
                if let previousCount = self?.dailyMinutes.count,
                   previousCount != self?.dailyMinutes.count {
                    Logger.debug("[ProgressViewModel] Processed data: \(self?.dailyMinutes.count ?? 0) days with sessions")
                }
                #endif
                
                // Load routine information after fetching session logs
                Task { @MainActor in
                    await self?.loadRoutineAdherence()
                    // Generate overview data after fetching session logs and routine
                    self?.generateOverviewData()
                }
            }
        }
    }

    /// Convenience
    func sessions(on date: Date) -> [SessionLog] {
        let cal = Calendar.current
        return sessionLogs.filter { cal.isDate($0.startTime, inSameDayAs: date) }
    }
    
    // MARK: - Overview Data Aggregation (Story 17.1)
    
    /// Overview data for the consolidated progress dashboard
    @Published var overviewData: ProgressOverviewData = ProgressOverviewData(isLoading: true)
    
    /// Generate overview data by aggregating existing metrics
    func generateOverviewData() {
        let calendarSummary = generateCalendarSummary()
        let statistics = generateStatisticsHighlights()
        let achievements = generateAchievementHighlights()
        
        // Generate insights
        let allInsights = insightService.generateInsights(
            from: overviewData,
            sessionLogs: sessionLogs,
            dailyMinutes: dailyMinutes,
            adherenceData: routineAdherenceData
        )
        
        // Filter out dismissed insights
        let activeInsights = allInsights.filter { !dismissedInsightIds.contains($0.id) }
        
        self.overviewData = ProgressOverviewData(
            calendarSummary: calendarSummary,
            statistics: statistics,
            achievements: achievements,
            insights: activeInsights,
            isLoading: false,
            errorMessage: nil
        )
    }
    
    /// Refresh overview data including adherence calculation
    func refreshOverviewData() {
        // First load adherence data
        Task { @MainActor in
            await loadRoutineAdherence()
            // Then regenerate overview data
            generateOverviewData()
        }
    }
    
    /// Load routine adherence data
    private func loadRoutineAdherence() async {
        guard let userId = currentUserID else { 
            Logger.debug("[ProgressViewModel] No user ID available for adherence calculation")
            return 
        }
        
        // Get selected routine ID using callback-based API
        await withCheckedContinuation { continuation in
            userService.fetchSelectedRoutineId(userId: userId) { routineId in
                guard let routineId = routineId else {
                    Logger.debug("[ProgressViewModel] No routine selected for user")
                    self.routineAdherenceData = nil
                    continuation.resume()
                    return
                }
                
                Logger.debug("[ProgressViewModel] Found selected routine: \(routineId)")
                
                // Fetch routine details (checking both custom and main collections)
                self.routineService.fetchRoutineFromAnySource(by: routineId, userId: userId) { result in
                    switch result {
                    case .success(let routine):
                        Logger.debug("[ProgressViewModel] Fetched routine: \(routine.name)")
                        Task {
                            do {
                                let adherenceData = try await self.adherenceService.calculateAdherence(
                                    for: routine,
                                    timeRange: self.selectedTimeRange,
                                    userId: userId
                                )
                                Logger.debug("[ProgressViewModel] Calculated adherence: \(adherenceData.adherencePercentage)% (\(adherenceData.completedSessions)/\(adherenceData.expectedSessions) sessions)")
                                Logger.debug("[ProgressViewModel] Session details count: \(adherenceData.sessionDetails.count)")
                                await MainActor.run {
                                    self.currentRoutine = routine
                                    self.routineAdherenceData = adherenceData
                                }
                            } catch {
                                Logger.error("[ProgressViewModel] Error calculating adherence: \(error.localizedDescription)")
                                await MainActor.run {
                                    self.currentRoutine = routine
                                    self.routineAdherenceData = nil
                                }
                            }
                            continuation.resume()
                        }
                    case .failure(let error):
                        Logger.error("[ProgressViewModel] Failed to fetch routine: \(error.localizedDescription)")
                        self.currentRoutine = nil
                        self.routineAdherenceData = nil
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Generate calendar summary data for overview
    private func generateCalendarSummary() -> CalendarSummaryData {
        let monthlyData = generateCalendarItems(for: .month)
        let weeklyData = generateCalendarItems(for: .week)
        
        // Calculate total sessions including rest days
        let dataForRange = selectedTimeRange == .week ? weeklyData : monthlyData
        let restDaysCompleted = dataForRange.filter { $0.isRestDay && $0.restDayCompleted }.count
        let totalSessionsWithRest = totalSessionsInRange + restDaysCompleted
        
        return CalendarSummaryData(
            monthlyData: monthlyData,
            weeklyData: weeklyData,
            selectedRange: selectedTimeRange,
            totalSessions: totalSessionsWithRest,
            totalMinutes: totalMinutesInRange
        )
    }
    
    /// Generate calendar items for a specific time range
    private func generateCalendarItems(for timeRange: TimeRange) -> [CalendarSummaryItem] {
        let calendar = Calendar.current
        let startDate = timeRange.startDate
        
        return (0..<timeRange.daySpan).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            let dayMinutes = dailyMinutes[startOfDay] ?? 0
            let daySessions = sessions(on: startOfDay)
            
            // Check if this is a rest day in the current routine
            let isRestDay = isRestDay(for: date)
            
            // For rest days, consider them automatically completed
            // They can optionally have wellness activities logged
            let restDayCompleted = isRestDay
            
            return CalendarSummaryItem(
                date: startOfDay,
                sessionCount: daySessions.count,
                totalMinutes: dayMinutes,
                isRestDay: isRestDay,
                restDayCompleted: restDayCompleted
            )
        }
    }
    
    /// Generate statistics highlights for overview
    private func generateStatisticsHighlights() -> [StatisticHighlight] {
        var highlights: [StatisticHighlight] = []
        
        // Total Sessions
        let sessionsTrend = trendSessionsPercent.map { TrendInfo(percentageChange: $0, description: "vs last \(selectedTimeRange.rawValue.lowercased())") }
        highlights.append(StatisticHighlight(
            title: "Total Sessions",
            value: "\(totalSessionsInRange)",
            subtitle: "In last \(selectedTimeRange.rawValue.lowercased())",
            iconName: "figure.mind.and.body",
            trend: sessionsTrend,
            colorTheme: "GrowthGreen"
        ))
        
        // Total Time
        let minutesTrend = trendMinutesPercent.map { TrendInfo(percentageChange: $0, description: "vs last \(selectedTimeRange.rawValue.lowercased())") }
        let hours = totalMinutesInRange / 60
        let minutes = totalMinutesInRange % 60
        let timeValue = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        highlights.append(StatisticHighlight(
            title: "Total Time",
            value: timeValue,
            subtitle: "Practice time",
            iconName: "clock.fill",
            trend: minutesTrend,
            colorTheme: "BrightTeal"
        ))
        
        // Average Session
        let avgTrend = trendAvgDurationPercent.map { TrendInfo(percentageChange: $0, description: "vs last \(selectedTimeRange.rawValue.lowercased())") }
        highlights.append(StatisticHighlight(
            title: "Average Session",
            value: "\(averageSessionMinutes)m",
            subtitle: "Per session",
            iconName: "chart.bar.fill",
            trend: avgTrend,
            colorTheme: "MintGreen"
        ))
        
        // Current Streak
        let currentStreak = calculateCurrentStreak()
        highlights.append(StatisticHighlight(
            title: "Current Streak",
            value: "\(currentStreak)",
            subtitle: currentStreak == 1 ? "day" : "days",
            iconName: "flame.fill",
            trend: nil,
            colorTheme: "ErrorColor"
        ))
        
        // Routine Adherence
        if let adherenceData = routineAdherenceData {
            highlights.append(StatisticHighlight(
                title: "Routine Adherence",
                value: "\(adherenceData.formattedPercentage)%",
                subtitle: adherenceData.progressDescription,
                iconName: "target",
                trend: nil,
                colorTheme: adherenceData.colorTheme
            ))
        }
        
        return highlights
    }
    
    /// Generate achievement highlights for overview
    private func generateAchievementHighlights() -> [AchievementHighlight] {
        var highlights: [AchievementHighlight] = []
        
        // Mock achievements for now - in a real implementation, these would come from a badge service
        if totalSessionsInRange >= 7 {
            highlights.append(AchievementHighlight(
                title: "Consistent Practitioner",
                description: "Completed 7+ sessions this \(selectedTimeRange.rawValue.lowercased())",
                iconName: "star.fill",
                isEarned: true,
                earnedDate: Date(),
                colorTheme: "GrowthGreen"
            ))
        } else {
            let progress = Double(totalSessionsInRange) / 7.0
            highlights.append(AchievementHighlight(
                title: "Consistent Practitioner",
                description: "\(totalSessionsInRange)/7 sessions completed",
                iconName: "star",
                isEarned: false,
                progress: progress,
                colorTheme: "GrowthGreen"
            ))
        }
        
        if totalMinutesInRange >= 300 {
            highlights.append(AchievementHighlight(
                title: "Time Master",
                description: "Practiced for 5+ hours this \(selectedTimeRange.rawValue.lowercased())",
                iconName: "clock.badge.checkmark.fill",
                isEarned: true,
                earnedDate: Date(),
                colorTheme: "BrightTeal"
            ))
        } else {
            let progress = Double(totalMinutesInRange) / 300.0
            highlights.append(AchievementHighlight(
                title: "Time Master",
                description: "\(totalMinutesInRange)/300 minutes completed",
                iconName: "clock.badge.checkmark",
                isEarned: false,
                progress: progress,
                colorTheme: "BrightTeal"
            ))
        }
        
        return highlights
    }
    
    /// Dismiss an insight
    func dismissInsight(_ insightId: String) {
        dismissedInsightIds.insert(insightId)
        // Update the overview data to reflect the dismissed insight
        let filteredInsights = overviewData.insights.filter { $0.id != insightId }
        overviewData = ProgressOverviewData(
            calendarSummary: overviewData.calendarSummary,
            statistics: overviewData.statistics,
            achievements: overviewData.achievements,
            insights: filteredInsights,
            isLoading: false,
            errorMessage: nil
        )
    }
    
    // MARK: - Persistence Methods
    
    /// Save dismissed insights to UserDefaults
    private func saveDismissedInsights() {
        let idsArray = Array(dismissedInsightIds)
        UserDefaults.standard.set(idsArray, forKey: dismissedInsightsKey)
    }
    
    /// Load dismissed insights from UserDefaults
    private func loadDismissedInsights() {
        if let idsArray = UserDefaults.standard.stringArray(forKey: dismissedInsightsKey) {
            dismissedInsightIds = Set(idsArray)
        }
    }
    
    /// Calculate current streak of consecutive days with practice
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        // Check if user practiced today or yesterday (allow for flexibility)
        let todayMinutes = dailyMinutes[today] ?? 0
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayMinutes = dailyMinutes[yesterdayDate] ?? 0
        
        // Start from yesterday if no practice today, or today if there was practice
        if todayMinutes > 0 {
            // Start counting from today
        } else if yesterdayMinutes > 0 {
            // Start counting from yesterday
            currentDate = yesterdayDate
        } else {
            // No recent practice
            return 0
        }
        
        // Count consecutive days backwards
        while true {
            let minutes = dailyMinutes[currentDate] ?? 0
            if minutes > 0 {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Public Methods for Stats Calculations
    
    /// Get method distribution statistics
    func getMethodDistribution() -> [(method: String, minutes: Int, percentage: Double)] {
        var methodStats: [String: Int] = [:]
        let totalMinutes = sessionLogs.reduce(0) { $0 + $1.duration }
        
        for session in sessionLogs {
            let methodName = session.variation ?? "Practice Session"
            methodStats[methodName, default: 0] += session.duration
        }
        
        return methodStats.map { method, minutes in
            let percentage = totalMinutes > 0 ? (Double(minutes) / Double(totalMinutes)) * 100 : 0
            return (method: method, minutes: minutes, percentage: percentage)
        }.sorted { $0.minutes > $1.minutes }
    }
    
    /// Get practice time distribution by hour of day
    func getPracticeTimeDistribution() -> [Int: Int] {
        let calendar = Calendar.current
        var hourDistribution: [Int: Int] = [:]
        
        for session in sessionLogs {
            let hour = calendar.component(.hour, from: session.startTime)
            hourDistribution[hour, default: 0] += 1
        }
        
        return hourDistribution
    }
    
    /// Get practice frequency by day of week
    func getPracticeDayDistribution() -> [String: Int] {
        let calendar = Calendar.current
        var dayDistribution: [String: Int] = [:]
        
        for date in dailyMinutes.keys {
            let dayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            dayDistribution[dayName, default: 0] += 1
        }
        
        return dayDistribution
    }
    
    // MARK: - Rest Day Helpers
    
    /// Check if a given date is a rest day based on the current routine
    private func isRestDay(for date: Date) -> Bool {
        guard let routine = currentRoutine else { return false }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Convert weekday to dayNumber (1-7 where 1 = Monday)
        let dayNumber = ((weekday + 5) % 7) + 1
        
        // Find the schedule for this day
        if let daySchedule = routine.schedule.first(where: { $0.dayNumber == dayNumber }) {
            return daySchedule.isRestDay
        }
        
        return false
    }
    
    /// Check if there are wellness activities logged for a given date
    private func hasWellnessActivities(on date: Date) -> Bool {
        let calendar = Calendar.current
        // Check session logs for wellness activities (they have "wellness_" prefix in variation)
        return sessionLogs.contains { log in
            calendar.isDate(log.startTime, inSameDayAs: date) &&
            (log.variation?.hasPrefix("wellness_") ?? false)
        }
    }
    
} 