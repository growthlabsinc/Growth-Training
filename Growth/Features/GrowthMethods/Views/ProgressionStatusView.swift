import SwiftUI

/// A lightweight view that provides a summary of the user's readiness to progress for a given Growth Method.
struct ProgressionStatusView: View {
    let snapshot: ProgressionSnapshot

    private var statusColor: Color {
        switch snapshot.overallStatus {
        case .notReady: return .red
        case .approaching: return .yellow
        case .ready: return .green
        case .exceeded: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Progression Readiness", systemImage: "speedometer")
                    .font(AppTheme.Typography.title3Font())
                Spacer()
                Text(snapshot.overallStatusText)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(statusColor)
            }
            .padding(.bottom, 4)

            // Sessions criterion
            if let required = snapshot.requiredSessions {
                criterionRow(icon: "checkmark.seal", title: "Sessions", current: snapshot.currentSessions, required: required)
            }
            // Consecutive days criterion
            if let requiredDays = snapshot.requiredConsecutiveDays {
                criterionRow(icon: "calendar", title: "Consecutive Days", current: snapshot.currentConsecutiveDays, required: requiredDays)
            }
            // Time criterion
            if let requiredMinutes = snapshot.requiredMinutes {
                criterionRow(icon: "clock", title: "Minutes Practiced", current: snapshot.currentMinutes, required: requiredMinutes)
            }
            // Mood criterion rows
            if let moodProgress = snapshot.moodProgress {
                ForEach(moodProgress.sorted(by: { $0.key < $1.key }), id: \.key) { mood, tuple in
                    criterionRow(icon: "face.smiling", title: "Mood \(mood.capitalized)", current: tuple.current, required: tuple.required)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func criterionRow(icon: String, title: String, current: Int, required: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(title)
                .font(AppTheme.Typography.bodyFont())
            Spacer()
            Text("\(current)/\(required)")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(current >= required ? .green : .secondary)
        }
    }
}

private extension ProgressionSnapshot {
    var overallStatusText: String {
        switch overallStatus {
        case .notReady: return "Not Ready"
        case .approaching: return "Getting Close"
        case .ready: return "Ready!"
        case .exceeded: return "More Than Ready"
        }
    }
}

#if DEBUG
#Preview {
    let snapshot = ProgressionSnapshot(
        currentSessions: 8,
        requiredSessions: 10,
        currentConsecutiveDays: 3,
        requiredConsecutiveDays: 5,
        moodProgress: ["good": (2,3)],
        currentMinutes: 180,
        requiredMinutes: 300,
        overallStatus: .approaching
    )
    return ProgressionStatusView(snapshot: snapshot)
        .padding()
}
#endif 