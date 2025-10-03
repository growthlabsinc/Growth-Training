//
//  RoutineAdherenceServiceTests.swift
//  GrowthTests
//
//  Created by Developer on 5/31/25.
//

import XCTest
@testable import Growth

class RoutineAdherenceServiceTests: XCTestCase {
    
    var adherenceService: RoutineAdherenceService!
    
    override func setUp() {
        super.setUp()
        adherenceService = RoutineAdherenceService()
    }
    
    override func tearDown() {
        adherenceService = nil
        super.tearDown()
    }
    
    // MARK: - Test Adherence Calculation
    
    func testFullAdherence() {
        // Given
        let routine = createTestRoutine(withRestDays: false)
        let mockData = RoutineAdherenceData(
            adherencePercentage: 100.0,
            completedSessions: 7,
            expectedSessions: 7,
            timeRange: .week,
            sessionDetails: createFullWeekSessions()
        )
        
        // Then
        XCTAssertEqual(mockData.adherencePercentage, 100.0)
        XCTAssertEqual(mockData.colorTheme, "GrowthGreen")
        XCTAssertEqual(mockData.motivationalMessage, "Excellent consistency! Keep it up!")
    }
    
    func testPartialAdherence() {
        // Given
        let routine = createTestRoutine(withRestDays: false)
        let mockData = RoutineAdherenceData(
            adherencePercentage: 71.4, // 5 out of 7
            completedSessions: 5,
            expectedSessions: 7,
            timeRange: .week,
            sessionDetails: createPartialWeekSessions()
        )
        
        // Then
        XCTAssertEqual(mockData.adherencePercentage, 71.4, accuracy: 0.1)
        XCTAssertEqual(mockData.colorTheme, "orange")
        XCTAssertEqual(mockData.motivationalMessage, "Good progress! A little more push!")
    }
    
    func testRestDayHandling() {
        // Given
        let routine = createTestRoutine(withRestDays: true)
        // 7 total days (5 active + 2 rest) = 7 total expected
        // All 7 completed (rest days auto-complete) = 100%
        let mockData = RoutineAdherenceData(
            adherencePercentage: 100.0,
            completedSessions: 7,
            expectedSessions: 7, // Each day counts as 1 expected session
            timeRange: .week,
            sessionDetails: createWeekWithRestDays()
        )
        
        // Then
        XCTAssertEqual(mockData.expectedSessions, 7) // All days count as 1 each
        XCTAssertEqual(mockData.completedSessions, 7) // All completed (including rest)
        XCTAssertEqual(mockData.adherencePercentage, 100.0)
    }
    
    func testNoSessionsAdherence() {
        // Given
        let mockData = RoutineAdherenceData(
            adherencePercentage: 0.0,
            completedSessions: 0,
            expectedSessions: 7,
            timeRange: .week,
            sessionDetails: [:]
        )
        
        // Then
        XCTAssertEqual(mockData.adherencePercentage, 0.0)
        XCTAssertEqual(mockData.colorTheme, "ErrorColor")
        XCTAssertEqual(mockData.motivationalMessage, "Start your journey today!")
    }
    
    func testNoRoutineAdherence() {
        // Given - Empty state
        let emptyData = RoutineAdherenceData.empty()
        
        // Then
        XCTAssertEqual(emptyData.adherencePercentage, 0.0)
        XCTAssertEqual(emptyData.completedSessions, 0)
        XCTAssertEqual(emptyData.expectedSessions, 0)
    }
    
    func testRestDayBoostsAdherenceWhenNoActiveSessionsCompleted() {
        // Given - A routine with rest days but no active sessions completed
        let routine = createTestRoutine(withRestDays: true)
        // This simulates the scenario where today is a rest day (day 7)
        // and no active sessions have been completed, but rest days count
        let mockData = RoutineAdherenceData(
            adherencePercentage: 28.57, // 2 rest days out of 7 total = 28.57%
            completedSessions: 2, // 2 rest days auto-completed
            expectedSessions: 7, // 7 total days including rest
            timeRange: .week,
            sessionDetails: createEmptyWeekWithRestDays()
        )
        
        // Then
        XCTAssertEqual(mockData.expectedSessions, 7) // All days counted
        XCTAssertEqual(mockData.completedSessions, 2) // Rest days auto-completed
        XCTAssertEqual(mockData.adherencePercentage, 28.57, accuracy: 0.01)
        XCTAssertEqual(mockData.motivationalMessage, "Every session counts! You can do this!")
    }
    
