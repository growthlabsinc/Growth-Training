import SwiftUI
import os.log

struct EducationalResourcesListView: View {
    @StateObject private var viewModel = EducationalResourcesListViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
                if viewModel.isLoading {
                    SwiftUI.ProgressView("Loading Resources...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(AppTheme.Colors.errorColor)
                        Text(errorMessage)
                            .font(AppTheme.Typography.gravityBook(13))
                            .foregroundColor(AppTheme.Colors.errorColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            viewModel.fetchEducationalResources()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .font(AppTheme.Typography.gravitySemibold(13))
                    }
                } else if viewModel.educationalResources.isEmpty {
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("No educational resources available at the moment. Please check back later.")
                            .font(AppTheme.Typography.gravityBook(13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.educationalResources) { resource in
                            if let resourceId = resource.id, !resourceId.isEmpty {
                                NavigationLink {
                                    EducationalResourceDetailView(resourceId: resourceId)
                                        .environmentObject(authViewModel)
                                } label: {
                                    EducationalResourceRowView(resource: resource)
                                }
                            } else {
                                EducationalResourceRowView(resource: resource)
                                    .onAppear {
                                        os_log(.error, "Warning: EducationalResource item with nil or empty ID: %{public}@", resource.title)
                                    }
                            }
                        }
                    }
                    .listStyle(PlainListStyle()) // Or InsetGroupedListStyle based on preference
                }
            }
        .onAppear {
            // Data is fetched in ViewModel's init, but can add a pull-to-refresh later if needed
            // Or re-fetch if view appears and data is stale/empty
            if viewModel.educationalResources.isEmpty && !viewModel.isLoading {
                // viewModel.fetchEducationalResources() // Uncomment if re-fetch on appear is desired
            }
        }
    }
}

#Preview {
    EducationalResourcesListView()
        .environmentObject(AuthViewModel())
} 
