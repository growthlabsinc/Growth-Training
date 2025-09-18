import SwiftUI

/// Card component that displays routines performed today
struct TodayRoutinesCard: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var todaySessions: [SessionLog] {
        viewModel.sessions(on: Date())
    }
    
    private var totalMinutesToday: Int {
        todaySessions.reduce(0) { $0 + $1.duration }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Routines")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextColor"))
                        
                        if !todaySessions.isEmpty {
                            Text("\(todaySessions.count) session\(todaySessions.count == 1 ? "" : "s") • \(totalMinutesToday) minutes total")
                                .font(AppTheme.Typography.gravityBook(12))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                    
                    Spacer()
                    
                    // View all button
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("SwitchToProgressCalendar"),
                            object: nil
                        )
                    }) {
                        Text("View All")
                            .font(AppTheme.Typography.gravitySemibold(12))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                Divider()
                    .background(Color("TextSecondaryColor").opacity(0.2))
                
                // Content
                if todaySessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 40))
                .foregroundColor(Color("TextSecondaryColor").opacity(0.5))
            
            Text("No sessions logged today")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
            
            Button(action: {
                NotificationCenter.default.post(
                    name: .switchToPracticeTab,
                    object: nil
                )
            }) {
                Text("Start Practice")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    .padding(.vertical, AppTheme.Layout.spacingS)
                    .background(Color("GrowthGreen"))
                    .cornerRadius(AppTheme.Layout.cornerRadiusM)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Layout.spacingM)
    }
    
    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            ForEach(todaySessions.prefix(3)) { session in
                SessionRowView(session: session)
                
                if session.id != todaySessions.prefix(3).last?.id {
                    Divider()
                        .background(Color("TextSecondaryColor").opacity(0.1))
                }
            }
            
            if todaySessions.count > 3 {
                Text("+ \(todaySessions.count - 3) more session\(todaySessions.count - 3 == 1 ? "" : "s")")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Session Row View
private struct SessionRowView: View {
    let session: SessionLog
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Layout.spacingM) {
            // Time and duration
            VStack(alignment: .leading, spacing: 2) {
                Text(timeFormatter.string(from: session.startTime))
                    .font(AppTheme.Typography.gravitySemibold(12))
                    .foregroundColor(Color("TextColor"))
                
                Text("\(session.duration) min")
                    .font(AppTheme.Typography.gravityBook(11))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .frame(width: 60, alignment: .leading)
            
            // Method name and details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.variation ?? "Practice Session")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                    .lineLimit(1)
                
                if let intensity = session.intensity {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(intensityColor(for: intensity))
                        
                        Text("Intensity: \(intensity)/10")
                            .font(AppTheme.Typography.gravityBook(11))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
            }
            
            Spacer()
            
            // Mood indicator if available
            if session.moodAfter != .neutral {
                Text(session.moodAfter.emoji)
                    .font(.system(size: 16))
            }
        }
    }
    
    private func intensityColor(for intensity: Int) -> Color {
        switch intensity {
        case 0...3:
            return Color("MintGreen")
        case 4...6:
            return Color("BrightTeal")
        case 7...10:
            return Color("GrowthGreen")
        default:
            return Color("TextSecondaryColor")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Card with sessions - will show sample data if available
        TodayRoutinesCard(viewModel: ProgressViewModel())
        
        // Empty state card
        TodayRoutinesCard(viewModel: ProgressViewModel())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}