//
//  TimerActivityAttributes+Encoding.swift
//  Growth
//
//  Custom encoding/decoding for TimerActivityAttributes to handle timestamp conversion
//

import Foundation
import FirebaseFirestore

// Extension to convert ContentState to Firestore-compatible dictionary
extension TimerActivityAttributes.ContentState {
    
    /// Converts ContentState to a dictionary suitable for Firestore
    /// All Date objects are converted to Firestore Timestamps
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            // New simplified format
            "startedAt": Timestamp(date: startedAt),
            "duration": duration,
            "methodName": methodName,
            "sessionType": sessionType.rawValue,
            "isCompleted": isCompleted,
            
            // Legacy format for backward compatibility
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "isPaused": isPaused
        ]
        
        if let pausedAt = pausedAt {
            data["pausedAt"] = Timestamp(date: pausedAt)
        }
        
        if let completionMessage = completionMessage {
            data["completionMessage"] = completionMessage
        }
        
        return data
    }
    
    /// Converts ContentState to a dictionary with Unix timestamps for push notifications
    /// All Date objects are converted to Unix timestamps (seconds since 1970)
    func toPushNotificationData() -> [String: Any] {
        var data: [String: Any] = [
            // New simplified format
            "startedAt": startedAt.timeIntervalSince1970,
            "duration": duration,
            "methodName": methodName,
            "sessionType": sessionType.rawValue,
            "isCompleted": isCompleted,
            
            // Legacy format for backward compatibility
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "isPaused": isPaused
        ]
        
        if let pausedAt = pausedAt {
            data["pausedAt"] = pausedAt.timeIntervalSince1970
        }
        
        if let completionMessage = completionMessage {
            data["completionMessage"] = completionMessage
        }
        
        return data
    }
}