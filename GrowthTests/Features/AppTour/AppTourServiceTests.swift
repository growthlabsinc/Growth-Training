import XCTest
@testable import Growth

class AppTourServiceTests: XCTestCase {
    var service: AppTourService!
    
    override func setUp() {
        super.setUp()
        service = AppTourService.shared
        // Reset state for testing
        service.resetTourState()
    }
    
    override func tearDown() {
        service.resetTourState()
        service = nil
        super.tearDown()
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() {
        XCTAssertFalse(service.hasCompletedTour)
        XCTAssertFalse(service.hasSeenTour)
        XCTAssertTrue(service.shouldShowTour())
    }
    
    func testShouldShowTourLogic() {
        // Initial state - should show tour
        XCTAssertTrue(service.shouldShowTour())
        
        // After marking as seen
        service.markTourStarted()
        XCTAssertFalse(service.shouldShowTour())
        
        // Reset and mark as completed
        service.resetTourState()
        service.markTourCompleted()
        XCTAssertFalse(service.shouldShowTour())
    }
    
    // MARK: - Tour State Updates
    
    func testMarkTourStarted() {
        service.markTourStarted()
        
        XCTAssertTrue(service.hasSeenTour)
        XCTAssertFalse(service.hasCompletedTour)
        
        // Verify UserDefaults persistence
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenAppTour"))
    }
    
    func testMarkTourCompleted() {
        service.markTourCompleted()
        
        XCTAssertTrue(service.hasCompletedTour)
        XCTAssertTrue(service.hasSeenTour)
        
        // Verify UserDefaults persistence
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedAppTour"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenAppTour"))
    }
    
    func testMarkTourSkipped() {
        service.markTourSkipped()
        
        XCTAssertTrue(service.hasSeenTour)
        XCTAssertFalse(service.hasCompletedTour)
        
        // Verify UserDefaults persistence
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenAppTour"))
    }
    
    // MARK: - Reset Tests
    
    func testResetTourState() {
        // Set some state
        service.markTourCompleted()
        XCTAssertTrue(service.hasCompletedTour)
        XCTAssertTrue(service.hasSeenTour)
        
        // Reset
        service.resetTourState()
        
        // Verify reset
        XCTAssertFalse(service.hasCompletedTour)
        XCTAssertFalse(service.hasSeenTour)
        XCTAssertTrue(service.shouldShowTour())
        
        // Verify UserDefaults cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedAppTour"))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasSeenAppTour"))
    }
    
    // MARK: - Configuration Tests
    
    func testGetTourConfiguration() {
        let config = service.getTourConfiguration()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(config.allowSkip)
        XCTAssertTrue(config.showProgress)
        // Steps will be empty until stories 20.2-20.6
        XCTAssertEqual(config.steps.count, 0)
    }
}