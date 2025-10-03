import SwiftUI

/// A view that displays the user's streak statistics and allows quick practice
struct StreakStatsView: View {
    // MARK: - Properties
    
    /// View model for streak statistics
    @StateObject private var viewModel = StreakStatsViewModel()
    
    /// Dismiss action for when presented in a sheet
    @Environment(\.dismiss) private var dismiss
    
    /// State for showing quick practice timer
    @State private var showQuickPracticeTimer = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    SwiftUI.ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current streak card
                            streakCard
                            
                            // Quick practice card
                            quickPracticeCard
                            
                            // Streak history
                            streakHistoryCard
                            
                            // 30-day practice calendar
                            streakCalendarCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Streak Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadStreakData()
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showQuickPracticeTimer) {
                NavigationStack {
                    QuickPracticeTimerView()
                }
            }
        }
    }
    
    // MARK: - Card Views
    
    /// Card displaying the current streak
    private var streakCard: some View {
        VStack(spacing: 10) {
            Text("Current Streak")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)
                
                Text("DAYS")
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            
            // Flame icon that grows with streak
            Image(systemName: "flame.fill")
                .font(.system(size: min(48, 24 + CGFloat(viewModel.currentStreak) * 1.5)))
                .foregroundColor(streakColor)
                .padding()
                .scaleEffect(viewModel.isStreakAtRisk ? 1.1 : 1.0)
                .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                           value: viewModel.isStreakAtRisk)
            
            // Warning text when streak is at risk
            if viewModel.isStreakAtRisk {
                Text("Your streak is at risk! Practice today to keep it going.")
                    .font(AppTheme.Typography.calloutFont())
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Card for quick practice session
    private var quickPracticeCard: some View {
        VStack(spacing: 15) {
            Text("Need a quick session to maintain your streak?")
                .font(AppTheme.Typography.headlineFont())
                .multilineTextAlignment(.center)
            
            Button {
                showQuickPracticeTimer = true
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Start 5-Minute Practice")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Card displaying streak history
    private var streakHistoryCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Streak History")
                .font(AppTheme.Typography.headlineFont())
                .padding(.bottom, 5)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Longest Streak")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.longestStreak) days")
                        .font(AppTheme.Typography.title3Font())
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last Practice")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.lastPracticeFormatted)
                        .font(AppTheme.Typography.title3Font())
                        .fontWeight(.semibold)
                }
            }
            
            // Streak achievement badges (placeholder for future enhancement)
            if viewModel.currentStreak > 0 {
                VStack(alignment: .leading) {
                    Text("Achievements")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            streakBadge(days: 3, current: viewModel.currentStreak)
                            streakBadge(days: 7, current: viewModel.currentStreak)
                            streakBadge(days: 14, current: viewModel.currentStreak)
                            streakBadge(days: 30, current: viewModel.currentStreak)
                            streakBadge(days: 90, current: viewModel.currentStreak)
                            streakBadge(days: 180, current: viewModel.currentStreak)
                            streakBadge(days: 365, current: viewModel.currentStreak)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Card containing calendar visualization of last 30 days
    private var streakCalendarCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Last 30 Days")
                .font(AppTheme.Typography.headlineFont())
            StreakCalendarView(calendarData: viewModel.calendarData)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    
    /// Badge for streak milestones
    /// - Parameters:
    ///   - days: The number of days for this milestone
    ///   - current: The current streak count
    /// - Returns: A streak badge view
    private func streakBadge(days: Int, current: Int) -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(current >= days ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    if days >= 100 {
                        Text("\(days)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("\(days)d")
                .font(AppTheme.Typography.captionFont())
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Color based on streak length
    private var streakColor: Color {
        if viewModel.currentStreak <= 0 {
            return .gray
        } else if viewModel.currentStreak < 7 {
            return .orange
        } else if viewModel.currentStreak < 30 {
            return .red
        } else {
            return .purple
        }
    }
}

// MARK: - Preview

struct StreakStatsView_Previews: PreviewProvider {
    static var previews: some View {
        StreakStatsView()
    }
} 