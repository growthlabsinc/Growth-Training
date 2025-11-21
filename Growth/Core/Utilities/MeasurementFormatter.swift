//
//  MeasurementFormatter.swift
//  Growth
//
//  Created for millimeters support
//  Handles all measurement formatting and display logic
//

import Foundation
import UIKit

/// Utility class for formatting measurement values for display
struct MeasurementFormatter {

    // MARK: - Number Formatting

    /// Returns the appropriate decimal places for a measurement unit
    /// - Parameter unit: The measurement unit
    /// - Returns: Number of decimal places to display
    static func decimalPlaces(for unit: MeasurementUnit) -> Int {
        switch unit {
        case .imperial:
            return 2  // Show 2 decimal places for inches (e.g., 6.25")
        case .metric:
            return 1  // Show 1 decimal place for cm (e.g., 15.8 cm)
        case .millimeters:
            return 0  // Show no decimal places for mm (e.g., 158 mm)
        }
    }

    /// Returns the step increment for a measurement unit (for steppers/pickers)
    /// - Parameter unit: The measurement unit
    /// - Returns: Step increment value
    static func stepIncrement(for unit: MeasurementUnit) -> Double {
        switch unit {
        case .imperial:
            return 0.25  // Quarter inch increments
        case .metric:
            return 0.5   // Half centimeter increments
        case .millimeters:
            return 5.0   // 5mm increments
        }
    }

    /// Returns the minor step increment for fine adjustments
    /// - Parameter unit: The measurement unit
    /// - Returns: Minor step increment value
    static func minorStepIncrement(for unit: MeasurementUnit) -> Double {
        switch unit {
        case .imperial:
            return 0.05  // 1/20th inch
        case .metric:
            return 0.1   // 1mm
        case .millimeters:
            return 1.0   // 1mm
        }
    }

    // MARK: - Value Formatting

    /// Formats a measurement value for display
    /// - Parameters:
    ///   - value: The measurement value in the specified unit
    ///   - unit: The measurement unit
    ///   - includeSymbol: Whether to include the unit symbol
    /// - Returns: Formatted string
    static func formatValue(_ value: Double, unit: MeasurementUnit, includeSymbol: Bool = true) -> String {
        let places = decimalPlaces(for: unit)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places

        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(value)"

        if includeSymbol {
            return "\(formattedNumber) \(unit.lengthSymbol)"
        } else {
            return formattedNumber
        }
    }

    /// Formats a measurement value from inches (internal storage) to display unit
    /// - Parameters:
    ///   - inches: The measurement value in inches
    ///   - displayUnit: The unit to display in
    ///   - includeSymbol: Whether to include the unit symbol
    /// - Returns: Formatted string
    static func formatFromInches(_ inches: Double, to displayUnit: MeasurementUnit, includeSymbol: Bool = true) -> String {
        let convertedValue = MeasurementValidator.fromInches(inches, to: displayUnit)
        return formatValue(convertedValue, unit: displayUnit, includeSymbol: includeSymbol)
    }

    /// Formats a measurement range for display
    /// - Parameters:
    ///   - min: Minimum value in the specified unit
    ///   - max: Maximum value in the specified unit
    ///   - unit: The measurement unit
    /// - Returns: Formatted range string
    static func formatRange(min: Double, max: Double, unit: MeasurementUnit) -> String {
        let minFormatted = formatValue(min, unit: unit, includeSymbol: false)
        let maxFormatted = formatValue(max, unit: unit, includeSymbol: false)
        return "\(minFormatted) - \(maxFormatted) \(unit.lengthSymbol)"
    }

    // MARK: - Input Validation

    /// Returns the keyboard type appropriate for a measurement unit
    /// - Parameter unit: The measurement unit
    /// - Returns: Recommended keyboard type
    static func keyboardType(for unit: MeasurementUnit) -> UIKeyboardType {
        switch unit {
        case .imperial, .metric:
            return .decimalPad  // Allow decimal input
        case .millimeters:
            return .numberPad   // Only whole numbers for mm
        }
    }

    /// Returns the input range for a measurement type in the specified unit
    /// - Parameters:
    ///   - type: The measurement type
    ///   - unit: The measurement unit
    /// - Returns: Tuple of (min, max) values in the specified unit
    static func inputRange(for type: MeasurementType, unit: MeasurementUnit) -> (min: Double, max: Double) {
        // Get the hard limits in inches
        let hardLimitsInInches: (min: Double, max: Double)

        switch type {
        case .bpel, .nbpel, .bpfsl, .nbpfsl, .fl, .bpfl:
            // Length measurements
            hardLimitsInInches = (min: 3.0, max: 11.0)
        case .mseg, .beg, .heg, .eg, .msfg, .bfg, .fg:
            // Girth measurements
            hardLimitsInInches = (min: 3.0, max: 8.0)
        }

        // Convert to the requested unit
        let min = MeasurementValidator.fromInches(hardLimitsInInches.min, to: unit)
        let max = MeasurementValidator.fromInches(hardLimitsInInches.max, to: unit)

        return (min: min, max: max)
    }

