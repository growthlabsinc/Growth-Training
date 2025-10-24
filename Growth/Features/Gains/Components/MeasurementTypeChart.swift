//
//  MeasurementTypeChart.swift
//  Growth
//
//  Created by Developer on 10/23/25.
//
//  Chart component that displays progress for specific measurement types

import SwiftUI
import Charts
import FirebaseAuth

struct MeasurementTypeChart: View {
    @StateObject private var gainsService = GainsService.shared
    @State private var selectedType: MeasurementType
    @State private var selectedTimeRange: ChartTimeRange = .month
    @State private var showComparison = false
    @State private var comparisonType: MeasurementType? = nil

    let measurementCategory: MeasurementCategory

    init(measurementCategory: MeasurementCategory) {
        self.measurementCategory = measurementCategory
        // Initialize selectedType with the appropriate default for the category
        _selectedType = State(initialValue: measurementCategory.defaultType)
    }

    enum MeasurementCategory {
        case length
        case girth
        case all

        var availableTypes: [MeasurementType] {
            switch self {
            case .length:
                return MeasurementType.lengthMeasurements
            case .girth:
                return MeasurementType.girthMeasurements
            case .all:
                return MeasurementType.allCases
            }
        }

        var defaultType: MeasurementType {
            switch self {
            case .length:
                return .bpel
            case .girth:
                return .mseg
            case .all:
                return .bpel
            }
        }

        var title: String {
            switch self {
            case .length:
                return "Length Progress"
            case .girth:
                return "Girth Progress"
            case .all:
                return "All Measurements"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header with measurement selector
            headerView

            // Chart
            if hasDataForSelectedType {
                chartView
            } else {
                emptyStateView
            }

            // Statistics for selected measurement
            if hasDataForSelectedType {
                statisticsView
            }
        }
        .onAppear {
            updateComparisonType()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(measurementCategory.title)
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))

                Spacer()

                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(Color("GrowthGreen"))
            }

