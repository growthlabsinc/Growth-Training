//
//  GrowthTimerWidget.swift
//  GrowthTimerWidget
//
//  Created by TradeFlowJ on 6/18/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct GrowthTimerWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Growth Timer")
                .font(.headline)
            Text(entry.date, style: .time)
                .font(.caption)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GrowthTimerWidget: Widget {
    let kind: String = "GrowthTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GrowthTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Growth Timer")
        .description("Track your growth training sessions.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    GrowthTimerWidget()
} timeline: {
    SimpleEntry(date: .now)
}