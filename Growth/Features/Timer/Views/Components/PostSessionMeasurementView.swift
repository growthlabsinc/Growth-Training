//
//  PostSessionMeasurementView.swift
//  Growth
//
//  Post-session measurement capture that integrates with SessionCompletionViewModel
//

import SwiftUI

struct PostSessionMeasurementView: View {
    @ObservedObject var viewModel: SessionCompletionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showMeasurementInput = false
    @State private var capturedMeasurements: [MeasurementType: Double]? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "ruler")
                    .font(.system(size: 20))
                    .foregroundColor(Color("GrowthGreen"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Track Post-Session Measurements")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(.primary)

                    Text("Measure gains immediately after your session")
                        .font(AppTheme.Typography.gravityBook(11))
                        .foregroundColor(Color("TextSecondaryColor"))
                }

                Spacer()

                // Show check if measurements captured
                if capturedMeasurements != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("GrowthGreen"))
                }
            }
            .padding()
            .background(Color("MintGreen").opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("MintGreen"), lineWidth: 1)
            )
            .onTapGesture {
                showMeasurementInput = true
            }

            // Display captured measurements if available
            if let measurements = capturedMeasurements {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured Measurements")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))

                    HStack(spacing: 16) {
                        if let bpel = measurements[.bpel] {
                            MeasurementTag(type: .bpel, value: bpel)
                        }
                        if let bpfsl = measurements[.bpfsl] {
                            MeasurementTag(type: .bpfsl, value: bpfsl)
                        }
                        if let mseg = measurements[.mseg] {
                            MeasurementTag(type: .mseg, value: mseg)
                        }
                    }

                    // Calculate and show yield if pre-measurements exist
                    if let preMeasurements = viewModel.preMeasurements {
                        YieldDisplay(
                            preMeasurements: preMeasurements,
                            postMeasurements: measurements
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .sheet(isPresented: $showMeasurementInput) {
            PreSessionMeasurementInputView(
                preMeasurements: $capturedMeasurements,
                isPostSession: true
            )
            .onDisappear {
                // Update viewModel when measurements are captured
                if let measurements = capturedMeasurements {
                    viewModel.setPostSessionMeasurements(measurements)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MeasurementTag: View {
    let type: MeasurementType
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Text(type.displayName)
                .font(AppTheme.Typography.gravityBook(10))
                .foregroundColor(Color("TextSecondaryColor"))

            Text(String(format: "%.1f", value))
                .font(AppTheme.Typography.gravitySemibold(12))
                .foregroundColor(Color("GrowthGreen"))

            Text(GainsService.shared.preferredUnit == .imperial ? "in" : "cm")
                .font(AppTheme.Typography.gravityBook(10))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("MintGreen").opacity(0.1))
        .cornerRadius(6)
    }
}

struct YieldDisplay: View {
    let preMeasurements: [MeasurementType: Double]
    let postMeasurements: [MeasurementType: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Session Yield")
                .font(AppTheme.Typography.gravitySemibold(12))
                .foregroundColor(Color("TextColor"))

            HStack(spacing: 12) {
                ForEach(calculateYields(), id: \.type) { yield in
                    HStack(spacing: 2) {
                        Text(yield.type.displayName)
                            .font(AppTheme.Typography.gravityBook(10))
                            .foregroundColor(Color("TextSecondaryColor"))

                        Text(String(format: "%+.1f%%", yield.percentage))
                            .font(AppTheme.Typography.gravitySemibold(11))
                            .foregroundColor(yield.percentage > 0 ? Color("GrowthGreen") : Color("TextSecondaryColor"))
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private func calculateYields() -> [(type: MeasurementType, percentage: Double)] {
        var yields: [(type: MeasurementType, percentage: Double)] = []

        for (type, preValue) in preMeasurements {
            if let postValue = postMeasurements[type], preValue > 0 {
                let percentage = ((postValue - preValue) / preValue) * 100
                yields.append((type: type, percentage: percentage))
            }
        }

        return yields.sorted { $0.type.rawValue < $1.type.rawValue }
    }
}