import SwiftUI

/// Card summarizing a single statistic (Story 14.6)
struct StatInsightCard: View {
    let title: String
    let valueText: String
    let trendPercent: Double? // Positive for upward, negative downward, nil for N/A
    var compact: Bool = false
    var customHeight: CGFloat? = nil // Allows caller to override default height
    
    private var trendColor: Color {
        guard let percent = trendPercent else { return .secondary }
        return percent >= 0 ? Color("GrowthGreen") : .red
    }
    
    private var trendIcon: String? {
        guard let percent = trendPercent else { return nil }
        return percent >= 0 ? "arrow.up" : "arrow.down"
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(customHeight != nil ? .caption2 : .caption)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            Text(valueText)
                .font(.system(size: customHeight != nil ? 18 : 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            if let percent = trendPercent, let icon = trendIcon {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(String(format: "%.0f%%", abs(percent)))
                }
                .font(customHeight != nil ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundColor(trendColor)
            }
        }
        .frame(width: compact ? 80 : 90, height: customHeight ?? (compact ? 90 : 110))
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#if DEBUG
struct StatInsightCard_Previews: PreviewProvider {
    static var previews: some View {
        StatInsightCard(title: "Avg Duration", valueText: "32m", trendPercent: 12)
            .previewLayout(.sizeThatFits)
    }
}
#endif 