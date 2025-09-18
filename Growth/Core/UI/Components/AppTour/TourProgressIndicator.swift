import SwiftUI

/// Displays progress through the app tour
struct TourProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let progressText: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color("GrowthGreen") : Color("TextSecondaryColor").opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
            
            // Progress text
            Text(progressText)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextColor"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("TourProgressIndicator")
        .accessibilityLabel(progressText)
    }
}