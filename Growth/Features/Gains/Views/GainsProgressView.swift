//
//  GainsProgressView.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import SwiftUI
import FirebaseAuth
import Charts

struct GainsProgressView: View {
    @StateObject private var gainsService = GainsService.shared
    @State private var selectedTimeRange: TimeRange = .month
    @State private var entryToDelete: GainsEntry?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header without add button
                headerView
                
                // Gains input card for adding measurements
                EnhancedGainsInputCard()
                
                if gainsService.isLoading {
                    ProgressView("Loading measurements...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if gainsService.entries.isEmpty {
                    emptyStateView
                } else {
                    // Current stats cards
                    currentStatsView
                    
                    // Progress charts
                    progressChartsView
                    
                    // Gains summary
                    gainsSummaryView
                    
                    // Recent entries
                    recentEntriesView
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if let userId = Auth.auth().currentUser?.uid {
                gainsService.startListening(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reload data when app comes to foreground
            if let userId = Auth.auth().currentUser?.uid {
                gainsService.startListening(userId: userId)
            }
        }
        .alert("Delete Measurement", isPresented: $showDeleteConfirmation, presenting: entryToDelete) { entry in
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                performDelete(entry)
            }
        } message: { entry in
            Text("Are you sure you want to delete this measurement from \(entry.timestamp.formatted(date: .abbreviated, time: .omitted))?")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Growth Tracking")
                .font(AppTheme.Typography.gravitySemibold(24))
                .foregroundColor(Color("TextColor"))
            
            Text("Monitor your progress over time")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(Color("GrowthGreen"))
            
            VStack(spacing: 8) {
                Text("Start Tracking Your Progress")
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .foregroundColor(Color("TextColor"))
                
                Text("Use the card above to record your first measurement and begin monitoring your growth journey")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                Text("Tap the card above to get started")
                    .font(AppTheme.Typography.gravitySemibold(14))
            }
            .foregroundColor(Color("GrowthGreen"))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Current Stats View
    
    private var currentStatsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                GainsStatCard(
                    title: "Length",
                    value: formatMeasurement(gainsService.statistics?.latest?.displayLength(in: gainsService.preferredUnit) ?? 0, isLength: true),
                    gain: formatGain(gainsService.statistics?.lengthGain, isLength: true),
                    gainPercentage: gainsService.statistics?.lengthGainPercentage,
                    icon: "ruler",
                    color: Color("GrowthGreen")
                )
                
                GainsStatCard(
                    title: "Girth",
                    value: formatMeasurement(gainsService.statistics?.latest?.displayGirth(in: gainsService.preferredUnit) ?? 0, isLength: false),
                    gain: formatGain(gainsService.statistics?.girthGain, isLength: false),
                    gainPercentage: gainsService.statistics?.girthGainPercentage,
                    icon: "circle",
                    color: Color("BrightTeal")
                )
            }
            
            HStack(spacing: 16) {
                GainsStatCard(
                    title: "Volume",
                    value: formatVolume(gainsService.statistics?.latest?.volume ?? 0),
                    gain: formatVolumeGain(gainsService.statistics?.volumeGain),
                    gainPercentage: gainsService.statistics?.volumeGainPercentage,
                    icon: "cube",
                    color: Color("MintGreen")
                )
                
                GainsStatCard(
                    title: "EQ Score",
                    value: "\(gainsService.statistics?.latest?.erectionQuality ?? 0)/10",
                    gain: gainsService.statistics?.erectionQualityGain.map { "+\($0)" },
                    gainPercentage: nil,
                    icon: "chart.line.uptrend.xyaxis",
                    color: colorForEQ(gainsService.statistics?.latest?.erectionQuality ?? 7)
                )
            }
        }
    }
    
    // MARK: - Progress Charts View
    
