import SwiftUI
import FirebaseFirestore

/// View for displaying details of an educational resource
struct EducationalResourceDetailView: View {
    /// The unique identifier of the resource to display
    let resourceId: String
    
    /// View model for fetching and managing resource data
    @StateObject private var viewModel: EducationalResourceDetailViewModel
    
    /// Auth view model shared through the environment
    @EnvironmentObject var authViewModel: AuthViewModel
    
    init(resourceId: String) {
        self.resourceId = resourceId
        self._viewModel = StateObject(wrappedValue: EducationalResourceDetailViewModel(resourceId: resourceId))
    }

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.isLoading {
                    SwiftUI.ProgressView("Loading article...")
                        .padding(.top, AppTheme.Layout.spacingXL)
                } else if let resource = viewModel.resource {
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                        // Title
                        Text(resource.title)
                            .font(AppTheme.Typography.title1Font())
                            .foregroundColor(AppTheme.Colors.text)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.top, AppTheme.Layout.spacingM)
                        
                        // Category
                        Text(resource.category.rawValue)
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.vertical, AppTheme.Layout.spacingXS)
                            .background(AppTheme.Colors.systemGray.opacity(0.2))
                            .cornerRadius(AppTheme.Layout.cornerRadiusS)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                        
                        // Visual placeholder/image - local image takes precedence
                        if let localImageName = resource.localImageName {
                            Image(localImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(AppTheme.Layout.cornerRadiusM)
                                .clipped()
                                .padding(.horizontal, AppTheme.Layout.spacingM)
                        } else if let imageUrl = resource.visualPlaceholderUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(AppTheme.Colors.systemGray.opacity(0.3))
                                        .frame(height: 200)
                                        .cornerRadius(AppTheme.Layout.cornerRadiusM)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .cornerRadius(AppTheme.Layout.cornerRadiusM)
                                        .clipped()
                                case .failure:
                                    Rectangle()
                                        .fill(AppTheme.Colors.systemGray.opacity(0.3))
                                        .frame(height: 200)
                                        .cornerRadius(AppTheme.Layout.cornerRadiusM)
                                        .overlay(
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(AppTheme.Typography.largeTitleFont())
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                        }
                        
                        // Content text with markdown support
                        FormattedTextView(content: resource.contentText)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.bottom, AppTheme.Layout.spacingL)
                        
                        // Show citations if content mentions scientific claims
                        if resource.contentText.contains("research") || 
                           resource.contentText.contains("study") || 
                           resource.contentText.contains("evidence") ||
                           resource.category == .science {
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                    .padding(.horizontal, AppTheme.Layout.spacingM)
                                
                                NavigationLink(destination: AllCitationsView()) {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .font(.system(size: 14))
                                        Text("View Scientific References")
                                            .font(AppTheme.Typography.captionFont())
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .padding(.horizontal, AppTheme.Layout.spacingM)
                                    .padding(.vertical, AppTheme.Layout.spacingS)
                                }
                            }
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(AppTheme.Typography.largeTitleFont())
                            .foregroundColor(AppTheme.Colors.errorColor)
                        
                        Text("Error loading resource")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text(errorMessage)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.errorColor)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            viewModel.fetchResource()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(AppTheme.Layout.spacingL)
                } else {
                    Text("Resource not found")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(AppTheme.Colors.text)
                        .padding()
                }
            }
        }
        .navigationTitle("Resource Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct EducationalResourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        return NavigationView {
            EducationalResourceDetailView(resourceId: "preview-id")
                .environmentObject(authViewModel)
        }
    }
}
#endif