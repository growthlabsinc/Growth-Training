//
//  GainsInputCard.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import SwiftUI
import FirebaseAuth

struct GainsInputCard: View {
    @StateObject private var gainsService = GainsService.shared
    @State private var isExpanded = false
    @State private var showingSuccessAlert = false
    @State private var isSaving = false
    
    // Input values (stored in current display unit)
    @State private var length: Double = 6.5 // Middle of 1-12 range
    @State private var girth: Double = 4.5 // Middle of 1-8 range
    @State private var erectionQuality: Int = 7
    @State private var notes: String = ""

    // Track previous unit to detect changes
    @State private var previousUnit: MeasurementUnit?

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
                    
                    // Input fields
                    inputFieldsView
                    
                    // Notes field
                    notesFieldView
                    
                    // Action buttons
                    actionButtonsView
                }
            }
        }
        .onAppear {
            previousUnit = gainsService.preferredUnit
            initializeDefaultValues()
            loadLastEntry()
        }
        .alert("Measurement Saved!", isPresented: $showingSuccessAlert) {
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
                        Text("Last: \(formatMeasurement(lastEntry.displayLength(in: gainsService.preferredUnit), isLength: true)) × \(formatMeasurement(lastEntry.displayGirth(in: gainsService.preferredUnit), isLength: false))")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    } else {
                        Text("Tap to record your first measurement")
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
    
    // MARK: - Input Fields View
    
    private var inputFieldsView: some View {
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
                .onChange(of: gainsService.preferredUnit) { newUnit in
                    convertMeasurementValues(from: previousUnit ?? .imperial, to: newUnit)
                    previousUnit = newUnit
                }
            }
            
            // Length input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Length", systemImage: "ruler")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    Text(formatMeasurement(length, isLength: true))
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                Slider(
                    value: $length,
                    in: convertedRange(lengthRange, isLength: true),
                    step: MeasurementFormatter.stepIncrement(for: gainsService.preferredUnit)
                )
                .tint(Color("GrowthGreen"))
            }
            
            // Girth input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Girth", systemImage: "circle")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    Text(formatMeasurement(girth, isLength: false))
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                Slider(
                    value: $girth,
                    in: convertedRange(girthRange, isLength: false),
                    step: MeasurementFormatter.stepIncrement(for: gainsService.preferredUnit)
                )
                .tint(Color("GrowthGreen"))
            }
            
            // Erection Quality input
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
            .disabled(isSaving)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadLastEntry() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            if let entry = try? await GainsService.shared.getLatestEntry(userId: userId) {
                await MainActor.run {
                    lastEntry = entry
                    // Pre-fill with last values
                    length = entry.displayLength(in: gainsService.preferredUnit)
                    girth = entry.displayGirth(in: gainsService.preferredUnit)
                    erectionQuality = entry.erectionQuality
                }
            }
        }
    }
    
    private func saveMeasurement() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Convert to inches for storage
        let lengthInches = MeasurementValidator.toInches(length, from: gainsService.preferredUnit)
        let girthInches = MeasurementValidator.toInches(girth, from: gainsService.preferredUnit)
        
        // Validate
        let validation = GainsService.validateMeasurements(
            length: length,
            girth: girth,
            unit: gainsService.preferredUnit
        )
        
        guard validation.isValid else {
            // TODO: Show validation error
            return
        }
        
        isSaving = true
        
        let entry = GainsEntry(
            userId: userId,
            length: lengthInches,
            girth: girthInches,
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
    
    private func formatMeasurement(_ value: Double, isLength: Bool) -> String {
        switch gainsService.preferredUnit {
        case .imperial:
            return String(format: "%.1f\"", value)
        case .metric:
            return String(format: "%.1fcm", value)
        case .millimeters:
            return String(format: "%.0fmm", value)
        }
    }
    
    private func convertedRange(_ range: ClosedRange<Double>, isLength: Bool) -> ClosedRange<Double> {
        switch gainsService.preferredUnit {
        case .imperial:
            return range
        case .metric:
            return (range.lowerBound * 2.54)...(range.upperBound * 2.54)
        case .millimeters:
            return (range.lowerBound * 25.4)...(range.upperBound * 25.4)
        }
    }
    
    private func colorForEQ(_ value: Int) -> Color {
        switch value {
        case 1...3:
            return Color.red
        case 4...6:
            return Color("ErrorColor")
        case 7...8:
            return Color("BrightTeal")
        case 9...10:
            return Color("GrowthGreen")
        default:
            return Color("NeutralGray")
        }
    }

    private func initializeDefaultValues() {
        // Initialize with middle of range in current unit if not already set from lastEntry
        if lastEntry == nil {
            let lengthMiddle = (lengthRange.lowerBound + lengthRange.upperBound) / 2.0
            let girthMiddle = (girthRange.lowerBound + girthRange.upperBound) / 2.0
            length = MeasurementValidator.fromInches(lengthMiddle, to: gainsService.preferredUnit)
            girth = MeasurementValidator.fromInches(girthMiddle, to: gainsService.preferredUnit)
        }
    }

    private func convertMeasurementValues(from oldUnit: MeasurementUnit, to newUnit: MeasurementUnit) {
        // Convert length and girth from old unit to new unit
        let lengthInches = MeasurementValidator.toInches(length, from: oldUnit)
        let girthInches = MeasurementValidator.toInches(girth, from: oldUnit)
        length = MeasurementValidator.fromInches(lengthInches, to: newUnit)
        girth = MeasurementValidator.fromInches(girthInches, to: newUnit)
    }
}

#Preview {
    VStack {
        GainsInputCard()
            .padding()
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}