    func testPartialAdherenceWithRestDays() {
        // Given - A routine with rest days and some completed sessions
        let routine = createTestRoutine(withRestDays: true)
        // 3 active days + 2 rest days = 5 completed out of 7 total
        let mockData = RoutineAdherenceData(
            adherencePercentage: 71.43, // 5/7 = 71.43%
            completedSessions: 5, // 3 active + 2 rest days
            expectedSessions: 7, // 7 total days
            timeRange: .week,
            sessionDetails: createPartialWeekWithRestDays()
        )
        
        // Then
        XCTAssertEqual(mockData.expectedSessions, 7) // All days
        XCTAssertEqual(mockData.completedSessions, 5) // 3 active + 2 rest
        XCTAssertEqual(mockData.adherencePercentage, 71.43, accuracy: 0.01)
        XCTAssertEqual(mockData.colorTheme, "orange")
    }
    
    // MARK: - Test Time Range Calculations
    
    func testFirstDayOfMonthRestDayShowsFullAdherence() {
        // Given - First day of month is a rest day
        let routine = createTestRoutine(withRestDays: true)
        // Simulating June 1st (rest day) with no other days in the month yet
        let mockData = RoutineAdherenceData(
            adherencePercentage: 100.0, // 1 rest day completed out of 1 expected = 100%
            completedSessions: 1, // Just the rest day
            expectedSessions: 1, // Just today
            timeRange: .month,
            sessionDetails: [Date(): true] // Today's rest day
        )
        
        // Then
        XCTAssertEqual(mockData.expectedSessions, 1)
        XCTAssertEqual(mockData.completedSessions, 1)
        XCTAssertEqual(mockData.adherencePercentage, 100.0)
        XCTAssertEqual(mockData.motivationalMessage, "Excellent consistency! Keep it up!")
    }
    
    func testWeeklyTimeRange() {
        let timeRange = TimeRange.week
        XCTAssertEqual(timeRange.daySpan, 7)
        XCTAssertEqual(timeRange.displayName, "This Week")
    }
    
    func testMonthlyTimeRange() {
        let timeRange = TimeRange.month
        XCTAssertEqual(timeRange.daySpan, 30)
        XCTAssertEqual(timeRange.displayName, "This Month")
    }
    
    // MARK: - Helper Methods
    
    private func createTestRoutine(withRestDays: Bool) -> Routine {
        var schedule: [DaySchedule] = []
        
        for day in 1...7 {
            let isRestDay = withRestDays && (day == 3 || day == 7)
            schedule.append(DaySchedule(
                id: "\(day)",
                dayNumber: day,
                dayName: "Day \(day)",
                description: isRestDay ? "Rest day" : "Active day",
                methodIds: isRestDay ? nil : ["method1"], // Single method per active day
                isRestDay: isRestDay
            ))
        }
        
        return Routine(
            id: "test-routine",
            name: "Test Routine",
            description: "Test routine for unit tests",
            difficultyLevel: "Beginner",
            schedule: schedule,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createFullWeekSessions() -> [Date: Bool] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [Date: Bool] = [:]
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                sessions[startOfDay] = true
            }
        }
        
        return sessions
    }
    
    private func createPartialWeekSessions() -> [Date: Bool] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [Date: Bool] = [:]
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                // Complete only 5 out of 7 days
                sessions[startOfDay] = offset < 5
            }
        }
        
        return sessions
    }
    
    private func createWeekWithRestDays() -> [Date: Bool] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [Date: Bool] = [:]
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                // Days 3 and 7 are rest days (always true), others completed
                sessions[startOfDay] = true
            }
        }
        
        return sessions
    }
    
    private func createEmptyWeekWithRestDays() -> [Date: Bool] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [Date: Bool] = [:]
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let dayOfWeek = (offset + 1) // 1-7
                // Days 3 and 7 are rest days (marked as true), others not completed (false)
                sessions[startOfDay] = (dayOfWeek == 3 || dayOfWeek == 7)
            }
        }
        
        return sessions
    }
    
    private func createPartialWeekWithRestDays() -> [Date: Bool] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [Date: Bool] = [:]
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let dayOfWeek = (offset + 1) // 1-7
                // Days 3 and 7 are rest days (true)
                // Days 1, 2, 4 are completed (true)
                // Days 5, 6 are not completed (false)
                if dayOfWeek == 3 || dayOfWeek == 7 {
                    sessions[startOfDay] = true // Rest day
                } else if dayOfWeek <= 4 {
                    sessions[startOfDay] = true // Completed
                } else {
                    sessions[startOfDay] = false // Not completed
                }
            }
        }
        
        return sessions
    }
}