    private var progressChartsView: some View {
        VStack(spacing: 24) {
            // New measurement type charts for specific tracking

            // Length measurements chart (BPEL, NBPEL, etc.)
            CardView {
                MeasurementTypeChart(measurementCategory: .length)
            }

            // Girth measurements chart (MSEG, BEG, etc.)
            CardView {
                MeasurementTypeChart(measurementCategory: .girth)
            }

            // Original Volume Chart (calculated metric)
            CardView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Volume Progress")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(Color("TextColor"))

                        Spacer()

                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(Color("MintGreen"))
                    }

                    if volumeChartData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(Color("TextSecondaryColor").opacity(0.3))
                            Text("No volume data yet")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    } else {
                        Chart {
                            ForEach(volumeChartData, id: \.date) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Volume", dataPoint.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.yellow, Color("MintGreen"), Color("GrowthGreen")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.catmullRom)

                                // Only show point for the most recent data point
                                if dataPoint.date == volumeChartData.last?.date {
                                    PointMark(
                                        x: .value("Date", dataPoint.date),
                                        y: .value("Volume", dataPoint.value)
                                    )
                                    .foregroundStyle(Color("MintGreen"))
                                    .symbolSize(150)
                                    .symbol {
                                        Circle()
                                            .fill(Color("MintGreen"))
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 3)
                                            )
                                            .shadow(color: Color("MintGreen").opacity(0.5), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Gains Summary View
    
    private var gainsSummaryView: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Progress Summary")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))
                
                if let stats = gainsService.statistics {
                    VStack(spacing: 12) {
                        SummaryRow(
                            label: "Total Measurements",
                            value: "\(gainsService.entries.count)"
                        )
                        
                        if let days = daysSinceBaseline {
                            SummaryRow(
                                label: "Days Tracking",
                                value: "\(days) days"
                            )
                        }
                        
                        if let avgFrequency = measurementFrequency {
                            SummaryRow(
                                label: "Measurement Frequency",
                                value: avgFrequency
                            )
                        }
                        
                        if let bestVolume = stats.best?.volume {
                            SummaryRow(
                                label: "Best Volume",
                                value: formatVolume(bestVolume)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Entries View

    private var recentEntriesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Measurements")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))

            VStack(spacing: 12) {
                ForEach(gainsService.entries.prefix(5), id: \.timestamp) { entry in
                    RecentEntryRow(entry: entry, unit: gainsService.preferredUnit) {
                        deleteEntry(entry)
                    }
                }
            }
        }
    }

    // MARK: - Delete Entry

    private func deleteEntry(_ entry: GainsEntry) {
        Logger.debug("Delete button tapped for entry: \(entry.id ?? "no-id")")
        entryToDelete = entry
        showDeleteConfirmation = true
    }

    private func performDelete(_ entry: GainsEntry) {
        guard let entryId = entry.id else {
            Logger.error("Cannot delete entry: missing ID")
            deleteErrorMessage = "Cannot delete this measurement: missing identifier"
            showDeleteError = true
            return
        }

        Logger.debug("Performing delete for entry: \(entryId)")

        Task {
            do {
                try await gainsService.deleteEntry(entryId)
                Logger.debug("Successfully deleted entry: \(entryId)")
                // UI will update automatically via the listener
                await MainActor.run {
                    entryToDelete = nil
                }
            } catch {
                Logger.error("Failed to delete gains entry: \(error.localizedDescription)")
                await MainActor.run {
                    deleteErrorMessage = "Failed to delete measurement: \(error.localizedDescription)"
                    showDeleteError = true
                    entryToDelete = nil
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredEntries: [GainsEntry] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.daySpan,
            to: Date()
        ) ?? Date()
        
        return gainsService.entries.filter { $0.timestamp >= cutoffDate }
    }

    private var volumeChartData: [ChartDataPoint] {
        filteredEntries
            .sorted { $0.timestamp < $1.timestamp } // Sort chronologically
            .map { entry in
                ChartDataPoint(
                    date: entry.timestamp,
                    value: entry.displayVolume(in: gainsService.preferredUnit)
                )
            }
    }
    
    private var daysSinceBaseline: Int? {
        guard let baseline = gainsService.statistics?.baseline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: baseline.timestamp, to: Date()).day ?? 0
        return days
    }
    
    private var measurementFrequency: String? {
        guard let days = daysSinceBaseline, days > 0 else { return nil }
        let frequency = Double(gainsService.entries.count) / Double(days)
        
        if frequency >= 0.7 {
            return "Daily"
        } else if frequency >= 0.3 {
            return "Every \(Int(1/frequency)) days"
        } else {
            return "Weekly"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatMeasurement(_ value: Double, isLength: Bool) -> String {
        // Value is already converted by displayLength/displayGirth methods
        return String(format: "%.1f%@", value, gainsService.preferredUnit.lengthSymbol)
    }
    
    private func formatGain(_ gain: Double?, isLength: Bool) -> String? {
        guard let gain = gain, gain != 0 else { return nil }
        let displayGain = gainsService.preferredUnit == .metric ? gain * 2.54 : gain
        return String(format: "%+.1f", displayGain)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let displayVolume = gainsService.preferredUnit == .metric ? volume * 16.387 : volume
        return String(format: "%.0f%@", displayVolume, gainsService.preferredUnit.volumeSymbol)
    }
    
    private func formatVolumeGain(_ gain: Double?) -> String? {
        guard let gain = gain, gain != 0 else { return nil }
        let displayGain = gainsService.preferredUnit == .metric ? gain * 16.387 : gain
        return String(format: "%+.0f", displayGain)
    }
    
    private func colorForEQ(_ value: Int) -> Color {
        switch value {
        case 9...10: return Color("GrowthGreen")
        case 7...8: return Color("BrightTeal")
        case 5...6: return Color("ErrorColor")
        default: return Color.red
        }
    }
}

// MARK: - Supporting Views

struct GainsStatCard: View {
    let title: String
    let value: String
    let gain: String?
    let gainPercentage: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let percentage = gainPercentage, percentage > 0 {
                        Text("+\(Int(percentage))%")
                            .font(AppTheme.Typography.gravityBook(11))
                            .foregroundColor(Color("GrowthGreen"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("GrowthGreen").opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                Text(title)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppTheme.Typography.gravitySemibold(20))
                        .foregroundColor(Color("TextColor"))
                    
                    if let gain = gain {
                        Text(gain)
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
            }
        }
    }
}


struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
        }
    }
}

struct RecentEntryRow: View {
    let entry: GainsEntry
    let unit: MeasurementUnit
    let onDelete: () -> Void

    var body: some View {
        CardView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.timestamp, style: .date)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))

                    HStack(spacing: 12) {
                        Text("\(formatValue(entry.displayLength(in: unit))) × \(formatValue(entry.displayGirth(in: unit)))")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))

                        Text("EQ: \(entry.erectionQuality)")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Delete button
                    Button(action: {
                        Logger.debug("Delete button tapped for entry")
                        onDelete()
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.3))
                            .padding(6)
                            .background(Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Spacer()

                    Text("Volume")
                        .font(AppTheme.Typography.gravityBook(10))
                        .foregroundColor(Color("TextSecondaryColor"))

                    Text(formatVolume(entry.displayVolume(in: unit), unit: unit))
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("MintGreen"))
                }
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        String(format: "%.1f%@", value, unit.lengthSymbol)
    }
    
    private func formatVolume(_ value: Double, unit: MeasurementUnit) -> String {
        String(format: "%.0f%@", value, unit.volumeSymbol)
    }
}

#Preview {
    NavigationStack {
        GainsProgressView()
    }
}