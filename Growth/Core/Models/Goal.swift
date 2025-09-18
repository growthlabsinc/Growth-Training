import Foundation
import FirebaseFirestore

/// Represents a user-defined goal tied to growth practice.
struct Goal: Identifiable, Codable {
    // Firestore document ID
    var id: String? = UUID().uuidString

    // MARK: Core Fields
    let userId: String
    var title: String
    var description: String

    /// IDs of GrowthMethod documents this goal applies to.
    var associatedMethodIds: [String]

    /// Numeric target value (e.g. 30 sessions, 600 minutes)
    var targetValue: Double
    /// Progress toward the target
    var currentValue: Double

    var valueType: GoalValueType
    var timeframe: GoalTimeframe

    /// Optional calendar deadline for the goal.
    var deadline: Date?

    /// Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?

    /// Soft-delete / archive flag
    var isArchived: Bool = false

    // MARK: - Firestore Conversion
    var toFirestore: [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "title": title,
            "description": description,
            "associatedMethodIds": associatedMethodIds,
            "targetValue": targetValue,
            "currentValue": currentValue,
            "valueType": valueType.rawValue,
            "timeframe": timeframe.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isArchived": isArchived
        ]
        if let deadline = deadline {
            data["deadline"] = Timestamp(date: deadline)
        }
        if let completedAt = completedAt {
            data["completedAt"] = Timestamp(date: completedAt)
        }
        return data
    }

    init(userId: String,
         title: String,
         description: String,
         associatedMethodIds: [String],
         targetValue: Double,
         valueType: GoalValueType,
         timeframe: GoalTimeframe,
         deadline: Date? = nil) {
        self.userId = userId
        self.title = title
        self.description = description
        self.associatedMethodIds = associatedMethodIds
        self.targetValue = targetValue
        self.currentValue = 0
        self.valueType = valueType
        self.timeframe = timeframe
        self.deadline = deadline
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let associatedMethodIds = data["associatedMethodIds"] as? [String],
              let targetValue = data["targetValue"] as? Double,
              let currentValue = data["currentValue"] as? Double,
              let valueTypeRaw = data["valueType"] as? String,
              let valueType = GoalValueType(rawValue: valueTypeRaw),
              let timeframeRaw = data["timeframe"] as? String,
              let timeframe = GoalTimeframe(rawValue: timeframeRaw)
        else { return nil }

        self.id = document.documentID
        self.userId = userId
        self.title = title
        self.description = description
        self.associatedMethodIds = associatedMethodIds
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.valueType = valueType
        self.timeframe = timeframe

        if let ts = data["deadline"] as? Timestamp { self.deadline = ts.dateValue() }
        if let ts = data["createdAt"] as? Timestamp { self.createdAt = ts.dateValue() }
        if let ts = data["updatedAt"] as? Timestamp { self.updatedAt = ts.dateValue() }
        if let ts = data["completedAt"] as? Timestamp { self.completedAt = ts.dateValue() }
        self.isArchived = data["isArchived"] as? Bool ?? false
    }
}

enum GoalValueType: String, Codable {
    case sessions
    case minutes
    case days
    case custom
}

enum GoalTimeframe: String, Codable {
    case shortTerm
    case mediumTerm
    case longTerm
} 