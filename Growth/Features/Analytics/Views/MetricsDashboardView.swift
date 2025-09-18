/**
 * MetricsDashboardView.swift
 * Growth App Real-time Analytics Dashboard
 *
 * Comprehensive SwiftUI dashboard for paywall conversion metrics,
 * revenue analytics, A/B testing results, and cohort analysis.
 */

import SwiftUI
import Charts

// Import TrendDirection from AI Models
import Foundation

/// Real-time metrics dashboard view
public struct MetricsDashboardView: View {
    
    @StateObject private var viewModel = MetricsDashboardViewModel()
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @State private var showingExportSheet = false
    @State private var selectedExportFormat: ExportFormat = .csv
    
    public init() {}
    
    public var body: some View {
        if entitlementManager.hasPremium {
            premiumAnalyticsView
        } else {
            basicAnalyticsView
        }
    }
    
    // MARK: - Premium Analytics View
    
    private var premiumAnalyticsView: some View {
        NavigationView {
            ZStack {
                if let error = viewModel.errorState {
                    errorStateView(error)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Header with time range selector and network status
                            headerSection
                            
                            // Network status indicator
                            if viewModel.networkStatus != .connected {
                                networkStatusBanner
                            }
                            
                            // Loading indicator
                            if viewModel.isLoading {
                                loadingSection
                            } else {
                                // Key metrics cards
                                keyMetricsSection
                                
                                // Conversion funnel chart
                                conversionFunnelSection
                                
                                // Revenue analytics
                                revenueAnalyticsSection
                                
                                // Active experiments
                                activeExperimentsSection
                                
                                // Cohort analysis
                                cohortAnalysisSection
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isRetrying {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(format.displayName) {
                                selectedExportFormat = format
                                exportReport()
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(viewModel.errorState != nil)
                }
            }
            .refreshable {
                viewModel.refreshAllMetrics()
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
    }
    
    // MARK: - Basic Analytics View (Free Tier)
    
    private var basicAnalyticsView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Basic Analytics")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Text("Get basic insights about your progress. Upgrade to Premium for detailed analytics and trends.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Basic metrics (limited)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        BasicMetricCard(
                            title: "Sessions Completed",
                            value: "12",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        BasicMetricCard(
                            title: "Current Streak",
                            value: "3 days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        BasicMetricCard(
                            title: "Total Time",
                            value: "2.5h",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        BasicMetricCard(
                            title: "This Week",
                            value: "5 sessions",
                            icon: "calendar.circle.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Upgrade prompt
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Unlock Advanced Analytics")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Get detailed insights, trends, export capabilities, and more with Premium.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach([
                                "Detailed progress tracking",
                                "Trend analysis & predictions",
                                "Export data (CSV, PDF)",
                                "Historical data retention",
                                "Goal tracking & milestones"
                            ], id: \.self) { benefit in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(benefit)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            // Track analytics interaction if needed
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("Upgrade to Premium")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Track view appearance if needed
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Real-time Metrics")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let lastUpdate = viewModel.lastUpdateTime {
                        Text("Updated \(lastUpdate, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Network status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(viewModel.networkStatus.color))
                            .frame(width: 8, height: 8)
                        Text(viewModel.networkStatus.displayText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Time range picker
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Conversion Rate",
                value: viewModel.conversionMetrics.overallConversionRate,
                formatter: .percent,
                trend: .increasing,
                color: .green
            )
            
            MetricCard(
                title: "Total Revenue",
                value: viewModel.revenueMetrics.totalRevenue,
                formatter: .currency,
                trend: .increasing,
                color: .blue
            )
            
            MetricCard(
                title: "Total Impressions",
                value: Double(viewModel.conversionMetrics.totalImpressions),
                formatter: .number,
                trend: .increasing,
                color: .orange
            )
            
            MetricCard(
                title: "Revenue per Visitor",
                value: viewModel.revenueMetrics.revenuePerVisitor,
                formatter: .currency,
                trend: .increasing,
                color: .purple
            )
        }
    }
    
    // MARK: - Conversion Funnel Section
    
    private var conversionFunnelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conversion Funnel")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(Array(viewModel.conversionMetrics.funnelBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                    BarMark(
                        x: .value("Count", item.value),
                        y: .value("Step", getFunnelStepDisplayName(item.key))
                    )
                    .foregroundStyle(funnelColor(for: item.key))
                }
            }
            .frame(height: 200)
            
            // Funnel conversion rates
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(viewModel.conversionMetrics.funnelBreakdown.sorted(by: { $0.key < $1.key })), id: \.key) { step, count in
                    HStack {
                        Text(step)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        // Conversion rate calculation removed since step is a String, not FunnelStep enum
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Revenue Analytics Section
    
    private var revenueByFeatureChart: some View {
        Chart {
            ForEach(Array(viewModel.revenueMetrics.revenueByFeature.prefix(5)), id: \.featureName) { featureRevenue in
                BarMark(
                    x: .value("Revenue", featureRevenue.revenue),
                    y: .value("Feature", featureRevenue.featureName)
                )
                .foregroundStyle(.blue.gradient)
            }
        }
        .frame(height: 150)
    }
    
    private var revenueAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Revenue by Feature")
                .font(.headline)
                .fontWeight(.semibold)
            
            revenueByFeatureChart
            
            // Top performing sources
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Revenue Sources")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(viewModel.conversionMetrics.conversionRatesBySource.sorted(by: { $0.value > $1.value }).prefix(3)), id: \.key) { source, rate in
                    HStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        
                        Text(source.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(rate, format: .percent.precision(.fractionLength(1)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Active Experiments Section
    
    private var activeExperimentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Experiments")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.activeExperiments.count) running")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.activeExperiments.isEmpty {
                Text("No active experiments")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.activeExperiments, id: \.id) { experiment in
                    ExperimentRow(experiment: experiment)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Cohort Analysis Section
    
    private var cohortAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Cohort Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(Array(viewModel.cohortAnalysis.cohortPerformance), id: \.key) { item in
                    let cohort = item.key
                    let performance = item.value
                    BarMark(
                        x: .value("Conversion Rate", performance.conversionRate),
                        y: .value("Cohort", getCohortDisplayName(cohort))
                    )
                    .foregroundStyle(getCohortColor(cohort))
                }
            }
            .frame(height: 150)
            
            // Key insights
            if !viewModel.cohortAnalysis.keyInsights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Insights")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(viewModel.cohortAnalysis.keyInsights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(insight)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Error States
    
    private func errorStateView(_ error: AnalyticsError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Analytics Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if error.isRetryable {
                Button("Try Again") {
                    viewModel.retryFailedOperations()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRetrying)
            }
            
            Button("Dismiss") {
                viewModel.clearError()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var networkStatusBanner: some View {
        HStack {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.orange)
            
            Text(viewModel.networkStatus.displayText)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if viewModel.networkStatus == .disconnected {
                Button("Retry") {
                    viewModel.retryFailedOperations()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading analytics data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Export Sheet
    
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.headline)
                
                Picker("Format", selection: $selectedExportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                
                Button("Export Report") {
                    exportReport()
                    showingExportSheet = false
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func exportReport() {
        if let url = viewModel.exportMetricsReport(format: selectedExportFormat) {
            // Present share sheet with exported file
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    private func funnelColor(for step: Any) -> Color {
        // FunnelStep type not accessible, using generic color
        return .blue
    }
    
    private func getCohortDisplayName(_ cohort: Any) -> String {
        // Since UserCohort is not accessible, use string representation
        let cohortString = String(describing: cohort)
        switch cohortString {
        case "newUser", "new_user": return "New User"
        case "returningFreeUser", "returning_free_user": return "Returning Free User"
        case "trialUser", "trial_user": return "Trial User"
        case "expiredSubscriber", "expired_subscriber": return "Expired Subscriber"
        case "activePowerUser", "active_power_user": return "Active Power User"
        case "cancelledSubscriber", "cancelled_subscriber": return "Cancelled Subscriber"
        case "reactivatedUser", "reactivated_user": return "Reactivated User"
        default: return cohortString.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func getCohortColor(_ cohort: Any) -> Color {
        let cohortString = String(describing: cohort)
        switch cohortString {
        case "newUser", "new_user": return .blue
        case "returningFreeUser", "returning_free_user": return .green
        case "trialUser", "trial_user": return .orange
        case "expiredSubscriber", "expired_subscriber": return .red
        case "activePowerUser", "active_power_user": return .purple
        case "cancelledSubscriber", "cancelled_subscriber": return .gray
        case "reactivatedUser", "reactivated_user": return .mint
        default: return .blue
        }
    }
    
    private func getFunnelStepDisplayName(_ step: Any) -> String {
        // Since FunnelStep is not accessible, use string representation
        let stepString = String(describing: step)
        switch stepString {
        case "viewPaywall": return "View Paywall"
        case "startTrial": return "Start Trial"
        case "completePurchase": return "Complete Purchase"
        case "retainSubscription": return "Retain Subscription"
        default: return stepString.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    // Function removed as it's no longer used after simplifying funnel display
    // private func getPreviousFunnelStepCount(_ step: Any) -> Int {
    //     // Simplified implementation - would need proper funnel step ordering
    //     return viewModel.conversionMetrics.funnelBreakdown.values.max() ?? 0
    // }
}

// MARK: - Supporting Views

/// Metric card component for key metrics display
private struct MetricCard: View {
    let title: String
    let value: Double
    let formatter: MetricFormatter
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.iconName)
                    .foregroundColor(trend.swiftUIColor)
                    .font(.caption)
            }
            
            Text(formattedValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var formattedValue: String {
        switch formatter {
        case .currency:
            return value.formatted(.currency(code: "USD"))
        case .percent:
            return value.formatted(.percent.precision(.fractionLength(1)))
        case .number:
            return value.formatted(.number.precision(.fractionLength(0)))
        }
    }
}

/// Experiment row component
private struct ExperimentRow: View {
    let experiment: ExperimentSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(experiment.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                StatusBadge(status: experiment.status)
            }
            
            HStack {
                Text("Sample: \(experiment.sampleSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if experiment.hasSignificantResults {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        if let winner = experiment.winningVariant {
                            Text("Winner: \(winner)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            if experiment.conversionLift != 0 {
                Text("Lift: \(experiment.conversionLift, format: .percent.precision(.fractionLength(1)))")
                    .font(.caption)
                    .foregroundColor(experiment.conversionLift > 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator))
                .opacity(0.5),
            alignment: .bottom
        )
    }
}

/// Status badge for experiments
private struct StatusBadge: View {
    let status: ExperimentStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .created: return .gray
        case .running: return .green
        case .stopped: return .orange
        case .paused: return .yellow
        case .completed: return .blue
        }
    }
    
    private var textColor: Color {
        return .white
    }
}

// MARK: - Basic Metric Card

/// Simple metric card for free tier analytics
private struct BasicMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Supporting Enums

private enum MetricFormatter {
    case currency, percent, number
}

// MARK: - TrendDirection Extension for SwiftUI

extension TrendDirection {
    var swiftUIColor: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    MetricsDashboardView()
}