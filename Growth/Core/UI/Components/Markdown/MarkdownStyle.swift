//
//  MarkdownStyle.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import SwiftUI

/// Defines styling configuration for markdown elements
struct MarkdownStyle {
    // MARK: - Typography Styles
    struct Typography {
        let h1: Font
        let h2: Font
        let h3: Font
        let body: Font
        let caption: Font
        let code: Font
        
        // Spacing
        let h1TopSpacing: CGFloat
        let h2TopSpacing: CGFloat
        let h3TopSpacing: CGFloat
        let paragraphSpacing: CGFloat
        let listItemSpacing: CGFloat
        let lineSpacing: CGFloat
        
        static let `default` = Typography(
            h1: AppTheme.Typography.title1Font(),
            h2: AppTheme.Typography.title2Font(),
            h3: AppTheme.Typography.title3Font(),
            body: AppTheme.Typography.bodyFont(),
            caption: AppTheme.Typography.captionFont(),
            code: .system(.body, design: .monospaced),
            h1TopSpacing: AppTheme.Layout.spacingL,
            h2TopSpacing: AppTheme.Layout.spacingM,
            h3TopSpacing: AppTheme.Layout.spacingS,
            paragraphSpacing: AppTheme.Layout.spacingM,
            listItemSpacing: AppTheme.Layout.spacingXS,
            lineSpacing: 6
        )
        
        /// Returns a typography style scaled for the given font size
        static func scaled(fontSize: CGFloat) -> Typography {
            let scale = fontSize / AppTheme.Typography.body
            return Typography(
                h1: AppTheme.Typography.gravityBoldFont(AppTheme.Typography.title1 * scale),
                h2: AppTheme.Typography.gravitySemibold(AppTheme.Typography.title2 * scale),
                h3: AppTheme.Typography.gravitySemibold(AppTheme.Typography.title3 * scale),
                body: AppTheme.Typography.gravityBook(fontSize),
                caption: AppTheme.Typography.gravityBook(AppTheme.Typography.caption * scale),
                code: .system(size: fontSize * 0.9, weight: .regular, design: .monospaced),
                h1TopSpacing: AppTheme.Layout.spacingL,
                h2TopSpacing: AppTheme.Layout.spacingM,
                h3TopSpacing: AppTheme.Layout.spacingS,
                paragraphSpacing: AppTheme.Layout.spacingM,
                listItemSpacing: AppTheme.Layout.spacingXS,
                lineSpacing: 6 * scale
            )
        }
    }
    
    // MARK: - Color Styles
    struct Colors {
        let text: Color
        let secondaryText: Color
        let link: Color
        let codeBackground: Color
        let codeBorder: Color
        let tipBackground: Color
        let tipBorder: Color
        let tipIcon: Color
        let warningBackground: Color
        let warningBorder: Color
        let warningIcon: Color
        let infoBackground: Color
        let infoBorder: Color
        let infoIcon: Color
        let successBackground: Color
        let successBorder: Color
        let successIcon: Color
        
        static let light = Colors(
            text: AppTheme.Colors.text,
            secondaryText: AppTheme.Colors.textSecondary,
            link: AppTheme.Colors.accent,
            codeBackground: Color(.systemGray6),
            codeBorder: Color(.systemGray4),
            tipBackground: Color.yellow.opacity(0.1),
            tipBorder: Color.yellow.opacity(0.3),
            tipIcon: .yellow,
            warningBackground: Color.red.opacity(0.1),
            warningBorder: Color.red.opacity(0.3),
            warningIcon: .red,
            infoBackground: Color.blue.opacity(0.1),
            infoBorder: Color.blue.opacity(0.3),
            infoIcon: .blue,
            successBackground: AppTheme.Colors.success.opacity(0.1),
            successBorder: AppTheme.Colors.success.opacity(0.3),
            successIcon: AppTheme.Colors.success
        )
        
        static let dark = Colors(
            text: AppTheme.Colors.text,
            secondaryText: AppTheme.Colors.textSecondary,
            link: AppTheme.Colors.accent,
            codeBackground: Color(.systemGray5),
            codeBorder: Color(.systemGray3),
            tipBackground: Color.yellow.opacity(0.15),
            tipBorder: Color.yellow.opacity(0.4),
            tipIcon: .yellow,
            warningBackground: Color.red.opacity(0.15),
            warningBorder: Color.red.opacity(0.4),
            warningIcon: .red,
            infoBackground: Color.blue.opacity(0.15),
            infoBorder: Color.blue.opacity(0.4),
            infoIcon: .blue,
            successBackground: AppTheme.Colors.success.opacity(0.15),
            successBorder: AppTheme.Colors.success.opacity(0.4),
            successIcon: AppTheme.Colors.success
        )
    }
    
    // MARK: - Layout Configuration
    struct Layout {
        let contentPadding: EdgeInsets
        let blockPadding: EdgeInsets
        let codeBlockPadding: EdgeInsets
        let listIndentation: CGFloat
        let blockCornerRadius: CGFloat
        let codeCornerRadius: CGFloat
        
        static let `default` = Layout(
            contentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            blockPadding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
            codeBlockPadding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12),
            listIndentation: 20,
            blockCornerRadius: 12,
            codeCornerRadius: 8
        )
    }
    
    // MARK: - Properties
    let typography: Typography
    let colors: Colors
    let layout: Layout
    
    // MARK: - Default Styles
    static let light = MarkdownStyle(
        typography: .default,
        colors: .light,
        layout: .default
    )
    
    static let dark = MarkdownStyle(
        typography: .default,
        colors: .dark,
        layout: .default
    )
    
    /// Returns a style scaled for the given font size
    static func scaled(fontSize: CGFloat, colorScheme: ColorScheme) -> MarkdownStyle {
        MarkdownStyle(
            typography: .scaled(fontSize: fontSize),
            colors: colorScheme == .dark ? .dark : .light,
            layout: .default
        )
    }
}

// MARK: - Special Block Types
enum MarkdownBlockType {
    case tip
    case warning
    case info
    case success
    case note
    
    var icon: String {
        switch self {
        case .tip: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .note: return "note.text"
        }
    }
    
    var title: String {
        switch self {
        case .tip: return "Tip"
        case .warning: return "Warning"
        case .info: return "Info"
        case .success: return "Success"
        case .note: return "Note"
        }
    }
    
    func backgroundColor(from style: MarkdownStyle) -> Color {
        switch self {
        case .tip: return style.colors.tipBackground
        case .warning: return style.colors.warningBackground
        case .info: return style.colors.infoBackground
        case .success: return style.colors.successBackground
        case .note: return style.colors.infoBackground
        }
    }
    
    func borderColor(from style: MarkdownStyle) -> Color {
        switch self {
        case .tip: return style.colors.tipBorder
        case .warning: return style.colors.warningBorder
        case .info: return style.colors.infoBorder
        case .success: return style.colors.successBorder
        case .note: return style.colors.infoBorder
        }
    }
    
    func iconColor(from style: MarkdownStyle) -> Color {
        switch self {
        case .tip: return style.colors.tipIcon
        case .warning: return style.colors.warningIcon
        case .info: return style.colors.infoIcon
        case .success: return style.colors.successIcon
        case .note: return style.colors.infoIcon
        }
    }
}