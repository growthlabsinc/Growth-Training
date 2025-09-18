//
//  TimerActivityAttributes.swift
//  Growth
//
//  Built from scratch based on expo-live-activity-timer research
//  Uses startedAt/pausedAt pattern as recommended by Apple
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
public struct TimerActivityAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        // Core timer state - based on expo-live-activity-timer pattern
        public var startedAt: Date
        public var pausedAt: Date?
        public var methodName: String
        public var duration: TimeInterval // Total duration for countdown
        public var sessionType: SessionType
        public var totalPausedDuration: TimeInterval = 0 // Cumulative pause time across all pause/resume cycles
        
        // Computed properties for Live Activity UI
        public var isPaused: Bool {
            return pausedAt != nil
        }
        
        public var isRunning: Bool {
            return pausedAt == nil
        }
        
        // End time for countdown sessions - adjusted for total paused duration
        public var endTime: Date {
            // Add the total paused duration to account for all pause/resume cycles
            startedAt.addingTimeInterval(duration + totalPausedDuration)
        }
        
        // Helper methods from expo-live-activity-timer research
        public func getElapsedTimeInSeconds() -> TimeInterval {
            if let pausedAt = pausedAt {
                // When paused, return time from start to pause minus total previous pause duration
                return pausedAt.timeIntervalSince(startedAt) - totalPausedDuration
            } else {
                // When running, return current time minus start minus total pause duration
                return Date().timeIntervalSince(startedAt) - totalPausedDuration
            }
        }
        
        public var elapsedTime: TimeInterval {
            return getElapsedTimeInSeconds()
        }
        
        // Legacy property names for backward compatibility
        public var currentElapsedTime: TimeInterval {
            return elapsedTime
        }
        
        public var currentRemainingTime: TimeInterval {
            return getTimeRemaining()
        }
        
        public var startTime: Date {
            return startedAt
        }
        
        // Completion state properties
        public var isCompleted: Bool {
            return sessionType == .countdown && getTimeRemaining() <= 0
        }
        
        public var completionMessage: String? {
            return isCompleted ? "Timer completed!" : nil
        }
        
        public func getTimeRemaining() -> TimeInterval {
            let elapsedTime = getElapsedTimeInSeconds()
            return max(0, duration - elapsedTime)
        }
        
        public var getFutureDate: Date {
            return Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year out for infinite timer
        }
        
        public func getFormattedElapsedTime() -> String {
            let elapsed = getElapsedTimeInSeconds()
            let totalSeconds = Int(elapsed)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
        
        public func getFormattedRemainingTime() -> String {
            let remaining = getTimeRemaining()
            let totalSeconds = Int(remaining)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
        
        // Simple progress calculation for ProgressView
        public var progress: Double {
            let elapsed = getElapsedTimeInSeconds()
            return min(elapsed / duration, 1.0)
        }
        
        // Use the main app's SessionType enum for consistency
        
        public init(startedAt: Date, pausedAt: Date? = nil, duration: TimeInterval, 
                    methodName: String, sessionType: SessionType, totalPausedDuration: TimeInterval = 0) {
            self.startedAt = startedAt
            self.pausedAt = pausedAt
            self.duration = duration
            self.methodName = methodName
            self.sessionType = sessionType
            self.totalPausedDuration = totalPausedDuration
        }
    }
    
    // Static attributes from research
    public var methodId: String
    public var timerType: String
    
    // Legacy property for backward compatibility
    public var totalDuration: TimeInterval {
        return 0 // This will be set based on ContentState.duration
    }
    
    public init(methodId: String, timerType: String = "main") {
        self.methodId = methodId
        self.timerType = timerType
    }
}

// Note: SessionType is imported from the main app's SessionType.swift