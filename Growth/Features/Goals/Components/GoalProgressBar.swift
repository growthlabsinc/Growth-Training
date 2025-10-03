import SwiftUI

/// A simple horizontal progress bar representing goal progress.
/// - Parameters:
///   - progress: Value between 0.0 and 1.0 indicating completion.
///   - height: Bar height (default 10).
///   - backgroundColor: Background track color.
///   - fillColor: Foreground fill color representing progress.
struct GoalProgressBar: View {
    var progress: Double // 0.0 – 1.0
    var height: CGFloat = 10
    var backgroundColor: Color = Color(.systemGray5)
    var fillColor: Color = Color("GrowthGreen")

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(fillColor)
                    .frame(width: max(0, min(CGFloat(progress) * geometry.size.width, geometry.size.width)), height: height)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
    }
}

#if DEBUG
struct GoalProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            GoalProgressBar(progress: 0.25)
            GoalProgressBar(progress: 0.6, height: 14, fillColor: .blue)
            GoalProgressBar(progress: 1.0, height: 8, fillColor: .green)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 