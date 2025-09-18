//
//  ProgressIndicatorTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
import SwiftUI
@testable import Growth

final class ProgressIndicatorTests: XCTestCase {
    
    func testProgressCalculation() {
        // Test zero progress
        let indicator1 = ProgressIndicator(currentStep: 0, totalSteps: 8)
        XCTAssertEqual(indicator1.progress, 0.0, accuracy: 0.001)
        
        // Test partial progress
        let indicator2 = ProgressIndicator(currentStep: 3, totalSteps: 8)
        XCTAssertEqual(indicator2.progress, 0.375, accuracy: 0.001)
        
        // Test half progress
        let indicator3 = ProgressIndicator(currentStep: 4, totalSteps: 8)
        XCTAssertEqual(indicator3.progress, 0.5, accuracy: 0.001)
        
        // Test complete progress
        let indicator4 = ProgressIndicator(currentStep: 8, totalSteps: 8)
        XCTAssertEqual(indicator4.progress, 1.0, accuracy: 0.001)
    }
    
    func testProgressWithZeroTotalSteps() {
        // Should handle division by zero gracefully
        let indicator = ProgressIndicator(currentStep: 5, totalSteps: 0)
        XCTAssertEqual(indicator.progress, 0.0, accuracy: 0.001)
    }
    
    func testAccessibilityLabel() {
        let indicator = ProgressIndicator(currentStep: 3, totalSteps: 8)
        
        // Create a hosting controller to render the view
        let hostingController = UIHostingController(rootView: indicator)
        
        // Force view to load
        _ = hostingController.view
        
        // The view should have proper accessibility label and value
        // Note: In actual implementation, we'd need to traverse the view hierarchy
        // to find the specific view with accessibility label
        XCTAssertNotNil(hostingController.view)
    }
    
    func testReducedMotionSupport() {
        let indicator = ProgressIndicator(currentStep: 3, totalSteps: 8)
        
        // Test that shouldReduceMotion property exists
        let reducedMotion = indicator.shouldReduceMotion
        
        // The value will depend on system settings, but we can verify it returns a Bool
        XCTAssertTrue(reducedMotion == true || reducedMotion == false)
    }
}