//
//  MeasurementValidatorTests.swift
//  GrowthTests
//
//  Created by Dev Agent (James) on 11/3/25.
//  Story 10.2: Pre-Session Measurement Capture UI
//

import XCTest
@testable import Growth

final class MeasurementValidatorTests: XCTestCase {

    // MARK: - Hard Limit Validation Tests

    func testBPELBelowHardLimit() {
        // BPEL 2.9" should trigger hard limit error (min is 3.0")
        let result = MeasurementValidator.validate(value: 2.9, type: .bpel)
        XCTAssertTrue(result.isHardError, "BPEL 2.9\" should trigger hard limit error")
        if case .hardLimitError(let message) = result {
            XCTAssertTrue(message.contains("3.0"), "Error message should contain minimum limit")
            XCTAssertTrue(message.contains("11.0"), "Error message should contain maximum limit")
        } else {
            XCTFail("Expected hardLimitError result")
        }
    }

    func testBPELAboveHardLimit() {
        // BPEL 11.1" should trigger hard limit error (max is 11.0")
        let result = MeasurementValidator.validate(value: 11.1, type: .bpel)
        XCTAssertTrue(result.isHardError, "BPEL 11.1\" should trigger hard limit error")
        if case .hardLimitError(let message) = result {
            XCTAssertTrue(message.contains("3.0"), "Error message should contain minimum limit")
            XCTAssertTrue(message.contains("11.0"), "Error message should contain maximum limit")
        } else {
            XCTFail("Expected hardLimitError result")
        }
    }

    func testBPELAtMinimumHardLimit() {
        // BPEL 3.0" is at hard limit boundary (should pass hard limit, may trigger soft limit)
        let result = MeasurementValidator.validate(value: 3.0, type: .bpel)
        XCTAssertFalse(result.isHardError, "BPEL 3.0\" should NOT trigger hard limit error (boundary value)")
        // Note: 3.0" is below soft limit (4.0") so should trigger soft limit warning
        XCTAssertTrue(result.isSoftWarning, "BPEL 3.0\" should trigger soft limit warning")
    }

    func testBPELAtMaximumHardLimit() {
        // BPEL 11.0" is at hard limit boundary (should pass hard limit, may trigger soft limit)
        let result = MeasurementValidator.validate(value: 11.0, type: .bpel)
        XCTAssertFalse(result.isHardError, "BPEL 11.0\" should NOT trigger hard limit error (boundary value)")
        // Note: 11.0" is above soft limit (10.0") so should trigger soft limit warning
        XCTAssertTrue(result.isSoftWarning, "BPEL 11.0\" should trigger soft limit warning")
    }

    func testMSEGBelowHardLimit() {
        // MSEG 2.9" should trigger hard limit error (min is 3.0")
        let result = MeasurementValidator.validate(value: 2.9, type: .mseg)
        XCTAssertTrue(result.isHardError, "MSEG 2.9\" should trigger hard limit error")
    }

    func testMSEGAboveHardLimit() {
        // MSEG 8.1" should trigger hard limit error (max is 8.0")
        let result = MeasurementValidator.validate(value: 8.1, type: .mseg)
        XCTAssertTrue(result.isHardError, "MSEG 8.1\" should trigger hard limit error")
    }

    func testBPFSLBelowHardLimit() {
        // BPFSL has same limits as BPEL (3.0" - 11.0")
        let result = MeasurementValidator.validate(value: 2.9, type: .bpfsl)
        XCTAssertTrue(result.isHardError, "BPFSL 2.9\" should trigger hard limit error")
    }

    func testBPFSLAboveHardLimit() {
        // BPFSL has same limits as BPEL (3.0" - 11.0")
        let result = MeasurementValidator.validate(value: 11.1, type: .bpfsl)
        XCTAssertTrue(result.isHardError, "BPFSL 11.1\" should trigger hard limit error")
    }

    // MARK: - Soft Limit Validation Tests

