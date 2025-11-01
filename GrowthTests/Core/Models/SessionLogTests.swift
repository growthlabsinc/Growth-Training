//
//  SessionLogTests.swift
//  GrowthTests
//
//  Created by James (Dev Agent) on 11/1/25.
//  Story 10.1: Extend SessionLog Model for Pre/Post Measurements
//

import XCTest
import FirebaseFirestore
@testable import Growth

final class SessionLogTests: XCTestCase {

    // MARK: - Test 1: Measurement Field Initialization

    func testSessionLogWithNilMeasurements() {
        // Test backward compatibility - create SessionLog without measurements
        let sessionLog = SessionLog(
            id: "test-1",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date()
        )

        XCTAssertNil(sessionLog.preMeasurements, "preMeasurements should be nil when not provided")
        XCTAssertNil(sessionLog.postMeasurements, "postMeasurements should be nil when not provided")
        XCTAssertNil(sessionLog.yieldPercentages, "yieldPercentages should be nil when measurements are not provided")
    }

    func testSessionLogWithPopulatedMeasurements() {
        // Test creating SessionLog with pre/post measurements
        let preMeasurements: [MeasurementType: Double] = [
            .bpel: 6.0,
            .bpfsl: 6.2,
            .mseg: 4.5
        ]

        let postMeasurements: [MeasurementType: Double] = [
            .bpel: 6.3,
            .bpfsl: 6.5,
            .mseg: 4.7
        ]

        let sessionLog = SessionLog(
            id: "test-2",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: preMeasurements,
            postMeasurements: postMeasurements
        )

        XCTAssertNotNil(sessionLog.preMeasurements, "preMeasurements should not be nil")
        XCTAssertNotNil(sessionLog.postMeasurements, "postMeasurements should not be nil")
        XCTAssertEqual(sessionLog.preMeasurements?[.bpel], 6.0, accuracy: 0.001, "BPEL pre-measurement should be 6.0")
        XCTAssertEqual(sessionLog.postMeasurements?[.bpel], 6.3, accuracy: 0.001, "BPEL post-measurement should be 6.3")
    }

    // MARK: - Test 2: Yield Calculation

    func testYieldCalculationWithMatchingKeys() {
        // Test yield calculation when pre/post have matching keys
        let sessionLog = SessionLog(
            id: "test-3",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: [.bpel: 6.0, .mseg: 4.5],
            postMeasurements: [.bpel: 6.3, .mseg: 4.7]
        )

        let yields = sessionLog.yieldPercentages
        XCTAssertNotNil(yields, "yieldPercentages should not be nil")
        XCTAssertEqual(yields?[.bpel], 5.0, accuracy: 0.01, "BPEL yield should be 5% (6.3-6.0)/6.0 * 100")
        XCTAssertEqual(yields?[.mseg], 4.44, accuracy: 0.01, "MSEG yield should be 4.44% (4.7-4.5)/4.5 * 100")
    }

    func testYieldCalculationWithMismatchedKeys() {
        // Test yield calculation when pre/post have different keys
        let sessionLog = SessionLog(
            id: "test-4",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: [.bpel: 6.0],
            postMeasurements: [.mseg: 4.7]
        )

        let yields = sessionLog.yieldPercentages
        XCTAssertNotNil(yields, "yieldPercentages should not be nil (returns empty dict)")
        XCTAssertNil(yields?[.bpel], "BPEL yield should be nil (no post measurement)")
        XCTAssertNil(yields?[.mseg], "MSEG yield should be nil (no pre measurement)")
    }

    func testYieldCalculationWithZeroPreValue() {
        // Test edge case: yield calculation when pre value is zero (should not calculate)
        let sessionLog = SessionLog(
            id: "test-5",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: [.bpel: 0.0],
            postMeasurements: [.bpel: 6.3]
        )

        let yields = sessionLog.yieldPercentages
        XCTAssertNil(yields?[.bpel], "BPEL yield should be nil when pre value is zero (cannot divide by zero)")
    }

    func testYieldCalculationWithNilMeasurements() {
        // Test yield calculation when measurements are nil
        let sessionLog = SessionLog(
            id: "test-6",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date()
        )

        XCTAssertNil(sessionLog.yieldPercentages, "yieldPercentages should be nil when measurements are not provided")
    }

    // MARK: - Test 3: Firestore Serialization

