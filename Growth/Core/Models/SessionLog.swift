//
//  SessionLog.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import FirebaseFirestore

/// Model for tracking practice sessions
struct SessionLog: Identifiable, Codable, Equatable {
    /// Unique identifier for the session log
    var id: String
    
    /// User ID of the person who performed the session
    var userId: String
    
    /// Duration of the session in minutes
    var duration: Int
    
    /// Start time of the session
    var startTime: Date
    
    /// End time of the session
    var endTime: Date
    
    /// Optional user notes about the session
    var userNotes: String?
    
    /// Growth method ID if this session is part of a structured program
    var methodId: String?
    
    /// Session index within a method (if applicable)
    var sessionIndex: Int?
    
    /// Mood before the session
    var moodBefore: Mood = .neutral
    
    /// Mood after the session
    var moodAfter: Mood = .neutral
    
    // MARK: - Enhanced Fields (Story 12.3)
    
    /// Optional user reported intensity/difficulty on a 1-1005 scale
    var intensity: Int?
    
    /// Optional exercise variation identifier/name the user performed
    var variation: String?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case duration
        case startTime
        case endTime
        case userNotes = "notes"
        case methodId
        case sessionIndex
        case moodBefore
        case moodAfter
        case intensity
        case variation
    }
    
    // MARK: - Initializers
    
    /// Standard initializer
    init(id: String, userId: String, duration: Int, startTime: Date, endTime: Date, userNotes: String? = nil, methodId: String? = nil, sessionIndex: Int? = nil, moodBefore: Mood = .neutral, moodAfter: Mood = .neutral, intensity: Int? = nil, variation: String? = nil) {
        self.id = id
        self.userId = userId
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.userNotes = userNotes
        self.methodId = methodId
        self.sessionIndex = sessionIndex
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.intensity = intensity
        self.variation = variation
    }
    
    // MARK: - Firestore Conversion
    
    /// Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        guard let userId = document.data()["userId"] as? String,
              let duration = document.data()["duration"] as? Int,
              let startTimestamp = document.data()["startTime"] as? Timestamp,
              let endTimestamp = document.data()["endTime"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.duration = duration
        self.startTime = startTimestamp.dateValue()
        self.endTime = endTimestamp.dateValue()
        self.userNotes = document.data()["notes"] as? String
        self.methodId = document.data()["methodId"] as? String
        self.sessionIndex = document.data()["sessionIndex"] as? Int
        if let beforeRaw = document.data()["moodBefore"] as? String, let before = Mood(rawValue: beforeRaw) {
            self.moodBefore = before
        }
        if let afterRaw = document.data()["moodAfter"] as? String, let after = Mood(rawValue: afterRaw) {
            self.moodAfter = after
        }
        
        // Enhanced fields
        self.intensity = document.data()["intensity"] as? Int
        self.variation = document.data()["variation"] as? String
    }
    
    /// Initialize from generic Firestore DocumentSnapshot (can be from getDocument)
    init?(snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let userId = data["userId"] as? String,
              let duration = data["duration"] as? Int,
              let startTimestamp = data["startTime"] as? Timestamp,
              let endTimestamp = data["endTime"] as? Timestamp else {
            return nil
        }
        self.id = snapshot.documentID
        self.userId = userId
        self.duration = duration
        self.startTime = startTimestamp.dateValue()
        self.endTime = endTimestamp.dateValue()
        self.userNotes = data["notes"] as? String
        self.methodId = data["methodId"] as? String
        self.sessionIndex = data["sessionIndex"] as? Int
        if let beforeRaw = data["moodBefore"] as? String, let before = Mood(rawValue: beforeRaw) {
            self.moodBefore = before
        }
        if let afterRaw = data["moodAfter"] as? String, let after = Mood(rawValue: afterRaw) {
            self.moodAfter = after
        }
        
        // Enhanced fields
        self.intensity = data["intensity"] as? Int
        self.variation = data["variation"] as? String
    }
    
    /// Convert to Firestore data
    var toFirestore: [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "duration": duration,
            "startTime": startTime,
            "endTime": endTime,
            "moodBefore": moodBefore.rawValue,
            "moodAfter": moodAfter.rawValue
        ]
        
        if let userNotes = userNotes {
            data["notes"] = userNotes
        }
        
        if let methodId = methodId {
            data["methodId"] = methodId
        }
        
        if let sessionIndex = sessionIndex {
            data["sessionIndex"] = sessionIndex
        }
        
        if let intensity = intensity {
            data["intensity"] = intensity
        }
        
        if let variation = variation, !variation.isEmpty {
            data["variation"] = variation
        }
        
        return data
    }
    
    /// Convenience alias used by FirestoreService for saving
    func toFirestoreData() -> [String: Any] {
        return toFirestore
    }
    
    // Computed alias for backward compatibility
    var notes: String? {
        get { userNotes }
        set { userNotes = newValue }
    }
}

/// Mood state for tracking before and after sessions
enum Mood: String, Codable, CaseIterable, Hashable {
    /// Very negative mood
    case veryNegative = "very_negative"
    
    /// Negative mood
    case negative = "negative"
    
    /// Neutral mood
    case neutral = "neutral"
    
    /// Positive mood
    case positive = "positive"
    
    /// Very positive mood
    case veryPositive = "very_positive"

    var emoji: String {
        switch self {
        case .veryNegative: return "😞"
        case .negative:     return "🙁"
        case .neutral:      return "😐"
        case .positive:     return "🙂"
        case .veryPositive: return "😄"
        }
    }
    
    var displayName: String {
        switch self {
        case .veryNegative: return "Very Negative"
        case .negative:     return "Negative"
        case .neutral:      return "Neutral"
        case .positive:     return "Positive"
        case .veryPositive: return "Very Positive"
        }
    }
} 