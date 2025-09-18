//
//  View+Extensions.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import SwiftUI

/// Extensions for SwiftUI View to add commonly used modifiers
extension View {
    
    /// Applies the default card style to the view
    /// - Returns: Styled view
    func cardStyle(
        hasShadow: Bool = true,
        backgroundColor: Color = AppTheme.Colors.systemBackground,
        cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusM,
        padding: CGFloat = AppTheme.Layout.spacingM
    ) -> some View {
        self
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: hasShadow ? Color.black.opacity(AppTheme.Layout.shadowOpacity) : .clear,
                radius: AppTheme.Layout.shadowRadius,
                x: AppTheme.Layout.shadowOffset.width,
                y: AppTheme.Layout.shadowOffset.height
            )
    }
    
    /// Applies the default heading 1 text style to a Text view
    /// - Returns: Styled view
    func h1Style() -> some View {
        self.font(AppTheme.Typography.title1Font())
            .foregroundColor(AppTheme.Colors.text)
    }
    
    /// Applies the default heading 2 text style to a Text view
    /// - Returns: Styled view
    func h2Style() -> some View {
        self.font(AppTheme.Typography.title2Font())
            .foregroundColor(AppTheme.Colors.text)
    }
    
    /// Applies the default body text style to a Text view
    /// - Returns: Styled view
    func bodyStyle() -> some View {
        self.font(AppTheme.Typography.bodyFont())
            .foregroundColor(AppTheme.Colors.text)
    }
    
    /// Applies the default caption text style to a Text view
    /// - Returns: Styled view
    func captionStyle() -> some View {
        self.font(AppTheme.Typography.captionFont())
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    /// Centers the view horizontally and vertically in its container
    /// - Returns: Centered view
    func centered() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Makes the view fill the width of its container
    /// - Returns: Full-width view
    func fillWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }
    
    /// Adds default padding to the view
    /// - Returns: Padded view
    func standardPadding() -> some View {
        self.padding(AppTheme.Layout.spacingM)
    }
    
    /// Conditionally applies a view modifier
    /// - Parameters:
    ///   - condition: Whether to apply the modifier
    ///   - transform: The modifier to apply
    /// - Returns: Modified or unmodified view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 