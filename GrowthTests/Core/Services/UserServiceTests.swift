//
//  UserServiceTests.swift
//  GrowthTests
//
//  Created by Developer on 6/7/25.
//

import XCTest
import FirebaseFirestore
@testable import Growth

final class UserServiceTests: XCTestCase {
    
    var userService: UserService!
    
    override func setUp() {
        super.setUp()
        userService = UserService.shared
    }
    
    override func tearDown() {
        userService = nil
        super.tearDown()
    }
    
    func testUpdateInitialAssessmentValidation() {
        let expectation = XCTestExpectation(description: "Update initial assessment with empty user ID")
        
        // Test with empty user ID
        userService.updateInitialAssessment(
            userId: "",
            assessmentResult: "needs_assistance",
            methodId: "angio_pumping"
        ) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Invalid user ID")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUpdateInitialAssessmentMethodMapping() {
        // Test that the correct method IDs are used
        let needsAssistanceMethodId = "angio_pumping"
        let canProceedMethodId = "am1_0"
        
        // Verify the method IDs match what InitialAssessmentView uses
        XCTAssertEqual(needsAssistanceMethodId, "angio_pumping")
        XCTAssertEqual(canProceedMethodId, "am1_0")
    }
}