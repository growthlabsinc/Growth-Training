//
//  ProgressSummaryCard.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Reusable summary card component for progress data
struct ProgressSummaryCard<Content: View>: View {
    /// Card title
    let title: String
    
    /// Card subtitle (optional)
    let subtitle: String?
    
    /// Icon name for the card header
    let iconName: String
    
    /// Color theme for the card
    let colorTheme: String
    
    /// Action to perform when card is tapped (optional)
    let onTap: (() -> Void)?
    
    /// Card content
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        iconName: String,
        colorTheme: String = "GrowthGreen",
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.colorTheme = colorTheme
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                // Header
                headerSection
                
                // Content
                content
                
                // Tap indicator if action is provided
                if onTap != nil {
                    tapIndicator
                }
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            Spacer()
            
            Image(systemName: iconName)
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(Color(colorTheme))
        }
    }
    
    // MARK: - Tap Indicator
    
    private var tapIndicator: some View {
        HStack {
            Text("Tap to view details")
                .font(AppTheme.Typography.gravitySemibold(14))
            Spacer()
            Image(systemName: "arrow.right")
                .font(AppTheme.Typography.captionFont())
        }
        .foregroundColor(Color(colorTheme))
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ProgressSummaryCard(
            title: "Weekly Summary",
            subtitle: "Your progress this week",
            iconName: "chart.bar.fill",
            colorTheme: "GrowthGreen",
            onTap: { print("Card tapped") } // Release OK - Preview
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("5 sessions completed")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextColor"))
                
                Text("2h 30m total practice time")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        
        ProgressSummaryCard(
            title: "Achievements",
            iconName: "trophy.fill",
            colorTheme: "BrightTeal"
        ) {
            Text("No new achievements")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}