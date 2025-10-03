//
//  StatsTrendCard.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

struct StatsTrendCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let trend: TrendInfo?
    let colorTheme: String
    let showChart: Bool
    let chartData: [ChartDataPoint]?
    
    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        trend: TrendInfo? = nil,
        colorTheme: String = "GrowthGreen",
        showChart: Bool = false,
        chartData: [ChartDataPoint]? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.colorTheme = colorTheme
        self.showChart = showChart
        self.chartData = chartData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color(colorTheme))
                
                Spacer()
                
                if let trend = trend {
                    TrendBadge(trend: trend)
                }
            }
            
            // Value and title
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextColor"))
                
                Text(title)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                Text(subtitle)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Mini chart (if enabled)
            if showChart, let chartData = chartData, !chartData.isEmpty {
                MiniTrendChart(data: chartData, color: Color(colorTheme))
                    .frame(height: 60)
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundColor"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


// Trend badge component
private struct TrendBadge: View {
    let trend: TrendInfo
    
    private var trendColor: Color {
        trend.isPositive ? Color("GrowthGreen") : Color("ErrorColor")
    }
    
    private var trendIcon: String {
        trend.isPositive ? "arrow.up.right" : "arrow.down.right"
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(AppTheme.Typography.captionFont())
                
                Text(String(format: "%.0f%%", abs(trend.percentageChange)))
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.medium)
            }
            .foregroundColor(trendColor)
            
            Text(trend.description)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
    }
}

// Mini trend chart
private struct MiniTrendChart: View {
    let data: [ChartDataPoint]
    let color: Color
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    private var minValue: Double {
        data.map { $0.value }.min() ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let xStep = geometry.size.width / CGFloat(data.count - 1)
                let valueRange = maxValue - minValue
                let yScale = valueRange > 0 ? geometry.size.height / CGFloat(valueRange) : 0
                
                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * xStep
                    let y = geometry.size.height - CGFloat(point.value - minValue) * yScale
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            
            // Fill gradient
            Path { path in
                guard !data.isEmpty else { return }
                
                let xStep = geometry.size.width / CGFloat(data.count - 1)
                let valueRange = maxValue - minValue
                let yScale = valueRange > 0 ? geometry.size.height / CGFloat(valueRange) : 0
                
                // Start from bottom left
                path.move(to: CGPoint(x: 0, y: geometry.size.height))
                
                // Draw line to data points
                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * xStep
                    let y = geometry.size.height - CGFloat(point.value - minValue) * yScale
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                // Close path at bottom right
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.3),
                        color.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Sample chart data
        let sampleData = (0..<7).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: 20...40)
            )
        }.reversed()
        
        StatsTrendCard(
            title: "Total Sessions",
            value: "24",
            subtitle: "In last month",
            icon: "figure.mind.and.body",
            trend: TrendInfo(percentageChange: 15.5, description: "vs last month"),
            colorTheme: "GrowthGreen",
            showChart: true,
            chartData: Array(sampleData)
        )
        
        StatsTrendCard(
            title: "Average Duration",
            value: "32m",
            subtitle: "Per session",
            icon: "clock.fill",
            trend: TrendInfo(percentageChange: -5.2, description: "vs last week"),
            colorTheme: "BrightTeal"
        )
        
        StatsTrendCard(
            title: "Current Streak",
            value: "7",
            subtitle: "days",
            icon: "flame.fill",
            colorTheme: "ErrorColor"
        )
    }
    .padding()
    .background(Color("GrowthBackgroundLight"))
}