import SwiftUI

struct NextSessionDetailView: View {
    let suggestion: NextSessionSuggestion
    @StateObject private var viewModel: NextSessionDetailViewModel
    // Navigation triggers
    @State private var showMethodDetail = false
    @State private var showTimer = false

    init(suggestion: NextSessionSuggestion) {
        self.suggestion = suggestion
        _viewModel = StateObject(wrappedValue: NextSessionDetailViewModel(suggestion: suggestion))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            contentSection
            Spacer()
            ctaSection
        }
        .padding()
        .navigationTitle("Next Session")
        .navigationBarTitleDisplayMode(.inline)
        // navigationDestination for full method instructions
        .navigationDestination(isPresented: $showMethodDetail) {
            if let method = viewModel.method {
                GrowthMethodDetailView(method: method)
            } else {
                Text("Method unavailable")
            }
        }
        // navigationDestination for Timer
        .navigationDestination(isPresented: $showTimer) {
            if let method = viewModel.method {
                TimerView(growthMethod: method)
            } else {
                TimerView() // fallback
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(suggestion.methodTitle)
                .font(AppTheme.Typography.title1Font())
                .fontWeight(.bold)
            HStack(spacing: 8) {
                Text("Stage \(suggestion.stage)")
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.secondary)
                if let mins = suggestion.durationMinutes {
                    Text("· \(mins) min")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                SwiftUI.ProgressView("Loading session details…")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.secondary)
            } else if let method = viewModel.method {
                VStack(alignment: .leading, spacing: 12) {
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.bodyFont())
                    if !method.equipmentNeeded.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equipment Needed")
                                .font(AppTheme.Typography.headlineFont())
                            ForEach(method.equipmentNeeded, id: \.self) { equipment in
                                Text("• \(equipment)")
                                    .font(AppTheme.Typography.subheadlineFont())
                            }
                        }
                    }
                }
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showMethodDetail = true
            }) {
                Text("View Full Instructions")
                    .font(AppTheme.Typography.headlineFont())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .disabled(viewModel.method == nil)

            Button(action: {
                showTimer = true
            }) {
                Text("Begin Session")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("GrowthGreen"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BackgroundColor"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .disabled(viewModel.method == nil)
        }
    }
}

#if DEBUG
struct NextSessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NextSessionDetailView(suggestion: NextSessionSuggestion(id: "method123", methodTitle: "Power Shred", stage: 2, durationMinutes: 30))
        }
    }
}
#endif 