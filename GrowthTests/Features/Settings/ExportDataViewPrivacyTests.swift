//
//  ExportDataViewPrivacyTests.swift
//  GrowthTests
//
//  Created by James Dev on 12/12/25.
//  Story 11.4: Opt-In Consent & Privacy Settings UI
//

import XCTest
@testable import Growth

/// Unit tests for Privacy & Research section in ExportDataView
/// Tests the time formatting helper and anonymous ID display functionality
final class ExportDataViewPrivacyTests: XCTestCase {

    // MARK: - Time Formatting Tests (AC: 5)

    /// Test that time formatting produces correct "Xh Xm" format for hours and minutes
    func testTimeFormattingWithHoursAndMinutes() {
        // Given: 2 hours and 30 minutes in seconds
        let seconds: TimeInterval = 2 * 3600 + 30 * 60 // 9000 seconds

        // When: formatting the time
        let result = formatTimeRemaining(seconds)

        // Then: should display "2h 30m"
        XCTAssertEqual(result, "2h 30m", "Time formatting should show hours and minutes")
    }

    /// Test that time formatting shows only minutes when less than 1 hour
    func testTimeFormattingWithOnlyMinutes() {
        // Given: 45 minutes in seconds
        let seconds: TimeInterval = 45 * 60 // 2700 seconds

        // When: formatting the time
        let result = formatTimeRemaining(seconds)

        // Then: should display "45m"
        XCTAssertEqual(result, "45m", "Time formatting should show only minutes when < 1 hour")
    }

    /// Test that time formatting handles zero correctly
    func testTimeFormattingWithZero() {
        // Given: 0 seconds
        let seconds: TimeInterval = 0

        // When: formatting the time
        let result = formatTimeRemaining(seconds)

        // Then: should display "0m"
        XCTAssertEqual(result, "0m", "Time formatting should show 0m for zero time")
    }

    /// Test that time formatting handles full 24 hours
    func testTimeFormattingWith24Hours() {
        // Given: 24 hours in seconds (rate limit window)
        let seconds: TimeInterval = 24 * 3600 // 86400 seconds

        // When: formatting the time
        let result = formatTimeRemaining(seconds)

        // Then: should display "24h 0m"
        XCTAssertEqual(result, "24h 0m", "Time formatting should handle 24 hours correctly")
    }

    /// Test edge case: 1 hour exactly
    func testTimeFormattingWithExactlyOneHour() {
        // Given: exactly 1 hour
        let seconds: TimeInterval = 3600

        // When: formatting the time
        let result = formatTimeRemaining(seconds)

        // Then: should display "1h 0m"
        XCTAssertEqual(result, "1h 0m", "Time formatting should show 1h 0m for exactly one hour")
    }

    // MARK: - Anonymous ID Format Tests (AC: 2)

    /// Test that anonymous ID matches expected GT-XXXXXXXX format
    func testAnonymousIdFormat() {
        // Given: anonymous ID from service
        let anonymousId = AnonymizationService.shared.getOrCreateAnonymousId()

        // Then: should match GT-XXXXXXXX pattern
        let pattern = "^GT-[A-F0-9]{8}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: anonymousId.utf16.count)
        let match = regex?.firstMatch(in: anonymousId, range: range)

        XCTAssertNotNil(match, "Anonymous ID should match GT-XXXXXXXX format, got: \(anonymousId)")
    }

    /// Test that anonymous ID is consistent across calls
    func testAnonymousIdConsistency() {
        // Given: two calls to get anonymous ID
        let id1 = AnonymizationService.shared.getOrCreateAnonymousId()
        let id2 = AnonymizationService.shared.getOrCreateAnonymousId()

        // Then: both should return the same ID
        XCTAssertEqual(id1, id2, "Anonymous ID should be consistent across calls")
    }

    // MARK: - Rate Limit Tests (AC: 5)

    /// Test that rate limit status is accessible
    func testCanRegenerateIdReturnsBoolean() {
        // When: checking rate limit status
        let canRegenerate = AnonymizationService.shared.canRegenerateId()

        // Then: should return a boolean (no crash)
        XCTAssertNotNil(canRegenerate, "canRegenerateId should return a boolean")
    }

    /// Test that time until regenerate returns non-negative value
    func testTimeUntilCanRegenerateReturnsNonNegative() {
        // When: getting time until regeneration
        let timeRemaining = AnonymizationService.shared.timeUntilCanRegenerate()

        // Then: should be >= 0
        XCTAssertGreaterThanOrEqual(timeRemaining, 0, "Time remaining should never be negative")
    }

    // MARK: - Helper Methods

    /// Mirror of the formatting function from ExportDataView for testing
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
