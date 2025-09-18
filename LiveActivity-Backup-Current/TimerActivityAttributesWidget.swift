//
//  TimerActivityAttributesWidget.swift
//  GrowthTimerWidget
//
//  Combined types for widget - temporary solution until proper target membership is set
//

import Foundation
import ActivityKit
import AppIntents

// MARK: - Timer Activity Attributes

@available(iOS 16.1, *)
public struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Simplified state - just what we need for timer display
        public var startedAt: Date      // When timer started (adjusted for pauses)
        public var pausedAt: Date?      // When paused (nil if running)
        public var duration: TimeInterval // Total duration for countdown
        public var methodName: String
        public var sessionType: SessionType
        
        // Computed properties for UI
        public var isPaused: Bool {
            pausedAt != nil
        }
        
        public var isRunning: Bool {
            pausedAt == nil
        }
        
        // For countdown timers
        public var endTime: Date {
            startedAt.addingTimeInterval(duration)
        }
        
        // Calculate elapsed time
        public var elapsedTime: TimeInterval {
            if let pausedAt = pausedAt {
                return pausedAt.timeIntervalSince(startedAt)
            } else {
                return Date().timeIntervalSince(startedAt)
            }
        }
        
        // Legacy property names for backward compatibility
        public var currentElapsedTime: TimeInterval {
            return elapsedTime
        }
        
        public var currentRemainingTime: TimeInterval {
            return remainingTime
        }
        
        public var startTime: Date {
            return startedAt
        }
        
        // Completion state properties
        public var isCompleted: Bool {
            if sessionType == .countdown {
                return remainingTime <= 0
            }
            return false // Countup timers don't auto-complete
        }
        
        public var completionMessage: String? {
            return isCompleted ? "Timer completed!" : nil
        }
        
        // Calculate remaining time for countdown
        public var remainingTime: TimeInterval {
            if sessionType == .countdown {
                return max(0, duration - elapsedTime)
            }
            return 0
        }
        
        // Helper methods for Live Activity display (following expo-live-activity-timer pattern)
        public var getFutureDate: Date {
            return Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year out for infinite timer
        }
        
        public func getFormattedElapsedTime() -> String {
            let elapsed = elapsedTime
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
            let remaining = remainingTime
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
            let elapsed = elapsedTime
            if sessionType == .countdown {
                return min(elapsed / duration, 1.0)
            } else {
                let maxTime: TimeInterval = 3600 // 1 hour for countup
                return min(elapsed / maxTime, 1.0)
            }
        }
        
        public enum SessionType: String, Codable {
            case countdown = "countdown"
            case countup = "countup"
        }
        
        public init(startedAt: Date, pausedAt: Date? = nil, duration: TimeInterval, 
                    methodName: String, sessionType: SessionType) {
            self.startedAt = startedAt
            self.pausedAt = pausedAt
            self.duration = duration
            self.methodName = methodName
            self.sessionType = sessionType
        }
    }
    
    // Static attributes that don't change
    public var methodId: String
    public var timerType: String // "main" or "quick"
    
    // Legacy property for backward compatibility
    public var totalDuration: TimeInterval {
        return 0 // This will be set based on ContentState.duration
    }
    
    public init(methodId: String, timerType: String = "main") {
        self.methodId = methodId
        self.timerType = timerType
    }
}

// MARK: - Timer Action Enum is defined in TimerLiveActivity.swift

// MARK: - App Group Constants

struct AppGroupConstants {
    static let identifier = "group.com.growthlabs.growthmethod"
    
    /// UserDefaults instance for the app group
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: identifier)
    }
    
    struct Keys {
        static let currentTimerActivityId = "currentTimerActivityId"
        static let timerActivityStatePrefix = "timerActivityState_"
        static let timerPausedViaLiveActivity = "timerPausedViaLiveActivity"
        static let timerPauseTime = "timerPauseTime"
        static let lastTimerAction = "lastTimerAction"
        static let lastTimerType = "lastTimerType"
        static let lastTimerActionTime = "lastTimerActionTime"
        
        // Timer state keys
        static let timerStartTime = "com.growthlabs.growthmethod.timerStartTime"
        static let timerEndTime = "com.growthlabs.growthmethod.timerEndTime"
        static let timerElapsedTime = "com.growthlabs.growthmethod.timerElapsedTime"
        static let timerIsPaused = "com.growthlabs.growthmethod.timerIsPaused"
        static let timerMethodName = "com.growthlabs.growthmethod.timerMethodName"
        static let timerSessionType = "com.growthlabs.growthmethod.timerSessionType"
        static let liveActivityId = "com.growthlabs.growthmethod.liveActivityId"
    }
    
    /// Store timer state in app group
    static func storeTimerState(
        startTime: Date,
        endTime: Date,
        elapsedTime: TimeInterval,
        isPaused: Bool,
        methodName: String,
        sessionType: String,
        activityId: String?
    ) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(startTime, forKey: Keys.timerStartTime)
        defaults.set(endTime, forKey: Keys.timerEndTime)
        defaults.set(elapsedTime, forKey: Keys.timerElapsedTime)
        defaults.set(isPaused, forKey: Keys.timerIsPaused)
        defaults.set(methodName, forKey: Keys.timerMethodName)
        defaults.set(sessionType, forKey: Keys.timerSessionType)
        
        if let activityId = activityId {
            defaults.set(activityId, forKey: Keys.liveActivityId)
        }
        
        defaults.synchronize()
    }
    
    /// Clear timer state from app group
    static func clearTimerState() {
        guard let defaults = sharedDefaults else { return }
        
        defaults.removeObject(forKey: Keys.timerStartTime)
        defaults.removeObject(forKey: Keys.timerEndTime)
        defaults.removeObject(forKey: Keys.timerElapsedTime)
        defaults.removeObject(forKey: Keys.timerIsPaused)
        defaults.removeObject(forKey: Keys.timerMethodName)
        defaults.removeObject(forKey: Keys.timerSessionType)
        defaults.removeObject(forKey: Keys.liveActivityId)
        
        defaults.synchronize()
    }
}