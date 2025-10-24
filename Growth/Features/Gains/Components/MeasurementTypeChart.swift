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
    @State private var selectedType: MeasurementType = .bpel
    @State private var selectedTimeRange: ChartTimeRange = .month
    @State private var showComparison = false
    @State private var comparisonType: MeasurementType? = nil

    let measurementCategory: MeasurementCategory

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
            selectedType = measurementCategory.defaultType
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
        Chart {
            // Primary measurement data
            ForEach(chartData(for: selectedType), id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(selectedType.displayName, dataPoint.value)
                )
                .foregroundStyle(Color("GrowthGreen"))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(selectedType.displayName, dataPoint.value)
                )
                .foregroundStyle(Color("GrowthGreen"))
                .symbolSize(100)
            }

            // Comparison data if enabled
            if showComparison, let compType = comparisonType {
                ForEach(chartData(for: compType), id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(compType.displayName, dataPoint.value)
                    )
                    .foregroundStyle(Color("BrightTeal"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))

                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(compType.displayName, dataPoint.value)
                    )
                    .foregroundStyle(Color("BrightTeal"))
                    .symbolSize(80)
                    .symbol(.diamond)
                }
            }
        }
        .frame(height: 250)
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

    // MARK: - Helper Methods

    private func chartData(for type: MeasurementType) -> [ChartDataPoint] {
        filteredEntries
            .compactMap { entry in
                guard let value = entry.displayMeasurement(type, in: gainsService.preferredUnit) else {
                    return nil
                }
                return ChartDataPoint(date: entry.timestamp, value: value)
            }
            .sorted { $0.date < $1.date }
    }

    private func getComparisonTypes() -> [MeasurementType] {
        measurementCategory.availableTypes.filter { $0 != selectedType }
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