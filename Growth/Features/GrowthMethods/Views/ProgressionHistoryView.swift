import SwiftUI

/// Displays a timeline of progression events for a Growth Method.
struct ProgressionHistoryView: View {
    let events: [ProgressionEvent]

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progression History")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(.primary)
            if events.isEmpty {
                Text("No progression events yet. Keep practicing to advance!")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
            } else {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Advanced to Stage \(event.toStage)")
                                .font(AppTheme.Typography.headlineFont())
                            Text(dateFormatter.string(from: event.timestamp))
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

#Preview {
    ProgressionHistoryView(events: [])
} 