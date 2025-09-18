//
//  FontDemoView.swift
//  Growth
//
//  Created by Developer on 7/18/25.
//

import SwiftUI

/// A view to demonstrate the Inter font in different styles
struct FontDemoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Inter Font Demo")
                    .font(AppTheme.Typography.title1Font())
                    .padding(.bottom, 10)
                
                // System font styles using Inter
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("System Styles with Inter")
                    
                    fontRow("Title 1", font: .interTitle1)
                    fontRow("Title 2", font: .interTitle2)
                    fontRow("Title 3", font: .interTitle3)
                    fontRow("Headline", font: .interHeadline)
                    fontRow("Subheadline", font: .interSubheadline)
                    fontRow("Body", font: .interBody)
                    fontRow("Callout", font: .interCallout)
                    fontRow("Footnote", font: .interFootnote)
                    fontRow("Caption", font: .interCaption)
                }
                
                // Growth typography styles
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("Growth Typography Styles")
                    
                    growthFontRow("H1", style: .h1)
                    growthFontRow("H2", style: .h2)
                    growthFontRow("H3", style: .h3)
                    growthFontRow("Body Large", style: .bodyLarge)
                    growthFontRow("Body", style: .body)
                    growthFontRow("Body Small", style: .bodySmall)
                    growthFontRow("Caption", style: .caption)
                    growthFontRow("Button Text", style: .buttonText)
                    growthFontRow("Metric Value", style: .metricValue)
                    growthFontRow("Progress Label", style: .progressLabel)
                }
                
                // Different weights
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("Inter Font Weights")
                    
                    weightRow("Thin", weight: .thin)
                    weightRow("Extra Light", weight: .extraLight)
                    weightRow("Light", weight: .light)
                    weightRow("Regular", weight: .regular)
                    weightRow("Medium", weight: .medium)
                    weightRow("Semibold", weight: .semibold)
                    weightRow("Bold", weight: .bold)
                    weightRow("Extra Bold", weight: .extraBold)
                    weightRow("Black", weight: .black)
                }
            }
            .padding()
        }
    }
    
    // Helper to create a section header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.headlineFont())
            .foregroundColor(.blue)
            .padding(.top, 10)
    }
    
    // Helper to create a font sample row
    private func fontRow(_ title: String, font: Font) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.gray)
            
            Text("The quick brown fox jumps over the lazy dog")
                .font(font)
        }
    }
    
    // Helper to create a growth typography style row
    private func growthFontRow(_ title: String, style: AppTypography.TextStyle) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.gray)
            
            Text("The quick brown fox jumps over the lazy dog")
                .font(fontForStyle(style))
        }
    }
    
    // Helper to get font for AppTypography style
    private func fontForStyle(_ style: AppTypography.TextStyle) -> Font {
        switch style.weight {
        case .light:
            return AppTheme.Typography.gravityLight(style.size)
        case .regular:
            return AppTheme.Typography.gravityBook(style.size)
        case .medium:
            return AppTheme.Typography.gravitySemibold(style.size)
        case .semibold:
            return AppTheme.Typography.gravitySemibold(style.size)
        case .bold:
            return AppTheme.Typography.gravityBoldFont(style.size)
        }
    }
    
    // Helper to create a weight sample row
    private func weightRow(_ title: String, weight: InterFont.InterWeight) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.gray)
            
            Text("The quick brown fox jumps over the lazy dog")
                .font(InterFont.swiftUIFont(size: 17, weight: weight))
        }
    }
}

#Preview {
    FontDemoView()
} 