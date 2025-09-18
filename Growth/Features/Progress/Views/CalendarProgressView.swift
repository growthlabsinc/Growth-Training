import SwiftUI

struct CalendarProgressView: View {
    @StateObject private var viewModel = CalendarProgressViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Calendar
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Month
                        monthView(for: currentMonth)
                        
                        // Next Month
                        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                            monthView(for: nextMonth)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // Selected Date Summary
                selectedDateView
                
                // Done Button
                doneButton
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Progress Calendar")
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            
            // Placeholder for balance
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Month View
    private func monthView(for month: Date) -> some View {
        VStack(spacing: 0) {
            // Month Header
            Text(dateFormatter.string(from: month))
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar Grid
            calendarGrid(for: month)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Calendar Grid
    private func calendarGrid(for month: Date) -> some View {
        let days = generateDays(for: month)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(days, id: \.self) { day in
                if let day = day {
                    dayCell(for: day)
                } else {
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
    }
    
    // MARK: - Day Cell
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let progress = viewModel.getProgress(for: date)
        let hasSession = progress?.sessionsCompleted ?? 0 > 0
        
        return Button(action: { selectedDate = date }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if hasSession {
                    Text("\(progress?.sessionsCompleted ?? 0)")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                } else {
                    Text("—")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(.tertiaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForDate(date, isSelected: isSelected, hasSession: hasSession))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Background Color Logic
    private func backgroundColorForDate(_ date: Date, isSelected: Bool, hasSession: Bool) -> Color {
        if isSelected {
            return Color.blue
        } else if hasSession {
            return Color.blue.opacity(0.1)
        } else if calendar.isDateInToday(date) {
            return Color(.systemGray5)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Selected Date View
    private var selectedDateView: some View {
        VStack(spacing: 8) {
            Text(formatSelectedDate())
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.blue)
            
            if let progress = viewModel.getProgress(for: selectedDate) {
                HStack(spacing: 20) {
                    CalendarStatItem(title: "Sessions", value: "\(progress.sessionsCompleted)")
                    CalendarStatItem(title: "Time", value: formatDuration(progress.totalDuration))
                    CalendarStatItem(title: "Prompts", value: "\(progress.promptsCompleted)")
                }
            } else {
                Text("No activity on this date")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Done Button
    private var doneButton: some View {
        Button(action: { dismiss() }) {
            Text("Done")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Functions
    private func generateDays(for month: Date) -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Item
struct CalendarStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// View Model is in CalendarProgressViewModel.swift

// MARK: - Preview
struct CalendarProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarProgressView()
    }
}