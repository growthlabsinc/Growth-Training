//
//  SessionType.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

public enum SessionType: String, Codable {
    case single = "single"
    case multiMethod = "multi"
    case quickPractice = "quick"
    case freestyle = "freestyle"
    case restDay = "rest"
    
    // Timer-specific session types for Live Activity
    case countdown = "countdown"
    case countup = "countup"
    case interval = "interval"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .single:
            return "Single Method"
        case .multiMethod:
            return "Multi-Method Session"
        case .quickPractice:
            return "Quick Practice"
        case .freestyle:
            return "Freestyle Session"
        case .restDay:
            return "Rest Day"
        case .countdown:
            return "Countdown Timer"
        case .countup:
            return "Stopwatch Timer"
        case .interval:
            return "Interval Timer"
        case .completed:
            return "Completed"
        }
    }
}