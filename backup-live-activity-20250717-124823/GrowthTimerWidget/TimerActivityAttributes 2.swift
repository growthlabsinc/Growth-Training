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
            
            // Try to decode new simplified format first
            if let startedAtString = try? container.decode(String.self, forKey: .startedAt) {
                // New format with startedAt
                let formatter = ISO8601DateFormatter()
                self.startedAt = formatter.date(from: startedAtString) ?? Date()
                
                // Handle pausedAt
                if let pausedAtString = try? container.decode(String.self, forKey: .pausedAt) {
                    self.pausedAt = formatter.date(from: pausedAtString)
                } else {
                    self.pausedAt = nil
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
                return
            }
            
            // Fall back to legacy format for backward compatibility
            print("  ⚠️ Using legacy format decoder")
            
            // Handle dates that might come as ISO strings, Unix timestamps, or Date objects
            if let startTimeString = try? container.decode(String.self, forKey: .startTime) {
                // Handle ISO string format from Firebase
                print("  - Decoded startTime as String: \(startTimeString)")
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: startTimeString) {
                    self.startedAt = date
                    print("  - Parsed ISO string to Date: \(date)")
                } else {
                    print("  ⚠️ Failed to parse ISO string, using current date")
                    self.startedAt = Date()
                }
            } else if let startTimeInterval = try? container.decode(TimeInterval.self, forKey: .startTime) {
                // Handle numeric timestamps
                print("  - Decoded startTime as TimeInterval: \(startTimeInterval)")
                // Check if this looks like an NSDate reference timestamp
                // NSDate timestamps for dates around 2025 are typically 700M-800M range
                if startTimeInterval > 600000000 && startTimeInterval < 900000000 {
                    // This is likely an NSDate reference timestamp (seconds since 2001)
                    // Convert to Unix timestamp by adding the difference between epochs
                    let unixTimestamp = startTimeInterval + 978307200
                    self.startedAt = Date(timeIntervalSince1970: unixTimestamp)
                    print("  ⚠️ Converted NSDate reference timestamp for startTime: \(startTimeInterval) -> Unix: \(unixTimestamp) -> Date: \(self.startedAt)")
                } else if startTimeInterval < 946684800 { // Before Jan 1, 2000
                    print("  ⚠️ Invalid startTime timestamp: \(startTimeInterval), using current date")
                    self.startedAt = Date()
                } else {
                    self.startedAt = Date(timeIntervalSince1970: startTimeInterval)
                    print("  - Decoded startTime from Unix timestamp: \(self.startedAt)")
                }
            } else {
                let decodedDate = try container.decode(Date.self, forKey: .startTime)
                // CRITICAL: Check if this is an NSDate reference timestamp (from 2001) that needs conversion
                let timestamp = decodedDate.timeIntervalSince1970
                if timestamp < 0 {
                    // This is likely an NSDate reference timestamp, convert it
                    let nsDateRefTimestamp = decodedDate.timeIntervalSinceReferenceDate
                    let unixTimestamp = nsDateRefTimestamp + 978307200 // Add seconds between 1970 and 2001
                    self.startedAt = Date(timeIntervalSince1970: unixTimestamp)
                    print("  ⚠️ Converted NSDate reference timestamp: \(nsDateRefTimestamp) -> Unix: \(unixTimestamp)")
                } else if timestamp < 1577836800 {
                    print("  ⚠️ Decoded invalid startTime: \(decodedDate), using current date")
                    self.startedAt = Date()
                } else {
                    self.startedAt = decodedDate
                }
                print("  - Decoded startTime as Date: \(self.startedAt) (\(self.startedAt.timeIntervalSince1970))")
            }
            
            // For legacy format, decode basic fields and convert to new format
            // startedAt was already set above when decoding startTime
            let endTime: Date
            
            // Handle endTime (similar logic for ISO strings, Unix timestamps, or Date objects)
            if let endTimeString = try? container.decode(String.self, forKey: .endTime) {
                // Handle ISO string format from Firebase
                print("  - Decoded endTime as String: \(endTimeString)")
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: endTimeString) {
                    endTime = date
                    print("  - Parsed ISO string to Date: \(date)")
                } else {
                    print("  ⚠️ Failed to parse ISO string, using reasonable default")
                    endTime = self.startedAt.addingTimeInterval(300) // 5 minutes
                }
            } else if let endTimeInterval = try? container.decode(TimeInterval.self, forKey: .endTime) {
                // CRITICAL FIX: Check if this is an NSDate reference timestamp
                print("  - Decoded endTime as TimeInterval: \(endTimeInterval)")
                // Check if this looks like an NSDate reference timestamp
                // NSDate timestamps for dates around 2025 are typically 700M-800M range
                if endTimeInterval > 600000000 && endTimeInterval < 900000000 {
                    // This is likely an NSDate reference timestamp (seconds since 2001)
                    // Convert to Unix timestamp by adding the difference between epochs
                    let unixTimestamp = endTimeInterval + 978307200
                    endTime = Date(timeIntervalSince1970: unixTimestamp)
                    print("  ⚠️ Converted NSDate reference timestamp for endTime: \(endTimeInterval) -> Unix: \(unixTimestamp) -> Date: \(endTime)")
                } else if endTimeInterval > 4102444800 { // After year 2100
                    endTime = Date.distantFuture
                } else if endTimeInterval < 946684800 { // Before Jan 1, 2000
                    print("  ⚠️ Invalid endTime timestamp: \(endTimeInterval), using reasonable default")
                    // For invalid timestamps, calculate a reasonable end time
                    // If we have a valid start time, add 5 minutes
                    if self.startedAt.timeIntervalSince1970 > 946684800 {
                        endTime = self.startedAt.addingTimeInterval(300) // 5 minutes
                    } else {
                        // Both times invalid, use current date + 5 minutes
                        endTime = Date().addingTimeInterval(300)
                    }
                } else {
                    endTime = Date(timeIntervalSince1970: endTimeInterval)
                    print("  - Decoded endTime from Unix timestamp: \(endTime)")
                }
            } else {
                let decodedDate = try container.decode(Date.self, forKey: .endTime)
                // CRITICAL: Check if this is an NSDate reference timestamp (from 2001) that needs conversion
                let timestamp = decodedDate.timeIntervalSince1970
                if timestamp < 0 {
                    // This is likely an NSDate reference timestamp, convert it
                    let nsDateRefTimestamp = decodedDate.timeIntervalSinceReferenceDate
                    let unixTimestamp = nsDateRefTimestamp + 978307200 // Add seconds between 1970 and 2001
                    endTime = Date(timeIntervalSince1970: unixTimestamp)
                    print("  ⚠️ Converted NSDate reference timestamp: \(nsDateRefTimestamp) -> Unix: \(unixTimestamp)")
                } else if timestamp > 4102444800 {
                    endTime = Date.distantFuture
                } else if timestamp < 1577836800 {
                    print("  ⚠️ Decoded invalid endTime: \(decodedDate), using reasonable default")
                    // For invalid timestamps, calculate a reasonable end time
                    // If we have a valid start time, add 5 minutes
                    if self.startedAt.timeIntervalSince1970 > 946684800 {
                        endTime = self.startedAt.addingTimeInterval(300) // 5 minutes
                    } else {
                        // Both times invalid, use current date + 5 minutes
                        endTime = Date().addingTimeInterval(300)
                    }
                } else {
                    endTime = decodedDate
                }
                print("  - Decoded endTime as Date: \(endTime) (\(endTime.timeIntervalSince1970))")
            }
            
            // Finish decoding legacy format
            // endTime is now a local variable that was set above
            self.methodName = try container.decode(String.self, forKey: .methodName)
            self.sessionType = try container.decode(SessionType.self, forKey: .sessionType)
            let isPausedLegacy = try container.decode(Bool.self, forKey: .isPaused)
            
            // Convert legacy format to new simplified format
            if sessionType == .countdown {
                self.duration = endTime.timeIntervalSince(startedAt)
            } else {
                self.duration = 0 // Countup has no fixed duration
            }
            
            // startedAt was already set when decoding startTime
            
            // Set pausedAt based on isPaused flag
            if isPausedLegacy {
                // If paused in legacy format, use lastUpdateTime as pausedAt
                if let lastUpdateTime = try? container.decodeIfPresent(Date.self, forKey: .lastUpdateTime) {
                    self.pausedAt = lastUpdateTime
                } else {
                    self.pausedAt = Date()
                }
            } else {
                self.pausedAt = nil
            }
            
            // Decode completion fields
            self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
            self.completionMessage = try container.decodeIfPresent(String.self, forKey: .completionMessage)
            
            print("  ✅ Converted legacy format to simplified format:")
            print("  - startedAt: \(self.startedAt)")
            print("  - pausedAt: \(String(describing: self.pausedAt))")
            print("  - duration: \(self.duration)s")
            return
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