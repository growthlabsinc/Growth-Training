import SwiftUI

struct PremiumCalendarProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    @State private var currentMonth = Date()
    @State private var hoveredDate: Date? = nil
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    // Premium Color Palette
    private let primaryGreen = Color("GrowthGreen")
    private let secondaryGreen = Color("GrowthGreen").opacity(0.8)
    private let surfaceColor = Color(.secondarySystemGroupedBackground)
    private let textPrimary = Color(.label)
    private let textSecondary = Color(.secondaryLabel)
    private let inactiveColor = Color(.tertiaryLabel)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Month Header with Navigation
                monthHeader
                    .padding(.horizontal, 24)
                
                // Days of week
                weekdayHeader
                    .padding(.horizontal, 24)
                
                // Calendar Grid
                calendarGrid
                    .padding(.horizontal, 24)
                
                // Progress Summary
                progressSummary
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }
            .padding(.bottom, 20) // Add bottom padding for safe area
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .tracking(0.5)
                
                Text("\(getCompletionPercentage())% completed")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(primaryGreen)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textPrimary)
                        .frame(width: 40, height: 40)
                        .background(surfaceColor)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        nextMonth()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textPrimary)
                        .frame(width: 40, height: 40)
                        .background(surfaceColor)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(dayLabels(), id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
            }
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(getDays(for: currentMonth).enumerated()), id: \.offset) { index, date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 56)
                }
            }
        }
    }
    
    // MARK: - Day Cell
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false
        let isHovered = hoveredDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false
        let startOfDay = calendar.startOfDay(for: date)
        let minutes = viewModel.dailyMinutes[startOfDay] ?? 0
        let hasActivity = minutes > 0
        let isPast = date < Date()
        let isFuture = date > Date()
        
        // Get earliest logged date
        let earliestLoggedDate = viewModel.dailyMinutes.keys.min() ?? Date()
        let shouldShowBorder = !hasActivity && (isToday || (isPast && date >= earliestLoggedDate))
        
        return Button(action: { 
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                selectedDate = date
                hapticFeedback()
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackground(
                        hasActivity: hasActivity,
                        isToday: isToday,
                        isSelected: isSelected,
                        isPast: isPast,
                        minutes: minutes
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                shouldShowBorder ? primaryGreen.opacity(0.3) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                
                // Hover overlay
                if isHovered && !isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                }
                
                // Content
                VStack(spacing: 4) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 18, weight: isToday ? .semibold : .regular, design: .rounded))
                        .foregroundColor(textColor(
                            hasActivity: hasActivity,
                            isSelected: isSelected,
                            isPast: isPast,
                            isFuture: isFuture
                        ))
                    
                    if hasActivity {
                        // Activity minutes text
                        Text("\(minutes)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(activityTextColor(minutes: minutes, isSelected: isSelected))
                    }
                }
                .frame(width: 56, height: 56)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                hoveredDate = hovering ? date : nil
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(
            color: hasActivity ? primaryGreen.opacity(0.3) : Color.clear,
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
    }
    
    // MARK: - Progress Summary
    private var progressSummary: some View {
        HStack(spacing: 32) {
            summaryItem(
                value: "\(getCurrentStreak())",
                label: "Day Streak",
                icon: "flame.fill"
            )
            
            summaryItem(
                value: "\(getActiveDays())",
                label: "Active Days",
                icon: "calendar"
            )
            
            summaryItem(
                value: formatTotalTime(),
                label: "Total Time",
                icon: "clock.fill"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func summaryItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(primaryGreen)
                
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimary)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func cellBackground(hasActivity: Bool, isToday: Bool, isSelected: Bool, isPast: Bool, minutes: Int) -> Color {
        if isSelected && hasActivity {
            return primaryGreen
        } else if hasActivity {
            return primaryGreen.opacity(0.15)
        } else if isToday {
            return Color(.tertiarySystemGroupedBackground)
        } else if !isPast {
            return Color(.tertiarySystemGroupedBackground).opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private func textColor(hasActivity: Bool, isSelected: Bool, isPast: Bool, isFuture: Bool) -> Color {
        if isSelected && hasActivity {
            return .white
        } else if hasActivity || isFuture {
            return textPrimary
        } else if isPast {
            return textSecondary
        } else {
            return inactiveColor
        }
    }
    
    private func activityTextColor(minutes: Int, isSelected: Bool) -> Color {
        if isSelected && minutes > 0 {
            return .white
        } else if minutes >= 30 {
            return primaryGreen
        } else if minutes >= 15 {
            return primaryGreen.opacity(0.8)
        } else {
            return primaryGreen.opacity(0.6)
        }
    }
    
    private func getDays(for month: Date) -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday
        let leadingEmptyDays = (firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func dayLabels() -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        let weekdayOffset = calendar.firstWeekday - 1
        return (0..<7).map { symbols[($0 + weekdayOffset) % 7].uppercased() }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Data Calculations
    private func getCompletionPercentage() -> Int {
        let days = getDays(for: currentMonth).compactMap { $0 }
        let activeDays = days.filter { date in
            let minutes = viewModel.dailyMinutes[calendar.startOfDay(for: date)] ?? 0
            return minutes > 0
        }.count
        
        guard !days.isEmpty else { return 0 }
        return Int((Double(activeDays) / Double(days.count)) * 100)
    }
    
    private func getCurrentStreak() -> Int {
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
        while let minutes = viewModel.dailyMinutes[checkDate], minutes > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
    
    private func getActiveDays() -> Int {
        let days = getDays(for: currentMonth).compactMap { $0 }
        return days.filter { date in
            let minutes = viewModel.dailyMinutes[calendar.startOfDay(for: date)] ?? 0
            return minutes > 0
        }.count
    }
    
    private func formatTotalTime() -> String {
        let totalMinutes = viewModel.dailyMinutes.values.reduce(0, +)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Color extension removed - using the one from ColorExtensions.swift

// MARK: - Preview
struct PremiumCalendarProgressView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumCalendarProgressView(
            viewModel: ProgressViewModel(),
            selectedDate: .constant(nil)
        )
        .preferredColorScheme(.dark)
    }
}