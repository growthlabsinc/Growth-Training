//
//  EnhancedGainsInputCard.swift
//  Growth
//
//  Created by Developer on 10/23/25.
//
//  Enhanced gains input card supporting Reddit-standard PE measurement types

import SwiftUI
import FirebaseAuth

struct EnhancedGainsInputCard: View {
    @StateObject private var gainsService = GainsService.shared
    @State private var isExpanded = false
    @State private var showingSuccessAlert = false
    @State private var isSaving = false
    @State private var showAdvancedMeasurements = false

    // Selected measurement types to track
    @State private var selectedMeasurements: Set<MeasurementType> = Set(MeasurementType.primaryMeasurements)

    // Input values for each measurement type
    @State private var measurementValues: [MeasurementType: Double] = [:]
    @State private var erectionQuality: Int = 7
    @State private var notes: String = ""

    // Last entry for pre-filling
    @State private var lastEntry: GainsEntry?

    // Session context if applicable
    var sessionId: String? = nil
    var onSave: ((GainsEntry) -> Void)? = nil

    private let lengthRange: ClosedRange<Double> = 1...12
    private let girthRange: ClosedRange<Double> = 1...8

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerView

                if isExpanded {
                    Divider()

                    // Measurement mode toggle
                    measurementModeToggle

                    // Measurement selection
                    measurementSelectionView

                    Divider()

                    // Input fields for selected measurements
                    measurementInputFields

                    // Erection Quality input
                    erectionQualityView

                    // Notes field
                    notesFieldView

                    // Action buttons
                    actionButtonsView
                }
            }
        }
        .onAppear {
            loadLastEntry()
            initializeDefaultValues()
        }
        .alert("Measurements Saved!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your progress has been recorded successfully.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Track Measurements")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))

                if !isExpanded {
                    if let lastEntry = lastEntry {
                        // Show primary measurements from last entry
                        let bpel = lastEntry.displayMeasurement(.bpel, in: gainsService.preferredUnit) ?? 0
                        let mseg = lastEntry.displayMeasurement(.mseg, in: gainsService.preferredUnit) ?? 0
                        Text("Last: BPEL \(formatMeasurement(bpel)) × MSEG \(formatMeasurement(mseg))")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    } else {
                        Text("Tap to record your measurements")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("GrowthGreen"))
            }
        }
    }

    // MARK: - Measurement Mode Toggle

    private var measurementModeToggle: some View {
        HStack {
            Text("Measurement Mode")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))

            Spacer()

            Toggle("", isOn: $showAdvancedMeasurements)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color("GrowthGreen")))

            Text(showAdvancedMeasurements ? "Advanced" : "Basic")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .onChange(of: showAdvancedMeasurements) { newValue in
            updateSelectedMeasurements(advanced: newValue)
        }
    }

    // MARK: - Measurement Selection View

    private var measurementSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Measurements to Track")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))

            // Length measurements
            VStack(alignment: .leading, spacing: 8) {
                Text("Length Measurements")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))

                FlowLayout(spacing: 8) {
                    ForEach(availableLengthMeasurements, id: \.self) { type in
                        MeasurementChip(
                            type: type,
                            isSelected: selectedMeasurements.contains(type),
                            action: { toggleMeasurement(type) }
                        )
                    }
                }
            }

            // Girth measurements
            VStack(alignment: .leading, spacing: 8) {
                Text("Girth Measurements")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))

                FlowLayout(spacing: 8) {
                    ForEach(availableGirthMeasurements, id: \.self) { type in
                        MeasurementChip(
                            type: type,
                            isSelected: selectedMeasurements.contains(type),
                            action: { toggleMeasurement(type) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Measurement Input Fields

    private var measurementInputFields: some View {
        VStack(spacing: 20) {
            // Unit selector
            HStack {
                Text("Unit System")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))

                Spacer()

                Picker("Unit", selection: $gainsService.preferredUnit) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }

            // Input fields for selected measurements
            ForEach(Array(selectedMeasurements).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                MeasurementInputRow(
                    type: type,
                    value: binding(for: type),
                    unit: gainsService.preferredUnit,
                    range: type.isLength ? lengthRange : girthRange
                )
            }
        }
    }

    // MARK: - Erection Quality View

    private var erectionQualityView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Erection Quality", systemImage: "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))

                Spacer()

                Text("\(erectionQuality)/10")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(colorForEQ(erectionQuality))
            }

            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { value in
                    Button(action: {
                        erectionQuality = value
                    }) {
                        Circle()
                            .fill(erectionQuality >= value ? colorForEQ(value) : Color("NeutralGray").opacity(0.3))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("\(value)")
                                    .font(AppTheme.Typography.gravityBook(10))
                                    .foregroundColor(erectionQuality >= value ? .white : Color("TextSecondaryColor"))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Notes Field View

    private var notesFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes (Optional)", systemImage: "note.text")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))

            TextField("Add any observations...", text: $notes, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .font(AppTheme.Typography.gravityBook(14))
        }
    }

    // MARK: - Action Buttons View

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded = false
                }
            }) {
                Text("Cancel")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("NeutralGray").opacity(0.1))
                    .cornerRadius(12)
            }

            Button(action: saveMeasurement) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("Save")
                        .font(AppTheme.Typography.gravitySemibold(14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.buttonGradient)
                .cornerRadius(12)
            }
            .disabled(isSaving || selectedMeasurements.isEmpty)
        }
    }

    // MARK: - Helper Properties

    private var availableLengthMeasurements: [MeasurementType] {
        if showAdvancedMeasurements {
            return MeasurementType.lengthMeasurements
        } else {
            return [.bpel, .nbpel]
        }
    }

    private var availableGirthMeasurements: [MeasurementType] {
        if showAdvancedMeasurements {
            return MeasurementType.girthMeasurements
        } else {
            return [.mseg, .beg]
        }
    }

    // MARK: - Helper Methods

    private func initializeDefaultValues() {
        // Initialize with reasonable defaults for primary measurements
        if measurementValues[.bpel] == nil {
            measurementValues[.bpel] = 5.5
        }
        if measurementValues[.mseg] == nil {
            measurementValues[.mseg] = 4.5
        }
    }

    private func loadLastEntry() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            if let entry = try? await GainsService.shared.getLatestEntry(userId: userId) {
                await MainActor.run {
                    lastEntry = entry
                    // Pre-fill with last values
                    for (type, value) in entry.measurements {
                        measurementValues[type] = entry.displayMeasurement(type, in: gainsService.preferredUnit) ?? value
                    }
                    erectionQuality = entry.erectionQuality

                    // Update selected measurements based on what was tracked last time
                    if !entry.measurements.isEmpty {
                        selectedMeasurements = Set(entry.measurements.keys)
                    }
                }
            }
        }
    }

    private func toggleMeasurement(_ type: MeasurementType) {
        if selectedMeasurements.contains(type) {
            selectedMeasurements.remove(type)
        } else {
            selectedMeasurements.insert(type)
            // Initialize with default value if not present
            if measurementValues[type] == nil {
                measurementValues[type] = type.isLength ? 5.0 : 4.0
            }
        }
    }

    private func updateSelectedMeasurements(advanced: Bool) {
        if advanced {
            // Add secondary measurements
            selectedMeasurements.formUnion(MeasurementType.secondaryMeasurements)
        } else {
            // Keep only primary measurements
            let toKeep = Set(MeasurementType.primaryMeasurements)
            selectedMeasurements = selectedMeasurements.intersection(toKeep)
            if selectedMeasurements.isEmpty {
                selectedMeasurements = toKeep
            }
        }
    }

    private func binding(for type: MeasurementType) -> Binding<Double> {
        Binding(
            get: { measurementValues[type] ?? (type.isLength ? 5.0 : 4.0) },
            set: { measurementValues[type] = $0 }
        )
    }

    private func saveMeasurement() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Convert measurements to inches if needed
        var measurementsInInches: [MeasurementType: Double] = [:]
        for type in selectedMeasurements {
            if let value = measurementValues[type] {
                let inches = gainsService.preferredUnit == .metric ? value / 2.54 : value
                measurementsInInches[type] = inches
            }
        }

        isSaving = true

        let entry = GainsEntry(
            userId: userId,
            measurements: measurementsInInches,
            erectionQuality: erectionQuality,
            notes: notes.isEmpty ? nil : notes,
            sessionId: sessionId,
            measurementUnit: gainsService.preferredUnit
        )

        Task {
            do {
                try await GainsService.shared.addEntry(entry)

                await MainActor.run {
                    isSaving = false
                    showingSuccessAlert = true
                    isExpanded = false
                    notes = ""
                    onSave?(entry)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // TODO: Show error alert
                }
            }
        }
    }

    private func formatMeasurement(_ value: Double) -> String {
        switch gainsService.preferredUnit {
        case .imperial:
            return String(format: "%.1f\"", value)
        case .metric:
            return String(format: "%.1fcm", value)
        case .millimeters:
            return String(format: "%.0fmm", value)
        }
    }

    private func colorForEQ(_ value: Int) -> Color {
        switch value {
        case 1...3: return Color.red
        case 4...6: return Color("ErrorColor")
        case 7...8: return Color("BrightTeal")
        case 9...10: return Color("GrowthGreen")
        default: return Color("NeutralGray")
        }
    }
}

