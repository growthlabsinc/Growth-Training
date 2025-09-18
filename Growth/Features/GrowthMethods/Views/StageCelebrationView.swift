import SwiftUI

/// A placeholder celebration view displayed when the user progresses to a new stage.
struct StageCelebrationView: View {
    let newStage: Int
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            Text("Congratulations!")
                .font(AppTheme.Typography.largeTitleFont())
                .fontWeight(.bold)
            Text("You've reached Stage \(newStage)!")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                // Dismiss action handled by parent using .presentation
            }) {
                Text("Continue")
                    .font(AppTheme.Typography.headlineFont())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

#Preview {
    StageCelebrationView(newStage: 2)
} 