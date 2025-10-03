import WidgetKit
import SwiftUI

@main
struct GrowthTimerWidgetBundle: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        // Only include the Live Activity widget on iOS 16.2+
        if #available(iOSApplicationExtension 16.2, *) {
            GrowthTimerWidgetLiveActivity()
        }
    }
}