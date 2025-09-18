import SwiftUI

/// Heatmap showing practice intensity over the selected time range (Story 14.6)
struct PracticeHeatmapView: View {
    /// Dictionary keyed by startOfDay date, value = total minutes practiced
    let dailyMinutes: [Date: Int]
    let timeRange: TimeRange
    var onSelectDate: ((Date) -> Void)? = nil
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = ThemeManager.shared.firstDayOfWeek
        return cal
    }
    
    // Determine the granularity based on time range
    private var cellGranularity: CellGranularity {
        switch timeRange {
        case .week, .month:
            return .daily
        case .quarter:
            return .weekly
        case .year, .all:
            return .monthly
        }
    }
    
    private enum CellGranularity {
        case daily
        case weekly
        case monthly
    }
    
    // Get aggregated data based on granularity
    private var aggregatedData: [(date: Date, minutes: Int, label: String)] {
        switch cellGranularity {
        case .daily:
            return getDailyData()
        case .weekly:
            return getWeeklyData()
        case .monthly:
            return getMonthlyData()
        }
    }
    
    private func getDailyData() -> [(date: Date, minutes: Int, label: String)] {
        let start = timeRange.startDate
        var data: [(date: Date, minutes: Int, label: String)] = []
        
        for offset in 0..<timeRange.daySpan {
            if let date = calendar.date(byAdding: .day, value: offset, to: start) {
                let startOfDay = calendar.startOfDay(for: date)
                let minutes = dailyMinutes[startOfDay] ?? 0
                let label = "\(calendar.component(.day, from: date))"
                data.append((date: startOfDay, minutes: minutes, label: label))
            }
        }
        return data
    }
    
    private func getWeeklyData() -> [(date: Date, minutes: Int, label: String)] {
        let start = timeRange.startDate
        var data: [(date: Date, minutes: Int, label: String)] = []
        
        // Start from the beginning of the week containing the start date
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start else { return data }
        
        var currentWeek = weekStart
        let endDate = Date()
        
        while currentWeek <= endDate {
            // Calculate total minutes for this week
            var weekMinutes = 0
            for dayOffset in 0..<7 {
                if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: currentWeek) {
                    let startOfDay = calendar.startOfDay(for: dayDate)
                    weekMinutes += dailyMinutes[startOfDay] ?? 0
                }
            }
            
            // Create label (e.g., "W1", "W2", etc.)
            let weekOfMonth = calendar.component(.weekOfMonth, from: currentWeek)
            let label = "W\(weekOfMonth)"
            
            data.append((date: currentWeek, minutes: weekMinutes, label: label))
            
            // Move to next week
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) else { break }
            currentWeek = nextWeek
        }
        
        return data
    }
    
    private func getMonthlyData() -> [(date: Date, minutes: Int, label: String)] {
        let start = timeRange.startDate
        var data: [(date: Date, minutes: Int, label: String)] = []
        
        // Start from the beginning of the month containing the start date
        guard let monthStart = calendar.dateInterval(of: .month, for: start)?.start else { return data }
        
        var currentMonth = monthStart
        let endDate = Date()
        
        while currentMonth <= endDate {
            // Calculate total minutes for this month
            var monthMinutes = 0
            if let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) {
                var dayDate = monthInterval.start
                while dayDate < monthInterval.end {
                    let startOfDay = calendar.startOfDay(for: dayDate)
                    monthMinutes += dailyMinutes[startOfDay] ?? 0
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayDate) else { break }
                    dayDate = nextDay
                }
            }
            
            // Create label (e.g., "Jan", "Feb", etc.)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let label = formatter.string(from: currentMonth)
            
            data.append((date: currentMonth, minutes: monthMinutes, label: label))
            
            // Move to next month
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { break }
            currentMonth = nextMonth
        }
        
        return data
    }
    
    private func color(for minutes: Int) -> Color {
        // Adjust thresholds based on granularity
        let thresholds: (low: Int, medium: Int, high: Int)
        
        switch cellGranularity {
        case .daily:
            thresholds = (low: 10, medium: 25, high: 45)
        case .weekly:
            thresholds = (low: 70, medium: 175, high: 315) // 7x daily thresholds
        case .monthly:
            thresholds = (low: 300, medium: 750, high: 1350) // 30x daily thresholds
        }
        
        switch minutes {
        case 0: return Color.gray.opacity(0.15)
        case 1...thresholds.low: return Color("GrowthGreen").opacity(0.3)
        case (thresholds.low + 1)...thresholds.medium: return Color("GrowthGreen").opacity(0.55)
        case (thresholds.medium + 1)...thresholds.high: return Color("GrowthGreen").opacity(0.75)
        default: return Color("GrowthGreen")
        }
    }
    
    var body: some View {
        let data = aggregatedData
        let columnsCount = cellGranularity == .monthly ? 4 : 7
        let rowCount = Int(ceil(Double(data.count) / Double(columnsCount)))
        let cellHeight: CGFloat = cellGranularity == .monthly ? 60 : 40
        let totalHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(rowCount - 1, 0)) * 4
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: columnsCount)

        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(data, id: \.date) { item in
                RoundedRectangle(cornerRadius: 6)
                    .fill(color(for: item.minutes))
                    .frame(height: cellHeight)
                    .overlay(
                        VStack(spacing: 2) {
                            Text(item.label)
                                .font(.system(size: cellGranularity == .monthly ? 12 : 10, weight: .medium))
                                .foregroundColor(item.minutes == 0 ? .gray : .white)
                            if item.minutes > 0 {
                                Text("\(item.minutes)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    )
                    .accessibilityLabel(accessibilityLabel(for: item))
                    .accessibilityHint("Double tap to view details")
                    .onTapGesture {
                        onSelectDate?(item.date)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: totalHeight)
    }
    
    private func accessibilityLabel(for item: (date: Date, minutes: Int, label: String)) -> String {
        let formatter = DateFormatter()
        
        switch cellGranularity {
        case .daily:
            formatter.dateStyle = .medium
            return "\(item.minutes) minutes on \(formatter.string(from: item.date))"
        case .weekly:
            formatter.dateFormat = "MMM d"
            return "\(item.minutes) minutes for week starting \(formatter.string(from: item.date))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return "\(item.minutes) minutes in \(formatter.string(from: item.date))"
        }
    }
}

#if DEBUG
struct PracticeHeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        var dummy: [Date: Int] = [:]
        
        // Generate dummy data for the past year
        for i in 0..<365 {
            let date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: Date())!)
            dummy[date] = Int.random(in: 0...60)
        }
        
        return VStack(spacing: 20) {
            Text("Week View (Daily)")
                .font(AppTheme.Typography.headlineFont())
            PracticeHeatmapView(dailyMinutes: dummy, timeRange: .week)
            
            Text("Month View (Daily)")
                .font(AppTheme.Typography.headlineFont())
            PracticeHeatmapView(dailyMinutes: dummy, timeRange: .month)
            
            Text("Quarter View (Weekly)")
                .font(AppTheme.Typography.headlineFont())
            PracticeHeatmapView(dailyMinutes: dummy, timeRange: .quarter)
            
            Text("Year View (Monthly)")
                .font(AppTheme.Typography.headlineFont())
            PracticeHeatmapView(dailyMinutes: dummy, timeRange: .year)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 