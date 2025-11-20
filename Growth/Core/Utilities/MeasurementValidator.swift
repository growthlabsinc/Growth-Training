//
//  MeasurementValidator.swift
//  Growth
//
//  Created by Dev Agent (James) on 11/3/25.
//  Story 10.2: Pre-Session Measurement Capture UI
//

import Foundation

/// Validation result for measurement values
enum MeasurementValidationResult: Equatable {
    case valid
    case softLimitWarning(message: String)
    case hardLimitError(message: String)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var isSoftWarning: Bool {
        if case .softLimitWarning = self {
            return true
        }
        return false
    }

    var isHardError: Bool {
        if case .hardLimitError = self {
            return true
        }
        return false
    }
}

/// Utility class for validating measurement values according to GrowthTrack standards
/// Implements hard and soft limits for BPEL, BPFSL, and MSEG measurements
struct MeasurementValidator {

    // MARK: - Hard Limits (Reject Immediately)

    private static let hardLimits: [MeasurementType: (min: Double, max: Double)] = [
        .bpel: (min: 3.0, max: 11.0),
        .bpfsl: (min: 3.0, max: 11.0),
        .mseg: (min: 3.0, max: 8.0)
    ]

    // MARK: - Soft Limits (Confirmation Dialog)

    private static let softLimits: [MeasurementType: (min: Double, max: Double)] = [
        .bpel: (min: 4.0, max: 10.0),
        .bpfsl: (min: 4.0, max: 10.0),
        .mseg: (min: 3.5, max: 6.5)
    ]

    // MARK: - Unit Conversion

    /// Converts centimeters to inches
    /// - Parameter cm: Value in centimeters
    /// - Returns: Value in inches
    static func cmToInches(_ cm: Double) -> Double {
        return cm / 2.54
    }

    /// Converts inches to centimeters
    /// - Parameter inches: Value in inches
    /// - Returns: Value in centimeters
    static func inchesToCm(_ inches: Double) -> Double {
        return inches * 2.54
    }

    // MARK: - Validation Methods

    /// Checks if value is within hard limits for the given measurement type
    /// - Parameters:
    ///   - value: Measurement value in inches
    ///   - type: Type of measurement
    /// - Returns: True if within hard limits, false otherwise
    static func isWithinHardLimits(value: Double, type: MeasurementType) -> Bool {
        guard let limits = hardLimits[type] else {
            // If no hard limits defined for this type, consider it valid
            return true
        }
        return value >= limits.min && value <= limits.max
    }

    /// Checks if value is within soft limits for the given measurement type
    /// - Parameters:
    ///   - value: Measurement value in inches
    ///   - type: Type of measurement
    /// - Returns: True if within soft limits, false otherwise
    static func isWithinSoftLimits(value: Double, type: MeasurementType) -> Bool {
        guard let limits = softLimits[type] else {
            // If no soft limits defined for this type, consider it valid
            return true
        }
        return value >= limits.min && value <= limits.max
    }

    /// Validates a measurement value against hard and soft limits
    /// - Parameters:
    ///   - value: Measurement value in inches
    ///   - type: Type of measurement
    /// - Returns: MeasurementValidationResult indicating valid, soft warning, or hard error
    static func validate(value: Double, type: MeasurementType) -> MeasurementValidationResult {
        // Check hard limits first (reject)
        if !isWithinHardLimits(value: value, type: type) {
            guard let limits = hardLimits[type] else {
                return .hardLimitError(message: "Invalid measurement type")
            }
            let message = "Value must be between \(limits.min)\" and \(limits.max)\""
            return .hardLimitError(message: message)
        }

        // Check soft limits (warn, allow continue)
        if !isWithinSoftLimits(value: value, type: type) {
            guard let limits = softLimits[type] else {
                return .valid
            }
            let message = "This value (\(String(format: "%.2f", value))\") is outside the typical range (\(limits.min)\" - \(limits.max)\"). Are you sure?"
            return .softLimitWarning(message: message)
        }

        return .valid
    }

    /// Validates a measurement value with automatic unit conversion
    /// - Parameters:
    ///   - value: Measurement value
    ///   - type: Type of measurement
    ///   - unit: Unit of measurement (imperial or metric)
    /// - Returns: MeasurementValidationResult indicating valid, soft warning, or hard error
    static func validate(value: Double, type: MeasurementType, unit: MeasurementUnit) -> MeasurementValidationResult {
        // Convert to inches if metric
        let valueInInches = unit == .metric ? cmToInches(value) : value
        return validate(value: valueInInches, type: type)
    }

    // MARK: - Edge Case Handling

    /// Validates if a value is acceptable (handles nil, zero, negative)
    /// - Parameter value: Optional measurement value
    /// - Returns: True if value is acceptable for validation
    static func isValidValue(_ value: Double?) -> Bool {
        guard let value = value else {
            return false
        }
        // Reject zero, negative, or extremely large values
        return value > 0 && value < 1000
    }
}
