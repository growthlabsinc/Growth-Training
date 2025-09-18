//
//  UserTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
import FirebaseFirestore
@testable import Growth

final class UserTests: XCTestCase {
    
    func testUserCodableWithInitialAssessmentFields() throws {
        // Create a user with initial assessment fields
        var user = User(
            id: "test123",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            linkedProgressData: nil,
            settings: UserSettings(
                notificationsEnabled: true,
                reminderTime: nil,
                privacyLevel: .medium
            ),
            disclaimerAccepted: true,
            disclaimerAcceptedTimestamp: Date(),
            disclaimerVersion: "1.0",
            streak: 5,
            earnedBadges: ["badge1", "badge2"],
            selectedRoutineId: "routine123",
            consentRecords: nil
        )
        
        // Set initial assessment fields
        user.initialMethodId = "angio_pumping"
        user.initialAssessmentResult = "needs_assistance"
        user.initialAssessmentDate = Date()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Verify initial assessment fields
        XCTAssertEqual(decodedUser.initialMethodId, "angio_pumping")
        XCTAssertEqual(decodedUser.initialAssessmentResult, "needs_assistance")
        XCTAssertNotNil(decodedUser.initialAssessmentDate)
        
        // Verify other fields remain intact
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.firstName, user.firstName)
        XCTAssertEqual(decodedUser.streak, user.streak)
    }
    
    func testUserFirestoreConversionWithInitialAssessment() {
        // Create a user with initial assessment
        var user = User(
            id: "test123",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            linkedProgressData: nil,
            settings: UserSettings(
                notificationsEnabled: false,
                reminderTime: nil,
                privacyLevel: .high
            ),
            disclaimerAccepted: true,
            disclaimerAcceptedTimestamp: Date(),
            disclaimerVersion: "1.0",
            streak: 0,
            earnedBadges: [],
            selectedRoutineId: nil,
            consentRecords: nil
        )
        
        user.initialMethodId = "am1_0"
        user.initialAssessmentResult = "can_proceed"
        user.initialAssessmentDate = Date()
        
        // Convert to Firestore data
        let firestoreData = user.toFirestoreData()
        
        // Verify initial assessment fields are included
        XCTAssertEqual(firestoreData["initialMethodId"] as? String, "am1_0")
        XCTAssertEqual(firestoreData["initialAssessmentResult"] as? String, "can_proceed")
        XCTAssertNotNil(firestoreData["initialAssessmentDate"] as? Timestamp)
        
        // Verify other required fields
        XCTAssertEqual(firestoreData["userId"] as? String, "test123")
        XCTAssertNotNil(firestoreData["creationDate"] as? Timestamp)
        XCTAssertNotNil(firestoreData["lastLogin"] as? Timestamp)
    }
    
    func testUserFirestoreConversionWithoutInitialAssessment() {
        // Create a user without initial assessment
        let user = User(
            id: "test123",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            linkedProgressData: nil,
            settings: UserSettings(
                notificationsEnabled: false,
                reminderTime: nil,
                privacyLevel: .high
            ),
            disclaimerAccepted: true,
            disclaimerAcceptedTimestamp: Date(),
            disclaimerVersion: "1.0",
            streak: 0,
            earnedBadges: [],
            selectedRoutineId: nil,
            consentRecords: nil
        )
        
        // Convert to Firestore data
        let firestoreData = user.toFirestoreData()
        
        // Verify initial assessment fields are not included when nil
        XCTAssertNil(firestoreData["initialMethodId"])
        XCTAssertNil(firestoreData["initialAssessmentResult"])
        XCTAssertNil(firestoreData["initialAssessmentDate"])
    }
}