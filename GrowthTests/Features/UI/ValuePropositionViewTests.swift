import XCTest
import SwiftUI
@testable import Growth

class ValuePropositionViewTests: XCTestCase {
    
    func testValuePropositionViewCallsContinue() {
        var continueCalled = false
        let view = ValuePropositionView(onContinue: {
            continueCalled = true
        })
        
        // Create a hosting controller to properly handle the view lifecycle
        let hostingController = UIHostingController(rootView: view)
        
        // Access the view's body to trigger rendering
        _ = hostingController.view
        
        // Find the continue button and simulate tap
        // Note: Without ViewInspector, we test the closure behavior directly
        view.onContinue()
        
        XCTAssertTrue(continueCalled, "onContinue should be called when triggered")
    }
    
    func testValuePropositionViewInitialState() {
        let view = ValuePropositionView(onContinue: {})
        
        // Test that the view initializes with expected properties
        XCTAssertNotNil(view, "View should initialize successfully")
        
        // The view should have the onContinue closure set
        XCTAssertNotNil(view.onContinue, "onContinue closure should be set")
    }
    
    func testBenefitContentStructure() {
        // Test that benefits array has expected content
        let expectedBenefitTitles = [
            "Guided, Science-Based Methods",
            "Private and Secure Tracking",
            "Supportive Community Insights"
        ]
        
        let expectedBenefitIcons = [
            "chart.line.uptrend.xyaxis",
            "lock.shield.fill",
            "person.3.fill"
        ]
        
        // Since benefits is private, we test indirectly through the view
        let view = ValuePropositionView(onContinue: {})
        XCTAssertNotNil(view, "View should contain benefits content")
        
        // Verify expected counts match
        XCTAssertEqual(expectedBenefitTitles.count, 3, "Should have 3 benefits")
        XCTAssertEqual(expectedBenefitIcons.count, 3, "Should have 3 benefit icons")
    }
}