//
//  Report.swift
//  Growth
//
//  Model for content reporting system
//

import Foundation
import FirebaseFirestore

/// Model representing a user report on content
public struct Report: Codable, Identifiable {
    @DocumentID public var id: String?
    public let reporterId: String
    public let contentId: String
    public let contentType: ContentType
    public let creatorId: String
    public let reason: ReportReason
    public let details: String?
    public let createdAt: Date
    public var status: ReportStatus
    public var moderatorId: String?
    public var moderatorAction: ModeratorAction?
    public var resolutionDate: Date?
    public var resolutionNotes: String?
    
    public init(reporterId: String, contentId: String, contentType: ContentType, creatorId: String, reason: ReportReason, details: String? = nil) {
        self.reporterId = reporterId
        self.contentId = contentId
        self.contentType = contentType
        self.creatorId = creatorId
        self.reason = reason
        self.details = details
        self.createdAt = Date()
        self.status = .pending
    }
    
    public init(reporterId: String, contentId: String, contentType: ContentType, creatorId: String, reason: ReportReason, details: String? = nil, createdAt: Date, status: ReportStatus) {
        self.reporterId = reporterId
        self.contentId = contentId
        self.contentType = contentType
        self.creatorId = creatorId
        self.reason = reason
        self.details = details
        self.createdAt = createdAt
        self.status = status
    }
}

/// Types of content that can be reported
public enum ContentType: String, Codable, CaseIterable {
    case routine = "routine"
    case comment = "comment" // For future use
    case review = "review" // For future use
    case user = "user" // For reporting users directly
    
    public var displayName: String {
        switch self {
        case .routine: return "Routine"
        case .user: return "User Profile"
        case .comment: return "Comment"
        case .review: return "Review"
        }
    }
}

/// Reasons for reporting content
public enum ReportReason: String, Codable, CaseIterable {
    case inappropriate = "inappropriate"
    case spam = "spam"
    case misleading = "misleading"
    case harmful = "harmful"
    case copyright = "copyright"
    case impersonation = "impersonation"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .inappropriate: return "Inappropriate Content"
        case .spam: return "Spam or Scam"  
        case .misleading: return "Misleading Information"
        case .harmful: return "Harmful or Dangerous"
        case .copyright: return "Copyright Violation"
        case .impersonation: return "Impersonation"
        case .other: return "Other"
        }
    }
    
    public var description: String {
        switch self {
        case .inappropriate: 
            return "Contains offensive language, explicit content, or inappropriate material"
        case .spam: 
            return "Promotional content, repetitive posts, or scam attempts"
        case .misleading: 
            return "False or misleading health claims or information"
        case .harmful: 
            return "Promotes dangerous practices or could cause harm"
        case .copyright: 
            return "Uses copyrighted material without permission"
        case .impersonation:
            return "Pretending to be someone else or a different brand"
        case .other: 
            return "Violates community guidelines in other ways"
        }
    }
    
    public var icon: String {
        switch self {
        case .inappropriate: return "exclamationmark.triangle.fill"
        case .spam: return "envelope.badge.shield.half.filled"
        case .misleading: return "info.circle.fill"
        case .harmful: return "exclamationmark.shield.fill"
        case .copyright: return "c.circle.fill"
        case .impersonation: return "person.fill.xmark"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Status of a report
public enum ReportStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case reviewing = "reviewing"
    case resolved = "resolved"
    case dismissed = "dismissed"
    case escalated = "escalated"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .reviewing: return "Under Review"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        case .escalated: return "Escalated"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .reviewing: return "blue"
        case .resolved: return "green"
        case .dismissed: return "gray"
        case .escalated: return "red"
        }
    }
}

/// Actions that can be taken by moderators
public enum ModeratorAction: String, Codable, CaseIterable {
    case contentRemoved = "content_removed"
    case contentApproved = "content_approved"
    case contentEdited = "content_edited"
    case userWarned = "user_warned"
    case userSuspended = "user_suspended"
    case userBanned = "user_banned"
    case noAction = "no_action"
    
    public var displayName: String {
        switch self {
        case .contentRemoved: return "Content Removed"
        case .contentApproved: return "Content Approved"
        case .contentEdited: return "Content Edited"
        case .userWarned: return "User Warned"
        case .userSuspended: return "User Suspended"
        case .userBanned: return "User Banned"
        case .noAction: return "No Action Taken"
        }
    }
    
    public var severity: Int {
        switch self {
        case .noAction, .contentApproved: return 0
        case .contentEdited: return 1
        case .userWarned: return 2
        case .contentRemoved: return 3
        case .userSuspended: return 4
        case .userBanned: return 5
        }
    }
}

/// Extension to convert Report to Firestore data
extension Report {
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "reporterId": reporterId,
            "contentId": contentId,
            "contentType": contentType.rawValue,
            "creatorId": creatorId,
            "reason": reason.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]
        
        if let details = details {
            dict["details"] = details
        }
        
        if let moderatorId = moderatorId {
            dict["moderatorId"] = moderatorId
        }
        
        if let moderatorAction = moderatorAction {
            dict["moderatorAction"] = moderatorAction.rawValue
        }
        
        if let resolutionDate = resolutionDate {
            dict["resolutionDate"] = Timestamp(date: resolutionDate)
        }
        
        if let resolutionNotes = resolutionNotes {
            dict["resolutionNotes"] = resolutionNotes
        }
        
        return dict
    }
    
    /// Check if report is actionable
    public var isActionable: Bool {
        return status == .pending || status == .reviewing
    }
    
    /// Check if report is closed
    public var isClosed: Bool {
        return status == .resolved || status == .dismissed
    }
    
    /// Get time since report
    public var timeSinceReport: String {
        let interval = Date().timeIntervalSince(createdAt)
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }
    }
}