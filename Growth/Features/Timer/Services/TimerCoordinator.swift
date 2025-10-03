//
//  TimerCoordinator.swift
//  Growth
//
//  Coordinates timer instances to ensure only one timer runs at a time
//

import Foundation
import Combine

/// Coordinates timer instances to prevent multiple timers running simultaneously
class TimerCoordinator {
    static let shared = TimerCoordinator()
    
    private var activeTimerType: String?
    private let lock = NSLock()
    
    private init() {}
    
    /// Check if a timer of the given type can start
    func canStartTimer(type: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        print("TimerCoordinator: canStartTimer('\(type)') called - current activeTimerType: '\(activeTimerType ?? "nil")'")
        
        // If no timer is active, we can start
        if activeTimerType == nil {
            // Don't set activeTimerType here - wait for timerStarted() to be called
            print("TimerCoordinator: Timer '\(type)' can start - no active timer")
            return true
        }
        
        // If the same timer type is already active, allow it (resuming)
        if activeTimerType == type {
            print("TimerCoordinator: Timer '\(type)' can start - same type already active (resuming)")
            return true
        }
        
        // Different timer is active, cannot start
        print("TimerCoordinator: Timer '\(type)' cannot start - '\(activeTimerType ?? "unknown")' is active")
        return false
    }
    
    /// Register that a timer has started
    func timerStarted(type: String) {
        lock.lock()
        defer { lock.unlock() }
        
        activeTimerType = type
        print("TimerCoordinator: Timer '\(type)' started")
    }
    
    /// Register that a timer has stopped
    func timerStopped(type: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if activeTimerType == type {
            activeTimerType = nil
            print("TimerCoordinator: Timer '\(type)' stopped")
        }
    }
    
    /// Get the currently active timer type
    var activeTimer: String? {
        lock.lock()
        defer { lock.unlock() }
        
        return activeTimerType
    }
    
    /// Check if any timer is active
    var isAnyTimerActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return activeTimerType != nil
    }
    
    /// Force clear all timer states (use with caution)
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        activeTimerType = nil
        print("TimerCoordinator: Reset - all timers cleared")
    }
}