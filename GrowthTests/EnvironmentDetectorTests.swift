//
//  EnvironmentDetectorTests.swift
//  GrowthTests
//
//  Created by Claude on 2025-06-25.
//

import XCTest
@testable import Growth

final class EnvironmentDetectorTests: XCTestCase {
    
    func testEnvironmentDetectionLogic() {
        // Note: These tests document the expected behavior
        // In actual unit tests, we can't easily mock Bundle.main.bundleIdentifier
        // but we can test the logic structure
        
        // Test that detectEnvironment returns a valid FirebaseEnvironment
        let environment = EnvironmentDetector.detectEnvironment()
        XCTAssertTrue([.development, .staging, .production].contains(environment))
    }
    
    func testConvenienceProperties() {
        // Test that only one environment is active at a time
        let isDev = EnvironmentDetector.isDevelopment
        let isStaging = EnvironmentDetector.isStaging
        let isProd = EnvironmentDetector.isProduction
        
        // Exactly one should be true
        let activeCount = [isDev, isStaging, isProd].filter { $0 }.count
        XCTAssertEqual(activeCount, 1, "Exactly one environment should be active")
    }
    
    func testCurrentEnvironmentDescription() {
        // Test that description includes both environment and bundle ID
        let description = EnvironmentDetector.currentEnvironmentDescription
        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("Bundle ID:"))
        
        // Check that it contains one of the environment names
        let containsEnvironment = description.contains("dev") || 
                                 description.contains("staging") || 
                                 description.contains("prod")
        XCTAssertTrue(containsEnvironment, "Description should contain environment name")
    }
}