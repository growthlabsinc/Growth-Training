//
//  TimerActivityAttributes.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
public struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Core timer state - simplified approach like in the video
        public var startedAt: Date      // When the timer started (adjusted for pauses)
        public var pausedAt: Date?      // When the timer was paused (nil if running)
        public var duration: TimeInterval // Total duration for countdown timers
        public var methodName: String
        public var sessionType: SessionType
        
        // Completion state
        public var isCompleted: Bool = false
        public var completionMessage: String?
        
        // Computed properties for UI
        public var isPaused: Bool {
            pausedAt != nil
        }
        
        public var startTime: Date {
            // For compatibility with existing UI code
            startedAt
        }
        
        public var endTime: Date {
            // For countdown timers, calculate end time from startedAt + duration
            if sessionType == .countdown {
                return startedAt.addingTimeInterval(duration)
            } else {
                // For countup timers, use distant future
                return Date.distantFuture
            }
        }
        
        // Helper computed properties for time calculations
        public var currentElapsedTime: TimeInterval {
            if let pausedAt = pausedAt {
                // If paused, return time from startedAt to pausedAt
                return pausedAt.timeIntervalSince(startedAt)
            } else {
                // If running, return time from startedAt to now
                return Date().timeIntervalSince(startedAt)
            }
        }
        
        public var currentRemainingTime: TimeInterval {
            if sessionType == .countdown {
                return max(0, duration - currentElapsedTime)
            }
            return 0
        }
        
        // Helper methods for Live Activity display (following expo-live-activity-timer pattern)
        public var isRunning: Bool {
            return pausedAt == nil
        }
        
        public var getFutureDate: Date {
            return Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year out for infinite timer
        }
        
        public func getFormattedElapsedTime() -> String {
            let elapsed = currentElapsedTime
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
        
        // Custom decoding to handle timestamps from push notifications
        enum CodingKeys: String, CodingKey {
            case startedAt, pausedAt, duration, methodName, sessionType
            case isCompleted, completionMessage
            // Legacy keys for backward compatibility
            case startTime, endTime, isPaused
            case lastUpdateTime, elapsedTimeAtLastUpdate, remainingTimeAtLastUpdate
            case lastKnownGoodUpdate, expectedEndTime
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            print("🔍 TimerActivityAttributes.ContentState decoding...")
            
            // Debug: Print all available keys to understand what we're receiving
            print("  🔍 Available keys: \(container.allKeys.map { $0.stringValue })")
            
            do {
                // Try to decode new simplified format first
                if container.contains(.startedAt) {
                    print("  📋 Found 'startedAt' key - using new format")
                    
                    // New format with startedAt - handle multiple formats
                    if let startedAtString = try? container.decode(String.self, forKey: .startedAt) {
                        let formatter = ISO8601DateFormatter()
                        self.startedAt = formatter.date(from: startedAtString) ?? Date()
                        print("  - startedAt from string: \(startedAtString) -> \(self.startedAt)")
                    } else if let startedAtDate = try? container.decode(Date.self, forKey: .startedAt) {
                        self.startedAt = startedAtDate
                        print("  - startedAt from date: \(self.startedAt)")
                    } else {
                        // Try to handle as TimeInterval (Unix timestamp)
                        do {
                            let startedAtInterval = try container.decode(TimeInterval.self, forKey: .startedAt)
                            self.startedAt = Date(timeIntervalSince1970: startedAtInterval)
                            print("  - startedAt from TimeInterval: \(startedAtInterval) -> \(self.startedAt)")
                        } catch {
                            print("  ⚠️ Could not decode startedAt as String, Date, or TimeInterval: \(error)")
                            print("  ⚠️ Using current date as fallback")
                            self.startedAt = Date()
                        }
                    }
                    
                    // Handle pausedAt - same multi-format handling
                    if container.contains(.pausedAt) {
                        if let pausedAtString = try? container.decode(String.self, forKey: .pausedAt) {
                            let formatter = ISO8601DateFormatter()
                            self.pausedAt = formatter.date(from: pausedAtString)
                            print("  - pausedAt from string: \(pausedAtString) -> \(String(describing: self.pausedAt))")
                        } else if let pausedAtDate = try? container.decode(Date.self, forKey: .pausedAt) {
                            self.pausedAt = pausedAtDate
                            print("  - pausedAt from date: \(String(describing: self.pausedAt))")
                        } else {
                            // Try to handle as TimeInterval (Unix timestamp)
                            do {
                                let pausedAtInterval = try container.decode(TimeInterval.self, forKey: .pausedAt)
                                self.pausedAt = Date(timeIntervalSince1970: pausedAtInterval)
                                print("  - pausedAt from TimeInterval: \(pausedAtInterval) -> \(String(describing: self.pausedAt))")
                            } catch {
                                print("  ⚠️ Could not decode pausedAt as String, Date, or TimeInterval: \(error)")
                                self.pausedAt = nil
                            }
                        }
                    } else {
                        self.pausedAt = nil
                        print("  - pausedAt: nil (key not present)")
                    }
                    
                    self.duration = try container.decode(TimeInterval.self, forKey: .duration)
                    self.methodName = try container.decode(String.self, forKey: .methodName)
                    self.sessionType = try container.decode(SessionType.self, forKey: .sessionType)
                    self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
                    self.completionMessage = try container.decodeIfPresent(String.self, forKey: .completionMessage)
                    
                    print("  ✅ Decoded new simplified format")
                    print("  - startedAt: \(self.startedAt)")
                    print("  - pausedAt: \(String(describing: self.pausedAt))")
                    print("  - duration: \(self.duration)s")
                    print("  - methodName: \(self.methodName)")
                    print("  - sessionType: \(self.sessionType)")
                    return
                }
                
                // Fall back to legacy format for backward compatibility
                print("  ⚠️ Using legacy format decoder")
                
                // Decode required fields first - wrap in try-catch for better error reporting
                do {
                    self.methodName = try container.decode(String.self, forKey: .methodName)
                    print("  - methodName: \(self.methodName)")
                } catch {
                    print("  ❌ Failed to decode methodName: \(error)")
                    throw error
                }
                
                do {
                    self.sessionType = try container.decode(SessionType.self, forKey: .sessionType)
                    print("  - sessionType: \(self.sessionType)")
                } catch {
                    print("  ❌ Failed to decode sessionType: \(error)")
                    throw error
                }
                
                do {
                    let isPausedLegacy = try container.decode(Bool.self, forKey: .isPaused)
                    print("  - isPaused: \(isPausedLegacy)")
                    
                    // Set pausedAt based on isPaused flag
                    if isPausedLegacy {
                        if let lastUpdateTime = try? container.decodeIfPresent(Date.self, forKey: .lastUpdateTime) {
                            self.pausedAt = lastUpdateTime
                            print("  - pausedAt from lastUpdateTime: \(lastUpdateTime)")
                        } else {
                            self.pausedAt = Date()
                            print("  - pausedAt defaulted to current date")
                        }
                    } else {
                        self.pausedAt = nil
                        print("  - pausedAt: nil (not paused)")
                    }
                } catch {
                    print("  ❌ Failed to decode isPaused: \(error)")
                    throw error
                }
                
                // Simple date decoding - try Date first, then fallback
                if let startTime = try? container.decode(Date.self, forKey: .startTime) {
                    self.startedAt = startTime
                    print("  - startedAt from Date: \(self.startedAt)")
                } else if let startTimeInterval = try? container.decode(TimeInterval.self, forKey: .startTime) {
                    // Handle NSDate reference timestamps (common in ActivityKit)
                    if startTimeInterval > 600000000 && startTimeInterval < 900000000 {
                        // NSDate reference timestamp - convert to Unix timestamp
                        let unixTimestamp = startTimeInterval + 978307200
                        self.startedAt = Date(timeIntervalSince1970: unixTimestamp)
                        print("  ⚠️ Converted NSDate reference timestamp: \(startTimeInterval) -> \(self.startedAt)")
                    } else {
                        self.startedAt = Date(timeIntervalSince1970: startTimeInterval)
                        print("  - startedAt from TimeInterval: \(self.startedAt)")
                    }
                } else {
                    self.startedAt = Date()
                    print("  ⚠️ Could not decode startTime, using current date")
                }
                
                // Decode endTime and calculate duration
                if let endTime = try? container.decode(Date.self, forKey: .endTime) {
                    if sessionType == .countdown {
                        self.duration = max(60, endTime.timeIntervalSince(startedAt)) // Minimum 1 minute
                    } else {
                        self.duration = 0 // Countup has no fixed duration
                    }
                    print("  - duration calculated from endTime: \(self.duration)s")
                } else if let endTimeInterval = try? container.decode(TimeInterval.self, forKey: .endTime) {
                    let endTime: Date
                    if endTimeInterval > 600000000 && endTimeInterval < 900000000 {
                        // NSDate reference timestamp
                        let unixTimestamp = endTimeInterval + 978307200
                        endTime = Date(timeIntervalSince1970: unixTimestamp)
                        print("  ⚠️ Converted NSDate reference timestamp for endTime: \(endTimeInterval) -> \(endTime)")
                    } else {
                        endTime = Date(timeIntervalSince1970: endTimeInterval)
                        print("  - endTime from TimeInterval: \(endTime)")
                    }
                    
                    if sessionType == .countdown {
                        self.duration = max(60, endTime.timeIntervalSince(startedAt)) // Minimum 1 minute
                    } else {
                        self.duration = 0
                    }
                    print("  - duration calculated: \(self.duration)s")
                } else {
                    // No valid endTime found, use a reasonable default based on session type
                    if sessionType == .countdown {
                        self.duration = 300 // 5 minutes default for countdown
                    } else {
                        self.duration = 0 // Countup has no duration
                    }
                    print("  ⚠️ Could not decode endTime, using default duration: \(self.duration)s")
                }
                
                // Decode completion fields
                self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
                self.completionMessage = try container.decodeIfPresent(String.self, forKey: .completionMessage)
                
                print("  ✅ Converted legacy format to simplified format:")
                print("  - startedAt: \(self.startedAt)")
                print("  - pausedAt: \(String(describing: self.pausedAt))")
                print("  - duration: \(self.duration)s")
                
            } catch {
                print("  ❌ Decoding failed with error: \(error)")
                print("  ❌ Error details: \(String(describing: error))")
                
                // Emergency fallback - create a minimal valid state
                print("  🚨 Creating emergency fallback state")
                self.startedAt = Date()
                self.pausedAt = nil
                self.duration = 300 // 5 minutes default
                self.methodName = "Timer"
                self.sessionType = .countdown
                self.isCompleted = false
                self.completionMessage = nil
                
                print("  🚨 Emergency fallback created:")
                print("  - startedAt: \(self.startedAt)")
                print("  - duration: \(self.duration)s")
                print("  - methodName: \(self.methodName)")
                
                // Still rethrow the error so we know there's an issue
                throw error
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            // Encode new simplified format
            try container.encode(startedAt, forKey: .startedAt)
            try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
            try container.encode(duration, forKey: .duration)
            try container.encode(methodName, forKey: .methodName)
            try container.encode(sessionType, forKey: .sessionType)
            try container.encode(isCompleted, forKey: .isCompleted)
            try container.encodeIfPresent(completionMessage, forKey: .completionMessage)
            
            // Also encode legacy fields for backward compatibility
            try container.encode(startTime, forKey: .startTime)
            try container.encode(endTime, forKey: .endTime)
            try container.encode(isPaused, forKey: .isPaused)
        }
        
        // New simplified initializer
        public init(startedAt: Date, pausedAt: Date? = nil, duration: TimeInterval, 
             methodName: String, sessionType: SessionType,
             isCompleted: Bool = false, completionMessage: String? = nil) {
            self.startedAt = startedAt
            self.pausedAt = pausedAt
            self.duration = duration
            self.methodName = methodName
            self.sessionType = sessionType
            self.isCompleted = isCompleted
            self.completionMessage = completionMessage
        }

        // Legacy initializer for backward compatibility
        public init(startTime: Date, endTime: Date, methodName: String, sessionType: SessionType,
 
             isPaused: Bool, lastUpdateTime: Date = Date(), elapsedTimeAtLastUpdate: TimeInterval = 0,
             remainingTimeAtLastUpdate: TimeInterval = 0, lastKnownGoodUpdate: Date = Date(),
             expectedEndTime: Date? = nil, isCompleted: Bool = false, completionMessage: String? = nil) {
            // Convert legacy format to new format
            self.startedAt = startTime
            self.pausedAt = isPaused ? lastUpdateTime : nil
            self.duration = sessionType == .countdown ? endTime.timeIntervalSince(startTime) : 0
            self.methodName = methodName
            self.sessionType = sessionType
            self.isCompleted = isCompleted
            self.completionMessage = completionMessage
        }
        
        public enum SessionType: String, Codable {
            case countdown = "countdown"
            case countup = "countup"
            case interval = "interval"
            case completed = "completed"
        }
    }
    
    // Fixed attributes that don't change during the activity
    public var methodId: String
    public var totalDuration: TimeInterval
    public var timerType: String = "main" // "main" or "quick"
    
    public init(methodId: String, totalDuration: TimeInterval, timerType: String = "main") {
        self.methodId = methodId
        self.totalDuration = totalDuration
        self.timerType = timerType
    }
}