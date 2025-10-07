//
//  TrainingProtocol.swift
//  Growth
//
//  Renamed from GrowthMethod.swift for Epic 5 Story 5.3
//

import Foundation
import FirebaseFirestore

/// Model representing a training protocol in the application
class TrainingProtocol: NSObject, Codable, Identifiable, NSSecureCoding {
    /// Unique identifier for the training protocol
    @DocumentID var id: String?

    /// Stage or progression level of the protocol (1, 2, 3, etc.)
    var stage: Int

    /// Classification label ("Beginner", "Foundation", "Intermediate", "Expert", "Master")
    var classification: String?

    /// Title of the training protocol
    var title: String

    /// Brief description of the training protocol
    var protocolDescription: String

    /// Detailed instructions text for performing the protocol
    var instructionsText: String

    /// URL for an image or video placeholder
    var visualPlaceholderUrl: String?

    /// List of equipment needed for the protocol
    var equipmentNeeded: [String]

    /// Estimated time to complete (in minutes)
    var estimatedDurationMinutes: Int?

    /// Categories or tags this protocol belongs to
    var categories: [String]

    /// Flag to indicate if this entry should be featured
    var isFeatured: Bool

    /// Legacy free-form text criteria (to be deprecated)
    var progressionCriteriaText: String?

    /// Structured criteria model for progression
    var progressionCriteria: ProgressionCriteria?

    /// Safety notes for the protocol
    var safetyNotes: String?

    /// Benefits of the protocol
    var benefits: [String]?

    /// Related protocols to this protocol
    var relatedMethods: [String]?

    /// Timer configuration for the protocol
    var timerConfig: TimerConfiguration?

    /// Structured steps for the protocol (if available)
    var steps: [MethodStep]?

    /// Creation date of the entry
    var createdAt: Date

    /// Last update date of the entry
    var updatedAt: Date

    /// Returns whether the class supports secure coding
    public static var supportsSecureCoding: Bool {
        return true
    }

    /// Designated initializer
    init(id: String?,
         stage: Int,
         classification: String? = nil,
         title: String,
         protocolDescription: String,
         instructionsText: String,
         visualPlaceholderUrl: String? = nil,
         equipmentNeeded: [String] = [],
         estimatedDurationMinutes: Int? = nil,
         categories: [String] = [],
         isFeatured: Bool = false,
         progressionCriteriaText: String? = nil,
         progressionCriteria: ProgressionCriteria? = nil,
         safetyNotes: String? = nil,
         benefits: [String]? = nil,
         relatedMethods: [String]? = nil,
         timerConfig: TimerConfiguration? = nil,
         steps: [MethodStep]? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.stage = stage
        self.classification = classification
        self.title = title
        self.protocolDescription = protocolDescription
        self.instructionsText = instructionsText
        self.visualPlaceholderUrl = visualPlaceholderUrl
        self.equipmentNeeded = equipmentNeeded
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.categories = categories
        self.isFeatured = isFeatured
        self.progressionCriteriaText = progressionCriteriaText
        self.progressionCriteria = progressionCriteria
        self.safetyNotes = safetyNotes
        self.benefits = benefits
        self.relatedMethods = relatedMethods
        self.timerConfig = timerConfig
        self.steps = steps
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Encode the object with a coder
    /// CRITICAL: NSSecureCoding keys preserved exactly from TrainingProtocol for backward compatibility
    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(stage, forKey: "stage")
        coder.encode(title, forKey: "title")
        coder.encode(protocolDescription, forKey: "description")
        coder.encode(instructionsText, forKey: "instructionsText")
        coder.encode(visualPlaceholderUrl, forKey: "visualPlaceholderUrl")
        coder.encode(equipmentNeeded as NSArray, forKey: "equipmentNeeded")
        coder.encode(estimatedDurationMinutes, forKey: "estimatedDurationMinutes")
        coder.encode(categories as NSArray, forKey: "categories")
        coder.encode(isFeatured, forKey: "isFeatured")
        coder.encode(progressionCriteriaText, forKey: "progressionCriteriaText")
        coder.encode(safetyNotes, forKey: "safetyNotes")
        if let benefits = benefits {
            coder.encode(benefits as NSArray, forKey: "benefits")
        }
        if let relatedMethods = relatedMethods {
            coder.encode(relatedMethods as NSArray, forKey: "relatedMethods")
        }
        // Encode TimerConfiguration as Data
        if let timerConfig = timerConfig {
            do {
                let timerConfigData = try JSONEncoder().encode(timerConfig)
                coder.encode(timerConfigData, forKey: "timerConfig")
            } catch {
                Logger.error("Error encoding TimerConfiguration: \(error)")
                // Handle encoding error, perhaps by encoding nil or a default
            }
        }
        // Encode steps as Data
        if let steps = steps {
            do {
                let stepsData = try JSONEncoder().encode(steps)
                coder.encode(stepsData, forKey: "steps")
            } catch {
                Logger.error("Error encoding steps: \(error)")
            }
        }
        coder.encode(createdAt, forKey: "createdAt")
        coder.encode(updatedAt, forKey: "updatedAt")
        // Encode structured criteria as JSON data
        if let criteria = progressionCriteria {
            do {
                let data = try JSONEncoder().encode(criteria)
                coder.encode(data, forKey: "progressionCriteriaModel")
            } catch {
                Logger.error("Error encoding ProgressionCriteria: \(error)")
            }
        }
        if let classification = classification {
            coder.encode(classification, forKey: "classification")
        }
    }

