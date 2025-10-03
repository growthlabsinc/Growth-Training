import SwiftUI

/// A button style that provides gentle press feedback for card-like buttons.
/// Applies a slight scale and shadow change when pressed, matching Story 14.2 requirements.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.12 : 0.08),
                radius: configuration.isPressed ? 12 : 8,
                x: 0,
                y: 2
            )
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#if DEBUG
struct CardButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {}) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 120)
                .overlay(Text("Pressable Card"))
        }
        .buttonStyle(CardButtonStyle())
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 