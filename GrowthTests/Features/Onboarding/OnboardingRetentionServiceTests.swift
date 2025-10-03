//
//  OnboardingRetentionServiceTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
@testable import Growth

final class OnboardingRetentionServiceTests: XCTestCase {
    
    var service: OnboardingRetentionService!
    
    override func setUp() {
        super.setUp()
        service = OnboardingRetentionService.shared
        
        // Clear UserDefaults
        let userId = "testUser123"
        UserDefaults.standard.removeObject(forKey: "hasSeenDashboard_\(userId)")
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
    }
    
    override func tearDown() {
        // Clean up
        let userId = "testUser123"
        UserDefaults.standard.removeObject(forKey: "hasSeenDashboard_\(userId)")
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
        super.tearDown()
    }
    
    // MARK: - Test Onboarding Completion
    
    func testIsOnboardingComplete() {
        // Test when onboarding is not complete
        UserDefaults.standard.set(OnboardingStep.initialAssessment.rawValue, forKey: "onboardingStep")
        XCTAssertFalse(service.isOnboardingComplete(for: "testUser123"))
        
        // Test when onboarding is complete
        UserDefaults.standard.set(OnboardingStep.complete.rawValue, forKey: "onboardingStep")
        XCTAssertTrue(service.isOnboardingComplete(for: "testUser123"))
    }
    
    // MARK: - Test Onboarding Stage Detection
    
    func testGetCurrentOnboardingStage_NotStarted() {
        let user = User(
            id: "",
            firstName: nil,
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium)
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .notStarted)
    }
    
    func testGetCurrentOnboardingStage_AccountCreated() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium)
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .accountCreated)
    }
    
    func testGetCurrentOnboardingStage_DisclaimerAccepted() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .disclaimerAccepted)
    }
    
    func testGetCurrentOnboardingStage_PrivacyAccepted() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true,
            consentRecords: [ConsentRecord(documentId: "privacy_policy", documentVersion: "1.0", acceptedAt: Date())]
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .privacyAccepted)
    }
    
    func testGetCurrentOnboardingStage_AssessmentCompleted() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true,
            consentRecords: [ConsentRecord(documentId: "privacy_policy", documentVersion: "1.0", acceptedAt: Date())],
            initialAssessmentResult: "completed"
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .assessmentCompleted)
    }
    
    func testGetCurrentOnboardingStage_PracticePreferenceSet() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true,
            consentRecords: [ConsentRecord(documentId: "privacy_policy", documentVersion: "1.0", acceptedAt: Date())],
            initialAssessmentResult: "completed",
            preferredPracticeMode: "routine"
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .practicePreferenceSet)
    }
    
    func testGetCurrentOnboardingStage_Completed() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: true, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true,
            consentRecords: [ConsentRecord(documentId: "privacy_policy", documentVersion: "1.0", acceptedAt: Date())],
            initialAssessmentResult: "completed",
            preferredPracticeMode: "routine"
        )
        let stage = service.getCurrentOnboardingStage(for: user)
        XCTAssertEqual(stage, .completed)
    }
    
    // MARK: - Test Re-engagement Logic
    
    func testShouldTriggerReengagement_Completed() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: true, reminderTime: nil, privacyLevel: .medium),
            preferredPracticeMode: "routine"
        )
        let shouldTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-7200))
        XCTAssertFalse(shouldTrigger) // Should not re-engage completed users
    }
    
    func testShouldTriggerReengagement_NotStarted() {
        let user = User(
            id: "",
            firstName: nil,
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium)
        )
        let shouldTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-7200))
        XCTAssertFalse(shouldTrigger) // Should not re-engage users who haven't started
    }
    
    func testShouldTriggerReengagement_AccountCreated() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium)
        )
        
        // Less than 2 hours - should not trigger
        let shouldNotTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-3600))
        XCTAssertFalse(shouldNotTrigger)
        
        // More than 2 hours - should trigger
        let shouldTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-7201))
        XCTAssertTrue(shouldTrigger)
    }
    
    func testShouldTriggerReengagement_AssessmentCompleted() {
        let user = User(
            id: "test",
            firstName: "Test",
            creationDate: Date(),
            lastLogin: Date(),
            settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
            disclaimerAccepted: true,
            consentRecords: [ConsentRecord(documentId: "privacy_policy", documentVersion: "1.0", acceptedAt: Date())],
            initialAssessmentResult: "completed"
        )
        
        // Less than 12 hours - should not trigger
        let shouldNotTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-36000))
        XCTAssertFalse(shouldNotTrigger)
        
        // More than 12 hours - should trigger
        let shouldTrigger = service.shouldTriggerReengagement(for: user, lastActiveDate: Date().addingTimeInterval(-43201))
        XCTAssertTrue(shouldTrigger)
    }
    
    // MARK: - Test Re-engagement Messages
    
    func testGetReengagementMessage_AccountCreated() {
        let message = service.getReengagementMessage(for: .accountCreated)
        XCTAssertEqual(message.title, "Complete Your Setup")
        XCTAssertTrue(message.body.contains("few steps away"))
    }
    
    func testGetReengagementMessage_AssessmentCompleted() {
        let message = service.getReengagementMessage(for: .assessmentCompleted)
        XCTAssertEqual(message.title, "Choose Your Practice Style")
        XCTAssertTrue(message.body.contains("structured routine"))
    }
    
    // MARK: - Test Dashboard Tracking
    
    func testHasSeenDashboard() {
        let userId = "testUser123"
        
        // Initially should be false
        XCTAssertFalse(service.hasSeenDashboard(userId: userId))
        
        // Mark as seen
        service.markDashboardSeen(userId: userId)
        
        // Now should be true
        XCTAssertTrue(service.hasSeenDashboard(userId: userId))
    }
    
    func testMarkDashboardSeen() {
        let userId = "testUser123"
        
        // Mark dashboard as seen
        service.markDashboardSeen(userId: userId)
        
        // Verify UserDefaults was updated
        let key = "hasSeenDashboard_\(userId)"
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
    }
}