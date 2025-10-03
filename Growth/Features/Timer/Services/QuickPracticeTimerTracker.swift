//
//  QuickPracticeTimerTracker.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import Combine

/// Tracks active quick practice timers to prevent multiple timers running simultaneously
class QuickPracticeTimerTracker: ObservableObject {
    static let shared = QuickPracticeTimerTracker()
    
    @Published private(set) var activeTimerId: String?
    @Published private(set) var isTimerActive: Bool = false
    
    private init() {}
    
    /// Register a timer as active
    func startTimer(withId id: String) {
        activeTimerId = id
        isTimerActive = true
    }
    
    /// Mark timer as stopped
    func stopTimer() {
        activeTimerId = nil
        isTimerActive = false
    }
    
    /// Check if a specific timer is currently active
    func isTimer(withId id: String, active: Bool) -> Bool {
        return isTimerActive && activeTimerId == id
    }
    
    /// Check if any timer other than the specified one is active
    func hasActiveTimerOtherThan(id: String) -> Bool {
        return isTimerActive && activeTimerId != id
    }
}