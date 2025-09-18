import SwiftUI
#if canImport(Charts)
import Charts
#endif

/// Timeline visualization of daily practice totals (Story 14.6)
struct ProgressTimelineView: View {
    let data: [ProgressTimelineData]
    let timeRange: TimeRange
    var onSelectDate: ((Date) -> Void)? = nil
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ChartView(data: data, timeRange: timeRange, onSelectDate: onSelectDate)
                .frame(height: 180)
        } else {
            Text("Timeline requires iOS 16+")
                .foregroundColor(.secondary)
        }
    }
}

@available(iOS 16.0, *)
private struct ChartView: View {
    let data: [ProgressTimelineData]
    let timeRange: TimeRange
    var onSelectDate: ((Date) -> Void)? = nil
    private let calendar = Calendar.current
    
    private static let accessibilityFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    // Pre-computed grid dates for vertical RuleMarks
    private var gridDates: [Date] {
        guard let minDate = data.map({ $0.date }).min(),
              let maxDate = data.map({ $0.date }).max() else { return [] }
        let strideDays = timeRange == .year ? 30 : (timeRange == .quarter ? 15 : 7)
        var dates: [Date] = []
        var current = calendar.startOfDay(for: minDate)
        while current <= maxDate {
            dates.append(current)
            if let next = calendar.date(byAdding: .day, value: strideDays, to: current) {
                current = next
            } else {
                break
            }
        }
        return dates
    }
    
    var body: some View {
        let maxMinutes = data.map { $0.totalMinutes }.max() ?? 100
        let upperBound = max(maxMinutes, 100)

        Chart {
            // Grid lines
            ForEach(gridDates, id: \.self) { date in
                RuleMark(x: .value("Grid", date, unit: .day))
                    .foregroundStyle(Color.gray.opacity(0.18))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2]))
            }

            // Bar marks
            ForEach(data, id: \..date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Minutes", item.totalMinutes)
                )
                .cornerRadius(4)
                .foregroundStyle(Color("GrowthGreen").opacity(0.95))
                .accessibilityLabel("\(item.date, formatter: Self.accessibilityFormatter): \(item.totalMinutes) minutes")
                .annotation(position: .overlay, alignment: .center) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { onSelectDate?(item.date) }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: timeRange == .year ? 30 : (timeRange == .quarter ? 15 : 7))) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(Color.gray.opacity(0.18))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.gray.opacity(0.25))
                AxisValueLabel(format: .dateTime.day().month(.narrow))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(Color.gray.opacity(0.18))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.gray.opacity(0.25))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYScale(domain: 0...upperBound)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color("BackgroundColor"))
                .cornerRadius(12)
        }
        .accessibilityHint("Tap bar to view details")
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ProgressTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -29, to: Date())!
        var sample: [ProgressTimelineData] = []
        for offset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            sample.append(ProgressTimelineData(date: date, totalMinutes: Int.random(in: 0...60)))
        }
        return ProgressTimelineView(data: sample, timeRange: .month)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 