import SwiftUI

struct GrowthProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @State private var selectedDate: Date? // To hold the date selected from the calendar
    @State private var detailDate: DrillDownDate? // For drill-down sheets
    @State private var calendarRefreshID = UUID() // Force calendar refresh
    @State private var isCalendarDataLoaded = false // Track when data is loaded
    @State private var showModernCalendar = false // Show modern calendar modal
    
    // Access authentication state
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range selector
                    TimeRangeSelector(selectedRange: $viewModel.selectedTimeRange)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    // Stats cards
                    statsGrid
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    // Timeline chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Practice Timeline")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(Color("GrowthGreen"))
                            .padding(.leading, 4)
                        Text("Minutes practiced per day")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        ProgressTimelineView(data: viewModel.timelineData, timeRange: viewModel.selectedTimeRange) { date in
                            detailDate = DrillDownDate(date: date)
                        }
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Bar chart showing minutes practiced per day for the selected range.")
                        .padding(.bottom, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Heatmap with title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Practice Intensity")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(Color("GrowthGreen"))
                            .padding(.horizontal, 20)

                        PracticeHeatmapView(dailyMinutes: viewModel.dailyMinutes, timeRange: viewModel.selectedTimeRange) { date in
                            detailDate = DrillDownDate(date: date)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Calendar section with improved UI
                    if #available(iOS 16.0, *) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Activity Calendar")
                                    .font(AppTheme.Typography.headlineFont())
                                    .foregroundColor(Color("GrowthGreen"))
                                
                                Spacer()
                                
                                Button(action: { showModernCalendar = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                        Text("View Full")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if isCalendarDataLoaded && !viewModel.dailyMinutes.isEmpty {
                                InlineModernCalendarView(viewModel: viewModel, selectedDate: $selectedDate)
                                    .id(calendarRefreshID)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                            } else {
                                // Show placeholder while loading
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 280)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("GrowthGreen")))
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 80) // More space at the bottom
            }
            // When user picks a date on the calendar, present drill-down sheet
            .onChangeCompat(of: selectedDate) { newValue in
                if let date = newValue {
                    detailDate = DrillDownDate(date: date)
                }
            }
            .onChangeCompat(of: viewModel.dailyMinutes) { newValue in
                // When data loads, set flag and force calendar recreation
                if !newValue.isEmpty {
                    isCalendarDataLoaded = true
                    calendarRefreshID = UUID()
                }
            }
            .navigationTitle("Progress")
            .onAppear {
                if authViewModel.isAuthenticated {
                    viewModel.fetchLoggedDates()
                }
            }
            .sheet(item: $detailDate) { wrapper in
                DailyDrillDownView(date: wrapper.date, sessions: viewModel.sessions(on: wrapper.date))
                    .onDisappear {
                        // Reset selectedDate when sheet is dismissed so the same date can be selected again
                        selectedDate = nil
                    }
            }
            .sheet(isPresented: $showModernCalendar) {
                ModernCalendarProgressView(viewModel: viewModel, isPresented: $showModernCalendar)
            }
        }
    }

    // MARK: - Subviews

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatInsightCard(title: "Sessions", valueText: "\(viewModel.totalSessionsInRange)", trendPercent: viewModel.trendSessionsPercent)
                .frame(maxWidth: .infinity)
            StatInsightCard(title: "Minutes", valueText: "\(viewModel.totalMinutesInRange)", trendPercent: viewModel.trendMinutesPercent)
                .frame(maxWidth: .infinity)
            StatInsightCard(title: "Avg Duration", valueText: "\(viewModel.averageSessionMinutes)m", trendPercent: viewModel.trendAvgDurationPercent)
                .frame(maxWidth: .infinity)
        }
    }
}

struct GrowthProgressView_Previews: PreviewProvider {
    static var previews: some View {
        GrowthProgressView()
            .environmentObject(AuthViewModel()) // Corrected type name for preview
    }
} 
