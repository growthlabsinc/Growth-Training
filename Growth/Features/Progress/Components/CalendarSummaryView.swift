import SwiftUI

/// A calendar view component for the Progress feature that displays a summary of training sessions
struct CalendarSummaryView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Calendar days
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasSession: hasSession(on: date),
                            sessionCount: getSessionCount(for: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(AppTheme.Colors.card)
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let leadingDays = Array(repeating: nil as Date?, count: firstWeekday)
        
        let daysInMonth = monthRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
        
        return leadingDays + daysInMonth
    }
    
    private func hasSession(on date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return (viewModel.dailyMinutes[startOfDay] ?? 0) > 0
    }
    
    private func getSessionCount(for date: Date) -> Int {
        return viewModel.sessions(on: date).count
    }
}

// MARK: - Calendar Day View
private struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasSession: Bool
    let sessionCount: Int
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Background
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.primary.opacity(0.2))
            } else if hasSession {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.success.opacity(0.1))
            }
            
            // Day number
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.text)
                
                // Session indicator
                if sessionCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(sessionCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

#if DEBUG
struct CalendarSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarSummaryView(viewModel: ProgressViewModel())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif