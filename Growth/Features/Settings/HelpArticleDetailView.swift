//
//  HelpArticleDetailView.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import SwiftUI
import Foundation  // For Logger

struct HelpArticleDetailView: View {
    let article: HelpArticle
    @StateObject private var repository = HelpArticleRepository.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var relatedArticles: [HelpArticle] {
        repository.getRelatedArticles(for: article)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    // Category Badge
                    HStack {
                        Image(systemName: article.category.icon)
                            .font(.caption)
                        Text(article.category.rawValue)
                            .font(AppTheme.Typography.captionFont())
                    }
                    .foregroundColor(article.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(article.category.color.opacity(0.1))
                    .cornerRadius(20)
                    
                    // Title
                    Text(article.title)
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(Color("TextColor"))
                    
                    // Subtitle
                    Text(article.subtitle)
                        .font(AppTheme.Typography.gravityBook(16))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    // Metadata
                    HStack(spacing: 16) {
                        Label("\(article.readingTime) min read", systemImage: "clock")
                        Label("Updated \(article.lastUpdated, style: .date)", systemImage: "calendar")
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                    
                    // Premium Badge
                    if article.isPremium {
                        Label("Premium Content", systemImage: "crown.fill")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Content
                FormattedTextView(content: article.content)
                    .padding(.horizontal)
                
                // Tags
                if !article.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(article.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(Color("GrowthGreen"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color("GrowthGreen").opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Related Articles
                if !relatedArticles.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Related Articles")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(Color("TextColor"))
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(relatedArticles) { relatedArticle in
                                NavigationLink {
                                    HelpArticleDetailView(article: relatedArticle)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(relatedArticle.title)
                                                .font(AppTheme.Typography.gravitySemibold(15))
                                                .foregroundColor(Color("TextColor"))
                                                .multilineTextAlignment(.leading)
                                            
                                            Text(relatedArticle.subtitle)
                                                .font(AppTheme.Typography.captionFont())
                                                .foregroundColor(Color("TextSecondaryColor"))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(Color("TextSecondaryColor"))
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Help Actions
                VStack(spacing: 16) {
                    Text("Was this article helpful?")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("TextColor"))
                    
                    HStack(spacing: 20) {
                        Button {
                            // Track helpful feedback
                            provideFeedback(helpful: true)
                        } label: {
                            Label("Yes", systemImage: "hand.thumbsup.fill")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                        .buttonStyle(BorderedButtonStyle())
                        
                        Button {
                            // Track unhelpful feedback
                            provideFeedback(helpful: false)
                        } label: {
                            Label("No", systemImage: "hand.thumbsdown")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                    
                    Text("Still need help?")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    NavigationLink {
                        ContactSupportView()
                    } label: {
                        Text("Contact Support")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("GrowthGreen"))
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share Article", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(Color("TextColor"))
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = URL(string: "https://growth.app/help/\(article.id)") {
                ShareSheet(items: [url])
            }
        }
    }
    
    
    // MARK: - Helper Methods
    private func provideFeedback(helpful: Bool) {
        // Track feedback analytics
        // For now, just show a simple acknowledgment
        // You could show an alert or toast here with message:
        // helpful ? "Thanks for your feedback!" : "We'll work on improving this article."
        
        Logger.debug("Article feedback: \(article.id) - Helpful: \(helpful)")
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        HelpArticleDetailView(
            article: HelpArticleRepository.defaultArticles[0]
        )
    }
}