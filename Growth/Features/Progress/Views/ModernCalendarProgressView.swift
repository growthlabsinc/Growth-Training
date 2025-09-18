import SwiftUI

struct ModernCalendarProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var isPresented: Bool
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDetails = false
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Current Month
                    monthCalendarView(for: currentMonth)
                    
                    // Next Month
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                        monthCalendarView(for: nextMonth)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            
            // Selected Date Info & Done Button
            VStack(spacing: 0) {
                selectedDateInfo
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                doneButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
            }
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            )
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showingDetails) {
            DailyDrillDownView(date: selectedDate, sessions: viewModel.sessions(on: selectedDate))
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(.systemGray5)))
            }
            
            Spacer()
            
            Text("Select Date")
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            
            // Month navigation
            HStack(spacing: 20) {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Month Calendar
    private func monthCalendarView(for month: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month & Year
            Text(monthYearString(from: month))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            // Days of week
            HStack(spacing: 0) {
                ForEach(dayLabels(), id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(getDays(for: month), id: \.self) { date in
                    if let date = date {
                        dayCell(for: date, in: month)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
    
    // MARK: - Day Cell
    private func dayCell(for date: Date, in month: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let startOfDay = calendar.startOfDay(for: date)
        let minutes = viewModel.dailyMinutes[startOfDay] ?? 0
        let hasActivity = minutes > 0
        
        return Button(action: { 
            selectedDate = date
            hapticFeedback()
        }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .semibold : .medium))
                    .foregroundColor(textColor(isSelected: isSelected, hasActivity: hasActivity))
                
                // Activity indicator
                if hasActivity {
                    Text("\(minutes)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(activityTextColor(minutes: minutes, isSelected: isSelected))
                } else {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : Color(.tertiaryLabel))
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellBackground(isSelected: isSelected, hasActivity: hasActivity, minutes: minutes))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Selected Date Info
    private var selectedDateInfo: some View {
        VStack(spacing: 8) {
            Text(selectedDateString())
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
            
            if let minutes = viewModel.dailyMinutes[calendar.startOfDay(for: selectedDate)], minutes > 0 {
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.sessions(on: selectedDate).count)")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Sessions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(minutes)")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Minutes")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text(averageDuration(minutes: minutes))
                            .font(.system(size: 18, weight: .semibold))
                        Text("Avg Duration")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                
                Button(action: { showingDetails = true }) {
                    Text("View Details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            } else {
                Text("No activity on this date")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Done Button
    private var doneButton: some View {
        Button(action: { isPresented = false }) {
            Text("Done")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(14)
        }
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
    
    private func selectedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private func textColor(isSelected: Bool, hasActivity: Bool) -> Color {
        if isSelected {
            return .white
        } else if hasActivity {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private func activityTextColor(minutes: Int, isSelected: Bool) -> Color {
        if isSelected {
            return .white.opacity(0.9)
        } else if minutes >= 30 {
            return Color("GrowthGreen")
        } else if minutes >= 15 {
            return Color("BrightTeal")
        } else {
            return Color("MintGreen")
        }
    }
    
    private func cellBackground(isSelected: Bool, hasActivity: Bool, minutes: Int) -> Color {
        if isSelected {
            return .blue
        } else if hasActivity {
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
    
    private func averageDuration(minutes: Int) -> String {
        let sessions = viewModel.sessions(on: selectedDate)
        guard !sessions.isEmpty else { return "0m" }
        let avg = minutes / sessions.count
        return "\(avg)m"
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
struct ModernCalendarProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ModernCalendarProgressView(
            viewModel: ProgressViewModel(),
            isPresented: .constant(true)
        )
    }
}