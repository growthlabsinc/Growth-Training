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

                if showComparison {
                    Picker("Compare with", selection: $comparisonType) {
                        Text("None").tag(nil as MeasurementType?)
                        ForEach(getComparisonTypes(), id: \.self) { type in
                            Text(type.displayName).tag(type as MeasurementType?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(Color("BrightTeal"))
                }
            }
        }
    }

    // MARK: - Chart View

    private var chartView: some View {
        let primaryData = chartData(for: selectedType)

        let comparisonData: [ChartDataPoint]
        if let compType = comparisonType {
            comparisonData = chartData(for: compType)
        } else {
            comparisonData = []
        }

        return Chart {
            // Primary measurement data
            ForEach(primaryData, id: \.date) { dataPoint in
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
                ForEach(comparisonData, id: \.date) { dataPoint in
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
        let dataPoints: [ChartDataPoint] = filteredEntries
            .compactMap { entry -> ChartDataPoint? in
                guard let value = entry.displayMeasurement(type, in: gainsService.preferredUnit) else {
                    return nil
                }
                return ChartDataPoint(date: entry.timestamp, value: value)
            }

        return dataPoints.sorted { $0.date < $1.date }
    }

    private func getComparisonTypes() -> [MeasurementType] {
        return measurementCategory.availableTypes.filter { $0 != selectedType }
    }

    private func updateComparisonType() {
        // Auto-select comparison type based on selected type
        if selectedType == .bpel {
            comparisonType = .nbpel
        } else if selectedType == .mseg {
            comparisonType = .beg
        } else {
            comparisonType = nil
        }
    }

    private func getYAxisLabel() -> String {
        let unit = gainsService.preferredUnit.displayName.lowercased()
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
        let decimalPlaces = MeasurementFormatter.decimalPlaces(for: gainsService.preferredUnit)
        let format = "%.\(decimalPlaces)f%@"
        return String(format: format, value, gainsService.preferredUnit.lengthSymbol)
    }

    private func formatGain(_ gain: Double?) -> String {
        guard let gain = gain else { return "--" }
        let decimalPlaces = MeasurementFormatter.decimalPlaces(for: gainsService.preferredUnit)
        let format = "%+.\(decimalPlaces)f%@"
        return String(format: format, gain, gainsService.preferredUnit.lengthSymbol)
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