    /// Returns suggested/common values for quick selection
    /// - Parameters:
    ///   - type: The measurement type
    ///   - unit: The measurement unit
    /// - Returns: Array of suggested values in the specified unit
    static func suggestedValues(for type: MeasurementType, unit: MeasurementUnit) -> [Double] {
        // Define suggested values in inches
        let suggestedInInches: [Double]

        switch type {
        case .bpel, .nbpel, .bpfsl, .nbpfsl, .fl, .bpfl:
            // Length measurements
            suggestedInInches = [4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0]
        case .mseg, .beg, .heg, .eg, .msfg, .bfg, .fg:
            // Girth measurements
            suggestedInInches = [4.0, 4.5, 5.0, 5.5, 6.0]
        }

        // Convert to requested unit
        return suggestedInInches.map { MeasurementValidator.fromInches($0, to: unit) }
    }

    // MARK: - Placeholder Text

    /// Returns appropriate placeholder text for measurement input
    /// - Parameters:
    ///   - type: The measurement type
    ///   - unit: The measurement unit
    /// - Returns: Placeholder string
    static func placeholder(for type: MeasurementType, unit: MeasurementUnit) -> String {
        let typical: Double

        switch type {
        case .bpel, .nbpel:
            typical = 5.5  // Typical erect length in inches
        case .bpfsl, .nbpfsl:
            typical = 5.7  // Typical stretched length in inches
        case .fl, .bpfl:
            typical = 3.5  // Typical flaccid length in inches
        case .mseg, .eg:
            typical = 4.5  // Typical mid-shaft girth in inches
        case .beg:
            typical = 4.8  // Typical base girth in inches
        case .heg:
            typical = 4.3  // Typical head girth in inches
        case .msfg, .bfg, .fg:
            typical = 3.5  // Typical flaccid girth in inches
        }

        let converted = MeasurementValidator.fromInches(typical, to: unit)
        return formatValue(converted, unit: unit, includeSymbol: false)
    }

    // MARK: - Volume Calculations

    /// Calculates volume based on length and girth measurements
    /// - Parameters:
    ///   - length: Length in inches (internal storage)
    ///   - girth: Girth circumference in inches (internal storage)
    ///   - displayUnit: The unit to display volume in
    /// - Returns: Formatted volume string
    static func calculateVolume(length: Double, girth: Double, displayUnit: MeasurementUnit) -> String {
        // Calculate radius from circumference
        let radius = girth / (2 * .pi)

        // Calculate volume in cubic inches
        let volumeInCubicInches = .pi * radius * radius * length

        // Convert to display unit
        let convertedVolume: Double
        let volumeSymbol: String

        switch displayUnit {
        case .imperial:
            convertedVolume = volumeInCubicInches
            volumeSymbol = "in³"
        case .metric:
            // 1 cubic inch = 16.387064 cubic cm
            convertedVolume = volumeInCubicInches * 16.387064
            volumeSymbol = "cm³"
        case .millimeters:
            // 1 cubic inch = 16387.064 cubic mm
            convertedVolume = volumeInCubicInches * 16387.064
            volumeSymbol = "mm³"
        }

        // Format with appropriate decimal places
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = displayUnit == .millimeters ? 0 : 1

        let formattedVolume = formatter.string(from: NSNumber(value: convertedVolume)) ?? "\(convertedVolume)"
        return "\(formattedVolume) \(volumeSymbol)"
    }

    // MARK: - Difference Calculations

    /// Calculates and formats the difference between two measurements
    /// - Parameters:
    ///   - current: Current measurement in inches
    ///   - baseline: Baseline measurement in inches
    ///   - displayUnit: The unit to display in
    /// - Returns: Formatted difference string with + or - sign
    static func formatDifference(current: Double, baseline: Double, displayUnit: MeasurementUnit) -> String {
        let differenceInInches = current - baseline
        let differenceInUnit = MeasurementValidator.fromInches(abs(differenceInInches), to: displayUnit)

        let sign = differenceInInches >= 0 ? "+" : "-"
        let formatted = formatValue(differenceInUnit, unit: displayUnit, includeSymbol: true)

        return "\(sign)\(formatted)"
    }

    /// Calculates and formats percentage change
    /// - Parameters:
    ///   - current: Current measurement
    ///   - baseline: Baseline measurement
    /// - Returns: Formatted percentage string
    static func formatPercentageChange(current: Double, baseline: Double) -> String {
        guard baseline > 0 else { return "N/A" }

        let percentageChange = ((current - baseline) / baseline) * 100
        let sign = percentageChange >= 0 ? "+" : ""

        return String(format: "\(sign)%.1f%%", percentageChange)
    }
}