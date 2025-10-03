import XCTest
@testable import Growth

class AppTourConfigurationTests: XCTestCase {
    
    // MARK: - Dashboard Tour Tests (Story 20.2)
    
    func testDefaultTourConfiguration() {
        let config = AppTourConfiguration.defaultTour
        
        // Test configuration properties
        XCTAssertTrue(config.allowSkip)
        XCTAssertTrue(config.showProgress)
        XCTAssertEqual(config.steps.count, 2)
    }
    
    func testDashboardTourSteps() {
        let config = AppTourConfiguration.defaultTour
        let steps = config.steps
        
        // Verify we have exactly 2 steps for dashboard tour
        XCTAssertEqual(steps.count, 2)
        
        // Test dashboard overview step
        let dashboardStep = steps[0]
        XCTAssertEqual(dashboardStep.id, "dashboard_overview")
        XCTAssertEqual(dashboardStep.targetViewId, "dashboard_title")
        XCTAssertEqual(dashboardStep.title, "Welcome to Your Dashboard")
        XCTAssertEqual(dashboardStep.description, "This is your Home screen, your starting point for each day. Your 'Today's Focus' shows you exactly what to do.")
        XCTAssertEqual(dashboardStep.highlightPadding, 20)
        XCTAssertEqual(dashboardStep.position, .below)
        XCTAssertEqual(dashboardStep.buttonTitle, "Next")
        XCTAssertFalse(dashboardStep.isLastStep)
        
        // Test weekly progress step
        let progressStep = steps[1]
        XCTAssertEqual(progressStep.id, "weekly_progress")
        XCTAssertEqual(progressStep.targetViewId, "weekly_progress_snapshot")
        XCTAssertEqual(progressStep.title, "Track Your Progress")
        XCTAssertEqual(progressStep.description, "Quickly check your weekly progress and streak right here.")
        XCTAssertEqual(progressStep.highlightPadding, 20)
        XCTAssertEqual(progressStep.position, .above)
        XCTAssertEqual(progressStep.buttonTitle, "Get Started")
        XCTAssertTrue(progressStep.isLastStep)
    }
    
    func testTourStepEquality() {
        let step1 = AppTourStep(
            id: "test",
            targetViewId: "test_view",
            title: "Test",
            description: "Test description"
        )
        
        let step2 = AppTourStep(
            id: "test",
            targetViewId: "test_view",
            title: "Test",
            description: "Test description"
        )
        
        let step3 = AppTourStep(
            id: "different",
            targetViewId: "test_view",
            title: "Test",
            description: "Test description"
        )
        
        XCTAssertEqual(step1, step2)
        XCTAssertNotEqual(step1, step3)
    }
    
    func testPopoverPositions() {
        // Test all popover position cases
        let automatic = PopoverPosition.automatic
        let above = PopoverPosition.above
        let below = PopoverPosition.below
        let leading = PopoverPosition.leading
        let trailing = PopoverPosition.trailing
        let custom = PopoverPosition.custom(x: 10, y: 20)
        
        // Ensure they're all different
        XCTAssertNotEqual(automatic, above)
        XCTAssertNotEqual(above, below)
        XCTAssertNotEqual(below, leading)
        XCTAssertNotEqual(leading, trailing)
        XCTAssertNotEqual(trailing, custom)
    }
}