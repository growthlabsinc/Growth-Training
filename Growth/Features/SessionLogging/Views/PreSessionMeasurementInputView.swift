//
//  PreSessionMeasurementInputView.swift
//  Growth
//
//  Created by Dev Agent (James) on 11/5/25.
//  Story 10.2: Pre-Session Measurement Capture UI
//

import SwiftUI

struct PreSessionMeasurementInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var preMeasurements: [MeasurementType: Double]?
    @ObservedObject private var gainsService = GainsService.shared
    @State private var bpelValue: String = ""
    @State private var bpfslValue: String = ""
    @State private var msegValue: String = ""

    // Optional parameter to indicate if this is post-session
    var isPostSession: Bool = false

    // Validation state
    @State private var bpelValidation: MeasurementValidationResult = .valid
    @State private var bpfslValidation: MeasurementValidationResult = .valid
    @State private var msegValidation: MeasurementValidationResult = .valid

    // Soft limit warning alert
    @State private var showingSoftLimitAlert = false
    @State private var softLimitMessage: String = ""
    @State private var softLimitPendingMeasurements: [MeasurementType: Double] = [:]

    var body: some View {
        ZStack {
            // Background gradient matching app style
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("GrowthGreen").opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button("Skip") {
                        // Skip measurements - proceed without data
                        preMeasurements = nil
                        dismiss()
                    }
                    .foregroundColor(Color("GrowthGreen"))

                    Spacer()

                    Text(isPostSession ? "Post-Session Measurements" : "Pre-Session Measurements")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Invisible placeholder for balance
                    Button("Skip") {
                    }
                    .foregroundColor(.clear)
                    .disabled(true)
                    .opacity(0)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.9))

                // Main content with ScrollView
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                            .padding(.top, 20)

                        // Measurement Input Card
                        measurementInputCard
                            .padding(.horizontal)

                        // Action Buttons
                        actionButtons
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .alert("Confirm Measurement", isPresented: $showingSoftLimitAlert) {
            Button("Cancel", role: .cancel) {
                // User canceled - clear pending measurements
                softLimitPendingMeasurements = [:]
            }
            Button("Continue") {
                // User confirmed - accept measurements despite soft limit warning
                preMeasurements = softLimitPendingMeasurements
                dismiss()
            }
        } message: {
            Text(softLimitMessage)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.system(size: 48))
                .foregroundColor(Color("GrowthGreen"))

            Text(isPostSession ? "Measure Your Gains" : "Track Your Baseline")
                .font(.title2)
                .fontWeight(.bold)

            Text(isPostSession
                ? "Measure after your session to calculate temporary gains (yield). Compare with pre-session measurements to see your progress."
                : "Measure before your session to track temporary gains (yield). This helps you understand session effectiveness.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Measurement Input Card

    private var measurementInputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Title
            HStack {
                Text("Primary Measurements")
                    .font(.headline)
                Spacer()
                // Unit display
                Text(gainsService.preferredUnit == .imperial ? "inches" : "cm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // BPEL Input
            measurementField(
                label: "BPEL",
                fullName: "Bone Pressed Erect Length",
                value: $bpelValue,
                validation: bpelValidation,
                measurementType: .bpel
            )

            Divider()

            // BPFSL Input
            measurementField(
                label: "BPFSL",
                fullName: "Bone Pressed Flaccid Stretched Length",
                value: $bpfslValue,
                validation: bpfslValidation,
                measurementType: .bpfsl
            )

            Divider()

            // MSEG Input
            measurementField(
                label: "MSEG",
                fullName: "Mid-Shaft Erect Girth",
                value: $msegValue,
                validation: msegValidation,
                measurementType: .mseg
            )
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Measurement Field Component

    private func measurementField(
        label: String,
        fullName: String,
        value: Binding<String>,
        validation: MeasurementValidationResult,
        measurementType: MeasurementType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(fullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Text Field
            HStack {
                TextField(
                    gainsService.preferredUnit == .imperial ? "e.g., 6.5" : "e.g., 16.5",
                    text: value,
                    onEditingChanged: { _ in },
                    onCommit: {
                        validateMeasurement(type: measurementType, value: value.wrappedValue)
                    }
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

                Text(gainsService.preferredUnit == .imperial ? "in" : "cm")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
            }

            // Validation Error Message
            if validation.isHardError {
                if case .hardLimitError(let message) = validation {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: handleContinue) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(continueButtonEnabled ? Color("GrowthGreen") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!continueButtonEnabled)

            // Help Text
            Text("All fields are optional. Tap 'Skip' to proceed without measurements.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Computed Properties

    private var continueButtonEnabled: Bool {
        // Enable if at least one measurement is entered AND no hard errors exist
        let hasAnyMeasurement = !bpelValue.isEmpty || !bpfslValue.isEmpty || !msegValue.isEmpty
        let hasHardErrors = bpelValidation.isHardError || bpfslValidation.isHardError || msegValidation.isHardError
        return hasAnyMeasurement && !hasHardErrors
    }

    // MARK: - Validation Logic

    private func validateMeasurement(type: MeasurementType, value: String) {
        guard !value.isEmpty, let numericValue = Double(value) else {
            // Reset validation if value is empty or invalid
            switch type {
            case .bpel: bpelValidation = .valid
            case .bpfsl: bpfslValidation = .valid
            case .mseg: msegValidation = .valid
            default: break
            }
            return
        }

        // Validate using MeasurementValidator
        let result = MeasurementValidator.validate(value: numericValue, type: type, unit: gainsService.preferredUnit)

        // Update validation state
        switch type {
        case .bpel: bpelValidation = result
        case .bpfsl: bpfslValidation = result
        case .mseg: msegValidation = result
        default: break
        }
    }

    // MARK: - Continue Action

    private func handleContinue() {
        var measurements: [MeasurementType: Double] = [:]
        var softLimitWarnings: [String] = []

        // Collect and validate BPEL
        if let bpel = Double(bpelValue), !bpelValue.isEmpty {
            let result = MeasurementValidator.validate(value: bpel, type: .bpel, unit: gainsService.preferredUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("BPEL: \(message)")
                }
            }
            // Convert to inches for storage if metric
            let valueInInches = gainsService.preferredUnit == .metric ? MeasurementValidator.cmToInches(bpel) : bpel
            measurements[.bpel] = valueInInches
        }

        // Collect and validate BPFSL
        if let bpfsl = Double(bpfslValue), !bpfslValue.isEmpty {
            let result = MeasurementValidator.validate(value: bpfsl, type: .bpfsl, unit: gainsService.preferredUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("BPFSL: \(message)")
                }
            }
            let valueInInches = gainsService.preferredUnit == .metric ? MeasurementValidator.cmToInches(bpfsl) : bpfsl
            measurements[.bpfsl] = valueInInches
        }

        // Collect and validate MSEG
        if let mseg = Double(msegValue), !msegValue.isEmpty {
            let result = MeasurementValidator.validate(value: mseg, type: .mseg, unit: gainsService.preferredUnit)
            if result.isSoftWarning {
                if case .softLimitWarning(let message) = result {
                    softLimitWarnings.append("MSEG: \(message)")
                }
            }
            let valueInInches = gainsService.preferredUnit == .metric ? MeasurementValidator.cmToInches(mseg) : mseg
            measurements[.mseg] = valueInInches
        }

        // If soft limit warnings exist, show confirmation alert
        if !softLimitWarnings.isEmpty {
            softLimitMessage = softLimitWarnings.joined(separator: "\n\n")
            softLimitPendingMeasurements = measurements
            showingSoftLimitAlert = true
        } else {
            // No warnings - proceed directly
            preMeasurements = measurements.isEmpty ? nil : measurements
            dismiss()
        }
    }
}

// MARK: - Preview

struct PreSessionMeasurementInputView_Previews: PreviewProvider {
    static var previews: some View {
        PreSessionMeasurementInputView(preMeasurements: .constant(nil))
    }
}
