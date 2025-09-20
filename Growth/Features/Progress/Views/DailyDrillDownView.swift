import SwiftUI

/// Simple drill-down view listing sessions for a selected date (Story 14.6)
struct DailyDrillDownView: View, Identifiable {
    var id: Date { date }
    let date: Date
    let sessions: [SessionLog]
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color("GrowthGreen").opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date header
                        dateHeaderView
                            .padding(.top, 20)
                        
                        // Summary stats
                        if !sessions.isEmpty {
                            summaryStatsView
                                .padding(.horizontal)
                        }
                        
                        // Sessions list
                        if sessions.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            sessionsListView
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Session Details")
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(AppTheme.Typography.title2Font())
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var dateHeaderView: some View {
        VStack(spacing: 8) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(AppTheme.Typography.gravitySemibold(20))
                .foregroundColor(.primary)
            
            if calendar.isDateInToday(date) {
                Label("Today", systemImage: "star.fill")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
            }
        }
    }
    
    private var summaryStatsView: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "clock.fill",
                title: "Total Time",
                value: "\(totalMinutes) min",
                color: Color("GrowthGreen")
            )
            
            StatCard(
                icon: "number.circle.fill",
                title: "Sessions",
                value: "\(sessions.count)",
                color: Color("BrightTeal")
            )
            
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Average",
                value: "\(averageDuration) min",
                color: Color("MintGreen")
            )
        }
    }
    
    private var sessionsListView: some View {
        VStack(spacing: 12) {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, log in
                SessionCard(log: log, sessionNumber: index + 1)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(Color("GrowthGreen").opacity(0.5))
            
            Text("No Sessions Logged")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(.primary)
            
            Text("You didn't log any practice sessions on this day.")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    private var averageDuration: Int {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes / sessions.count
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(.primary)
            
            Text(title)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SessionCard: View {
    let log: SessionLog
    let sessionNumber: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Session number indicator
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(sessionNumber)")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(log.duration) minutes")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.primary)
                    
                    if let methodId = log.methodId {
                        Text("• \(methodName(for: methodId))")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 12) {
                    Label(log.startTime.formatted(date: .omitted, time: .shortened), 
                          systemImage: "clock")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                    
                    if let intensity = log.intensity {
                        Label("Intensity: \(intensity)/10", systemImage: "flame.fill")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.orange)
                    }
                }
                
                if let notes = log.userNotes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Mood indicator
            moodIcon(for: log.moodAfter)
                .font(AppTheme.Typography.title2Font())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func methodName(for id: String) -> String {
        // Map method IDs to display names
        switch id {
        case "s2s_stretch": return "S2S Stretches"
        case "s2s_advanced": return "Advanced S2S"
        case "bfr_cyclic_bending": return "BFR Cyclic Bending"
        case "angio_pumping": return "Angio Pumping"
        case "bfr_glans_pulsing": return "BFR Glans Pulsing"
        default: return "Method"
        }
    }
    
    private func moodIcon(for mood: Mood) -> some View {
        switch mood {
        case .veryPositive:
            return Image(systemName: "face.smiling.fill")
                .foregroundColor(.green)
        case .positive:
            return Image(systemName: "face.smiling")
                .foregroundColor(.green.opacity(0.8))
        case .neutral:
            return Image(systemName: "face.dashed")
                .foregroundColor(.gray)
        case .negative:
            return Image(systemName: "face.frowning")
                .foregroundColor(.orange)
        case .veryNegative:
            return Image(systemName: "face.frowning.fill")
                .foregroundColor(.red)
        }
    }
}

#if DEBUG
struct DailyDrillDownView_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let sampleDate = calendar.startOfDay(for: Date())
        let logs = [
            SessionLog(
                id: "1", 
                userId: "user", 
                duration: 25, 
                startTime: Date().addingTimeInterval(-3600 * 8),
                endTime: Date().addingTimeInterval(-3600 * 8 + 1500),
                userNotes: "Great session, felt energized",
                methodId: "s2s_stretch",
                moodBefore: .neutral,
                moodAfter: .positive,
                intensity: 7
            ),
            SessionLog(
                id: "2", 
                userId: "user", 
                duration: 15, 
                startTime: Date().addingTimeInterval(-3600 * 3),
                endTime: Date().addingTimeInterval(-3600 * 3 + 900),
                userNotes: "Quick afternoon session",
                methodId: "angio_pumping",
                moodBefore: .negative,
                moodAfter: .neutral,
                intensity: 4
            )
        ]
        DailyDrillDownView(date: sampleDate, sessions: logs)
            .preferredColorScheme(.light)
    }
}
#endif 