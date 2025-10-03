//
//  ProgressInsight.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import Foundation

/// Represents a contextual insight generated from user's progress data
struct ProgressInsight: Identifiable {
    /// Unique identifier for the insight
    let id: String
    
    /// Type of insight for categorization and styling
    let type: InsightType
    
    /// Short, impactful title for the insight
    let title: String
    
    /// Detailed message providing context and encouragement
    let message: String
    
    /// SF Symbol name for visual representation
    let icon: String
    
    /// Optional action text for user engagement
    let actionText: String?
    
    /// Priority for sorting/filtering (higher = more important)
    let priority: Int
    
    /// When this insight was generated
    let generatedAt: Date
    
    /// When this insight should expire and no longer be shown
    let expiresAt: Date?
    
    /// Create a new insight with auto-generated ID and timestamp
    init(type: InsightType,
         title: String,
         message: String,
         icon: String,
         actionText: String? = nil,
         priority: Int,
         expiresAt: Date? = nil,
         customId: String? = nil) {
        // Use custom ID if provided, otherwise generate unique ID based on type, date, and content
        if let customId = customId {
            self.id = customId
        } else {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateString = Int(today.timeIntervalSince1970)
            let uniqueHash = "\(title)_\(message)".hashValue
            self.id = "\(type.rawValue)_\(dateString)_\(uniqueHash)"
        }
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.actionText = actionText
        self.priority = priority
        self.generatedAt = Date()
        self.expiresAt = expiresAt
    }
}

/// Types of insights that can be generated from progress data
enum InsightType: String, CaseIterable {
    /// Positive trend in practice time or frequency
    case trendPositive = "trend_positive"
    
    /// Negative trend indicating reduced activity
    case trendNegative = "trend_negative"
    
    /// High adherence to routine schedule
    case adherenceHigh = "adherence_high"
    
    /// Low adherence needing encouragement
    case adherenceLow = "adherence_low"
    
    /// Milestone achievement in practice streak
    case streakMilestone = "streak_milestone"
    
    /// Consistent practice pattern detected
    case consistencyPattern = "consistency_pattern"
    
    /// Warning about extended period of inactivity
    case inactivityWarning = "inactivity_warning"
    
    /// Color associated with the insight type for UI styling
    var color: String {
        switch self {
        case .trendPositive, .adherenceHigh, .streakMilestone, .consistencyPattern:
            return "GrowthGreen"
        case .trendNegative, .adherenceLow, .inactivityWarning:
            return "ErrorColor"
        }
    }
    
    /// Default icon for the insight type if not specified
    var defaultIcon: String {
        switch self {
        case .trendPositive:
            return "arrow.up.right.circle.fill"
        case .trendNegative:
            return "arrow.down.right.circle.fill"
        case .adherenceHigh:
            return "checkmark.circle.fill"
        case .adherenceLow:
            return "exclamationmark.triangle.fill"
        case .streakMilestone:
            return "flame.fill"
        case .consistencyPattern:
            return "calendar.badge.checkmark"
        case .inactivityWarning:
            return "clock.badge.exclamationmark.fill"
        }
    }
}

// MARK: - Equatable
extension ProgressInsight: Equatable {
    static func == (lhs: ProgressInsight, rhs: ProgressInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension ProgressInsight: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}