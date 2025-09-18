import ActivityKit
import WidgetKit
import SwiftUI

// Quick compilation test for SimpleLiveActivity
struct TestWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            VStack {
                Text("Test")
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Test")
                }
            } compactLeading: {
                Text("T")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("T")
            }
        }
    }
}