//
//  DetailedProgressStatsView.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

struct DetailedProgressStatsView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var selectedTimeRange: TimeRange = .month
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector
                timeRangeSelector
                
                // Key metrics cards
                keyMetricsSection
                
                // Trend charts
                trendChartsSection
                
                // Method distribution
                methodDistributionSection
                
                // Practice patterns
                practicePatternSection
            }
            .padding()
        }
        .background(Color("GrowthBackgroundLight"))
        .onChangeCompat(of: selectedTimeRange) { _ in
            updateTimeRange()
        }
        .onAppear {
            // Sync with viewModel's time range on appear
            selectedTimeRange = viewModel.selectedTimeRange
        }
    }
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var keyMetricsSection: some View {
        VStack(spacing: 16) {
            Text("Key Metrics")
                .font(AppTheme.Typography.title2Font())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Total Sessions
                StatsTrendCard(
                    title: "Total Sessions",
                    value: "\(viewModel.totalSessionsInRange)",
                    subtitle: "In \(selectedTimeRange.displayName.lowercased())",
                    icon: "figure.mind.and.body",
                    trend: viewModel.trendSessionsPercent.map { 
                        TrendInfo(
                            percentageChange: $0,
                            description: "vs previous \(selectedTimeRange.rawValue.lowercased())"
                        )
                    },
                    colorTheme: "GrowthGreen"
                )
                
                // Total Time
                StatsTrendCard(
                    title: "Total Time",
                    value: formatTotalTime(viewModel.totalMinutesInRange),
                    subtitle: "Practice time",
                    icon: "clock.fill",
                    trend: viewModel.trendMinutesPercent.map {
                        TrendInfo(
                            percentageChange: $0,
                            description: "vs previous \(selectedTimeRange.rawValue.lowercased())"
                        )
                    },
                    colorTheme: "BrightTeal"
                )
                
                // Average Session
                StatsTrendCard(
                    title: "Average Session",
                    value: "\(viewModel.averageSessionMinutes)m",
                    subtitle: "Per session",
                    icon: "chart.bar.fill",
                    trend: viewModel.trendAvgDurationPercent.map {
                        TrendInfo(
                            percentageChange: $0,
                            description: "vs previous \(selectedTimeRange.rawValue.lowercased())"
                        )
                    },
                    colorTheme: "MintGreen"
                )
                
                // Routine Adherence
                if let adherenceData = viewModel.routineAdherenceData {
                    StatsTrendCard(
                        title: "Routine Adherence",
                        value: "\(adherenceData.formattedPercentage)%",
                        subtitle: adherenceData.progressDescription,
                        icon: "target",
                        colorTheme: adherenceData.colorTheme
                    )
                }
            }
        }
    }
    
    private var trendChartsSection: some View {
        VStack(spacing: 16) {
            Text("Progress Trends")
                .font(AppTheme.Typography.title2Font())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Sessions trend
            TrendChartView(
                data: generateSessionsChartData(),
                title: "Sessions Over Time",
                color: Color("GrowthGreen"),
                yAxisUnit: "Sessions"
            )
            
            // Duration trend
            TrendChartView(
                data: generateDurationChartData(),
                title: "Practice Duration",
                color: Color("BrightTeal"),
                yAxisUnit: "Duration"
            )
            
            // Adherence trend (if routine is selected)
            if viewModel.routineAdherenceData != nil {
                TrendChartView(
                    data: generateAdherenceChartData(),
                    title: "Routine Adherence",
                    color: Color("MintGreen"),
                    yAxisUnit: "Percentage"
                )
            }
        }
    }
    
    private var methodDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Method Distribution")
                .font(AppTheme.Typography.title2Font())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
            
            if methodStats.isEmpty {
                EmptyMethodStatsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(methodStats.sorted(by: { $0.minutes > $1.minutes }), id: \.methodName) { stat in
                        MethodStatRow(stat: stat, maxMinutes: methodStats.map { $0.minutes }.max() ?? 1)
                    }
                }
                .padding()
                .background(Color("BackgroundColor"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var practicePatternSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Patterns")
                .font(AppTheme.Typography.title2Font())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 16) {
                // Most active day
                PatternCard(
                    title: "Most Active Day",
                    value: mostActiveDay,
                    icon: "calendar.badge.plus",
                    color: Color("GrowthGreen")
                )
                
                // Peak practice time
                PatternCard(
                    title: "Peak Time",
                    value: peakPracticeTime,
                    icon: "clock.badge.checkmark",
                    color: Color("BrightTeal")
                )
            }
            
            HStack(spacing: 16) {
                // Consistency score
                PatternCard(
                    title: "Consistency",
                    value: "\(consistencyScore)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color("MintGreen")
                )
                
                // Current streak
                PatternCard(
                    title: "Current Streak",
                    value: "\(calculateStreak()) days",
                    icon: "flame.fill",
                    color: Color("ErrorColor")
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateTimeRange() {
        viewModel.selectedTimeRange = selectedTimeRange
        viewModel.fetchLoggedDates()
    }
    
    private func formatTotalTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    private func generateSessionsChartData() -> [ChartDataPoint] {
        let data = viewModel.timelineData
        
        // Group by appropriate interval based on time range
        switch selectedTimeRange {
        case .week:
            // Daily data for week view
            return data.map { ChartDataPoint(date: $0.date, value: Double($0.totalMinutes > 0 ? 1 : 0)) }
        case .month:
            // Weekly aggregation for month view
            return aggregateByWeek(data)
        case .quarter, .year, .all:
            // Monthly aggregation for longer views
            return aggregateByMonth(data)
        }
    }
    
    private func generateDurationChartData() -> [ChartDataPoint] {
        viewModel.timelineData.map { 
            ChartDataPoint(date: $0.date, value: Double($0.totalMinutes))
        }
    }
    
    private func generateAdherenceChartData() -> [ChartDataPoint] {
        // Get adherence data from viewModel
        guard let adherenceData = viewModel.routineAdherenceData else {
            Logger.debug("[DetailedProgressStatsView] No routine adherence data available")
            return []
        }
        
        Logger.debug("[DetailedProgressStatsView] Generating adherence chart for \(selectedTimeRange.rawValue)")
        Logger.debug("[DetailedProgressStatsView] Adherence data has \(adherenceData.sessionDetails.count) entries")
        
        // Generate daily adherence points based on the time range
        var chartData: [ChartDataPoint] = []
        
        // Use viewModel's selectedTimeRange to ensure consistency with adherence data
        switch viewModel.selectedTimeRange {
        case .week:
            // For week view, show daily adherence
            chartData = generateDailyAdherenceData(adherenceData: adherenceData, days: 7)
        case .month:
            // For month view, show weekly adherence
            chartData = generateWeeklyAdherenceData(adherenceData: adherenceData)
        case .quarter:
            // For quarter view, show monthly adherence
            chartData = generateMonthlyAdherenceData(adherenceData: adherenceData, months: 3)
        case .year:
            // For year view, show monthly adherence
            chartData = generateMonthlyAdherenceData(adherenceData: adherenceData, months: 12)
        case .all:
            // For all time, show monthly adherence
            chartData = generateMonthlyAdherenceData(adherenceData: adherenceData, months: 24)
        }
        
        Logger.debug("[DetailedProgressStatsView] Generated \(chartData.count) chart points")
        return chartData
    }
    
    private func generateDailyAdherenceData(adherenceData: RoutineAdherenceData, days: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var chartData: [ChartDataPoint] = []
        
        // Get all dates from sessionDetails and sort them
        let sortedDates = adherenceData.sessionDetails.keys.sorted()
        
        // Take the last 'days' worth of data
        let relevantDates = sortedDates.suffix(days)
        
        for date in relevantDates {
            if let isCompleted = adherenceData.sessionDetails[date] {
                // Day was scheduled - add 100 if completed, 0 if not
                chartData.append(ChartDataPoint(date: date, value: isCompleted ? 100.0 : 0.0))
            }
        }
        
        // If we have no data, create empty points for visualization
        if chartData.isEmpty {
            let today = Date()
            for dayOffset in (0..<days).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    chartData.append(ChartDataPoint(date: date, value: 0.0))
                }
            }
        }
        
        return chartData
    }
    
    private func generateWeeklyAdherenceData(adherenceData: RoutineAdherenceData) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var chartData: [ChartDataPoint] = []
        
        // Group sessionDetails by week
        var weeklyData: [Date: (completed: Int, total: Int)] = [:]
        
        for (date, isCompleted) in adherenceData.sessionDetails {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            var weekData = weeklyData[weekStart] ?? (completed: 0, total: 0)
            weekData.total += 1
            if isCompleted {
                weekData.completed += 1
            }
            weeklyData[weekStart] = weekData
        }
        
        // Convert to chart data points
        for (weekStart, data) in weeklyData.sorted(by: { $0.key < $1.key }) {
            let adherencePercentage = data.total > 0 ? (Double(data.completed) / Double(data.total)) * 100.0 : 0.0
            chartData.append(ChartDataPoint(date: weekStart, value: adherencePercentage))
        }
        
        // If we have no data, create empty points for the last 4 weeks
        if chartData.isEmpty {
            let today = Date()
            for weekOffset in (0..<4).reversed() {
                if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) {
                    chartData.append(ChartDataPoint(date: weekStart, value: 0.0))
                }
            }
        }
        
        return chartData
    }
    
    private func generateMonthlyAdherenceData(adherenceData: RoutineAdherenceData, months: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var chartData: [ChartDataPoint] = []
        
        // Group sessionDetails by month
        var monthlyData: [Date: (completed: Int, total: Int)] = [:]
        
        for (date, isCompleted) in adherenceData.sessionDetails {
            let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
            var monthData = monthlyData[monthStart] ?? (completed: 0, total: 0)
            monthData.total += 1
            if isCompleted {
                monthData.completed += 1
            }
            monthlyData[monthStart] = monthData
        }
        
        // Convert to chart data points, take the most recent months
        let sortedMonths = monthlyData.keys.sorted()
        let relevantMonths = sortedMonths.suffix(months)
        
        for monthStart in relevantMonths {
            if let data = monthlyData[monthStart] {
                let adherencePercentage = data.total > 0 ? (Double(data.completed) / Double(data.total)) * 100.0 : 0.0
                chartData.append(ChartDataPoint(date: monthStart, value: adherencePercentage))
            }
        }
        
        // If we have no data, create empty points
        if chartData.isEmpty {
            let today = Date()
            for monthOffset in (0..<min(months, 12)).reversed() {
                if let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today) {
                    chartData.append(ChartDataPoint(date: monthStart, value: 0.0))
                }
            }
        }
        
        return chartData
    }
    
    private func calculateAdherenceForPeriod(adherenceData: RoutineAdherenceData, startDate: Date, endDate: Date) -> Double {
        var completedCount = 0
        var expectedCount = 0
        
        // Count completed and expected sessions in the period
        for (date, isCompleted) in adherenceData.sessionDetails {
            if date >= startDate && date <= endDate {
                expectedCount += 1
                if isCompleted {
                    completedCount += 1
                }
            }
        }
        
        // Return percentage
        return expectedCount > 0 ? (Double(completedCount) / Double(expectedCount)) * 100.0 : 0.0
    }
    
    private func aggregateByWeek(_ data: [ProgressTimelineData]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var weeklyData: [Date: Int] = [:]
        
        for item in data {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: item.date)?.start ?? item.date
            weeklyData[weekStart, default: 0] += (item.totalMinutes > 0 ? 1 : 0)
        }
        
        return weeklyData.map { ChartDataPoint(date: $0.key, value: Double($0.value)) }
            .sorted { $0.date < $1.date }
    }
    
    private func aggregateByMonth(_ data: [ProgressTimelineData]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var monthlyData: [Date: Int] = [:]
        
        for item in data {
            let monthStart = calendar.dateInterval(of: .month, for: item.date)?.start ?? item.date
            monthlyData[monthStart, default: 0] += (item.totalMinutes > 0 ? 1 : 0)
        }
        
        return monthlyData.map { ChartDataPoint(date: $0.key, value: Double($0.value)) }
            .sorted { $0.date < $1.date }
    }
    
    private var methodStats: [MethodStat] {
        var stats: [String: Int] = [:]
        
        for session in viewModel.sessionLogs {
            let methodName = session.variation ?? "Practice Session"
            stats[methodName, default: 0] += session.duration
        }
        
        return stats.map { MethodStat(methodName: $0.key, minutes: $0.value) }
    }
    
    private var mostActiveDay: String {
        let calendar = Calendar.current
        var dayCount: [String: Int] = [:]
        
        for date in viewModel.dailyMinutes.keys {
            let dayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            dayCount[dayName, default: 0] += 1
        }
        
        return dayCount.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    private var peakPracticeTime: String {
        let calendar = Calendar.current
        var hourCount: [Int: Int] = [:]
        
        for session in viewModel.sessionLogs {
            let hour = calendar.component(.hour, from: session.startTime)
            hourCount[hour, default: 0] += 1
        }
        
        if let peakHour = hourCount.max(by: { $0.value < $1.value })?.key {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            let date = calendar.date(bySettingHour: peakHour, minute: 0, second: 0, of: Date()) ?? Date()
            return formatter.string(from: date)
        }
        
        return "N/A"
    }
    
    private var consistencyScore: Int {
        let totalDays = selectedTimeRange.daySpan
        let activeDays = viewModel.loggedDates.count
        return min(100, Int((Double(activeDays) / Double(totalDays)) * 100))
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        let todayMinutes = viewModel.dailyMinutes[today] ?? 0
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayMinutes = viewModel.dailyMinutes[yesterdayDate] ?? 0
        
        if todayMinutes > 0 {
            // Start counting from today
        } else if yesterdayMinutes > 0 {
            currentDate = yesterdayDate
        } else {
            return 0
        }
        
        while true {
            let minutes = viewModel.dailyMinutes[currentDate] ?? 0
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
}

// Method stat model
private struct MethodStat {
    let methodName: String
    let minutes: Int
}

// Method stat row
private struct MethodStatRow: View {
    let stat: MethodStat
    let maxMinutes: Int
    
    private var percentage: Double {
        Double(stat.minutes) / Double(maxMinutes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.methodName)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                Text(formatDuration(stat.minutes))
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("GrowthGreen"))
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// Pattern card
private struct PatternCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            Text(title)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("BackgroundColor"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// Empty method stats view
private struct EmptyMethodStatsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.3))
            
            Text("No practice data yet")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color("BackgroundColor"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DetailedProgressStatsView(viewModel: ProgressViewModel())
        .preferredColorScheme(.light)
}