import SwiftUI

struct InlineModernCalendarView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Header with Navigation
            HStack {
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Days of week
            HStack(spacing: 0) {
                ForEach(dayLabels(), id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(getDays(for: currentMonth), id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Day Cell
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let startOfDay = calendar.startOfDay(for: date)
        let minutes = viewModel.dailyMinutes[startOfDay] ?? 0
        let hasActivity = minutes > 0
        
        return Button(action: { 
            selectedDate = date
            hapticFeedback()
        }) {
            VStack(spacing: 1) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                    .foregroundColor(textColor(hasActivity: hasActivity))
                
                // Activity indicator
                if hasActivity {
                    Text("\(minutes)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(activityTextColor(minutes: minutes))
                } else {
                    Text("—")
                        .font(.system(size: 9))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackground(hasActivity: hasActivity, minutes: minutes))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isToday ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
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
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayOffset = calendar.firstWeekday - 1
        return (0..<7).map { symbols[($0 + weekdayOffset) % 7] }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func textColor(hasActivity: Bool) -> Color {
        hasActivity ? .primary : .secondary
    }
    
    private func activityTextColor(minutes: Int) -> Color {
        if minutes >= 30 {
            return Color("GrowthGreen")
        } else if minutes >= 15 {
            return Color("BrightTeal")
        } else {
            return Color("MintGreen")
        }
    }
    
    private func cellBackground(hasActivity: Bool, minutes: Int) -> Color {
        if hasActivity {
            if minutes >= 30 {
                return Color("GrowthGreen").opacity(0.15)
            } else if minutes >= 15 {
                return Color("BrightTeal").opacity(0.15)
            } else {
                return Color("MintGreen").opacity(0.15)
            }
        } else {
            return Color(.systemGray6)
        }
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
}

// MARK: - Preview
struct InlineModernCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        InlineModernCalendarView(
            viewModel: ProgressViewModel(),
            selectedDate: .constant(nil)
        )
        .frame(height: 300)
        .padding()
    }
}