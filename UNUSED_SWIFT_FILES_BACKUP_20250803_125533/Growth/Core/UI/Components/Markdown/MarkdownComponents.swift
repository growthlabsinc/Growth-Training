//
//  MarkdownComponents.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import SwiftUI
import UIKit

// MARK: - Tip Block
struct MarkdownTipBlock: View {
    let content: String
    let style: MarkdownStyle
    
    var body: some View {
        MarkdownSpecialBlock(
            icon: "lightbulb.fill",
            title: "Tip",
            content: content,
            backgroundColor: style.colors.tipBackground,
            borderColor: style.colors.tipBorder,
            iconColor: style.colors.tipIcon,
            style: style
        )
    }
}

// MARK: - Warning Block
struct MarkdownWarningBlock: View {
    let content: String
    let style: MarkdownStyle
    
    var body: some View {
        MarkdownSpecialBlock(
            icon: "exclamationmark.triangle.fill",
            title: "Warning",
            content: content,
            backgroundColor: style.colors.warningBackground,
            borderColor: style.colors.warningBorder,
            iconColor: style.colors.warningIcon,
            style: style
        )
    }
}

// MARK: - Info Block
struct MarkdownInfoBlock: View {
    let content: String
    let style: MarkdownStyle
    
    var body: some View {
        MarkdownSpecialBlock(
            icon: "info.circle.fill",
            title: "Info",
            content: content,
            backgroundColor: style.colors.infoBackground,
            borderColor: style.colors.infoBorder,
            iconColor: style.colors.infoIcon,
            style: style
        )
    }
}

// MARK: - Success Block
struct MarkdownSuccessBlock: View {
    let content: String
    let style: MarkdownStyle
    
    var body: some View {
        MarkdownSpecialBlock(
            icon: "checkmark.circle.fill",
            title: "Success",
            content: content,
            backgroundColor: style.colors.successBackground,
            borderColor: style.colors.successBorder,
            iconColor: style.colors.successIcon,
            style: style
        )
    }
}

// MARK: - Generic Special Block
struct MarkdownSpecialBlock: View {
    let icon: String
    let title: String
    let content: String
    let backgroundColor: Color
    let borderColor: Color
    let iconColor: Color
    let style: MarkdownStyle
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Layout.spacingM) {
            Image(systemName: icon)
                .font(style.typography.body)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                Text(title)
                    .font(style.typography.body.weight(.semibold))
                    .foregroundColor(style.colors.text)
                
                Text(content)
                    .font(style.typography.body)
                    .foregroundColor(style.colors.text)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(style.layout.blockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: style.layout.blockCornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(style.layout.blockCornerRadius)
    }
}

// MARK: - Code Block
struct MarkdownCodeBlock: View {
    let code: String
    let language: String?
    let style: MarkdownStyle
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                if let language = language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(style.colors.secondaryText)
                }
                
                Spacer()
                
                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(isCopied ? "Copied!" : "Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(isCopied ? AppTheme.Colors.success : style.colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(style.colors.codeBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(style.colors.codeBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.colors.codeBorder.opacity(0.3))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(style.typography.code)
                    .foregroundColor(style.colors.text)
                    .padding(style.layout.codeBlockPadding)
            }
            .frame(maxWidth: .infinity)
        }
        .background(style.colors.codeBackground)
        .overlay(
            RoundedRectangle(cornerRadius: style.layout.codeCornerRadius)
                .stroke(style.colors.codeBorder, lineWidth: 1)
        )
        .cornerRadius(style.layout.codeCornerRadius)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = code
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}

// MARK: - Block Quote
struct MarkdownBlockQuote: View {
    let content: String
    let style: MarkdownStyle
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(style.colors.secondaryText.opacity(0.3))
                .frame(width: 4)
            
            Text(content)
                .font(style.typography.body.italic())
                .foregroundColor(style.colors.secondaryText)
                .padding(.leading, AppTheme.Layout.spacingM)
                .padding(.vertical, AppTheme.Layout.spacingS)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Checklist Item
struct MarkdownChecklistItem: View {
    let text: String
    @State private var isChecked: Bool
    let style: MarkdownStyle
    let onToggle: ((Bool) -> Void)?
    
