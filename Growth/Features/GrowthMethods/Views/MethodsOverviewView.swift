import SwiftUI

struct MethodsOverviewView: View {
    @StateObject private var viewModel = GrowthMethodsViewModel()
    @State private var selectedMethod: GrowthMethod? = nil
    @State private var showDetail = false
    @State private var showAllMethods = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    SwiftUI.ProgressView("Loading methods...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading methods")
                            .font(AppTheme.Typography.title3Font())
                            .fontWeight(.medium)
                        Text(error)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            viewModel.loadMethods()
                        }
                        .padding()
                        .background(Color("GrowthGreen"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(groupedMethods.keys.sorted(), id: \.self) { stage in
                                if let methods = groupedMethods[stage], !methods.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(stageTitle(for: stage))
                                            .font(AppTheme.Typography.title2Font()).bold()
                                            .foregroundColor(Color("GrowthGreen"))
                                            .padding(.horizontal, 16)
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 20) {
                                                ForEach(methods, id: \.id) { method in
                                                    MethodOverviewCard(method: method)
                                                        .onTapGesture {
                                                            selectedMethod = method
                                                            showDetail = true
                                                        }
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Methods")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadMethods()
            }
            .sheet(isPresented: $showDetail) {
                // TODO: Replace with real Method Detail screen
                if let method = selectedMethod {
                    VStack(spacing: 24) {
                        Text(method.title)
                            .font(AppTheme.Typography.title1Font())
                        Text(method.methodDescription)
                            .font(AppTheme.Typography.bodyFont())
                        Button("Close") { showDetail = false }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAllMethods = true
                    }) {
                        Text("View All Methods")
                            .font(AppTheme.Typography.bodyFont())
                            .fontWeight(.medium)
                            .foregroundColor(Color("MintGreen"))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationDestination(isPresented: $showAllMethods) {
                FixedGrowthMethodsListView()
            }
        }
    }

    // Group methods by stage (e.g., Beginner, Intermediate, etc.)
    private var groupedMethods: [String: [GrowthMethod]] {
        Dictionary(grouping: viewModel.methods) { method in
            stageTitle(for: method.stage)
        }
    }

    // Map stage int to display string
    private func stageTitle(for stage: Int) -> String {
        switch stage {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        case 4: return "Elite"
        default: return "Other"
        }
    }
    // Overload for string input
    private func stageTitle(for stage: String) -> String { stage }
}

struct MethodOverviewCard: View {
    let method: GrowthMethod
    // Use the same margin as Dashboard cards
    private let horizontalMargin: CGFloat = 16
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                // Image
                if method.id == "angio_pumping" || method.title.lowercased().contains("angio pumping") {
                    // Show angio pumping specific image
                    Image("angio_pumping")
                        .resizable()
                        .scaledToFill()
                } else if method.id == "am1_0" || method.title.lowercased().contains("angion method 1.0") {
                    // Show Angion Method 1.0 specific image
                    Image("am1_0")
                        .resizable()
                        .scaledToFill()
                } else if method.id == "am2_0" || method.title.lowercased().contains("angion method 2.0") {
                    // Show Angion Method 2.0 specific image
                    Image("am2_0")
                        .resizable()
                        .scaledToFill()
                } else if method.id == "am2_5" || method.title.lowercased().contains("angion method 2.5") {
                    // Show Angion Method 2.5 specific image
                    Image("am2_5")
                        .resizable()
                        .scaledToFill()
                } else if let urlString = method.visualPlaceholderUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color(.systemGray5)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color(.systemGray5)
                        @unknown default:
                            Color(.systemGray5)
                        }
                    }
                } else {
                    Color(.systemGray5)
                }
                // Overlay title
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 6)
                        .lineLimit(2)
                }
                .padding(12)
            }
            .frame(width: UIScreen.main.bounds.width - horizontalMargin * 2, height: 140)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .frame(width: UIScreen.main.bounds.width - horizontalMargin * 2)
    }
}

#if DEBUG
struct MethodsOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        MethodsOverviewView()
            .preferredColorScheme(.light)
    }
}
#endif 