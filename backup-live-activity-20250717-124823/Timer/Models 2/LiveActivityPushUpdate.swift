//
//  LiveActivityPushUpdate.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

/// Model for Live Activity push notification updates
struct LiveActivityPushUpdate: Codable {
    let activityId: String
    let contentState: TimerActivityContentState
    let timestamp: Date
    let updateType: UpdateType
    
    enum UpdateType: String, Codable {
        case periodic = "periodic"          // Regular time updates
        case stateChange = "stateChange"    // Pause/resume/stop
        case intervalChange = "intervalChange" // Interval timer transitions
        case completion = "completion"      // Timer completed
    }
    
    /// Create update for current timer state
    static func createUpdate(
        activityId: String,
        startTime: Date,
        endTime: Date,
        methodName: String,
        sessionType: TimerActivityAttributes.ContentState.SessionType,
        isPaused: Bool,
        updateType: UpdateType = .periodic
    ) -> LiveActivityPushUpdate {
        let contentState = TimerActivityContentState(
            startTime: startTime,
            endTime: endTime,
            methodName: methodName,
            sessionType: sessionType,
            isPaused: isPaused,
            currentTime: Date(),
            elapsedTime: Date().timeIntervalSince(startTime),
            remainingTime: max(0, endTime.timeIntervalSince(Date()))
        )
        
        return LiveActivityPushUpdate(
            activityId: activityId,
            contentState: contentState,
            timestamp: Date(),
            updateType: updateType
        )
    }
}

/// Extended content state with calculated values for push updates
struct TimerActivityContentState: Codable {
    let startTime: Date
    let endTime: Date
    let methodName: String
    let sessionType: TimerActivityAttributes.ContentState.SessionType
    let isPaused: Bool
    
    // Additional calculated fields for push updates
    let currentTime: Date
    let elapsedTime: TimeInterval
    let remainingTime: TimeInterval
    
    /// Convert to standard ContentState for Live Activity
    var toContentState: TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            startTime: startTime,
            endTime: endTime,
            methodName: methodName,
            sessionType: sessionType,
            isPaused: isPaused
        )
    }
}