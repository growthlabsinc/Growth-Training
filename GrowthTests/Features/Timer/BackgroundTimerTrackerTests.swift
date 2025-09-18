//
//  BackgroundTimerTrackerTests.swift
//  GrowthTests
//
//  Created by Developer on 6/5/25.
//

import XCTest
@testable import Growth

class BackgroundTimerTrackerTests: XCTestCase {
    
    var tracker: BackgroundTimerTracker!
    var timerService: TimerService!
    
    override func setUp() {
        super.setUp()
        tracker = BackgroundTimerTracker.shared
        timerService = TimerService()
        
        // Clear any existing state
        tracker.clearSavedState()
    }
    
    override func tearDown() {
        tracker.clearSavedState()
        super.tearDown()
    }
    
    // MARK: - State Saving Tests
    
    func testSaveTimerState_WhenRunning_SavesCorrectly() {
        // Given
        timerService.currentMethodId = "test-method-123"
        timerService.configure(with: TimerConfiguration(
            isCountdown: false,
            hasIntervals: false,
            recommendedDurationSeconds: nil,
            maxRecommendedDurationSeconds: nil,
            intervals: nil
        ))
        timerService.start()
        
        // Wait a bit for timer to accumulate some time
        let expectation = XCTestExpectation(description: "Timer runs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        tracker.saveTimerState(from: timerService, methodName: "Test Method")
        
        // Then
        XCTAssertTrue(tracker.hasActiveBackgroundTimer())
        
        if let state = tracker.peekTimerState() {
            XCTAssertTrue(state.isRunning)
            XCTAssertEqual(state.methodId, "test-method-123")
            XCTAssertEqual(state.methodName, "Test Method")
            XCTAssertGreaterThan(state.elapsedTimeAtExit, 0)
            XCTAssertEqual(state.timerMode, .stopwatch)
        } else {
            XCTFail("No timer state saved")
        }
    }
    
    func testSaveTimerState_WhenNotRunning_DoesNotSave() {
        // Given
        timerService.configure(with: TimerConfiguration(
            isCountdown: false,
            hasIntervals: false,
            recommendedDurationSeconds: nil,
            maxRecommendedDurationSeconds: nil,
            intervals: nil
        ))
        // Timer not started
        
        // When
        tracker.saveTimerState(from: timerService)
        
        // Then
        XCTAssertFalse(tracker.hasActiveBackgroundTimer())
    }
    
    // MARK: - State Restoration Tests
    
    func testRestoreTimerState_RestoresElapsedTime() {
        // Given
        timerService.configure(with: TimerConfiguration(
            isCountdown: false,
            hasIntervals: false,
            recommendedDurationSeconds: nil,
            maxRecommendedDurationSeconds: nil,
            intervals: nil
        ))
        timerService.start()
        
        // Wait for some elapsed time
        let expectation = XCTestExpectation(description: "Timer runs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let originalElapsedTime = timerService.elapsedTime
        tracker.saveTimerState(from: timerService)
        
        // Simulate background time passing
        let backgroundExpectation = XCTestExpectation(description: "Background time")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            backgroundExpectation.fulfill()
        }
        wait(for: [backgroundExpectation], timeout: 1.0)
        
        // When
        let restoredState = tracker.restoreTimerState(to: timerService)
        
        // Then
        XCTAssertNotNil(restoredState)
        XCTAssertGreaterThan(timerService.elapsedTime, originalElapsedTime)
        XCTAssertFalse(tracker.hasActiveBackgroundTimer()) // State should be cleared after restore
    }
    
    func testRestoreTimerState_WithCountdownMode_CalculatesCorrectly() {
        // Given
        let countdownDuration: TimeInterval = 60 // 1 minute
        timerService.configure(with: TimerConfiguration(
            isCountdown: true,
            hasIntervals: false,
            recommendedDurationSeconds: Int(countdownDuration),
            maxRecommendedDurationSeconds: nil,
            intervals: nil
        ))
        timerService.start()
        
        // Wait for some time
        let expectation = XCTestExpectation(description: "Timer runs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        tracker.saveTimerState(from: timerService)
        
        // When
        let restoredState = tracker.restoreTimerState(to: timerService)
        
        // Then
        XCTAssertNotNil(restoredState)
        XCTAssertEqual(restoredState?.timerMode, .countdown)
        XCTAssertEqual(restoredState?.totalDuration, countdownDuration)
    }
    
    // MARK: - Notification Tests
    
    func testSaveTimerState_SchedulesNotifications() {
        // Given
        let notificationCenter = UNUserNotificationCenter.current()
        timerService.start()
        
        // When
        tracker.saveTimerState(from: timerService, methodName: "Test Session")
        
        // Then - Check pending notifications were scheduled
        let expectation = XCTestExpectation(description: "Check notifications")
        notificationCenter.getPendingNotificationRequests { requests in
            let timerNotifications = requests.filter { 
                $0.identifier.hasPrefix("timer_") || $0.identifier.hasPrefix("interval_")
            }
            XCTAssertGreaterThan(timerNotifications.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClearSavedState_CancelsNotifications() {
        // Given
        let notificationCenter = UNUserNotificationCenter.current()
        timerService.start()
        tracker.saveTimerState(from: timerService)
        
        // When
        tracker.clearSavedState()
        
        // Then
        let expectation = XCTestExpectation(description: "Check notifications cleared")
        notificationCenter.getPendingNotificationRequests { requests in
            let timerNotifications = requests.filter { 
                $0.identifier.hasPrefix("timer_") || $0.identifier.hasPrefix("interval_")
            }
            XCTAssertEqual(timerNotifications.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleStatesNotOverwritten() {
        // Given
        timerService.start()
        tracker.saveTimerState(from: timerService, methodName: "First Session")
        
        // When - Try to save another state
        let secondService = TimerService()
        secondService.start()
        tracker.saveTimerState(from: secondService, methodName: "Second Session")
        
        // Then - Second save should overwrite the first
        if let state = tracker.peekTimerState() {
            XCTAssertEqual(state.methodName, "Second Session")
        }
    }
}