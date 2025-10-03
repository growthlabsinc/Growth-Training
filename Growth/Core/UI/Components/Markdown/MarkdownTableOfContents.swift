//
//  MarkdownTableOfContents.swift
//  Growth
//
//  Floating table of contents for enhanced navigation in long articles
//

import SwiftUI

// MARK: - Table of Contents Item
struct TOCItem: Identifiable {
    let id = UUID()
    let title: String
    let level: Int
    let sectionId: String
}

// MARK: - Floating Table of Contents
struct MarkdownFloatingTOC: View {
    let items: [TOCItem]
    @Binding var activeSection: String?
    @State private var isExpanded = false
    @State private var showTOC = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // TOC Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if isExpanded {
                        Text("Contents")
                            .font(AppTheme.Typography.gravitySemibold(14))
                    }
                }
                .foregroundColor(AppTheme.Colors.text)
                .padding(.horizontal, isExpanded ? 16 : 12)
                .padding(.vertical, 12)
                .background(
                    Color(.secondarySystemBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: isExpanded ? 16 : 25)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .cornerRadius(isExpanded ? 16 : 25)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // TOC Content
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            TOCItemView(
                                item: item,
                                isActive: activeSection == item.sectionId,
                                onTap: {
                                    activeSection = item.sectionId
                                    withAnimation {
                                        isExpanded = false
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: 280, maxHeight: 400)
                .background(
                    Color(.secondarySystemBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity),
                    removal: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity)
                ))
                .padding(.top, 8)
            }
        }
        .padding()
        .onAppear {
            // Show TOC after a delay if article is long
            if items.count > 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showTOC = true
                    }
                }
            }
        }
    }
}

// MARK: - TOC Item View
struct TOCItemView: View {
    let item: TOCItem
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Level indicator
                if item.level > 1 {
                    ForEach(1..<item.level, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
                
                // Title
                Text(item.title)
                    .font(item.level == 1 ? 
                          AppTheme.Typography.gravitySemibold(14) : 
                          AppTheme.Typography.gravityBook(13))
                    .foregroundColor(isActive ? AppTheme.Colors.accent : AppTheme.Colors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Active indicator
                if isActive {
                    Circle()
                        .fill(AppTheme.Colors.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                isActive ? AppTheme.Colors.accent.opacity(0.1) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Inline Table of Contents
struct MarkdownInlineTOC: View {
    let items: [TOCItem]
    let style: MarkdownStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
            // Header
            HStack {
                Image(systemName: "list.bullet.indent")
                    .font(style.typography.body)
                    .foregroundColor(style.colors.secondaryText)
                
                Text("Table of Contents")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(style.colors.text)
                
                Spacer()
            }
            
            Divider()
            
            // Contents
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                ForEach(items) { item in
                    HStack(spacing: 8) {
                        // Level indentation
                        if item.level > 1 {
                            ForEach(1..<item.level, id: \.self) { _ in
                                Text("  ")
                            }
                        }
                        
                        // Number or bullet
                        Text(item.level == 1 ? "•" : "◦")
                            .font(style.typography.body)
                            .foregroundColor(style.colors.secondaryText)
                        
                        // Title as link
                        Text(item.title)
                            .font(item.level == 1 ? style.typography.body : style.typography.caption)
                            .foregroundColor(style.colors.link)
                            .underline()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - TOC Generator
extension MarkdownRenderer {
    static func generateTOC(from content: String) -> [TOCItem] {
        var items: [TOCItem] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("### ") {
                let title = String(trimmed.dropFirst(4))
                let sectionId = title.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                items.append(TOCItem(title: title, level: 3, sectionId: sectionId))
            } else if trimmed.hasPrefix("## ") {
                let title = String(trimmed.dropFirst(3))
                let sectionId = title.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                items.append(TOCItem(title: title, level: 2, sectionId: sectionId))
            } else if trimmed.hasPrefix("# ") {
                let title = String(trimmed.dropFirst(2))
                let sectionId = title.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                items.append(TOCItem(title: title, level: 1, sectionId: sectionId))
            }
        }
        
        return items
    }
}

// MARK: - Scrollable Article with TOC
struct MarkdownArticleWithTOC: View {
    let content: String
    let fontSize: CGFloat
    @State private var activeSection: String?
    @State private var tocItems: [TOCItem] = []
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Article content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Inline TOC at the beginning if article is long
                        if tocItems.count > 5 {
                            MarkdownInlineTOC(
                                items: tocItems,
                                style: MarkdownStyle.scaled(fontSize: fontSize, colorScheme: colorScheme)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Article content
                        MarkdownRenderer(content: content, fontSize: fontSize)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .onChangeCompat(of: activeSection) { newValue in
                    if let sectionId = newValue {
                        withAnimation {
                            proxy.scrollTo(sectionId, anchor: .top)
                        }
                    }
                }
            }
            
            // Floating TOC
            if tocItems.count > 3 {
                MarkdownFloatingTOC(
                    items: tocItems,
                    activeSection: $activeSection
                )
            }
        }
        .onAppear {
            tocItems = MarkdownRenderer.generateTOC(from: content)
        }
    }
}