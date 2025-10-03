//
//  CardView.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import SwiftUI

/// A styled card component that can contain any content
struct CardView<Content: View>: View {
    // MARK: - Properties
    
    let content: Content
    var hasShadow: Bool = true
    var backgroundColor: Color = Color("BackgroundColor")
    var cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusL
    var padding: CGFloat = AppTheme.Layout.spacingM
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Initialization
    
    init(
        hasShadow: Bool = true,
        backgroundColor: Color = Color("BackgroundColor"),
        cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusL,
        padding: CGFloat = AppTheme.Layout.spacingM,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.hasShadow = hasShadow
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor ?? (colorScheme == .dark ? Color("NeutralGray").opacity(0.2) : .clear), lineWidth: borderWidth)
            )
            .shadow(
                color: hasShadow ? Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08) : .clear,
                radius: hasShadow ? 8 : 0,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Standard card
        CardView {
            VStack(alignment: .leading) {
                Text("Basic Card")
                    .font(AppTheme.Typography.headlineFont())
                Text("This is a simple card component with default styling.")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
            }
        }
        
        // Card with border
        CardView(
            hasShadow: false,
            borderColor: .gray.opacity(0.3)
        ) {
            VStack(alignment: .leading) {
                Text("Bordered Card")
                    .font(AppTheme.Typography.headlineFont())
                Text("This card has a border instead of a shadow.")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
            }
        }
        
        // Card with custom styling
        CardView(
            backgroundColor: .blue.opacity(0.1),
            cornerRadius: AppTheme.Layout.cornerRadiusL,
            padding: AppTheme.Layout.spacingL
        ) {
            VStack(alignment: .leading) {
                Text("Custom Card")
                    .font(AppTheme.Typography.headlineFont())
                Text("This card has custom styling with a different background color, corner radius, and padding.")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
} 