    /// Required initializer for NSSecureCoding
    /// CRITICAL: NSSecureCoding keys preserved exactly from TrainingProtocol for backward compatibility
    required public init?(coder: NSCoder) {
        guard let id = coder.decodeObject(of: NSString.self, forKey: "id") as String?,
              let title = coder.decodeObject(of: NSString.self, forKey: "title") as String?,
              let protocolDescription = coder.decodeObject(of: NSString.self, forKey: "description") as String?,
              let instructionsText = coder.decodeObject(of: NSString.self, forKey: "instructionsText") as String?,
              let createdAt = coder.decodeObject(of: NSDate.self, forKey: "createdAt") as Date?,
              let updatedAt = coder.decodeObject(of: NSDate.self, forKey: "updatedAt") as Date?
        else {
            return nil
        }

        self.id = id
        self.stage = coder.decodeInteger(forKey: "stage")
        self.classification = coder.decodeObject(of: NSString.self, forKey: "classification") as String?
        self.title = title
        self.protocolDescription = protocolDescription
        self.instructionsText = instructionsText
        self.visualPlaceholderUrl = coder.decodeObject(of: NSString.self, forKey: "visualPlaceholderUrl") as String?
        self.equipmentNeeded = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "equipmentNeeded") as? [String]) ?? []
        self.estimatedDurationMinutes = coder.decodeObject(of: NSNumber.self, forKey: "estimatedDurationMinutes") as? Int
        self.categories = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "categories") as? [String]) ?? []
        self.isFeatured = coder.decodeBool(forKey: "isFeatured")
        self.progressionCriteriaText = coder.decodeObject(of: NSString.self, forKey: "progressionCriteriaText") as String?
        self.safetyNotes = coder.decodeObject(of: NSString.self, forKey: "safetyNotes") as String?
        self.benefits = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "benefits") as? [String]
        self.relatedMethods = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "relatedMethods") as? [String]

        // Decode TimerConfiguration from Data
        if let timerConfigData = coder.decodeObject(of: NSData.self, forKey: "timerConfig") as Data? {
            do {
                self.timerConfig = try JSONDecoder().decode(TimerConfiguration.self, from: timerConfigData)
            } catch {
                Logger.error("Error decoding TimerConfiguration: \(error)")
                // Handle decoding error, perhaps by setting to nil or a default
                self.timerConfig = nil
            }
        } else {
            self.timerConfig = nil
        }

        // Decode steps from Data
        if let stepsData = coder.decodeObject(of: NSData.self, forKey: "steps") as Data? {
            do {
                self.steps = try JSONDecoder().decode([MethodStep].self, from: stepsData)
            } catch {
                Logger.error("Error decoding steps: \(error)")
                self.steps = nil
            }
        } else {
            self.steps = nil
        }

        // Decode structured criteria
        if let data = coder.decodeObject(of: NSData.self, forKey: "progressionCriteriaModel") as Data? {
            self.progressionCriteria = try? JSONDecoder().decode(ProgressionCriteria.self, from: data)
        }

        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Initialize from Firestore document
    /// CRITICAL: Firestore field mappings preserved exactly from TrainingProtocol for backward compatibility
    convenience init?(document: DocumentSnapshot) {
        guard let data = document.data() else {
            return nil
        }

        // Log document data for debugging

        // Extract required fields with type checking
        guard let id = document.documentID as String? else {
            return nil
        }

        guard let stage = data["stage"] as? Int else {
            return nil
        }

        let classification = data["classification"] as? String

        guard let title = data["title"] as? String else {
            return nil
        }

        // For description, try both "description" (Firestore field) and "methodDescription" (legacy Swift model name)
        // CRITICAL: Maintains backward compatibility with existing Firestore documents
        let descriptionValue: String
        if let desc = data["description"] as? String, !desc.isEmpty {
            descriptionValue = desc
        } else if let desc = data["methodDescription"] as? String, !desc.isEmpty {
            descriptionValue = desc
        } else {
            descriptionValue = "No description available"
        }

        // For instructions, try multiple field naming patterns
        // CRITICAL: Maintains backward compatibility with existing Firestore documents
        let instructionsText: String
        if let text = data["instructions_text"] as? String, !text.isEmpty {
            instructionsText = text
        } else if let text = data["instructionsText"] as? String, !text.isEmpty {
            instructionsText = text
        } else if let text = data["instructions"] as? String, !text.isEmpty {
            instructionsText = text
        } else {
            instructionsText = "No instructions provided"
        }

        // Optional fields with defaults and multi-format handling
        let visualPlaceholderUrl = data["visual_placeholder_url"] as? String ??
                                  data["visualPlaceholderUrl"] as? String

        let equipmentNeeded = data["equipment_needed"] as? [String] ??
                             data["equipmentNeeded"] as? [String] ?? []

        let estimatedDurationMinutes = data["estimated_duration_minutes"] as? Int ??
                                      data["estimatedDurationMinutes"] as? Int ??
                                      data["estimated_time_minutes"] as? Int

        let categories = data["categories"] as? [String] ?? []

        let isFeatured = data["isFeatured"] as? Bool ??
                        data["is_featured"] as? Bool ?? false

        var progressionCriteriaModel: ProgressionCriteria? = nil
        if let criteriaMap = data["progressionCriteria"] as? [String: Any] {
            // Convert dictionary to Data then decode
            if let jsonData = try? JSONSerialization.data(withJSONObject: criteriaMap, options: []) {
                progressionCriteriaModel = try? JSONDecoder().decode(ProgressionCriteria.self, from: jsonData)
            }
        }

        let progressionCriteriaText = data["progression_criteria"] as? String ?? data["progressionCriteriaText"] as? String

        let safetyNotes = data["safety_notes"] as? String

        let benefits = data["benefits"] as? [String]

        let relatedMethods = data["related_techniques"] as? [String] ?? data["related_methods"] as? [String]

        // Deserialize steps from Firestore
        var stepsValue: [MethodStep]? = nil
        if let stepsArray = data["steps"] as? [[String: Any]] {
            stepsValue = stepsArray.compactMap { stepData in
                guard let stepNumber = stepData["step_number"] as? Int ?? stepData["stepNumber"] as? Int,
                      let title = stepData["title"] as? String,
                      let description = stepData["description"] as? String else {
                    return nil
                }

                return MethodStep(
                    stepNumber: stepNumber,
                    title: title,
                    description: description,
                    duration: stepData["duration"] as? Int,
                    tips: stepData["tips"] as? [String],
                    warnings: stepData["warnings"] as? [String],
                    intensity: stepData["intensity"] as? String
                )
            }
        }

        // Deserialize TimerConfiguration from Firestore map/dictionary
        var timerConfigValue: TimerConfiguration? = nil
        if let timerConfigData = data["timerConfig"] as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: timerConfigData, options: [])
                timerConfigValue = try JSONDecoder().decode(TimerConfiguration.self, from: jsonData)
            } catch {
            }
        } else if data["timerConfig"] != nil {
        } else {
        }

        let createdTimestamp = data["createdAt"] as? Timestamp
        let updatedTimestamp = data["updatedAt"] as? Timestamp

        let createdAt = createdTimestamp?.dateValue() ?? Date()
        let updatedAt = updatedTimestamp?.dateValue() ?? Date()

        self.init(
            id: id,
            stage: stage,
            classification: classification,
            title: title,
            protocolDescription: descriptionValue,
            instructionsText: instructionsText,
            visualPlaceholderUrl: visualPlaceholderUrl,
            equipmentNeeded: equipmentNeeded,
            estimatedDurationMinutes: estimatedDurationMinutes,
            categories: categories,
            isFeatured: isFeatured,
            progressionCriteriaText: progressionCriteriaText,
            progressionCriteria: progressionCriteriaModel,
            safetyNotes: safetyNotes,
            benefits: benefits,
            relatedMethods: relatedMethods,
            timerConfig: timerConfigValue,
            steps: stepsValue,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Convert to a dictionary for Firestore storage
    /// CRITICAL: Firestore field names preserved exactly from TrainingProtocol for backward compatibility
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "stage": stage,
            "description": protocolDescription,
            "instructionsText": instructionsText
        ]
        // Add structured progression criteria if available
        if let criteria = progressionCriteria,
           let data = try? JSONEncoder().encode(criteria),
           let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["progressionCriteria"] = map
        } else if let legacy = progressionCriteriaText {
            dict["progression_criteria"] = legacy
        }

        if let classification = classification {
            dict["classification"] = classification
        }

        return dict
    }
}

// MARK: - Backward Compatibility Extension
extension TrainingProtocol {
    /// @deprecated Use protocolDescription instead. Provided for backward compatibility.
    @available(*, deprecated, message: "Use protocolDescription instead")
    var methodDescription: String {
        get { protocolDescription }
        set { protocolDescription = newValue }
    }
}

// TimerConfiguration and MethodInterval remain unchanged - they are shared structs
// Added for Story 7.2
struct TimerConfiguration: Codable, Hashable {
    var recommendedDurationSeconds: Int?
    var isCountdown: Bool?
    var hasIntervals: Bool?
    var intervals: [MethodInterval]?
    var maxRecommendedDurationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case recommendedDurationSeconds = "recommended_duration_seconds"
        case isCountdown = "is_countdown"
        case hasIntervals = "has_intervals"
        case intervals
        case maxRecommendedDurationSeconds = "max_recommended_duration_seconds"
    }
}

// Added for Story 7.2
struct MethodInterval: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var durationSeconds: Int

    enum CodingKeys: String, CodingKey {
        case name
        case durationSeconds = "duration_seconds"
    }
}
