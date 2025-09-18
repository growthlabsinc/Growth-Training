import SwiftUI
import Foundation  // For Logger

/// Generic view to display a legal document
struct LegalDocumentView: View {
    let documentId: String
    @State private var document: LegalDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading document...")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let document = document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Document header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(document.title)
                                .font(AppTheme.Typography.gravitySemibold(24))
                                .foregroundColor(Color("TextColor"))
                            
                            HStack {
                                Label("Version \(document.version)", systemImage: "doc.text")
                                    .font(AppTheme.Typography.gravityBook(13))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                
                                Spacer()
                                
                                Label("Updated \(formatted(date: document.lastUpdated))", systemImage: "calendar")
                                    .font(AppTheme.Typography.gravityBook(13))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Document content with markdown support
                        Text(.init(document.content))
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextColor"))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                    }
                    .padding()
                }
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Color("ErrorColor"))
                    
                    Text("Unable to Load Document")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(errorMessage ?? "The document could not be loaded. Please check your internet connection and try again.")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: fetch) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("GrowthGreen"))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .onAppear {
            fetch()
        }
    }
    
    private func fetch() {
        isLoading = true
        Logger.debug("LegalDocumentView: Fetching document with ID: \(documentId)")
        
        LegalDocumentService.shared.fetchDocument(withId: documentId) { doc in
            DispatchQueue.main.async {
                self.document = doc
                self.isLoading = false
                if let doc = doc {
                    Logger.info("LegalDocumentView: Successfully loaded \(doc.title)")
                } else {
                    Logger.error("LegalDocumentView: Failed to load document \(self.documentId)")
                    self.errorMessage = "Document not found. Please check your internet connection."
                }
            }
        }
    }
    
    private func formatted(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

#if DEBUG
struct LegalDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        LegalDocumentView(documentId: "privacy_policy")
            .environmentObject(AuthViewModel())
    }
}
#endif 