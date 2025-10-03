import SwiftUI

/// Visualization of the last 30 days of practice activity.
/// Each day is represented by a small circle with color intensity based on duration.
/// Empty days are shown with a subtle outline.
struct StreakCalendarView: View {
    /// Dictionary keyed by the start of day date, value = total minutes practiced.
    let calendarData: [Date: Int]

    private let columns = Array(repeating: GridItem(.flexible(minimum: 12, maximum: 24), spacing: 4), count: 7)

    private var last30Days: [Date] {
        let calendar = Calendar.current
        return (0..<30).compactMap { offset in
            calendar.startOfDay(for: Date().addingTimeInterval(Double(-offset) * 86400))
        }.reversed()
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(last30Days, id: \ .self) { date in
                let minutes = calendarData[date] ?? 0
                Circle()
                    .fill(color(for: minutes))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .opacity(minutes > 0 ? 1 : 0)
                    )
                    .accessibilityLabel(accessibilityLabel(for: date, minutes: minutes))
            }
        }
    }

    private func color(for minutes: Int) -> Color {
        if minutes == 0 {
            return Color.gray.opacity(0.15)
        } else if minutes < 10 {
            return Color("GrowthGreen").opacity(0.4)
        } else if minutes < 30 {
            return Color("GrowthGreen").opacity(0.7)
        } else {
            return Color("GrowthGreen")
        }
    }

    private func accessibilityLabel(for date: Date, minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)
        if minutes == 0 {
            return "\(dateString): No practice recorded"
        } else {
            return "\(dateString): \(minutes) minutes practiced"
        }
    }
}

#if DEBUG
struct StreakCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        // Generate mock data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [Date: Int] = [:]
        for i in 0..<15 {
            let date = today.addingTimeInterval(Double(-i) * 86400)
            data[date] = Int.random(in: 5...40)
        }
        return StreakCalendarView(calendarData: data)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 