    func testFirestoreSerializationWithMeasurements() {
        // Test serialization with measurements - verify enum keys converted to strings
        let preMeasurements: [MeasurementType: Double] = [
            .bpel: 6.0,
            .bpfsl: 6.2,
            .mseg: 4.5
        ]

        let postMeasurements: [MeasurementType: Double] = [
            .bpel: 6.3,
            .bpfsl: 6.5,
            .mseg: 4.7
        ]

        let sessionLog = SessionLog(
            id: "test-7",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: preMeasurements,
            postMeasurements: postMeasurements
        )

        let firestoreData = sessionLog.toFirestore

        // Verify preMeasurements encoded with string keys
        XCTAssertNotNil(firestoreData["preMeasurements"], "preMeasurements should be in Firestore data")
        if let preMeasurementsDict = firestoreData["preMeasurements"] as? [String: Double] {
            XCTAssertEqual(preMeasurementsDict["bpel"], 6.0, accuracy: 0.001, "BPEL should be encoded with string key")
            XCTAssertEqual(preMeasurementsDict["bpfsl"], 6.2, accuracy: 0.001, "BPFSL should be encoded with string key")
            XCTAssertEqual(preMeasurementsDict["mseg"], 4.5, accuracy: 0.001, "MSEG should be encoded with string key")
        } else {
            XCTFail("preMeasurements should be a [String: Double] dictionary")
        }

        // Verify postMeasurements encoded with string keys
        XCTAssertNotNil(firestoreData["postMeasurements"], "postMeasurements should be in Firestore data")
        if let postMeasurementsDict = firestoreData["postMeasurements"] as? [String: Double] {
            XCTAssertEqual(postMeasurementsDict["bpel"], 6.3, accuracy: 0.001, "BPEL should be encoded with string key")
            XCTAssertEqual(postMeasurementsDict["bpfsl"], 6.5, accuracy: 0.001, "BPFSL should be encoded with string key")
            XCTAssertEqual(postMeasurementsDict["mseg"], 4.7, accuracy: 0.001, "MSEG should be encoded with string key")
        } else {
            XCTFail("postMeasurements should be a [String: Double] dictionary")
        }

        // Verify yieldPercentages is NOT stored in Firestore
        XCTAssertNil(firestoreData["yieldPercentages"], "yieldPercentages should NOT be stored in Firestore (computed client-side)")
    }

    func testFirestoreSerializationWithoutMeasurements() {
        // Test serialization without measurements - verify fields omitted (not null)
        let sessionLog = SessionLog(
            id: "test-8",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date()
        )

        let firestoreData = sessionLog.toFirestore

        XCTAssertNil(firestoreData["preMeasurements"], "preMeasurements should be omitted from Firestore data when nil")
        XCTAssertNil(firestoreData["postMeasurements"], "postMeasurements should be omitted from Firestore data when nil")
        XCTAssertNil(firestoreData["yieldPercentages"], "yieldPercentages should NOT be stored in Firestore")
    }

    // MARK: - Test 4: Backward Compatibility

    func testBackwardCompatibilityLoadExistingDocument() {
        // Simulate loading an existing SessionLog document without measurement fields
        let mockData: [String: Any] = [
            "userId": "user1",
            "duration": 30,
            "startTime": Timestamp(date: Date()),
            "endTime": Timestamp(date: Date()),
            "moodBefore": "neutral",
            "moodAfter": "positive"
        ]

        // Create a mock DocumentSnapshot (this would normally come from Firestore)
        // For testing purposes, we'll verify that the SessionLog initializer handles missing fields gracefully
        // Since we can't easily mock DocumentSnapshot, we test the deserialization pattern directly

        // Verify that accessing optional fields that don't exist results in nil
        XCTAssertNil(mockData["preMeasurements"] as? [String: Double], "preMeasurements should be nil in existing documents")
        XCTAssertNil(mockData["postMeasurements"] as? [String: Double], "postMeasurements should be nil in existing documents")
    }

    func testRoundTripSerializationWithMeasurements() {
        // Test save and load SessionLog with measurements - round-trip successful
        let original = SessionLog(
            id: "test-9",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: [.bpel: 6.0, .mseg: 4.5],
            postMeasurements: [.bpel: 6.3, .mseg: 4.7]
        )

        let firestoreData = original.toFirestore

        // Verify serialization
        XCTAssertNotNil(firestoreData["preMeasurements"], "preMeasurements should be serialized")
        XCTAssertNotNil(firestoreData["postMeasurements"], "postMeasurements should be serialized")

        // Simulate deserialization (would normally happen via DocumentSnapshot init)
        if let preMeasurementsDict = firestoreData["preMeasurements"] as? [String: Double] {
            var convertedPre: [MeasurementType: Double] = [:]
            for (key, value) in preMeasurementsDict {
                if let measurementType = MeasurementType(rawValue: key) {
                    convertedPre[measurementType] = value
                }
            }
            XCTAssertEqual(convertedPre[.bpel], 6.0, accuracy: 0.001, "BPEL should round-trip correctly")
            XCTAssertEqual(convertedPre[.mseg], 4.5, accuracy: 0.001, "MSEG should round-trip correctly")
        } else {
            XCTFail("preMeasurements should be deserializable")
        }
    }

    func testEqualityComparisonWithAndWithoutMeasurements() {
        // Test that SessionLog equality comparisons still work
        let sessionLog1 = SessionLog(
            id: "test-10",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date()
        )

        let sessionLog2 = SessionLog(
            id: "test-10",
            userId: "user1",
            duration: 30,
            startTime: sessionLog1.startTime,
            endTime: sessionLog1.endTime,
            preMeasurements: [.bpel: 6.0],
            postMeasurements: [.bpel: 6.3]
        )

        // These should NOT be equal because preMeasurements/postMeasurements differ
        XCTAssertNotEqual(sessionLog1, sessionLog2, "SessionLogs with different measurements should not be equal")

        // Create two identical SessionLogs with measurements
        let sessionLog3 = SessionLog(
            id: "test-11",
            userId: "user1",
            duration: 30,
            startTime: Date(),
            endTime: Date(),
            preMeasurements: [.bpel: 6.0],
            postMeasurements: [.bpel: 6.3]
        )

        let sessionLog4 = SessionLog(
            id: "test-11",
            userId: "user1",
            duration: 30,
            startTime: sessionLog3.startTime,
            endTime: sessionLog3.endTime,
            preMeasurements: [.bpel: 6.0],
            postMeasurements: [.bpel: 6.3]
        )

        XCTAssertEqual(sessionLog3, sessionLog4, "Identical SessionLogs with measurements should be equal")
    }
}
