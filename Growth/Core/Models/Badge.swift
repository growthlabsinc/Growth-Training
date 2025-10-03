import Foundation
import FirebaseFirestore

/// Model representing a badge that can be earned by users
struct Badge: Identifiable, Codable {
    /// Unique identifier for the badge
    var id: String
    
    /// Display name of the badge
    var name: String
    
    /// Detailed description of the badge
    var description: String
    
    /// JSON representation of the criteria required to earn the badge
    var criteria: [String: Any]
    
    /// URL or placeholder for the badge icon
    var iconURL: String
    
    /// Date when the badge was earned by the user (if applicable)
    var earnedDate: Date?
    
    /// Whether the badge has been earned by the user
    var isEarned: Bool {
        return earnedDate != nil
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case criteria
        case iconURL = "icon_placeholder_url"
        case earnedDate
    }
    
    // MARK: - Initialization
    
    /// Initialize a new badge
    init(id: String, name: String, description: String, criteria: [String: Any], iconURL: String, earnedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.criteria = criteria
        self.iconURL = iconURL
        self.earnedDate = earnedDate
    }
    
    /// Initialize from generic DocumentSnapshot (e.g., fetched with getDocument)
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let criteria = data["criteria"] as? [String: Any],
              let iconURL = data["icon_placeholder_url"] as? String else {
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.description = description
        self.criteria = criteria
        self.iconURL = iconURL
        if let earnedTimestamp = data["earnedDate"] as? Timestamp {
            self.earnedDate = earnedTimestamp.dateValue()
        } else {
            self.earnedDate = nil
        }
    }
    
    /// Initialize from Firestore QueryDocumentSnapshot
    init?(document: QueryDocumentSnapshot) {
        self.init(document: document as DocumentSnapshot)
    }
    
    // MARK: - Codable Implementation
    
    /// Custom decoder to handle Firestore's dictionary representation of criteria
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        iconURL = try container.decode(String.self, forKey: .iconURL)
        
        // Since criteria is a dictionary with various types, we need to handle it specially
        if let criteriaData = try container.decodeIfPresent(Data.self, forKey: .criteria) {
            criteria = try JSONSerialization.jsonObject(with: criteriaData, options: []) as? [String: Any] ?? [:]
        } else {
            criteria = [:]
        }
        
        earnedDate = try container.decodeIfPresent(Date.self, forKey: .earnedDate)
    }
    
    /// Custom encoder to handle Firestore's dictionary representation of criteria
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(iconURL, forKey: .iconURL)
        
        // Convert criteria dictionary to Data
        if !criteria.isEmpty {
            let criteriaData = try JSONSerialization.data(withJSONObject: criteria, options: [])
            try container.encode(criteriaData, forKey: .criteria)
        }
        
        try container.encodeIfPresent(earnedDate, forKey: .earnedDate)
    }
    
    // MARK: - Firestore Conversion
    
    /// Convert to Firestore data
    var toFirestore: [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "description": description,
            "criteria": criteria,
            "icon_placeholder_url": iconURL
        ]
        
        if let earnedDate = earnedDate {
            data["earnedDate"] = earnedDate
        }
        
        return data
    }
}

// MARK: - Badge Criteria

/// Types of badge criteria
enum BadgeCriteriaType: String {
    case sessionsLogged = "sessionsLogged"
    case stageCompleted = "stageCompleted"
    case streakReached = "streakReached"
}

/// Helper for checking if badge criteria are met
struct BadgeCriteria {
    /// Check if a badge's criteria are met
    /// - Parameters:
    ///   - badge: The badge to check
    ///   - userData: User data containing relevant metrics
    /// - Returns: Whether the criteria are met
    static func isMet(badge: Badge, userData: [String: Any]) -> Bool {
        for (key, value) in badge.criteria {
            switch key {
            case BadgeCriteriaType.sessionsLogged.rawValue:
                if let requiredSessions = value as? Int,
                   let userSessions = userData["totalSessionsLogged"] as? Int {
                    if userSessions < requiredSessions {
                        return false
                    }
                }
                
            case BadgeCriteriaType.streakReached.rawValue:
                if let requiredStreak = value as? Int,
                   let currentStreak = userData["currentStreak"] as? Int,
                   let longestStreak = userData["longestStreak"] as? Int {
                    if currentStreak < requiredStreak && longestStreak < requiredStreak {
                        return false
                    }
                }
                
            case BadgeCriteriaType.stageCompleted.rawValue:
                if let requiredStage = value as? String,
                   let completedStages = userData["completedStages"] as? [String] {
                    if !completedStages.contains(requiredStage) {
                        return false
                    }
                }
                
            default:
                // Unknown criterion type - assume not met
                return false
            }
        }
        
        // All criteria were met
        return true
    }
}

// MARK: - Equatable & Hashable

extension Badge: Equatable, Hashable {
    static func == (lhs: Badge, rhs: Badge) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 