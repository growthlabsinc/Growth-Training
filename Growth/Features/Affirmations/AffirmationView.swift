import SwiftUI

/// A lightweight banner-style view that shows an affirmation message.
struct AffirmationView: View {
    let affirmation: Affirmation
    @Binding var isPresented: Bool

    @State private var opacity: Double = 0

    var body: some View {
        if isPresented {
            VStack {
                Spacer(minLength: 0)
                HStack(alignment: .center) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color("GrowthGreen"))
                    Text(affirmation.text)
                        .font(AppTheme.Typography.subheadlineFont())
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    Spacer(minLength: 4)
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 4)
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .opacity(opacity)
            }
            .onAppear {
                // Reset opacity for re-use
                opacity = 0
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 1
                }
                // Auto dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    dismiss()
                }
            }
            .padding(.bottom, 8)
            .ignoresSafeArea(.keyboard)
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 0
        }
        // Delay actual removal to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#if DEBUG
#Preview {
    AffirmationView(affirmation: Affirmation(text: "Great job staying consistent!"), isPresented: .constant(true))
}
#endif 