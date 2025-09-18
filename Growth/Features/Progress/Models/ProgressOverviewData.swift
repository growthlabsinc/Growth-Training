//
//  ProgressOverviewData.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation

/// Aggregate data structure containing summary metrics for the progress overview dashboard
struct ProgressOverviewData {
    /// Calendar summary data for visual representation
    let calendarSummary: CalendarSummaryData
    
    /// Key statistics to highlight
    let statistics: [StatisticHighlight]
    
    /// Recent achievements to showcase
    let achievements: [AchievementHighlight]
    
    /// Contextual insights based on progress data
    let insights: [ProgressInsight]
    
    /// Loading state
    let isLoading: Bool
    
    /// Error message if data loading failed
    let errorMessage: String?
    
    init(
        calendarSummary: CalendarSummaryData = CalendarSummaryData(),
        statistics: [StatisticHighlight] = [],
        achievements: [AchievementHighlight] = [],
        insights: [ProgressInsight] = [],
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.calendarSummary = calendarSummary
        self.statistics = statistics
        self.achievements = achievements
        self.insights = insights
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
}

/// Calendar summary data for the overview dashboard
struct CalendarSummaryData {
    /// Current month activity data
    let monthlyData: [CalendarSummaryItem]
    
    /// Current week activity data
    let weeklyData: [CalendarSummaryItem]
    
    /// Selected time range for display
    let selectedRange: TimeRange
    
    /// Total sessions in selected range
    let totalSessions: Int
    
    /// Total minutes in selected range
    let totalMinutes: Int
    
    init(
        monthlyData: [CalendarSummaryItem] = [],
        weeklyData: [CalendarSummaryItem] = [],
        selectedRange: TimeRange = .month,
        totalSessions: Int = 0,
        totalMinutes: Int = 0
    ) {
        self.monthlyData = monthlyData
        self.weeklyData = weeklyData
        self.selectedRange = selectedRange
        self.totalSessions = totalSessions
        self.totalMinutes = totalMinutes
    }
}

/// Representation of daily/weekly activity summaries for calendar display
struct CalendarSummaryItem: Identifiable {
    let id = UUID()
    
    /// Date for this summary item
    let date: Date
    
    /// Number of sessions on this date
    let sessionCount: Int
    
    /// Total minutes practiced on this date
    let totalMinutes: Int
    
    /// Whether this is a rest day
    let isRestDay: Bool
    
    /// Whether rest day was completed (wellness activities logged)
    let restDayCompleted: Bool
    
    init(
        date: Date,
        sessionCount: Int,
        totalMinutes: Int,
        isRestDay: Bool = false,
        restDayCompleted: Bool = false
    ) {
        self.date = date
        self.sessionCount = sessionCount
        self.totalMinutes = totalMinutes
        self.isRestDay = isRestDay
        self.restDayCompleted = restDayCompleted
    }
    
    /// Whether this date has any activity
    var hasActivity: Bool {
        // For rest days, consider it active if completed
        if isRestDay {
            return restDayCompleted
        }
        // For regular days, check for sessions
        return sessionCount > 0 && totalMinutes > 0
    }
}


/// Key performance metrics for display in overview
struct StatisticHighlight: Identifiable {
    let id = UUID()
    
    /// Title of the statistic
    let title: String
    
    /// Current value to display
    let value: String
    
    /// Subtitle or additional context
    let subtitle: String
    
    /// Icon name for the statistic
    let iconName: String
    
    /// Trend information (optional)
    let trend: TrendInfo?
    
    /// Color theme for the statistic
    let colorTheme: String
    
    init(
        title: String,
        value: String,
        subtitle: String,
        iconName: String,
        trend: TrendInfo? = nil,
        colorTheme: String = "GrowthGreen"
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconName = iconName
        self.trend = trend
        self.colorTheme = colorTheme
    }
}

/// Trend information for statistics
struct TrendInfo {
    /// Percentage change (positive or negative)
    let percentageChange: Double
    
    /// Text description of the trend
    let description: String
    
    /// Whether the trend is positive
    var isPositive: Bool {
        return percentageChange > 0
    }
    
    /// Icon for the trend direction
    var iconName: String {
        return isPositive ? "arrow.up.right" : "arrow.down.right"
    }
    
    /// Color for the trend
    var color: String {
        return isPositive ? "GrowthGreen" : "ErrorColor"
    }
}

/// Recent or upcoming achievement data for overview display
struct AchievementHighlight: Identifiable {
    let id = UUID()
    
    /// Achievement title
    let title: String
    
    /// Achievement description
    let description: String
    
    /// Icon or badge representation
    let iconName: String
    
    /// Whether this achievement has been earned
    let isEarned: Bool
    
    /// Date when achievement was earned (if applicable)
    let earnedDate: Date?
    
    /// Progress toward achievement (0.0 to 1.0) if not earned
    let progress: Double?
    
    /// Color theme for the achievement
    let colorTheme: String
    
    init(
        title: String,
        description: String,
        iconName: String,
        isEarned: Bool,
        earnedDate: Date? = nil,
        progress: Double? = nil,
        colorTheme: String = "GrowthGreen"
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isEarned = isEarned
        self.earnedDate = earnedDate
        self.progress = progress
        self.colorTheme = colorTheme
    }
}