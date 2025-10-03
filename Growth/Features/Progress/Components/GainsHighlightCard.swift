//
//  GainsHighlightCard.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import FirebaseAuth

/// Gains highlight card for the progress overview - shows impactful gains statistics
struct GainsHighlightCard: View {
    @StateObject private var gainsService = GainsService.shared
    
    /// Action to perform when user taps to view detailed gains
    let onViewGains: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                // Header
                headerSection
                
                // Gains content
                if gainsService.isLoading {
                    loadingView
                } else if gainsService.entries.isEmpty {
                    emptyStateView
                } else {
                    gainsContent
                }
                
                // View all gains button
                viewAllButton
            }
        }
        .onAppear {
            if let userId = Auth.auth().currentUser?.uid {
                gainsService.startListening(userId: userId)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Growth Progress")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text("Your measurable gains")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            // Growth icon with animation
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color("GrowthGreen"))
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .frame(height: 120)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("GrowthNeutralGray"))
            
            Text("Start tracking to see your gains!")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Layout.spacingL)
    }
    
    // MARK: - Gains Content
    
    private var gainsContent: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            // Primary gains display
            if let stats = gainsService.statistics {
                primaryGainsRow(stats: stats)
                
                // Secondary metrics
                secondaryMetricsRow(stats: stats)
                
                // Progress indicator
                if let percentageGain = calculateOverallPercentageGain(stats: stats) {
                    progressIndicator(percentage: percentageGain)
                }
            }
        }
    }
    
    // MARK: - Primary Gains Row
    
    private func primaryGainsRow(stats: GainsStatistics) -> some View {
        HStack(spacing: AppTheme.Layout.spacingM) {
            // Length gain
            GainMetricView(
                title: "Length",
                value: formatGain(stats.lengthGain, isLength: true),
                percentage: stats.lengthGainPercentage,
                icon: "ruler",
                color: Color("GrowthGreen")
            )
            
            Divider()
                .frame(height: 50)
            
            // Girth gain
            GainMetricView(
                title: "Girth", 
                value: formatGain(stats.girthGain, isLength: false),
                percentage: stats.girthGainPercentage,
                icon: "circle",
                color: Color("BrightTeal")
            )
            
            Divider()
                .frame(height: 50)
            
            // Volume gain
            GainMetricView(
                title: "Volume",
                value: formatVolumeGain(stats.volumeGain),
                percentage: stats.volumeGainPercentage,
                icon: "cube",
                color: Color("MintGreen")
            )
        }
        .padding(.vertical, AppTheme.Layout.spacingS)
    }
    
    // MARK: - Secondary Metrics Row
    
    private func secondaryMetricsRow(stats: GainsStatistics) -> some View {
        HStack {
            // Days tracking
            if let baseline = stats.baseline {
                let days = Calendar.current.dateComponents([.day], from: baseline.timestamp, to: Date()).day ?? 0
                SecondaryMetricView(
                    label: "Days Tracking",
                    value: "\(days)",
                    icon: "calendar"
                )
            }
            
            Spacer()
            
            // Total measurements
            SecondaryMetricView(
                label: "Measurements",
                value: "\(gainsService.entries.count)",
                icon: "number"
            )
            
            Spacer()
            
            // EQ improvement
            if let eqGain = stats.erectionQualityGain, eqGain > 0 {
                SecondaryMetricView(
                    label: "EQ Gain",
                    value: "+\(eqGain)",
                    icon: "arrow.up.circle"
                )
            }
        }
        .padding(.horizontal, AppTheme.Layout.spacingS)
    }
    
    // MARK: - Progress Indicator
    
    private func progressIndicator(percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Overall Progress")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                
                Spacer()
                
                Text("+\(Int(percentage))%")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            // Ensure value is clamped between 0 and 1 to avoid warnings
            let progressValue = max(0, min(percentage / 20, 1.0))
            ProgressView(value: progressValue) // Scale to show 20% as full
                .progressViewStyle(LinearProgressViewStyle(tint: Color("GrowthGreen")))
                .frame(height: 6)
                .background(Color("GrowthNeutralGray").opacity(0.2))
                .cornerRadius(3)
        }
        .padding(.top, AppTheme.Layout.spacingS)
    }
    
    // MARK: - View All Button
    
    private var viewAllButton: some View {
        Button(action: onViewGains) {
            HStack {
                Text("View Detailed Gains")
                    .font(AppTheme.Typography.gravitySemibold(14))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(AppTheme.Typography.captionFont())
            }
            .foregroundColor(Color("GrowthGreen"))
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatGain(_ gain: Double?, isLength: Bool) -> String {
        guard let gain = gain else { return "+0.0" }
        let displayGain = gainsService.preferredUnit == .metric ? gain * 2.54 : gain
        let unit = gainsService.preferredUnit == .metric ? "cm" : "″"
        return String(format: "%+.1f%@", displayGain, unit)
    }
    
    private func formatVolumeGain(_ gain: Double?) -> String {
        guard let gain = gain else { return "+0" }
        let displayGain = gainsService.preferredUnit == .metric ? gain * 16.387 : gain
        let unit = gainsService.preferredUnit == .metric ? "cc" : "in³"
        return String(format: "%+.0f%@", displayGain, unit)
    }
    
    private func calculateOverallPercentageGain(stats: GainsStatistics) -> Double? {
        let gains = [stats.lengthGainPercentage, stats.girthGainPercentage, stats.volumeGainPercentage].compactMap { $0 }
        guard !gains.isEmpty else { return nil }
        return gains.reduce(0, +) / Double(gains.count)
    }
}

// MARK: - Supporting Views

private struct GainMetricView: View {
    let title: String
    let value: String
    let percentage: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.Typography.gravityBook(11))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(Color("TextColor"))
            
            if let percentage = percentage {
                Text("+\(Int(percentage))%")
                    .font(AppTheme.Typography.gravityBook(10))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SecondaryMetricView: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.captionFont())
                Text(label)
                    .font(AppTheme.Typography.gravityBook(10))
            }
            .foregroundColor(Color("TextSecondaryColor"))
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
        }
    }
}

// MARK: - Preview

#Preview {
    GainsHighlightCard(
        onViewGains: { print("View gains") } // Release OK - Preview
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}