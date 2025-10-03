//
//  StatsHighlightView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Key statistics display component for the progress overview
struct StatsHighlightView: View {
    /// Statistics to display
    let statistics: [StatisticHighlight]
    
    /// Action to perform when user taps to view detailed statistics
    let onViewDetails: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                // Header
                headerSection
                
                // Statistics grid
                statisticsGrid
                
                // View details button
                viewDetailsButton
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Key Statistics")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text("Your progress at a glance")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(Color("BrightTeal"))
        }
    }
    
    // MARK: - Statistics Grid
    
    private var statisticsGrid: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            // First row: 2 items
            HStack(spacing: AppTheme.Layout.spacingM) {
                if statistics.count > 0 {
                    StatisticCardView(statistic: statistics[0])
                        .frame(maxWidth: .infinity)
                }
                if statistics.count > 1 {
                    StatisticCardView(statistic: statistics[1])
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Second row: 2 items or 1 centered
            HStack(spacing: AppTheme.Layout.spacingM) {
                if statistics.count > 2 {
                    StatisticCardView(statistic: statistics[2])
                        .frame(maxWidth: .infinity)
                }
                if statistics.count > 3 {
                    StatisticCardView(statistic: statistics[3])
                        .frame(maxWidth: .infinity)
                } else if statistics.count == 3 {
                    // Empty spacer to keep the third item on the left
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Third row: 1 item (full width)
            if statistics.count > 4 {
                StatisticCardView(statistic: statistics[4])
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - View Details Button
    
    private var viewDetailsButton: some View {
        Button(action: onViewDetails) {
            HStack {
                Text("View Detailed Stats")
                    .font(AppTheme.Typography.gravitySemibold(14))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(AppTheme.Typography.captionFont())
            }
            .foregroundColor(Color("BrightTeal"))
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Statistic Card View

/// Individual statistic card display
private struct StatisticCardView: View {
    let statistic: StatisticHighlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and trend
            HStack {
                Image(systemName: statistic.iconName)
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color(statistic.colorTheme))
                
                Spacer()
                
                if let trend = statistic.trend {
                    TrendIndicatorView(trend: trend)
                }
            }
            
            // Value
            Text(statistic.value)
                .font(AppTheme.Typography.gravityBoldFont(24))
                .foregroundColor(Color("TextColor"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(statistic.title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                
                Text(statistic.subtitle)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        .padding(AppTheme.Layout.spacingM)
        .background(Color(statistic.colorTheme).opacity(0.08))
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                .stroke(Color(statistic.colorTheme).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trend Indicator View

/// Trend indicator with percentage and direction
private struct TrendIndicatorView: View {
    let trend: TrendInfo
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.iconName)
                .font(AppTheme.Typography.captionFont())
            
            Text(String(format: "%.0f%%", abs(trend.percentageChange)))
                .font(AppTheme.Typography.gravityBoldFont(10))
        }
        .foregroundColor(Color(trend.color))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(trend.color).opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    let mockStatistics = [
        StatisticHighlight(
            title: "Total Sessions",
            value: "12",
            subtitle: "In last month",
            iconName: "figure.mind.and.body",
            trend: TrendInfo(percentageChange: 15.5, description: "vs last month"),
            colorTheme: "GrowthGreen"
        ),
        StatisticHighlight(
            title: "Total Time",
            value: "4h 30m",
            subtitle: "Practice time",
            iconName: "clock.fill",
            trend: TrendInfo(percentageChange: -5.2, description: "vs last month"),
            colorTheme: "BrightTeal"
        ),
        StatisticHighlight(
            title: "Average Session",
            value: "22m",
            subtitle: "Per session",
            iconName: "chart.bar.fill",
            trend: nil,
            colorTheme: "MintGreen"
        ),
        StatisticHighlight(
            title: "Current Streak",
            value: "7",
            subtitle: "days",
            iconName: "flame.fill",
            trend: nil,
            colorTheme: "ErrorColor"
        )
    ]
    
    StatsHighlightView(
        statistics: mockStatistics,
        onViewDetails: { print("View details") } // Release OK - Preview
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}