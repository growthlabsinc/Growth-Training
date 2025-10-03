//
//  RoutineGoalSelectionTests.swift
//  GrowthTests
//
//  Created by Developer on [Date]
//

import XCTest
@testable import Growth
import Firebase

final class RoutineGoalSelectionTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = OnboardingViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Unit Tests
    
    func testOnboardingStepIncludesRoutineGoalSelection() {
        // Verify the enum includes the new step
        let allSteps = OnboardingStep.allCases
        XCTAssertTrue(allSteps.contains(.routineGoalSelection), "OnboardingStep should include routineGoalSelection")
        
        // Verify the step order
        let initialAssessmentIndex = OnboardingStep.initialAssessment.rawValue
        let routineGoalIndex = OnboardingStep.routineGoalSelection.rawValue
        let profileSetupIndex = OnboardingStep.profileSetup.rawValue
        
        XCTAssertEqual(routineGoalIndex, initialAssessmentIndex + 1, "routineGoalSelection should come after initialAssessment")
        XCTAssertEqual(profileSetupIndex, routineGoalIndex + 1, "profileSetup should come after routineGoalSelection")
    }
    
    func testStepNavigationFromInitialAssessment() {
        // Set current step to initial assessment
        viewModel.currentStep = .initialAssessment
        
        // Advance to next step
        viewModel.advance()
        
        // Verify we're now at routine goal selection
        XCTAssertEqual(viewModel.currentStep, .routineGoalSelection, "Should advance from initialAssessment to routineGoalSelection")
    }
    
    func testStepNavigationFromRoutineGoalSelection() {
        // Set current step to routine goal selection
        viewModel.currentStep = .routineGoalSelection
        
        // Advance to next step
        viewModel.advance()
        
        // Verify we're now at profile setup
        XCTAssertEqual(viewModel.currentStep, .profileSetup, "Should advance from routineGoalSelection to profileSetup")
    }
    
    func testUserModelHasPracticePreferenceFields() {
        // Create a test user directly
        let testUser = createTestUser()
        
        // Initially should be nil
        XCTAssertNil(testUser.preferredPracticeMode, "preferredPracticeMode should initially be nil")
        XCTAssertNil(testUser.practicePreferenceSetAt, "practicePreferenceSetAt should initially be nil")
        
        // Create a user with practice preferences set
        var userWithPreferences = testUser
        userWithPreferences.preferredPracticeMode = "routine"
        userWithPreferences.practicePreferenceSetAt = Date()
        
        XCTAssertEqual(userWithPreferences.preferredPracticeMode, "routine", "User should have preferredPracticeMode set to 'routine'")
        XCTAssertNotNil(userWithPreferences.practicePreferenceSetAt, "User should have practicePreferenceSetAt timestamp")
    }
    
    func testUserModelFirestoreConversion() {
        // Create a test user with practice preferences
        var testUser = createTestUser()
        testUser.preferredPracticeMode = "adhoc"
        testUser.practicePreferenceSetAt = Date()
        
        // Convert to Firestore data
        let firestoreData = testUser.toFirestoreData()
        
        // Verify fields are included
        XCTAssertEqual(firestoreData["preferredPracticeMode"] as? String, "adhoc", "Firestore data should include preferredPracticeMode")
        XCTAssertNotNil(firestoreData["practicePreferenceSetAt"] as? Timestamp, "Firestore data should include practicePreferenceSetAt")
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser() -> User {
        return User(
            id: "test123",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            linkedProgressData: nil,
            settings: UserSettings(
                notificationsEnabled: false,
                reminderTime: nil,
                privacyLevel: .medium
            ),
            disclaimerAccepted: true,
            disclaimerAcceptedTimestamp: Date(),
            disclaimerVersion: "1.0",
            streak: 0,
            earnedBadges: [],
            selectedRoutineId: nil,
            consentRecords: nil,
            initialMethodId: nil,
            initialAssessmentResult: nil,
            initialAssessmentDate: nil,
            preferredPracticeMode: nil,
            practicePreferenceSetAt: nil
        )
    }
}