    func testBPELBelowSoftLimit() {
        // BPEL 3.5" is above hard limit (3.0") but below soft limit (4.0")
        let result = MeasurementValidator.validate(value: 3.5, type: .bpel)
        XCTAssertFalse(result.isHardError, "BPEL 3.5\" should NOT trigger hard limit error")
        XCTAssertTrue(result.isSoftWarning, "BPEL 3.5\" should trigger soft limit warning")
        if case .softLimitWarning(let message) = result {
            XCTAssertTrue(message.contains("3.5"), "Soft warning message should contain the entered value")
            XCTAssertTrue(message.contains("4.0"), "Soft warning message should contain minimum soft limit")
            XCTAssertTrue(message.contains("10.0"), "Soft warning message should contain maximum soft limit")
            XCTAssertTrue(message.contains("Are you sure?"), "Soft warning should ask for confirmation")
        } else {
            XCTFail("Expected softLimitWarning result")
        }
    }

    func testBPELAboveSoftLimit() {
        // BPEL 10.5" is below hard limit (11.0") but above soft limit (10.0")
        let result = MeasurementValidator.validate(value: 10.5, type: .bpel)
        XCTAssertFalse(result.isHardError, "BPEL 10.5\" should NOT trigger hard limit error")
        XCTAssertTrue(result.isSoftWarning, "BPEL 10.5\" should trigger soft limit warning")
    }

    func testMSEGBelowSoftLimit() {
        // MSEG 3.4" is above hard limit (3.0") but below soft limit (3.5")
        let result = MeasurementValidator.validate(value: 3.4, type: .mseg)
        XCTAssertFalse(result.isHardError, "MSEG 3.4\" should NOT trigger hard limit error")
        XCTAssertTrue(result.isSoftWarning, "MSEG 3.4\" should trigger soft limit warning")
    }

    func testMSEGAboveSoftLimit() {
        // MSEG 6.6" is below hard limit (8.0") but above soft limit (6.5")
        let result = MeasurementValidator.validate(value: 6.6, type: .mseg)
        XCTAssertFalse(result.isHardError, "MSEG 6.6\" should NOT trigger hard limit error")
        XCTAssertTrue(result.isSoftWarning, "MSEG 6.6\" should trigger soft limit warning")
    }

    func testBPELWithinSoftLimits() {
        // BPEL 5.0" is within soft limits (4.0" - 10.0")
        let result = MeasurementValidator.validate(value: 5.0, type: .bpel)
        XCTAssertTrue(result.isValid, "BPEL 5.0\" should be valid (within soft limits)")
        XCTAssertFalse(result.isHardError, "BPEL 5.0\" should NOT trigger hard limit error")
        XCTAssertFalse(result.isSoftWarning, "BPEL 5.0\" should NOT trigger soft limit warning")
    }

    func testMSEGWithinSoftLimits() {
        // MSEG 4.5" is within soft limits (3.5" - 6.5")
        let result = MeasurementValidator.validate(value: 4.5, type: .mseg)
        XCTAssertTrue(result.isValid, "MSEG 4.5\" should be valid (within soft limits)")
    }

    // MARK: - Metric Unit Conversion Tests

    func testMetricConversionValid() {
        // 10 cm = 3.937 inches (within soft limits for BPEL)
        let result = MeasurementValidator.validate(value: 10.0, type: .bpel, unit: .metric)
        // 3.937" is below soft limit (4.0") so should trigger soft warning
        XCTAssertTrue(result.isSoftWarning, "10 cm (3.937\") should trigger soft limit warning for BPEL")
    }

    func testMetricConversionHardLimitExceeded() {
        // 30 cm = 11.811 inches (exceeds hard limit for BPEL)
        let result = MeasurementValidator.validate(value: 30.0, type: .bpel, unit: .metric)
        XCTAssertTrue(result.isHardError, "30 cm (11.811\") should trigger hard limit error for BPEL")
    }

