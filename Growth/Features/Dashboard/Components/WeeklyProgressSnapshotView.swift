//
//  WeeklyProgressSnapshotView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct WeeklyProgressSnapshotView: View {
    @ObservedObject var viewModel: TodayViewViewModel
    let onViewProgress: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Weekly Progress")
                        .font(AppTheme.Typography.gravityBoldFont(18))
                        .foregroundColor(Color("TextColor"))
                    Spacer()
                    Button(action: onViewProgress) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(AppTheme.Typography.title2Font())
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                if viewModel.isLoadingWeeklyData {
                    loadingView
                } else {
                    progressContent
                }
            }
        }
        .modifier(TourTarget(id: "weekly_progress_snapshot"))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading progress...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Progress Content
    private var progressContent: some View {
        VStack(spacing: 16) {
            // Progress metrics row
            HStack(spacing: 0) {
                // Current Streak
                progressMetric(
                    title: "Streak",
                    value: "\(viewModel.currentStreak)",
                    unit: "days",
                    icon: "flame.fill",
                    color: streakColor
                )
                
                Divider()
                    .frame(height: 40)
                
                // Weekly Minutes
                progressMetric(
                    title: "This Week",
                    value: "\(viewModel.totalWeeklyMinutes)",
                    unit: "min",
                    icon: "clock.fill",
                    color: Color("GrowthGreen")
                )
                
                Divider()
                    .frame(height: 40)
                
                // Routine Adherence (Placeholder for Epic 17)
                progressMetric(
                    title: "Adherence",
                    value: "\(viewModel.routineAdherencePercent)",
                    unit: "%",
                    icon: "target",
                    color: adherenceColor
                )
            }
            
            // Weekly progress bar visualization
            weeklyProgressBar
        }
    }
    
    // MARK: - Progress Metric Component
    private func progressMetric(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.gravityBoldFont(20))
                    .foregroundColor(Color("TextColor"))
                
                Text(unit)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Text(title)
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Weekly Progress Bar
    private var weeklyProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Activity")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    weeklyDayBar(for: dayIndex)
                }
            }
        }
    }
    
    private func weeklyDayBar(for dayIndex: Int) -> some View {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? today
        let startOfDay = calendar.startOfDay(for: dayDate)
        let dayMinutes = viewModel.dailyMinutes[startOfDay] ?? 0
        
        // Calculate relative height (max 30 minutes = full height)
        let maxMinutes: CGFloat = 30
        let heightFraction = min(CGFloat(dayMinutes) / maxMinutes, 1.0)
        let barHeight: CGFloat = 20
        
        return VStack(spacing: 2) {
            Rectangle()
                .fill(dayMinutes > 0 ? Color("GrowthGreen") : Color.gray.opacity(0.3))
                .frame(height: max(2, barHeight * heightFraction))
                .cornerRadius(2)
            
            Text(dayAbbreviation(for: dayDate))
                .font(AppTheme.Typography.gravitySemibold(10))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 35)
    }
    
    // MARK: - Helper Methods
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private var streakColor: Color {
        if viewModel.currentStreak == 0 {
            return Color.gray
        } else if viewModel.currentStreak < 7 {
            return Color.orange
        } else if viewModel.currentStreak < 30 {
            return Color.red
        } else {
            return Color.purple
        }
    }
    
    private var adherenceColor: Color {
        if viewModel.routineAdherencePercent >= 80 {
            return Color("GrowthGreen")
        } else if viewModel.routineAdherencePercent >= 60 {
            return Color.orange
        } else {
            return Color.red
        }
    }
}

#Preview {
    let mockRoutinesVM = RoutinesViewModel(userId: "mock")
    let mockProgressVM = ProgressViewModel()
    let mockTodayVM = TodayViewViewModel(routinesViewModel: mockRoutinesVM, progressViewModel: mockProgressVM)
    
    return WeeklyProgressSnapshotView(
        viewModel: mockTodayVM,
        onViewProgress: { print("View progress") } // Release OK - Preview
    )
    .padding()
}