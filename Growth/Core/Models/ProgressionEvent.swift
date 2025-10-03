import Foundation
import FirebaseFirestore

/// A record representing a user advancing from one stage of a Growth Method to the next.
struct ProgressionEvent: Codable, Identifiable {
    /// Firestore document ID (UUID string)
    var id: String? = UUID().uuidString
    /// UID of the user progressing
    let userId: String
    /// Method ID being progressed
    let methodId: String
    /// Previous stage number
    let fromStage: Int
    /// New stage number
    let toStage: Int
    /// Time of progression (client-side – server timestamp also used in Firestore)
    let timestamp: Date
    /// Criteria snapshot that were met at time of progression (optional)
    let criteria: ProgressionCriteria?
    /// Optional user reflection or note
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case methodId
        case fromStage
        case toStage
        case timestamp
        case criteria
        case note
    }

    // MARK: Firestore Conversion
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "methodId": methodId,
            "fromStage": fromStage,
            "toStage": toStage,
            "timestamp": Timestamp(date: timestamp)
        ]
        if let note = note {
            data["note"] = note
        }
        if let criteria = criteria {
            if let jsonData = try? JSONEncoder().encode(criteria),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                data["criteriaJson"] = jsonString
            }
        }
        return data
    }

    init(userId: String, methodId: String, fromStage: Int, toStage: Int, timestamp: Date = Date(), criteria: ProgressionCriteria? = nil, note: String? = nil) {
        self.userId = userId
        self.methodId = methodId
        self.fromStage = fromStage
        self.toStage = toStage
        self.timestamp = timestamp
        self.criteria = criteria
        self.note = note
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard let userId = data["userId"] as? String,
              let methodId = data["methodId"] as? String,
              let fromStage = data["fromStage"] as? Int,
              let toStage = data["toStage"] as? Int,
              let ts = data["timestamp"] as? Timestamp else {
            return nil
        }
        self.id = document.documentID
        self.userId = userId
        self.methodId = methodId
        self.fromStage = fromStage
        self.toStage = toStage
        self.timestamp = ts.dateValue()
        if let criteriaJson = data["criteriaJson"] as? String,
           let jsonData = criteriaJson.data(using: .utf8) {
            self.criteria = try? JSONDecoder().decode(ProgressionCriteria.self, from: jsonData)
        } else {
            self.criteria = nil
        }
        self.note = data["note"] as? String
    }
} 