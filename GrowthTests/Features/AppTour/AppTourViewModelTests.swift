import XCTest
import Combine
@testable import Growth

class AppTourViewModelTests: XCTestCase {
    var viewModel: AppTourViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = AppTourViewModel()
        cancellables = []
        
        // Reset tour state for testing
        AppTourService.shared.resetTourState()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Tour Initialization Tests
    
    func testTourInitialization() {
        XCTAssertFalse(viewModel.isActive)
        XCTAssertEqual(viewModel.currentStepIndex, 0)
        XCTAssertTrue(viewModel.targetFrames.isEmpty)
    }
    
    func testCurrentStepReturnsNilWhenNoSteps() {
        // Create a configuration with no steps
        viewModel.configuration = AppTourConfiguration(steps: [])
        XCTAssertNil(viewModel.currentStep)
    }
    
    // MARK: - Tour Navigation Tests
    
    func testStartTour() {
        viewModel.startTour()
        
        XCTAssertTrue(viewModel.isActive)
        XCTAssertEqual(viewModel.currentStepIndex, 0)
    }
    
    func testNextStepAdvancesIndex() {
        // Setup test configuration with multiple steps
        let steps = [
            AppTourStep(id: "1", targetViewId: "view1", title: "Step 1", description: "Description 1"),
            AppTourStep(id: "2", targetViewId: "view2", title: "Step 2", description: "Description 2"),
            AppTourStep(id: "3", targetViewId: "view3", title: "Step 3", description: "Description 3")
        ]
        viewModel.configuration = AppTourConfiguration(steps: steps)
        viewModel.startTour()
        
        // Test advancing through steps
        XCTAssertEqual(viewModel.currentStepIndex, 0)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStepIndex, 1)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStepIndex, 2)
    }
    
    func testNextStepOnLastStepCompletesTour() {
        let steps = [
            AppTourStep(id: "1", targetViewId: "view1", title: "Step 1", description: "Description 1")
        ]
        viewModel.configuration = AppTourConfiguration(steps: steps)
        viewModel.startTour()
        
        XCTAssertTrue(viewModel.isActive)
        
        viewModel.nextStep()
        XCTAssertFalse(viewModel.isActive)
    }
    
    func testPreviousStep() {
        let steps = [
            AppTourStep(id: "1", targetViewId: "view1", title: "Step 1", description: "Description 1"),
            AppTourStep(id: "2", targetViewId: "view2", title: "Step 2", description: "Description 2")
        ]
        viewModel.configuration = AppTourConfiguration(steps: steps)
        viewModel.startTour()
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStepIndex, 1)
        
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStepIndex, 0)
        
        // Test that previous step doesn't go below 0
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStepIndex, 0)
    }
    
    // MARK: - Tour Skip/Complete Tests
    
    func testSkipTour() {
        viewModel.startTour()
        XCTAssertTrue(viewModel.isActive)
        
        viewModel.skipTour()
        XCTAssertFalse(viewModel.isActive)
    }
    
    func testCompleteTour() {
        viewModel.startTour()
        XCTAssertTrue(viewModel.isActive)
        
        viewModel.completeTour()
        XCTAssertFalse(viewModel.isActive)
    }
    
    // MARK: - Progress Tests
    
    func testProgressText() {
        let steps = [
            AppTourStep(id: "1", targetViewId: "view1", title: "Step 1", description: "Description 1"),
            AppTourStep(id: "2", targetViewId: "view2", title: "Step 2", description: "Description 2"),
            AppTourStep(id: "3", targetViewId: "view3", title: "Step 3", description: "Description 3")
        ]
        viewModel.configuration = AppTourConfiguration(steps: steps)
        
        XCTAssertEqual(viewModel.progressText, "Step 1 of 3")
        
        viewModel.currentStepIndex = 1
        XCTAssertEqual(viewModel.progressText, "Step 2 of 3")
        
        viewModel.currentStepIndex = 2
        XCTAssertEqual(viewModel.progressText, "Step 3 of 3")
    }
    
    func testProgressPercentage() {
        let steps = [
            AppTourStep(id: "1", targetViewId: "view1", title: "Step 1", description: "Description 1"),
            AppTourStep(id: "2", targetViewId: "view2", title: "Step 2", description: "Description 2"),
            AppTourStep(id: "3", targetViewId: "view3", title: "Step 3", description: "Description 3"),
            AppTourStep(id: "4", targetViewId: "view4", title: "Step 4", description: "Description 4")
        ]
        viewModel.configuration = AppTourConfiguration(steps: steps)
        
        XCTAssertEqual(viewModel.progressPercentage, 0.25, accuracy: 0.001)
        
        viewModel.currentStepIndex = 1
        XCTAssertEqual(viewModel.progressPercentage, 0.5, accuracy: 0.001)
        
        viewModel.currentStepIndex = 3
        XCTAssertEqual(viewModel.progressPercentage, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Target Frame Tests
    
    func testUpdateTargetFrame() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)
        viewModel.updateTargetFrame(for: "testView", frame: frame)
        
        XCTAssertEqual(viewModel.targetFrames["testView"], frame)
    }
    
    func testCurrentTargetFrame() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let step = AppTourStep(id: "1", targetViewId: "testView", title: "Step 1", description: "Description 1")
        viewModel.configuration = AppTourConfiguration(steps: [step])
        viewModel.updateTargetFrame(for: "testView", frame: frame)
        
        XCTAssertEqual(viewModel.currentTargetFrame, frame)
    }
    
    func testIsHighlighted() {
        let step = AppTourStep(id: "1", targetViewId: "testView", title: "Step 1", description: "Description 1")
        viewModel.configuration = AppTourConfiguration(steps: [step])
        viewModel.startTour()
        
        XCTAssertTrue(viewModel.isHighlighted(viewId: "testView"))
        XCTAssertFalse(viewModel.isHighlighted(viewId: "otherView"))
        
        // Test when tour is not active
        viewModel.isActive = false
        XCTAssertFalse(viewModel.isHighlighted(viewId: "testView"))
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationWithoutProgress() {
        viewModel.configuration = AppTourConfiguration(steps: [], showProgress: false)
        XCTAssertEqual(viewModel.progressText, "")
    }
    
    // MARK: - Dashboard Tour Tests (Story 20.2)
    
    func testDefaultTourContainsDashboardSteps() {
        let defaultTour = AppTourConfiguration.defaultTour
        
        XCTAssertEqual(defaultTour.steps.count, 2)
        
        // Test first step - Dashboard overview
        let step1 = defaultTour.steps[0]
        XCTAssertEqual(step1.id, "dashboard_overview")
        XCTAssertEqual(step1.targetViewId, "dashboard_title")
        XCTAssertEqual(step1.title, "Welcome to Your Dashboard")
        XCTAssertTrue(step1.description.contains("Home screen"))
        XCTAssertEqual(step1.position, .below)
        XCTAssertFalse(step1.isLastStep)
        
        // Test second step - Weekly progress
        let step2 = defaultTour.steps[1]
        XCTAssertEqual(step2.id, "weekly_progress")
        XCTAssertEqual(step2.targetViewId, "weekly_progress_snapshot")
        XCTAssertEqual(step2.title, "Track Your Progress")
        XCTAssertTrue(step2.description.contains("weekly progress"))
        XCTAssertEqual(step2.position, .above)
        XCTAssertTrue(step2.isLastStep)
        XCTAssertEqual(step2.buttonTitle, "Get Started")
    }
    
    func testDashboardTourStepsHaveUniqueIds() {
        let defaultTour = AppTourConfiguration.defaultTour
        let stepIds = defaultTour.steps.map { $0.id }
        let uniqueIds = Set(stepIds)
        
        XCTAssertEqual(stepIds.count, uniqueIds.count, "Tour steps should have unique IDs")
    }
    
    func testDashboardTourStepOrder() {
        let defaultTour = AppTourConfiguration.defaultTour
        
        // Ensure dashboard overview comes before weekly progress
        if defaultTour.steps.count >= 2 {
            XCTAssertEqual(defaultTour.steps[0].id, "dashboard_overview")
            XCTAssertEqual(defaultTour.steps[1].id, "weekly_progress")
        }
    }
}