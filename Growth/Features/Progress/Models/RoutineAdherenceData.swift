//
//  RoutineAdherenceData.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import Foundation

/// Model representing routine adherence metrics
struct RoutineAdherenceData: Codable {
    /// Adherence percentage (0-100)
    let adherencePercentage: Double
    
    /// Number of completed sessions
    let completedSessions: Int
    
    /// Number of expected sessions
    let expectedSessions: Int
    
    /// Time range for the adherence calculation
    let timeRange: TimeRange
    
    /// Detailed session completion status by date
    let sessionDetails: [Date: Bool]
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case adherencePercentage
        case completedSessions
        case expectedSessions
        case timeRange
        case sessionDetails
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adherencePercentage = try container.decode(Double.self, forKey: .adherencePercentage)
        completedSessions = try container.decode(Int.self, forKey: .completedSessions)
        expectedSessions = try container.decode(Int.self, forKey: .expectedSessions)
        timeRange = try container.decode(TimeRange.self, forKey: .timeRange)
        
        // Decode sessionDetails from array of date strings to [Date: Bool]
        let sessionDetailsData = try container.decode([String: Bool].self, forKey: .sessionDetails)
        var decodedSessionDetails: [Date: Bool] = [:]
        let formatter = ISO8601DateFormatter()
        
        for (dateString, value) in sessionDetailsData {
            if let date = formatter.date(from: dateString) {
                decodedSessionDetails[date] = value
            }
        }
        sessionDetails = decodedSessionDetails
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adherencePercentage, forKey: .adherencePercentage)
        try container.encode(completedSessions, forKey: .completedSessions)
        try container.encode(expectedSessions, forKey: .expectedSessions)
        try container.encode(timeRange, forKey: .timeRange)
        
        // Encode sessionDetails from [Date: Bool] to array of date strings
        let formatter = ISO8601DateFormatter()
        var encodedSessionDetails: [String: Bool] = [:]
        
        for (date, value) in sessionDetails {
            let dateString = formatter.string(from: date)
            encodedSessionDetails[dateString] = value
        }
        try container.encode(encodedSessionDetails, forKey: .sessionDetails)
    }
    
    // MARK: - Computed Properties
    
    /// Color theme based on adherence percentage
    var colorTheme: String {
        if adherencePercentage >= 80 {
            return "GrowthGreen"
        } else if adherencePercentage >= 60 {
            return "orange"
        } else {
            return "ErrorColor"
        }
    }
    
    /// Motivational message based on adherence level
    var motivationalMessage: String {
        if adherencePercentage >= 80 {
            return "Excellent consistency! Keep it up!"
        } else if adherencePercentage >= 60 {
            return "Good progress! A little more push!"
        } else if adherencePercentage > 0 {
            return "Every session counts! You can do this!"
        } else {
            return "Start your journey today!"
        }
    }
    
    /// Formatted percentage string
    var formattedPercentage: String {
        String(format: "%.0f", adherencePercentage)
    }
    
    /// Progress description
    var progressDescription: String {
        "\(completedSessions) of \(expectedSessions) sessions"
    }
    
    // MARK: - Initialization
    
    init(
        adherencePercentage: Double,
        completedSessions: Int,
        expectedSessions: Int,
        timeRange: TimeRange,
        sessionDetails: [Date: Bool]
    ) {
        self.adherencePercentage = adherencePercentage
        self.completedSessions = completedSessions
        self.expectedSessions = expectedSessions
        self.timeRange = timeRange
        self.sessionDetails = sessionDetails
    }
    
    // MARK: - Empty State
    
    /// Returns an empty adherence data for initial states
    static func empty(timeRange: TimeRange = .week) -> RoutineAdherenceData {
        return RoutineAdherenceData(
            adherencePercentage: 0,
            completedSessions: 0,
            expectedSessions: 0,
            timeRange: timeRange,
            sessionDetails: [:]
        )
    }
}