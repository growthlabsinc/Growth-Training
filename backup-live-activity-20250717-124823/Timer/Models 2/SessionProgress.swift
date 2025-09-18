//
//  SessionProgress.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

struct SessionProgress: Codable {
    let sessionId: String
    let sessionType: SessionType
    let methodId: String?
    let methodName: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var isPaused: Bool
    var pausedDuration: TimeInterval
    var stage: Int?
    var variation: String?
    
    // Multi-method properties
    var totalMethods: Int
    var completedMethods: Int
    var attemptedMethods: Int
    var methodDetails: [MethodDetail]
    
    // MARK: - Initialization
    init(sessionType: SessionType = .single,
         sessionId: String? = nil,
         methodId: String? = nil,
         methodName: String,
         startTime: Date = Date(),
         endTime: Date? = nil,
         totalMethods: Int = 1,
         completedMethods: Int = 0,
         attemptedMethods: Int = 0,
         methodDetails: [MethodDetail] = []) {
        self.sessionId = sessionId ?? UUID().uuidString
        self.sessionType = sessionType
        self.methodId = methodId
        self.methodName = methodName
        self.startTime = startTime
        self.endTime = endTime
        self.duration = 0
        self.isPaused = false
        self.pausedDuration = 0
        self.stage = nil
        self.variation = nil
        self.totalMethods = totalMethods
        self.completedMethods = completedMethods
        self.attemptedMethods = attemptedMethods
        self.methodDetails = methodDetails
    }
    
    // MARK: - Computed Properties
    var isComplete: Bool {
        return endTime != nil
    }
    
    var isPartiallyComplete: Bool {
        return sessionType == .multiMethod && completedMethods > 0 && completedMethods < totalMethods
    }
    
    var activeDuration: TimeInterval {
        return duration - pausedDuration
    }
    
    var totalElapsedTime: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(activeDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Methods
    func generateSummary() -> String {
        switch sessionType {
        case .single:
            return "Great job completing \(methodName)!"
        case .multiMethod:
            if completedMethods == totalMethods {
                return "Excellent! You completed all \(totalMethods) methods!"
            } else if completedMethods > 0 {
                return "Good effort! You completed \(completedMethods) of \(totalMethods) methods."
            } else {
                return "Session attempted. Keep practicing!"
            }
        case .quickPractice:
            return "Quick practice session completed!"
        case .freestyle:
            return "Freestyle session completed!"
        case .restDay:
            return "Rest day completed. Great job taking care of your recovery!"
        }
    }
}

// MARK: - Supporting Types
struct MethodDetail: Codable {
    let methodId: String
    let methodName: String
    let stage: String
    var started: Bool
    var completed: Bool
    var duration: TimeInterval
}