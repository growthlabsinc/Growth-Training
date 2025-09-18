//
//  RoutineProgress.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import FirebaseFirestore

/// Tracks user progress through a routine
struct RoutineProgress: Codable {
    let userId: String
    let routineId: String
    var currentDayNumber: Int
    var startDate: Date
    var lastCompletedDate: Date?
    var completedDays: [Int]
    var skippedDays: [Int]
    var isCompleted: Bool
    var updatedAt: Date
    
    init(userId: String, routineId: String, startDate: Date = Date()) {
        self.userId = userId
        self.routineId = routineId
        self.currentDayNumber = 1
        self.startDate = startDate
        self.lastCompletedDate = nil
        self.completedDays = []
        self.skippedDays = []
        self.isCompleted = false
        self.updatedAt = Date()
    }
    
    /// Check if the routine is overdue (more than a day since last activity)
    var isOverdue: Bool {
        guard let lastCompleted = lastCompletedDate else {
            // If never completed, check against start date
            return Date().timeIntervalSince(startDate) > 86400 // 24 hours
        }
        return Date().timeIntervalSince(lastCompleted) > 86400
    }
    
    /// Calculate completion percentage
    var completionPercentage: Double {
        guard completedDays.count > 0 else { return 0 }
        let totalDays = currentDayNumber
        return Double(completedDays.count) / Double(totalDays) * 100
    }
    
    /// Mark current day as completed
    mutating func markDayCompleted() {
        if !completedDays.contains(currentDayNumber) {
            completedDays.append(currentDayNumber)
        }
        lastCompletedDate = Date()
        updatedAt = Date()
    }
    
    /// Skip current day
    mutating func skipDay() {
        if !skippedDays.contains(currentDayNumber) {
            skippedDays.append(currentDayNumber)
        }
        updatedAt = Date()
    }
    
    /// Move to next day
    mutating func advanceToNextDay() {
        currentDayNumber += 1
        updatedAt = Date()
    }
}