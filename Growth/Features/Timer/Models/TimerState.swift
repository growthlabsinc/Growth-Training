//
//  TimerState.swift
//  Growth
//
//  Timer state enumeration
//

import Foundation

enum TimerState: String, Codable {
    case stopped = "stopped"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
}