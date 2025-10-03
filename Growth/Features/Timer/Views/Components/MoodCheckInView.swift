import SwiftUI

/// Simple modal view allowing the user to select their current mood or skip.
struct MoodCheckInView: View {
    var onSelect: (Mood) -> Void
    var onSkip: () -> Void

    @State private var selectedMood: Mood = .neutral

    private let columns = [GridItem(.adaptive(minimum: 60))]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("How are you feeling right now?")
                    .font(AppTheme.Typography.title3Font())
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button(action: { selectedMood = mood }) {
                            Text(mood.emoji)
                                .font(.system(size: 40))
                                .padding()
                                .background(mood == selectedMood ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Button(action: { onSelect(selectedMood) }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                Button("Skip") {
                    onSkip()
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Mood Check-In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
struct MoodCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        MoodCheckInView(onSelect: { _ in }, onSkip: {})
    }
}
#endif 