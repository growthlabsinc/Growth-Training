//
//  RoutineAdherenceView.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

/// View component for displaying routine adherence metrics
struct RoutineAdherenceView: View {
    /// The routine to display adherence for
    let routine: Routine
    
    /// The adherence service
    @StateObject private var adherenceService = RoutineAdherenceService()
    
    /// Current user ID
    private let userId: String
    
    /// Selected time range
    @State private var selectedTimeRange: TimeRange = .week
    
    /// Adherence data
    @State private var adherenceData: RoutineAdherenceData?
    
    /// Loading state
    @State private var isLoading: Bool = true
    
    /// Error message
    @State private var errorMessage: String?
    
    // MARK: - Initialization
    
    init(routine: Routine, userId: String) {
        self.routine = routine
        self.userId = userId
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection
                
                // Content based on state
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let data = adherenceData {
                    adherenceContent(data)
                } else {
                    noDataView
                }
            }
        }
        .onAppear {
            // Force immediate load
            loadAdherenceData()
        }
        .onChangeCompat(of: selectedTimeRange) { _ in
            loadAdherenceData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reload data when app comes to foreground in case it wasn't loaded properly
            loadAdherenceData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionLogged)) { _ in
            // Reload adherence data when a session is logged
            loadAdherenceData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineProgressUpdated)) { _ in
            // Reload adherence data when routine progress is updated
            loadAdherenceData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Routine Adherence")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text("Track your consistency")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            // Time range selector
            Picker("Time Range", selection: $selectedTimeRange) {
                Text("Week").tag(TimeRange.week)
                Text("Month").tag(TimeRange.month)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 140)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Calculating adherence...")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(Color("ErrorColor"))
            
            Text(message)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(Color("GrowthNeutralGray"))
            
            Text("No adherence data yet")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
            
            Text("Start logging sessions to track your consistency")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Adherence Content
    
    private func adherenceContent(_ data: RoutineAdherenceData) -> some View {
        VStack(spacing: 20) {
            // Main adherence display
            mainAdherenceDisplay(data)
            
            // Progress bar
            AdherenceProgressBar(percentage: data.adherencePercentage)
            
            // Calendar visualization
            calendarVisualization(data)
            
            // Motivational message
            motivationalMessage(data)
        }
    }
    
    // MARK: - Main Adherence Display
    
    private func mainAdherenceDisplay(_ data: RoutineAdherenceData) -> some View {
        HStack(spacing: 0) {
            // Percentage
            VStack(spacing: 4) {
                Text("\(data.formattedPercentage)%")
                    .font(AppTheme.Typography.gravityBoldFont(36))
                    .foregroundColor(Color(data.colorTheme))
                
                Text("Adherence")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
                .padding(.horizontal)
            
            // Progress
            VStack(spacing: 4) {
                Text("\(data.completedSessions)")
                    .font(AppTheme.Typography.gravityBoldFont(28))
                    .foregroundColor(Color("TextColor"))
                
                Text("of \(data.expectedSessions) sessions")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Calendar Visualization
    
    private func calendarVisualization(_ data: RoutineAdherenceData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Calendar")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
            
            // Weekly grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(getDatesForRange(), id: \.self) { date in
                    dayCell(for: date, data: data)
                }
            }
        }
    }
    
    // MARK: - Day Cell
    
    private func dayCell(for date: Date, data: RoutineAdherenceData) -> some View {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let isCompleted = data.sessionDetails[startOfDay] ?? false
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        
        // Check if this is a rest day based on scheduling type
        let schedulingType = routine.schedulingType ?? .sequential
        var isRestDay = false
        
        if schedulingType == .weekday {
            // For weekday-based routines, check by day of week
            let weekday = calendar.component(.weekday, from: date)
            // Convert from Calendar weekday (1=Sunday, 2=Monday...) to routine day (1=Monday, 2=Tuesday...)
            let dayNumber = weekday == 1 ? 7 : weekday - 1
            isRestDay = routine.schedule.first(where: { $0.day == dayNumber })?.isRestDay ?? false
        } else {
            // For sequential routines, calculate which day of the routine this is
            let routineStartDate = selectedTimeRange.startDate
            let daysSinceStart = calendar.dateComponents([.day], from: routineStartDate, to: date).day ?? 0
            let routineDayNumber = (daysSinceStart % routine.duration) + 1
            isRestDay = routine.schedule.first(where: { $0.day == routineDayNumber })?.isRestDay ?? false
        }
        
        return VStack(spacing: 2) {
            Text(dayAbbreviation(for: date))
                .font(AppTheme.Typography.gravityBook(10))
                .foregroundColor(Color("TextSecondaryColor"))
            
            ZStack {
                Circle()
                    .fill(cellColor(isCompleted: isCompleted, isFuture: isFuture, isRestDay: isRestDay))
                    .frame(width: 30, height: 30)
                
                if isRestDay {
                    // Show bed icon for rest days
                    Image(systemName: "bed.double")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Only show checkmark if rest day was actually logged
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .offset(x: 8, y: -8)
                    }
                } else if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(isToday ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Motivational Message
    
    private func motivationalMessage(_ data: RoutineAdherenceData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(Color(data.colorTheme))
            
            Text(data.motivationalMessage)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
            
            Spacer()
        }
        .padding()
        .background(Color(data.colorTheme).opacity(0.1))
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }
    
    // MARK: - Helper Methods
    
    private func loadAdherenceData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await adherenceService.calculateAdherence(
                    for: routine,
                    timeRange: selectedTimeRange,
                    userId: userId
                )
                
                await MainActor.run {
                    self.adherenceData = data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load adherence data"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getDatesForRange() -> [Date] {
        let calendar = Calendar.current
        let startDate = selectedTimeRange.startDate
        let dayCount = min(selectedTimeRange.daySpan, 28) // Limit to 4 weeks for display
        
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func cellColor(isCompleted: Bool, isFuture: Bool, isRestDay: Bool) -> Color {
        if isFuture {
            return Color("GrowthNeutralGray").opacity(0.1)
        } else if isCompleted {
            // Completed days (including logged rest days) show in green
            return isRestDay ? Color("GrowthGreen").opacity(0.7) : Color("GrowthGreen")
        } else if isRestDay {
            // Unlogged rest days show in neutral gray
            return Color("GrowthNeutralGray").opacity(0.3)
        } else {
            // Missed practice days show in error color
            return Color("ErrorColor").opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockRoutine = Routine(
        id: "1",
        name: "Beginner Growth",
        description: "A gentle introduction to growth practices",
        difficultyLevel: "Beginner",
        schedule: [
            DaySchedule(
                id: "1",
                dayNumber: 1,
                dayName: "Foundation Day",
                description: "Build your foundation",
                methodIds: ["1", "2"],
                isRestDay: false,
                additionalNotes: nil
            ),
            DaySchedule(
                id: "2",
                dayNumber: 2,
                dayName: "Rest Day",
                description: "Recovery and reflection",
                methodIds: nil,
                isRestDay: true,
                additionalNotes: "Remember to stay hydrated and get plenty of rest"
            )
        ],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    RoutineAdherenceView(routine: mockRoutine, userId: "mockUser")
        .padding()
        .background(Color(.systemGroupedBackground))
}