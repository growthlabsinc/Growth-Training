import SwiftUI

/// About view for the app
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                AppLogo(size: 100)
                    .padding(.top, 40)
                
                Text("Growth: Training")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Version 1.0.4")
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 15) {
                    aboutSection(
                        title: "About",
                        content: "Growth: Training is a comprehensive training app designed to help you achieve your personal development goals through scientifically-backed protocols and structured routines."
                    )
                    
                    aboutSection(
                        title: "Our Mission",
                        content: "To provide a simple yet powerful tool that empowers users to grow personally and professionally through structured protocols and consistent tracking."
                    )
                    
                    aboutSection(
                        title: "Contact Support",
                        content: "If you have any questions or feedback, please contact us at support@growthlabs.coach"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                Text("© 2025 Growth Labs. All rights reserved.")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Helper function to create a consistent about section
    private func aboutSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.headlineFont())
            
            Text(content)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
} 