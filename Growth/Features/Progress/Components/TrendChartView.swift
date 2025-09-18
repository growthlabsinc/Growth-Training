//
//  TrendChartView.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

struct TrendChartView: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    let showTrend: Bool
    let height: CGFloat
    let yAxisUnit: String?
    
    init(
        data: [ChartDataPoint],
        title: String,
        color: Color = Color("GrowthGreen"),
        showTrend: Bool = true,
        height: CGFloat = 200,
        yAxisUnit: String? = nil
    ) {
        self.data = data
        self.title = title
        self.color = color
        self.showTrend = showTrend
        self.height = height
        self.yAxisUnit = yAxisUnit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and trend
            HStack {
                Text(title)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                if showTrend, let trend = calculateTrend() {
                    TrendIndicator(trend: trend)
                }
            }
            
            // Chart with Y-axis labels
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Y-axis area with no spacing
                    HStack(spacing: 5) {
                        // Rotated unit label as single vertical word
                        if let unit = yAxisUnit, !data.isEmpty {
                            Text(unit)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color("TextSecondaryColor"))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 8, height: 100) // Ultra-minimal width
                                .clipped() // Clip any overflow
                        }
                        
                        // Y-axis value labels with increased space
                        if !data.isEmpty {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(Array(yAxisLabels().enumerated()), id: \.offset) { index, label in
                                    VStack {
                                        Spacer()
                                        Text(label)
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(Color("TextSecondaryColor"))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                            .truncationMode(.tail)
                                            .fixedSize(horizontal: true, vertical: false)
                                            .multilineTextAlignment(.trailing)
                                        Spacer()
                                    }
                                    .frame(height: max(20, (geometry.size.height - 40) / 5)) // Adjusted for reduced padding
                                }
                            }
                            .frame(width: 25, alignment: .trailing) // Increased width for better text fit
                        }
                    }
                    .frame(width: yAxisUnit != nil ? 73 : 65) // Ultra-tight spacing
                    
                    // Chart area with proper alignment
                    ZStack(alignment: .bottomLeading) {
                        // Background grid aligned with chart data
                        GridView()
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            .padding(.horizontal, 12)
                        
                        // Line chart with improved scaling
                        if !data.isEmpty {
                            GeometryReader { chartGeometry in
                                LineChart(
                                    data: data,
                                    size: CGSize(
                                        width: chartGeometry.size.width - 24,
                                        height: chartGeometry.size.height - 40
                                    ),
                                    color: color
                                )
                                .padding(.top, 20)
                                .padding(.bottom, 20)
                                .padding(.horizontal, 12)
                            }
                        } else {
                            EmptyChartView()
                                .padding(.top, 20)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .frame(height: height)
            .background(Color("BackgroundColor"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityValue(accessibilityDataSummary)
            
            // X-axis labels with proper alignment
            if !data.isEmpty {
                HStack(spacing: 0) {
                    // Left spacer to align with chart area
                    Spacer()
                        .frame(width: yAxisUnit != nil ? 77 : 65) // Match y-axis width exactly
                    
                    // X-axis date labels
                    HStack(spacing: 0) {
                        ForEach(Array(xAxisLabels().enumerated()), id: \.offset) { index, label in
                            Text(label)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Color("TextSecondaryColor"))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 12) // Match chart horizontal padding
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func calculateTrend() -> Double? {
        guard data.count >= 2 else { return nil }
        
        let recentPeriod = Array(data.suffix(data.count / 2))
        let previousPeriod = Array(data.prefix(data.count / 2))
        
        let recentAvg = recentPeriod.reduce(0) { $0 + $1.value } / Double(recentPeriod.count)
        let previousAvg = previousPeriod.reduce(0) { $0 + $1.value } / Double(previousPeriod.count)
        
        guard previousAvg > 0 else { return nil }
        return ((recentAvg - previousAvg) / previousAvg) * 100
    }
    
    private func xAxisLabels() -> [String] {
        guard !data.isEmpty else { return [] }
        
        // More minimal - show only 3 labels: start, middle, end
        let count = min(3, data.count)
        if count == 1 {
            return [formatDate(data[0].date)]
        } else if count == 2 {
            return [formatDate(data[0].date), formatDate(data[data.count - 1].date)]
        } else {
            let middleIndex = data.count / 2
            return [
                formatDate(data[0].date),
                formatDate(data[middleIndex].date),
                formatDate(data[data.count - 1].date)
            ]
        }
    }
    
    private func yAxisLabels() -> [String] {
        guard !data.isEmpty else { return [] }
        
        let values = data.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        
        // Add padding to match chart scaling
        let range = maxValue - minValue
        let padding = range * 0.1
        let displayMin = max(0, minValue - padding)
        let displayMax = maxValue + padding
        let displayRange = displayMax - displayMin
        
        // Create 5 labels from max to min (top to bottom)
        let step = displayRange / 4
        return (0...4).map { i in
            let value = displayMax - (Double(i) * step)
            return formatAxisValue(value)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        // Format based on the unit type for better readability and compactness
        if let unit = yAxisUnit {
            switch unit.lowercased() {
            case "sessions":
                if value < 1000 {
                    return String(format: "%.0f", value)
                } else {
                    return String(format: "%.0fK", value / 1000)
                }
            case "duration":
                if value >= 60 {
                    let hours = Int(value / 60)
                    return "\(hours)h"
                } else {
                    return "\(Int(value))m"
                }
            case "percentage":
                return "\(Int(value))%"
            case "length", "girth", "volume":
                // Show 1 decimal place for gains measurements
                return String(format: "%.1f", value)
            default:
                break
            }
        }
        
        // Default formatting with 1 decimal place
        if value == 0 {
            return "0.0"
        } else if value < 1000 {
            return String(format: "%.1f", value)
        } else {
            // Use K notation for large numbers
            return String(format: "%.1fK", value / 1000)
        }
    }
    
    // MARK: - Accessibility Support
    
    private var accessibilityDescription: String {
        var description = "Chart showing \(title.lowercased())"
        
        if let unit = yAxisUnit {
            description += " measured in \(unit.lowercased())"
        }
        
        if let trend = calculateTrend() {
            let trendDirection = trend >= 0 ? "increasing" : "decreasing"
            description += ". Overall trend is \(trendDirection) by \(String(format: "%.0f", abs(trend))) percent"
        }
        
        return description
    }
    
    private var accessibilityDataSummary: String {
        guard !data.isEmpty else { return "No data available" }
        
        let minValue = data.map { $0.value }.min() ?? 0
        let maxValue = data.map { $0.value }.max() ?? 0
        let avgValue = data.reduce(0) { $0 + $1.value } / Double(data.count)
        
        let unitSuffix = yAxisUnit != nil ? " \(yAxisUnit!.lowercased())" : ""
        
        return "Data ranges from \(formatAxisValue(minValue))\(unitSuffix) to \(formatAxisValue(maxValue))\(unitSuffix), with an average of \(formatAxisValue(avgValue))\(unitSuffix). Contains \(data.count) data points."
    }
}

// Chart data point
struct ChartDataPoint {
    let date: Date
    let value: Double
}

// Line chart component with improved scaling
private struct LineChart: View {
    let data: [ChartDataPoint]
    let size: CGSize
    let color: Color
    
    private var valueRange: (min: Double, max: Double) {
        guard !data.isEmpty else { return (0, 1) }
        let values = data.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        
        // Add padding to the range for better visualization
        let range = maxValue - minValue
        let padding = range * 0.1 // 10% padding
        
        return (
            min: max(0, minValue - padding), // Don't go below 0 for most metrics
            max: maxValue + padding
        )
    }
    
    var body: some View {
        let range = valueRange
        let valueSpan = range.max - range.min
        
        Path { path in
            guard !data.isEmpty, valueSpan > 0 else { return }
            
            let xStep = data.count > 1 ? size.width / CGFloat(data.count - 1) : 0
            let yScale = size.height / CGFloat(valueSpan)
            
            for (index, point) in data.enumerated() {
                let x = data.count > 1 ? CGFloat(index) * xStep : size.width / 2
                let normalizedValue = point.value - range.min
                let y = size.height - CGFloat(normalizedValue) * yScale
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, lineWidth: 2.5)
        .shadow(color: color.opacity(0.3), radius: 1, x: 0, y: 1)
        
        // Data points with improved positioning
        ForEach(Array(data.enumerated()), id: \.offset) { index, point in
            let xStep = data.count > 1 ? size.width / CGFloat(data.count - 1) : 0
            let yScale = size.height / CGFloat(valueSpan)
            let x = data.count > 1 ? CGFloat(index) * xStep : size.width / 2
            let normalizedValue = point.value - range.min
            let y = size.height - CGFloat(normalizedValue) * yScale
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1)
                .position(x: x, y: y)
        }
    }
}

// Grid view
private struct GridView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Horizontal lines
                for i in 0...4 {
                    let y = geometry.size.height * CGFloat(i) / 4
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        }
    }
}

// Empty chart view
private struct EmptyChartView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color.gray.opacity(0.3))
            
            Text("No data available")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextSecondaryColor"))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Trend indicator
private struct TrendIndicator: View {
    let trend: Double
    
    private var isPositive: Bool {
        trend >= 0
    }
    
    private var trendColor: Color {
        isPositive ? Color("GrowthGreen") : Color("ErrorColor")
    }
    
    private var trendIcon: String {
        isPositive ? "arrow.up.right" : "arrow.down.right"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(AppTheme.Typography.captionFont())
            
            Text(String(format: "%.0f%%", abs(trend)))
                .font(AppTheme.Typography.captionFont())
                .fontWeight(.medium)
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trendColor.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Sample data
        let sampleData = (0..<30).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: 10...60)
            )
        }.reversed()
        
        TrendChartView(
            data: Array(sampleData),
            title: "Session Duration Trend"
        )
        .padding()
        
        TrendChartView(
            data: [],
            title: "Empty Chart",
            color: .blue
        )
        .padding()
    }
    .background(Color("GrowthBackgroundLight"))
}
