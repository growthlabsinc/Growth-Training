import Foundation

/// Structured criteria that determines when a user is *ready* to progress from the current Growth Method stage.
public struct ProgressionCriteria: Codable, Hashable, Identifiable {
    public var id: String { UUID().uuidString }

    /// Minimum number of sessions the user must complete at this stage.
    public let minSessionsAtThisStage: Int?
    /// Minimum consecutive practice days required.
    public let minConsecutiveDaysPractice: Int?
    /// Subjective feedback requirement keyed by Mood/raw values (e.g. "good": 3 sessions).
    public let subjectiveFeedbackRequirement: [String: Int]?
    /// Minimum total minutes spent practicing at this stage.
    public let timeSpentAtStageMinutes: Int?
    /// Catch-all for method-specific or future criteria.
    public let additionalCriteria: [String: String]?

    public init(minSessionsAtThisStage: Int? = nil,
                minConsecutiveDaysPractice: Int? = nil,
                subjectiveFeedbackRequirement: [String: Int]? = nil,
                timeSpentAtStageMinutes: Int? = nil,
                additionalCriteria: [String: String]? = nil) {
        self.minSessionsAtThisStage = minSessionsAtThisStage
        self.minConsecutiveDaysPractice = minConsecutiveDaysPractice
        self.subjectiveFeedbackRequirement = subjectiveFeedbackRequirement
        self.timeSpentAtStageMinutes = timeSpentAtStageMinutes
        self.additionalCriteria = additionalCriteria
    }

    /// Human-readable description useful for debug/UI until dedicated UI is built.
    public var description: String {
        var parts: [String] = []
        if let minSessionsAtThisStage { parts.append("• At least \(minSessionsAtThisStage) sessions") }
        if let minConsecutiveDaysPractice { parts.append("• Practice \(minConsecutiveDaysPractice)+ consecutive days") }
        if let subjective = subjectiveFeedbackRequirement, !subjective.isEmpty {
            let desc = subjective.map { "\($0.key.capitalized): \($0.value)x" }.joined(separator: ", ")
            parts.append("• Feedback (")
            parts.append(desc)
            parts.append(")")
        }
        if let timeSpentAtStageMinutes { parts.append("• \(timeSpentAtStageMinutes) minutes total") }
        return parts.joined(separator: "\n")
    }
} 