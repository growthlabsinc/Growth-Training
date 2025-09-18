//
//  HelpCenterView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI

struct HelpCenterView: View {
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil
    @StateObject private var repository = HelpArticleRepository.shared
    
    var searchResults: [HelpArticle] {
        if searchText.isEmpty {
            return []
        }
        return repository.searchArticles(query: searchText)
    }
    
    var popularArticles: [HelpArticle] {
        // Get the most important articles for quick access
        return [
            repository.articles.first { $0.id == "welcome-to-growth" },
            repository.articles.first { $0.id == "first-routine-guide" },
            repository.articles.first { $0.id == "measurement-guide" },
            repository.articles.first { $0.id == "safety-fundamentals" }
        ].compactMap { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    TextField("Search for help...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AppTheme.Typography.gravityBook(16))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Search Results
                if !searchText.isEmpty && !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Search Results")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(Color("TextColor"))
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(searchResults.prefix(5)) { article in
                                NavigationLink {
                                    HelpArticleDetailView(article: article)
                                } label: {
                                    ArticleRow(
                                        article: article
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            NavigationLink {
                                HelpCategoryDetailView(category: .gettingStarted)
                            } label: {
                                QuickActionCard(
                                    icon: "play.circle.fill",
                                    title: "Getting Started",
                                    color: Color("GrowthGreen")
                                )
                            }
                            
                            NavigationLink {
                                HelpCategoryDetailView(category: .settingsFeatures)
                            } label: {
                                QuickActionCard(
                                    icon: "person.crop.circle.badge.questionmark",
                                    title: "Account Help",
                                    color: .blue
                                )
                            }
                            
                            NavigationLink {
                                HelpCategoryDetailView(category: .trackingProgress)
                            } label: {
                                QuickActionCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Tracking Progress",
                                    color: .orange
                                )
                            }
                            
                            NavigationLink {
                                HelpCategoryDetailView(category: .troubleshooting)
                            } label: {
                                QuickActionCard(
                                    icon: "exclamationmark.triangle",
                                    title: "Troubleshooting",
                                    color: .red
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Help Categories
                VStack(alignment: .leading, spacing: 16) {
                    Text("Browse by Topic")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(HelpCategory.allCases, id: \.self) { category in
                            NavigationLink {
                                HelpCategoryDetailView(category: category)
                            } label: {
                                HelpCategoryRow(category: category, articleCount: repository.getArticles(for: category).count)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Popular Articles
                VStack(alignment: .leading, spacing: 16) {
                    Text("Popular Articles")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(popularArticles) { article in
                            NavigationLink {
                                HelpArticleDetailView(article: article)
                            } label: {
                                ArticleRow(article: article)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Contact Support Card
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    Text("Can't find what you're looking for?")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("TextColor"))
                    
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
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Help Category
enum HelpCategory: String, CaseIterable, Codable {
    case gettingStarted = "Getting Started"
    case methodsTechniques = "Methods & Techniques"
    case trackingProgress = "Tracking & Progress"
    case aiCoach = "AI Coach"
    case settingsFeatures = "Settings & Features"
    case troubleshooting = "Troubleshooting"
    
    var icon: String {
        switch self {
        case .gettingStarted: return "book.fill"
        case .methodsTechniques: return "list.bullet.rectangle"
        case .trackingProgress: return "chart.line.uptrend.xyaxis"
        case .aiCoach: return "message.fill"
        case .settingsFeatures: return "gearshape.fill"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .gettingStarted: return Color("GrowthGreen")
        case .methodsTechniques: return .blue
        case .trackingProgress: return .orange
        case .aiCoach: return .purple
        case .settingsFeatures: return .gray
        case .troubleshooting: return .red
        }
    }
}

// MARK: - Components
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(title)
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct HelpCategoryRow: View {
    let category: HelpCategory
    let articleCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(category.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                
                Text("\(articleCount) articles")
                    .font(AppTheme.Typography.gravityBook(13))
                    .foregroundColor(Color("TextSecondaryColor"))
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

struct ArticleRow: View {
    let article: HelpArticle
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text(article.category.rawValue)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(article.category.color)
                    
                    Text("•")
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    Text("\(article.readingTime) min")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    if article.isPremium {
                        Text("•")
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        Image(systemName: "crown.fill")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Category Detail View
struct HelpCategoryDetailView: View {
    let category: HelpCategory
    @StateObject private var repository = HelpArticleRepository.shared
    
    var articles: [HelpArticle] {
        repository.getArticles(for: category)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if articles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        Text("No articles yet")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(Color("TextColor"))
                        
                        Text("Check back soon for new content")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(articles) { article in
                        NavigationLink {
                            HelpArticleDetailView(article: article)
                        } label: {
                            ArticleRow(article: article)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}