//
//  InsightGenerationServiceTests.swift
//  GrowthTests
//
//  Created by Developer on 5/31/25.
//

import XCTest
@testable import Growth

class InsightGenerationServiceTests: XCTestCase {
    
    var sut: InsightGenerationService!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        sut = InsightGenerationService()
        calendar = Calendar.current
    }
    
    override func tearDown() {
        sut = nil
        calendar = nil
        super.tearDown()
    }
    
    // MARK: - Trend Insight Tests
    
    func testGeneratesTrendPositiveInsight() {
        // Given
        let today = calendar.startOfDay(for: Date())
        var dailyMinutes: [Date: Int] = [:]
        
        // Current week: 200 minutes total
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 30
            }
        }
        
        // Previous week: 150 minutes total (25% increase)
        for i in 7..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 20
            }
        }
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: dailyMinutes,
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .trendPositive })
        if let trendInsight = insights.first(where: { $0.type == .trendPositive }) {
            XCTAssertTrue(trendInsight.message.contains("increased"))
            XCTAssertEqual(trendInsight.priority, 90)
        }
    }
    
    func testGeneratesTrendNegativeInsight() {
        // Given
        let today = calendar.startOfDay(for: Date())
        var dailyMinutes: [Date: Int] = [:]
        
        // Current week: 100 minutes total
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 15
            }
        }
        
        // Previous week: 200 minutes total (50% decrease)
        for i in 7..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 30
            }
        }
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: dailyMinutes,
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .trendNegative })
        if let trendInsight = insights.first(where: { $0.type == .trendNegative }) {
            XCTAssertTrue(trendInsight.message.contains("decreased"))
            XCTAssertEqual(trendInsight.actionText, "Schedule Session")
        }
    }
    
    // MARK: - Adherence Insight Tests
    
    func testGeneratesHighAdherenceInsight() {
        // Given
        let adherenceData = RoutineAdherenceData(
            adherencePercentage: 95,
            completedSessions: 9,
            expectedSessions: 10,
            timeRange: .week,
            sessionDetails: [:]
        )
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: [:],
            adherenceData: adherenceData
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .adherenceHigh })
        if let adherenceInsight = insights.first(where: { $0.type == .adherenceHigh }) {
            XCTAssertTrue(adherenceInsight.message.contains("95%"))
        }
    }
    
    func testGeneratesLowAdherenceInsight() {
        // Given
        let adherenceData = RoutineAdherenceData(
            adherencePercentage: 40,
            completedSessions: 4,
            expectedSessions: 10,
            timeRange: .week,
            sessionDetails: [:]
        )
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: [:],
            adherenceData: adherenceData
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .adherenceLow })
        if let adherenceInsight = insights.first(where: { $0.type == .adherenceLow }) {
            XCTAssertTrue(adherenceInsight.message.contains("40%"))
            XCTAssertEqual(adherenceInsight.actionText, "View Routine")
        }
    }
    
    // MARK: - Streak Insight Tests
    
    func testGeneratesStreakMilestoneInsight() {
        // Given
        let statistics = [
            StatisticHighlight(
                title: "Current Streak",
                value: "7",
                subtitle: "days",
                iconName: "flame.fill"
            )
        ]
        
        let overviewData = ProgressOverviewData(statistics: statistics)
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: [:],
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .streakMilestone })
        if let streakInsight = insights.first(where: { $0.type == .streakMilestone }) {
            XCTAssertTrue(streakInsight.title.contains("7-Day Streak"))
            XCTAssertEqual(streakInsight.priority, 95)
        }
    }
    
    // MARK: - Consistency Pattern Tests
    
    func testGeneratesConsistencyPatternInsight() {
        // Given
        let today = calendar.startOfDay(for: Date())
        var dailyMinutes: [Date: Int] = [:]
        
        // Practice 25 out of 30 days
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                if i % 7 != 6 { // Skip one day per week
                    dailyMinutes[date] = 20
                }
            }
        }
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: dailyMinutes,
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .consistencyPattern })
        if let consistencyInsight = insights.first(where: { $0.type == .consistencyPattern }) {
            XCTAssertTrue(consistencyInsight.message.contains("25 out of the last 30 days"))
        }
    }
    
    // MARK: - Inactivity Warning Tests
    
    func testGeneratesInactivityWarningForExtendedBreak() {
        // Given
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let sessionLog = SessionLog(
            id: "test-session",
            userId: "test-user",
            duration: 20,
            startTime: sevenDaysAgo,
            endTime: calendar.date(byAdding: .minute, value: 20, to: sevenDaysAgo)!
        )
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [sessionLog],
            dailyMinutes: [:],
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .inactivityWarning })
        if let inactivityInsight = insights.first(where: { $0.type == .inactivityWarning }) {
            XCTAssertTrue(inactivityInsight.message.contains("7 days"))
            XCTAssertEqual(inactivityInsight.actionText, "Start Practice")
            XCTAssertEqual(inactivityInsight.priority, 92)
        }
    }
    
    func testGeneratesInactivityWarningForShortBreak() {
        // Given
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let sessionLog = SessionLog(
            id: "test-session",
            userId: "test-user",
            duration: 20,
            startTime: threeDaysAgo,
            endTime: calendar.date(byAdding: .minute, value: 20, to: threeDaysAgo)!
        )
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [sessionLog],
            dailyMinutes: [:],
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.contains { $0.type == .inactivityWarning })
        if let inactivityInsight = insights.first(where: { $0.type == .inactivityWarning }) {
            XCTAssertTrue(inactivityInsight.message.contains("3 days"))
            XCTAssertEqual(inactivityInsight.actionText, "Quick Practice")
        }
    }
    
    // MARK: - Priority and Limit Tests
    
    func testLimitsInsightsToTopThree() {
        // Given - Create conditions for multiple insights
        let today = calendar.startOfDay(for: Date())
        var dailyMinutes: [Date: Int] = [:]
        
        // Setup for trend positive, consistency, and streak insights
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 30
            }
        }
        
        let statistics = [
            StatisticHighlight(
                title: "Current Streak",
                value: "30",
                subtitle: "days",
                iconName: "flame.fill"
            )
        ]
        
        let adherenceData = RoutineAdherenceData(
            adherencePercentage: 95,
            completedSessions: 9,
            expectedSessions: 10,
            timeRange: .week,
            sessionDetails: [:]
        )
        
        let overviewData = ProgressOverviewData(statistics: statistics)
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: dailyMinutes,
            adherenceData: adherenceData
        )
        
        // Then
        XCTAssertLessThanOrEqual(insights.count, 3)
        // Verify they are sorted by priority
        for i in 1..<insights.count {
            XCTAssertGreaterThanOrEqual(insights[i-1].priority, insights[i].priority)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testHandlesEmptyData() {
        // Given
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: [:],
            adherenceData: nil
        )
        
        // Then
        XCTAssertTrue(insights.isEmpty)
    }
    
    func testHandlesInsufficientDataForTrends() {
        // Given - Only current week data
        let today = calendar.startOfDay(for: Date())
        var dailyMinutes: [Date: Int] = [:]
        
        for i in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyMinutes[date] = 20
            }
        }
        
        let overviewData = ProgressOverviewData()
        
        // When
        let insights = sut.generateInsights(
            from: overviewData,
            sessionLogs: [],
            dailyMinutes: dailyMinutes,
            adherenceData: nil
        )
        
        // Then
        // Should not generate trend insights without previous week data
        XCTAssertFalse(insights.contains { $0.type == .trendPositive || $0.type == .trendNegative })
    }
}