            // Measurement type selector
            HStack {
                Text("Measurement:")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))

                Picker("Type", selection: $selectedType) {
                    ForEach(measurementCategory.availableTypes, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(Color("GrowthGreen"))

                Spacer()

                // Comparison toggle
                Toggle("Compare", isOn: $showComparison)
                    .toggleStyle(SwitchToggleStyle(tint: Color("BrightTeal")))
                    .labelsHidden()
                    .onChange(of: showComparison) { newValue in
                        print("🔄 [Toggle] showComparison changed to: \(newValue)")
                        print("   comparisonType is: \(comparisonType?.displayName ?? "nil")")
                    }

                if showComparison {
                    Picker("Compare with", selection: $comparisonType) {
                        Text("None").tag(nil as MeasurementType?)
                        ForEach(getComparisonTypes(), id: \.self) { type in
                            Text(type.displayName).tag(type as MeasurementType?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(Color("BrightTeal"))
                    .onChange(of: comparisonType) { newValue in
                        print("🔄 [Picker] comparisonType changed to: \(newValue?.displayName ?? "nil")")
                        print("   showComparison is: \(showComparison)")
                    }
                }
            }
        }
    }

    // MARK: - Chart View

    private var chartView: some View {
        let primaryData = chartData(for: selectedType)
        let _ = print("📊 [Chart] Primary data for \(selectedType.displayName): \(primaryData.count) points")
        let _ = primaryData.forEach { print("  📍 \(selectedType.displayName): \($0.date) = \($0.value)") }

        let comparisonData: [ChartDataPoint]
        if let compType = comparisonType {
            comparisonData = chartData(for: compType)
            print("📊 [Chart] Comparison data for \(compType.displayName): \(comparisonData.count) points")
            comparisonData.forEach { print("  📍 \(compType.displayName): \($0.date) = \($0.value)") }
        } else {
            comparisonData = []
        }

        print("🎛️ [Chart] showComparison: \(showComparison), comparisonType: \(comparisonType?.displayName ?? "nil")")

        return Chart {
            // Primary measurement data
            ForEach(primaryData, id: \.date) { dataPoint in
                let _ = print("🟢 [Rendering] Primary LineMark: \(dataPoint.date) = \(dataPoint.value)")
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value),
                    series: .value("Measurement", selectedType.displayName)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color("GrowthGreen"), Color("MintGreen")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Only show point for the most recent data point
                if dataPoint.date == primaryData.last?.date {
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(Color("GrowthGreen"))
                    .symbolSize(150)
                    .symbol {
                        Circle()
                            .fill(Color("GrowthGreen"))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: Color("GrowthGreen").opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
            }

            // Comparison data if enabled
            if showComparison, let compType = comparisonType {
                let _ = print("🔵 [Rendering] Comparison block ACTIVE for \(compType.displayName)")
                ForEach(comparisonData, id: \.date) { dataPoint in
                    let _ = print("🔵 [Rendering] Comparison LineMark: \(dataPoint.date) = \(dataPoint.value)")
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value),
                        series: .value("Measurement", compType.displayName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 4]))
                    .interpolationMethod(.catmullRom)

                    // Only show point for the most recent data point
                    if dataPoint.date == comparisonData.last?.date {
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(120)
                        .symbol {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2.5)
                                )
                                .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            } else {
                let _ = print("⚪ [Rendering] Comparison block INACTIVE")
            }
        }
        .frame(height: 250)
        .chartYScale(domain: yAxisDomain)
        .chartYAxisLabel(getYAxisLabel(), position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: getStrideCount())) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatAxisValue(doubleValue))
                    }
                }
            }
        }
        .chartLegend(position: .top) {
            if showComparison && comparisonType != nil {
                HStack(spacing: 16) {
                    legendItem(type: selectedType, color: Color("GrowthGreen"))
                    if let compType = comparisonType {
                        legendItem(type: compType, color: Color("BrightTeal"))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color("NeutralGray"))

            Text("No data for \(selectedType.fullName)")
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(Color("TextColor"))

            Text("Start tracking this measurement to see progress")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(Color("NeutralGray").opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Statistics View

    private var statisticsView: some View {
        HStack(spacing: 16) {
            MeasurementStatCard(
                title: "Current",
                value: formatValue(currentValue(for: selectedType)),
                color: Color("GrowthGreen")
            )

            MeasurementStatCard(
                title: "Baseline",
                value: formatValue(baselineValue(for: selectedType)),
                color: Color("NeutralGray")
            )

            MeasurementStatCard(
                title: "Gain",
                value: formatGain(gainValue(for: selectedType)),
                color: Color("BrightTeal")
            )

            MeasurementStatCard(
                title: "% Gain",
                value: formatPercentage(percentageGain(for: selectedType)),
                color: Color("MintGreen")
            )
        }
    }

    // MARK: - Helper Properties

    private var hasDataForSelectedType: Bool {
        !chartData(for: selectedType).isEmpty
    }

    private var filteredEntries: [GainsEntry] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.daySpan,
            to: Date()
        ) ?? Date()

        return gainsService.entries.filter { $0.timestamp >= cutoffDate }
    }

    private var yAxisDomain: ClosedRange<Double> {
        let primaryData = chartData(for: selectedType)
        var allValues = primaryData.map { $0.value }

        // Include comparison data if enabled
        if showComparison, let compType = comparisonType {
            let compData = chartData(for: compType)
            allValues.append(contentsOf: compData.map { $0.value })
        }

        guard !allValues.isEmpty else {
            return 0...10
        }

        let minValue = allValues.min() ?? 0
        let maxValue = allValues.max() ?? 10
        let range = maxValue - minValue

        // Add 30% padding above and below to center the line
        let padding = range * 0.3
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding

        return lowerBound...upperBound
    }

    // MARK: - Helper Methods

    private func chartData(for type: MeasurementType) -> [ChartDataPoint] {
        print("📥 [chartData] Fetching data for \(type.displayName)")
        print("   Total entries: \(gainsService.entries.count)")
        print("   Filtered entries: \(filteredEntries.count)")

        let dataPoints: [ChartDataPoint] = filteredEntries
            .compactMap { entry -> ChartDataPoint? in
                let value = entry.displayMeasurement(type, in: gainsService.preferredUnit)
                if value == nil {
                    print("   ⚠️ Entry at \(entry.timestamp) has no \(type.displayName) measurement")
                } else {
                    print("   ✅ Entry at \(entry.timestamp) has \(type.displayName) = \(value!)")
                }
                guard let value = value else {
                    return nil
                }
                return ChartDataPoint(date: entry.timestamp, value: value)
            }

        let sortedData = dataPoints.sorted { $0.date < $1.date }

        print("📊 [chartData] Returning \(sortedData.count) data points for \(type.displayName)")
        return sortedData
    }

    private func getComparisonTypes() -> [MeasurementType] {
        let types = measurementCategory.availableTypes.filter { $0 != selectedType }
        print("🔍 [getComparisonTypes] Available comparison types: \(types.map { $0.displayName })")
        return types
    }

    private func updateComparisonType() {
        print("🔧 [updateComparisonType] Called with selectedType = \(selectedType.displayName)")
        // Auto-select comparison type based on selected type
        if selectedType == .bpel {
            comparisonType = .nbpel
            print("   Setting comparisonType to NBPEL")
        } else if selectedType == .mseg {
            comparisonType = .beg
            print("   Setting comparisonType to BEG")
        } else {
            comparisonType = nil
            print("   Setting comparisonType to nil")
        }
        print("   Final comparisonType: \(comparisonType?.displayName ?? "nil")")
    }

    private func getYAxisLabel() -> String {
        let unit = gainsService.preferredUnit == .imperial ? "inches" : "cm"
        return "\(selectedType.displayName) (\(unit))"
    }

    private func getStrideCount() -> Int {
        switch selectedTimeRange {
        case .week:
            return 1
        case .month:
            return 5
        case .threeMonths:
            return 10
        case .sixMonths:
            return 15
        case .year:
            return 30
        case .all:
            return 30
        }
    }

    private func formatAxisValue(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func formatValue(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        let unit = gainsService.preferredUnit == .imperial ? "\"" : "cm"
        return String(format: "%.2f%@", value, unit)
    }

    private func formatGain(_ gain: Double?) -> String {
        guard let gain = gain else { return "--" }
        let unit = gainsService.preferredUnit == .imperial ? "\"" : "cm"
        return String(format: "%+.2f%@", gain, unit)
    }

    private func formatPercentage(_ percentage: Double?) -> String {
        guard let percentage = percentage else { return "--" }
        return String(format: "%+.1f%%", percentage)
    }

    private func currentValue(for type: MeasurementType) -> Double? {
        gainsService.entries.first?.displayMeasurement(type, in: gainsService.preferredUnit)
    }

    private func baselineValue(for type: MeasurementType) -> Double? {
        gainsService.entries.last?.displayMeasurement(type, in: gainsService.preferredUnit)
    }

    private func gainValue(for type: MeasurementType) -> Double? {
        guard let current = currentValue(for: type),
              let baseline = baselineValue(for: type) else { return nil }
        return current - baseline
    }

    private func percentageGain(for type: MeasurementType) -> Double? {
        guard let gain = gainValue(for: type),
              let baseline = baselineValue(for: type),
              baseline > 0 else { return nil }
        return (gain / baseline) * 100
    }

    private func legendItem(type: MeasurementType, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(type.displayName)
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextColor"))
        }
    }
}

// MARK: - Supporting Views

struct MeasurementStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.gravityBook(10))
                .foregroundColor(Color("TextSecondaryColor"))

            Text(value)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// Time range enum for measurement charts
enum ChartTimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var daySpan: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return 10000
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            MeasurementTypeChart(measurementCategory: .length)
                .padding()

            MeasurementTypeChart(measurementCategory: .girth)
                .padding()
        }
    }
    .background(Color(.systemGroupedBackground))
}