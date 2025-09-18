import SwiftUI

struct EducationalResourceRowView: View {
    let resource: EducationalResource

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Layout.spacingM) {
            // Display local image first, then URL, then placeholder
            if let localImageName = resource.localImageName {
                Image(localImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(AppTheme.Layout.cornerRadiusM)
            } else if let imageUrl = resource.visualPlaceholderUrl,
                      let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppTheme.Colors.systemGray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                    case .failure(_):
                        Rectangle()
                            .fill(AppTheme.Colors.systemGray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(AppTheme.Layout.cornerRadiusM)
                            .overlay(
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Fallback when no URL is provided
                Rectangle()
                    .fill(AppTheme.Colors.systemGray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(AppTheme.Layout.cornerRadiusM)
                    .overlay(
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    )
            }

            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
                Text(resource.title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(2)

                Text(resource.category.rawValue)
                    .font(AppTheme.Typography.gravityBook(11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Layout.spacingS)
                    .padding(.vertical, AppTheme.Layout.spacingXS)
                    .background(AppTheme.Colors.systemGray.opacity(0.2))
                    .cornerRadius(AppTheme.Layout.cornerRadiusS)
                
                // Placeholder for summary - to be added if resource model gets a summary field
                // Text(resource.summary ?? "Brief description of the article content goes here...")
                //     .font(AppTheme.Typography.footnoteFont())
                //     .foregroundColor(AppTheme.Colors.textSecondary)
                //     .lineLimit(2)
            }
            Spacer() // Pushes content to the left
        }
        .padding(.vertical, AppTheme.Layout.spacingS)
    }
}

#if DEBUG
struct EducationalResourceRowView_Previews: PreviewProvider {
    static var previews: some View {
        EducationalResourceRowView(
            resource: EducationalResource(
                id: "1",
                title: "Understanding Vascular Health: The Basics",
                contentText: "This is a long text for the article...",
                category: .basics,
                visualPlaceholderUrl: nil,
                localImageName: "beginners-guide-angion"
            )
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 