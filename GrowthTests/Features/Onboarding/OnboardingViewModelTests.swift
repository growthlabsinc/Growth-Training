//
//  OnboardingViewModelTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
@testable import Growth

final class OnboardingViewModelTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
        viewModel = OnboardingViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
        super.tearDown()
    }
    
    func testOnboardingStepProgression() {
        // Test initial state
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isOnboardingComplete)
        
        // Test progression through all steps
        viewModel.advance() // to account
        XCTAssertEqual(viewModel.currentStep, .account)
        
        viewModel.advance() // to disclaimer
        XCTAssertEqual(viewModel.currentStep, .disclaimer)
        
        viewModel.advance() // to privacy
        XCTAssertEqual(viewModel.currentStep, .privacy)
        
        viewModel.advance() // to initialAssessment
        XCTAssertEqual(viewModel.currentStep, .initialAssessment)
        
        viewModel.advance() // to routineGoalSelection
        XCTAssertEqual(viewModel.currentStep, .routineGoalSelection)
        
        viewModel.advance() // to notificationPermissions
        XCTAssertEqual(viewModel.currentStep, .notificationPermissions)
        
        viewModel.advance() // to profileSetup
        XCTAssertEqual(viewModel.currentStep, .profileSetup)
        
        viewModel.advance() // to complete
        XCTAssertEqual(viewModel.currentStep, .complete)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }
    
    func testOnboardingStepRegression() {
        // Move to middle of flow
        viewModel.currentStep = .initialAssessment
        
        // Test regression
        viewModel.regress() // to privacy
        XCTAssertEqual(viewModel.currentStep, .privacy)
        
        viewModel.regress() // to disclaimer
        XCTAssertEqual(viewModel.currentStep, .disclaimer)
        
        viewModel.regress() // to account
        XCTAssertEqual(viewModel.currentStep, .account)
        
        viewModel.regress() // to welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)
        
        // Test that we can't go before welcome
        viewModel.regress()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }
    
    func testInitialAssessmentStepIncluded() {
        // Verify that initialAssessment is properly included in the flow
        let allSteps = OnboardingStep.allCases
        XCTAssertTrue(allSteps.contains(.initialAssessment))
        
        // Verify order
        guard let assessmentIndex = allSteps.firstIndex(of: .initialAssessment),
              let privacyIndex = allSteps.firstIndex(of: .privacy),
              let profileIndex = allSteps.firstIndex(of: .profileSetup) else {
            XCTFail("Required steps not found")
            return
        }
        
        // initialAssessment should be between privacy and profileSetup
        XCTAssertGreaterThan(assessmentIndex, privacyIndex)
        XCTAssertLessThan(assessmentIndex, profileIndex)
    }
    
    func testProgressPersistence() {
        // Set a specific step
        viewModel.currentStep = .initialAssessment
        
        // Create a new view model to test persistence
        let newViewModel = OnboardingViewModel()
        XCTAssertEqual(newViewModel.currentStep, .initialAssessment)
    }
    
    func testReset() {
        // Move to middle of flow
        viewModel.currentStep = .initialAssessment
        viewModel.isOnboardingComplete = true
        
        // Reset
        viewModel.reset()
        
        // Verify reset state
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isOnboardingComplete)
        
        // Verify persistence was reset
        let newViewModel = OnboardingViewModel()
        XCTAssertEqual(newViewModel.currentStep, .welcome)
    }
    
    func testNotificationPermissionsStepIncluded() {
        // Verify that notificationPermissions is properly included in the flow
        let allSteps = OnboardingStep.allCases
        XCTAssertTrue(allSteps.contains(.notificationPermissions))
        
        // Verify order - notification permissions should come after routineGoalSelection and before profileSetup
        guard let notificationIndex = allSteps.firstIndex(of: .notificationPermissions),
              let routineIndex = allSteps.firstIndex(of: .routineGoalSelection),
              let profileIndex = allSteps.firstIndex(of: .profileSetup) else {
            XCTFail("Required steps not found")
            return
        }
        
        // notificationPermissions should be between routineGoalSelection and profileSetup
        XCTAssertGreaterThan(notificationIndex, routineIndex)
        XCTAssertLessThan(notificationIndex, profileIndex)
    }
    
    func testNotificationPermissionsStepAdvances() {
        // Set current step to notification permissions
        viewModel.currentStep = .notificationPermissions
        
        // Advance should go to profileSetup
        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .profileSetup)
        
        // Regress should go back to routineGoalSelection
        viewModel.currentStep = .notificationPermissions
        viewModel.regress()
        XCTAssertEqual(viewModel.currentStep, .routineGoalSelection)
    }
}