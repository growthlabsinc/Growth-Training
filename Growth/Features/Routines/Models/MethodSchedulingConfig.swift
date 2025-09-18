//
//  MethodSchedulingConfig.swift
//  Growth
//
//  Shared model for method scheduling configuration
//

import Foundation

struct MethodSchedulingConfig {
    let methodId: String
    var selectedDays: Set<Int> = [] // 1-based day numbers for sequential, or weekday numbers for weekday scheduling
    var frequency: ScheduleFrequency = .everyDay
    var duration: Int = 20 // Duration in minutes
    
    enum ScheduleFrequency: String, CaseIterable {
        case everyDay = "Every day"
        case everyOtherDay = "Every other day"
        case every2Days = "Every 2 days"
        case every3Days = "Every 3 days"
        case custom = "Custom days"
    }
}