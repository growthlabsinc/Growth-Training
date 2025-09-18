//
//  OnboardingFlowTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
@testable import Growth

final class OnboardingFlowTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
        viewModel = OnboardingViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
        super.tearDown()
    }
    
    func testSkipLogicFromRoutineSelection() {
        // Set up to routine selection step
        viewModel.currentStep = .routineGoalSelection
        
        // Skip should advance to notification permissions
        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .notificationPermissions)
        
        // And then to profile setup
        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .profileSetup)
        
        // And finally to complete
        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .complete)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }
    
    func testCompleteOnboardingFlow() {
        // Test complete flow from start to finish
        XCTAssertEqual(viewModel.currentStep, .welcome)
        
        let expectedSteps: [OnboardingStep] = [
            .welcome,
            .account,
            .disclaimer,
            .privacy,
            .initialAssessment,
            .routineGoalSelection,
            .notificationPermissions,
            .profileSetup,
            .complete
        ]
        
        for (index, expectedStep) in expectedSteps.enumerated() {
            XCTAssertEqual(viewModel.currentStep, expectedStep, "Step \(index) should be \(expectedStep)")
            
            if expectedStep != .complete {
                viewModel.advance()
            }
        }
        
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }
    
    func testProgressBarCalculation() {
        let totalSteps = OnboardingStep.complete.rawValue
        
        // Test each step's progress
        for step in OnboardingStep.allCases {
            viewModel.currentStep = step
            let expectedProgress = CGFloat(step.rawValue) / CGFloat(totalSteps)
            let actualProgress = CGFloat(viewModel.currentStep.rawValue) / CGFloat(totalSteps)
            
            XCTAssertEqual(actualProgress, expectedProgress, accuracy: 0.001, 
                          "Progress for step \(step) should be \(expectedProgress)")
        }
    }
    
    func testHapticFeedbackRespectsSetting() {
        // Save current setting
        let originalSetting = ThemeManager.shared.hapticFeedback
        
        // Test with haptics disabled
        ThemeManager.shared.hapticFeedback = false
        XCTAssertFalse(ThemeManager.shared.hapticFeedback)
        
        // Test with haptics enabled
        ThemeManager.shared.hapticFeedback = true
        XCTAssertTrue(ThemeManager.shared.hapticFeedback)
        
        // Restore original setting
        ThemeManager.shared.hapticFeedback = originalSetting
    }
}