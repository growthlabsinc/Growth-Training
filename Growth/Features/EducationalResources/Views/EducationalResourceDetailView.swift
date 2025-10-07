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
                        // Category badge at top
                        HStack {
                            Text(resource.category.rawValue)
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Layout.spacingM)
                                .padding(.vertical, AppTheme.Layout.spacingXS)
                                .background(AppTheme.Colors.systemGray.opacity(0.2))
                                .cornerRadius(AppTheme.Layout.cornerRadiusS)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Layout.spacingM)
                        .padding(.top, AppTheme.Layout.spacingM)

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
                        } else {
                            // Default placeholder when no image is provided
                            Rectangle()
                                .fill(AppTheme.Colors.systemGray.opacity(0.3))
                                .frame(height: 200)
                                .cornerRadius(AppTheme.Layout.cornerRadiusM)
                                .overlay(
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(AppTheme.Typography.largeTitleFont())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                )
                                .padding(.horizontal, AppTheme.Layout.spacingM)
                        }
                        
                        // Content text with markdown support
                        FormattedTextView(content: resource.contentText)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.bottom, AppTheme.Layout.spacingL)

                        // Medical Disclaimer - Prominently displayed with warning styling
                        if let disclaimer = viewModel.medicalDisclaimer {
                            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
                                // Warning header with icon
                                HStack(spacing: AppTheme.Layout.spacingS) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(AppTheme.Typography.bodyFont())
                                        .foregroundColor(AppTheme.Colors.warningColor)

                                    Text("Medical Disclaimer")
                                        .font(AppTheme.Typography.subheadlineFont())
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.Colors.warningColor)
                                }

                                // Disclaimer text
                                Text(disclaimer)
                                    .font(AppTheme.Typography.footnoteFont())
                                    .foregroundColor(AppTheme.Colors.text)
                                    .lineSpacing(4)
                            }
                            .padding(AppTheme.Layout.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                                    .fill(AppTheme.Colors.warningColor.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                                            .strokeBorder(AppTheme.Colors.warningColor.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                            .padding(.bottom, AppTheme.Layout.spacingL)
                        }

                        // References section (citations)
                        if viewModel.hasCitations {
                            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                                Divider()
                                    .padding(.horizontal, AppTheme.Layout.spacingM)

                                // Section header
                                Text("References")
                                    .font(AppTheme.Typography.headlineFont())
                                    .foregroundColor(AppTheme.Colors.text)
                                    .padding(.horizontal, AppTheme.Layout.spacingM)

                                // Citations list
                                if let citations = viewModel.resource?.citations {
                                    ForEach(citations) { citation in
                                        CitationRowView(citation: citation)
                                            .padding(.horizontal, AppTheme.Layout.spacingM)

                                        if citation.id != citations.last?.id {
                                            Divider()
                                                .padding(.horizontal, AppTheme.Layout.spacingM)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, AppTheme.Layout.spacingL)
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