import SwiftUI

/// Horizontal segmented selector for choosing the time range in Progress screen (Story 14.6)
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#if DEBUG
struct TimeRangeSelector_Previews: PreviewProvider {
    @State static var range: TimeRange = .month
    static var previews: some View {
        TimeRangeSelector(selectedRange: $range)
            .previewLayout(.sizeThatFits)
    }
}
#endif 