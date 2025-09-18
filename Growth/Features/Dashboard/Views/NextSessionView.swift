import SwiftUI

struct NextSessionView: View {
    @StateObject private var viewModel = NextSessionViewModel()
    /// Callback when user taps the CTA – parent can handle navigation to timer.
    var onStart: ((NextSessionSuggestion) -> Void)?

    var body: some View {
        content
            .onAppear { viewModel.loadSuggestion() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            SwiftUI.ProgressView("Loading next session…")
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let error = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Session")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("GrowthGreen"))
                Text(error)
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.secondary)
            }
        } else if let suggestion = viewModel.suggestion {
            ZStack(alignment: .bottomLeading) {
                // Hero image from asset catalog
                if let uiImage = UIImage(named: "hero_today") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    Color.gray.opacity(0.4)
                        .frame(height: 180)
                }

                // Gradient overlay (covers full height for stronger contrast)
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom)
                    .frame(maxHeight: .infinity)

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Session")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(.white)
                    Text(suggestion.methodTitle)
                        .font(AppTheme.Typography.title3Font())
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    HStack {
                        Text("Stage \(suggestion.stage)")
                        if let mins = suggestion.durationMinutes {
                            Text("· \(mins) min")
                        }
                    }
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.white.opacity(0.9))

                    Button(action: { onStart?(suggestion) }) {
                        Text("Start This Session")
                            .font(AppTheme.Typography.gravitySemibold(13))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color("GrowthGreen"), Color("BrightTeal")],
                                    startPoint: .leading,
                                    endPoint: .trailing)
                                    .cornerRadius(12)
                            )
                    }
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
    }
}

#if DEBUG
struct NextSessionView_Previews: PreviewProvider {
    static var previews: some View {
        NextSessionView(onStart: { _ in })
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 