    func testMetricConversionAccuracy() {
        // Test conversion accuracy: 15 cm should be 5.906 inches
        let cm = 15.0
        let expectedInches = 5.906
        let actualInches = MeasurementValidator.cmToInches(cm)
        XCTAssertEqual(actualInches, expectedInches, accuracy: 0.001, "Conversion from 15 cm to inches should be accurate")

        // Test reverse conversion
        let inches = 6.0
        let expectedCm = 15.24
        let actualCm = MeasurementValidator.inchesToCm(inches)
        XCTAssertEqual(actualCm, expectedCm, accuracy: 0.01, "Conversion from 6 inches to cm should be accurate")
    }

    func testImperialUnitPassthrough() {
        // Test that imperial units are not converted
        let result = MeasurementValidator.validate(value: 5.0, type: .bpel, unit: .imperial)
        XCTAssertTrue(result.isValid, "5.0 inches should be valid for BPEL with imperial units")
    }

    // MARK: - Edge Case Tests

    func testNilValueHandling() {
        // Test isValidValue with nil
        let nilValue: Double? = nil
        XCTAssertFalse(MeasurementValidator.isValidValue(nilValue), "Nil value should be invalid")
    }

    func testZeroValueHandling() {
        // Test isValidValue with zero
        XCTAssertFalse(MeasurementValidator.isValidValue(0.0), "Zero value should be invalid")

        // Test validation with zero (should fail hard limit)
        let result = MeasurementValidator.validate(value: 0.0, type: .bpel)
        XCTAssertTrue(result.isHardError, "Zero value should trigger hard limit error")
    }

    func testNegativeValueHandling() {
        // Test isValidValue with negative
        XCTAssertFalse(MeasurementValidator.isValidValue(-1.0), "Negative value should be invalid")

        // Test validation with negative (should fail hard limit)
        let result = MeasurementValidator.validate(value: -1.0, type: .bpel)
        XCTAssertTrue(result.isHardError, "Negative value should trigger hard limit error")
    }

    func testVeryLargeValueHandling() {
        // Test isValidValue with very large value
        XCTAssertFalse(MeasurementValidator.isValidValue(1001.0), "Very large value (>1000) should be invalid")

        // Test validation with very large value (should fail hard limit)
        let result = MeasurementValidator.validate(value: 100.0, type: .bpel)
        XCTAssertTrue(result.isHardError, "Very large value (100\") should trigger hard limit error")
    }

    func testValidValueAtBoundary() {
        // Test isValidValue with boundary values
        XCTAssertTrue(MeasurementValidator.isValidValue(0.1), "Small positive value (0.1) should be valid")
        XCTAssertTrue(MeasurementValidator.isValidValue(999.9), "Large value just under 1000 should be valid")
    }

    // MARK: - MeasurementValidationResult Equatable Tests

    func testMeasurementValidationResultEquatable() {
        // Test Equatable conformance for MeasurementValidationResult
        let valid1 = MeasurementValidationResult.valid
        let valid2 = MeasurementValidationResult.valid
        XCTAssertEqual(valid1, valid2, "Two .valid results should be equal")

        let soft1 = MeasurementValidationResult.softLimitWarning(message: "Test warning")
        let soft2 = MeasurementValidationResult.softLimitWarning(message: "Test warning")
        XCTAssertEqual(soft1, soft2, "Two softLimitWarning results with same message should be equal")

        let hard1 = MeasurementValidationResult.hardLimitError(message: "Test error")
        let hard2 = MeasurementValidationResult.hardLimitError(message: "Test error")
        XCTAssertEqual(hard1, hard2, "Two hardLimitError results with same message should be equal")

        XCTAssertNotEqual(valid1, soft1, ".valid should not equal .softLimitWarning")
        XCTAssertNotEqual(soft1, hard1, ".softLimitWarning should not equal .hardLimitError")
    }
}
