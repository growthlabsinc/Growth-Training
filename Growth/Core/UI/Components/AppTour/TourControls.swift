import SwiftUI

/// Navigation controls for the app tour
struct TourControls: View {
    let showPrevious: Bool
    let buttonTitle: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Previous button (if applicable)
            if showPrevious {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color("TextColor").opacity(0.1))
                        )
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            // Skip button
            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color("TextSecondaryColor").opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Next/Done button
            Button(action: onNext) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color("GrowthGreen"))
                    )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPrevious)
    }
}