//
//  TimerState.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

enum TimerState: String, Codable {
    case stopped = "stopped"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    
    var isActive: Bool {
        return self == .running || self == .paused
    }
    
    var canStart: Bool {
        return self == .stopped || self == .completed
    }
    
    var canPause: Bool {
        return self == .running
    }
    
    var canResume: Bool {
        return self == .paused
    }
    
    var canStop: Bool {
        return self != .stopped
    }
}