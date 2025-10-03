import SwiftUI

struct BadgesView: View {
    @StateObject private var viewModel = BadgesViewModel()

    private let gridColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var body: some View {
        VStack {
            // Filter Picker
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(BadgesViewModel.BadgeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .top])

            // Content area
            if viewModel.isLoading {
                Spacer()
                SwiftUI.ProgressView("Loading Badges...")
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        viewModel.loadBadges()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Spacer()
            } else if viewModel.filteredBadges.isEmpty {
                Spacer()
                Text("No badges to display.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 24) {
                        ForEach(viewModel.filteredBadges) { badge in
                            BadgeItemView(badge: badge, size: 80)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Badges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadBadges()
        }
    }
}

#if DEBUG
struct BadgesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BadgesView()
        }
    }
}
#endif 