import Foundation
import FirebaseFirestore

/// Represents the user's notification preferences for various types of notifications
struct NotificationPreferences: Codable, Equatable {
    /// Enable session reminders (e.g., reminders to practice a method)
    var sessionReminders: Bool
    
    /// Enable streak maintenance reminders (e.g., "Don't break your streak!")
    var streakMaintenance: Bool
    
    /// Enable achievement notifications (e.g., "You've reached a milestone!")
    var achievements: Bool
    
    /// Enable notifications about new content (e.g., new methods, features)
    var newContent: Bool
    
    /// Initialize with default values (all enabled)
    init(sessionReminders: Bool = true,
         streakMaintenance: Bool = true,
         achievements: Bool = true,
         newContent: Bool = true) {
        self.sessionReminders = sessionReminders
        self.streakMaintenance = streakMaintenance
        self.achievements = achievements
        self.newContent = newContent
    }
}

// MARK: - Firestore Conversion

extension NotificationPreferences {
    
    /// Convert to Firestore data
    var toFirestore: [String: Any] {
        return [
            "sessionReminders": sessionReminders,
            "streakMaintenance": streakMaintenance,
            "achievements": achievements,
            "newContent": newContent
        ]
    }
    
    /// Initialize from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        // Use default values for missing fields
        self.sessionReminders = data["sessionReminders"] as? Bool ?? true
        self.streakMaintenance = data["streakMaintenance"] as? Bool ?? true
        self.achievements = data["achievements"] as? Bool ?? true
        self.newContent = data["newContent"] as? Bool ?? true
    }
    
    /// Initialize from dictionary
    init?(data: [String: Any]) {
        self.sessionReminders = data["sessionReminders"] as? Bool ?? true
        self.streakMaintenance = data["streakMaintenance"] as? Bool ?? true
        self.achievements = data["achievements"] as? Bool ?? true
        self.newContent = data["newContent"] as? Bool ?? true
    }
} 