    init(text: String, isChecked: Bool = false, style: MarkdownStyle, onToggle: ((Bool) -> Void)? = nil) {
        self.text = text
        self._isChecked = State(initialValue: isChecked)
        self.style = style
        self.onToggle = onToggle
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isChecked.toggle()
                onToggle?(isChecked)
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Layout.spacingS) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(style.typography.body)
                    .foregroundColor(isChecked ? AppTheme.Colors.success : style.colors.secondaryText)
                    .scaleEffect(isChecked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isChecked)
                
                Text(text)
                    .font(style.typography.body)
                    .foregroundColor(style.colors.text)
                    .multilineTextAlignment(.leading)
                    .strikethrough(isChecked, color: style.colors.secondaryText)
                    .animation(.easeInOut(duration: 0.2), value: isChecked)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Interactive Checklist
struct MarkdownInteractiveChecklist: View {
    let items: [(String, Bool)]
    let style: MarkdownStyle
    @State private var checkedStates: [Bool]
    
    init(items: [(String, Bool)], style: MarkdownStyle) {
        self.items = items
        self.style = style
        self._checkedStates = State(initialValue: items.map { $0.1 })
    }
    
    var completionProgress: Double {
        let checkedCount = checkedStates.filter { $0 }.count
        return items.isEmpty ? 0 : Double(checkedCount) / Double(items.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            // Progress indicator
            if items.count > 2 {
                HStack {
                    Text("\(Int(completionProgress * 100))% Complete")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(style.colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(checkedStates.filter { $0 }.count) of \(items.count)")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.accent)
                }
                .padding(.bottom, 4)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.Colors.success)
                            .frame(width: geometry.size.width * completionProgress)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: completionProgress)
                    }
                }
                .frame(height: 4)
                .padding(.bottom, AppTheme.Layout.spacingM)
            }
            
            // Checklist items
            ForEach(items.indices, id: \.self) { index in
                MarkdownChecklistItem(
                    text: items[index].0,
                    isChecked: checkedStates[index],
                    style: style
                ) { isChecked in
                    checkedStates[index] = isChecked
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.bottom, style.typography.paragraphSpacing)
    }
}

// MARK: - Table Support
struct MarkdownTable: View {
    let headers: [String]
    let rows: [[String]]
    let style: MarkdownStyle
    
    var body: some View {
        VStack(spacing: 0) {
            // Headers
            HStack(spacing: 0) {
                ForEach(headers, id: \.self) { header in
                    Text(header)
                        .font(style.typography.body.weight(.semibold))
                        .foregroundColor(style.colors.text)
                        .padding(AppTheme.Layout.spacingS)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(style.colors.codeBackground)
                }
            }
            
            Divider()
            
            // Rows
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        Text(rows[rowIndex][colIndex])
                            .font(style.typography.body)
                            .foregroundColor(style.colors.text)
                            .padding(AppTheme.Layout.spacingS)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(rowIndex % 2 == 0 ? Color.clear : style.colors.codeBackground.opacity(0.5))
                    }
                }
                
                if rowIndex < rows.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: style.layout.codeCornerRadius)
                .stroke(style.colors.codeBorder, lineWidth: 1)
        )
        .cornerRadius(style.layout.codeCornerRadius)
    }
}

// MARK: - Inline Code
struct MarkdownInlineCode: View {
    let text: String
    let style: MarkdownStyle
    
    var body: some View {
        Text(text)
            .font(style.typography.code)
            .foregroundColor(style.colors.text)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(style.colors.codeBackground)
            .cornerRadius(4)
    }
}

// MARK: - Link
struct MarkdownLink: View {
    let text: String
    let url: String
    let style: MarkdownStyle
    @State private var isPressed = false
    
    var body: some View {
        Text(text)
            .font(style.typography.body)
            .foregroundColor(style.colors.link)
            .underline()
            .opacity(isPressed ? 0.6 : 1.0)
            .onTapGesture {
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {}
            )
    }
}