// MARK: - Supporting Views

struct MeasurementChip: View {
    let type: MeasurementType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.displayName)
                    .font(AppTheme.Typography.gravitySemibold(12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color("GrowthGreen") : Color("NeutralGray").opacity(0.2))
            .foregroundColor(isSelected ? .white : Color("TextColor"))
            .cornerRadius(16)
        }
    }
}

struct MeasurementInputRow: View {
    let type: MeasurementType
    @Binding var value: Double
    let unit: MeasurementUnit
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(type.fullName, systemImage: type.icon)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))

                Spacer()

                HStack(spacing: 4) {
                    Text(type.displayName)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))

                    Text(formatValue())
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("GrowthGreen"))
                }
            }

            Slider(
                value: $value,
                in: convertedRange(),
                step: unit == .imperial ? 0.1 : (unit == .metric ? 0.5 : 1.0)
            )
            .tint(Color("GrowthGreen"))
        }
    }

    private func formatValue() -> String {
        switch unit {
        case .imperial:
            return String(format: "%.1f\"", value)
        case .metric:
            return String(format: "%.1fcm", value)
        case .millimeters:
            return String(format: "%.0fmm", value)
        }
    }

    private func convertedRange() -> ClosedRange<Double> {
        switch unit {
        case .imperial:
            return range
        case .metric:
            return (range.lowerBound * 2.54)...(range.upperBound * 2.54)
        case .millimeters:
            return (range.lowerBound * 25.4)...(range.upperBound * 25.4)
        }
    }
}

// Simple flow layout for measurement chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var height: CGFloat = 0

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }

            height = y + rowHeight
        }
    }
}

#Preview {
    VStack {
        EnhancedGainsInputCard()
            .padding()
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}