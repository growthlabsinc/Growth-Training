//
//  User.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import FirebaseFirestore

/// Model representing a user in the application
struct User: Codable, Identifiable {
    /// Unique identifier for the user (Firebase Auth UID)
    let id: String
    
    /// User's first name
    var firstName: String?
    
    /// Date when the user account was created
    let creationDate: Date
    
    /// Date of the user's last login
    let lastLogin: Date
    
    /// Map of progress data linked to this user
    let linkedProgressData: [String: String]?
    
    /// User settings and preferences
    let settings: UserSettings
    
    /// Whether the user has accepted the medical disclaimer
    var disclaimerAccepted: Bool?
    /// Timestamp of acceptance
    var disclaimerAcceptedTimestamp: Date?
    /// Version of the disclaimer accepted
    var disclaimerVersion: String?
    
    /// User's current session streak (number of consecutive days)
    let streak: Int
    
    /// List of earned badge IDs (most recent last)
    let earnedBadges: [String]
    
    /// Selected routine ID
    var selectedRoutineId: String?
    
    /// Consent records for legal documents
    var consentRecords: [ConsentRecord]?
    
    /// Initial method ID selected during onboarding assessment
    var initialMethodId: String?
    
    /// Initial assessment result ("needs_assistance" or "can_proceed")
    var initialAssessmentResult: String?
    
    /// Date when the initial assessment was completed
    var initialAssessmentDate: Date?
    
    /// User's preferred practice mode ("routine" or "adhoc")
    var preferredPracticeMode: String?
    
    /// Date when practice preference was set
    var practicePreferenceSetAt: Date?
    
    /// Whether the user has completed the app tour
    var hasCompletedAppTour: Bool?
    
    /// Whether the user has seen the app tour (started or skipped)
    var hasSeenAppTour: Bool?
    
    /// Whether the user skipped the app tour
    var hasSkippedAppTour: Bool?
    
    /// Timestamp when the tour was completed
    var tourCompletedAt: Date?
    
    /// Timestamp when the tour was skipped
    var tourSkippedAt: Date?
    
    /// Whether the user has completed onboarding
    var onboardingCompleted: Bool?
    
    // MARK: - Community & Creator Fields
    
    /// Unique username for the user (used for community features)
    var username: String?
    
    /// Display name for public profile
    var displayName: String?
    
    /// List of user IDs this user has blocked
    var blockedUserIds: [String]?
    
    /// Whether this user has created any community content
    var hasCreatedContent: Bool?
    
    /// Creator statistics (only populated if user has shared content)
    var creatorStats: CreatorStats?
    
    // MARK: - Admin & Moderation Fields
    
    /// Whether the user is an admin
    var isAdmin: Bool?
    
    /// Whether the user is a developer (has access to development tools)
    var isDeveloper: Bool?
    
    /// Whether the user is banned from the platform
    var isBanned: Bool?
    
    /// Date when the user was banned
    var bannedDate: Date?
    
    /// Reason for ban
    var banReason: String?
    
    /// Whether the user is suspended
    var isSuspended: Bool?
    
    /// Date until which the user is suspended
    var suspendedUntil: Date?
    
    /// Reason for suspension
    var suspensionReason: String?
    
    /// Number of warnings received
    var warnings: Int?
    
    /// Date of last warning
    var lastWarningDate: Date?
    
    // MARK: - Subscription Fields
    
    /// Current subscription tier
    var currentSubscriptionTier: SubscriptionTier?
    
    /// Date when the subscription expires
    var subscriptionExpirationDate: Date?
    
    /// Date when the subscription started
    var subscriptionStartDate: Date?
    
    /// Whether the user has used their free trial
    var hasUsedFreeTrial: Bool?
    
    // MARK: - Initializers
    
    init(id: String, firstName: String? = nil, creationDate: Date, lastLogin: Date, 
         linkedProgressData: [String: String]? = nil, settings: UserSettings,
         disclaimerAccepted: Bool? = nil, disclaimerAcceptedTimestamp: Date? = nil,
         disclaimerVersion: String? = nil, streak: Int = 0, earnedBadges: [String] = [],
         selectedRoutineId: String? = nil, consentRecords: [ConsentRecord]? = nil,
         initialMethodId: String? = nil, initialAssessmentResult: String? = nil,
         initialAssessmentDate: Date? = nil, preferredPracticeMode: String? = nil,
         practicePreferenceSetAt: Date? = nil, hasCompletedAppTour: Bool? = nil,
         hasSeenAppTour: Bool? = nil, hasSkippedAppTour: Bool? = nil,
         tourCompletedAt: Date? = nil, tourSkippedAt: Date? = nil,
         onboardingCompleted: Bool? = nil,
         username: String? = nil, displayName: String? = nil,
         blockedUserIds: [String]? = nil, hasCreatedContent: Bool? = nil,
         creatorStats: CreatorStats? = nil,
         currentSubscriptionTier: SubscriptionTier? = nil,
         subscriptionExpirationDate: Date? = nil,
         subscriptionStartDate: Date? = nil,
         hasUsedFreeTrial: Bool? = nil,
         isAdmin: Bool? = nil,
         isDeveloper: Bool? = nil) {
        self.id = id
        self.firstName = firstName
        self.creationDate = creationDate
        self.lastLogin = lastLogin
        self.linkedProgressData = linkedProgressData
        self.settings = settings
        self.disclaimerAccepted = disclaimerAccepted
        self.disclaimerAcceptedTimestamp = disclaimerAcceptedTimestamp
        self.disclaimerVersion = disclaimerVersion
        self.streak = streak
        self.earnedBadges = earnedBadges
        self.selectedRoutineId = selectedRoutineId
        self.consentRecords = consentRecords
        self.initialMethodId = initialMethodId
        self.initialAssessmentResult = initialAssessmentResult
        self.initialAssessmentDate = initialAssessmentDate
        self.preferredPracticeMode = preferredPracticeMode
        self.practicePreferenceSetAt = practicePreferenceSetAt
        self.hasCompletedAppTour = hasCompletedAppTour
        self.hasSeenAppTour = hasSeenAppTour
        self.hasSkippedAppTour = hasSkippedAppTour
        self.tourCompletedAt = tourCompletedAt
        self.tourSkippedAt = tourSkippedAt
        self.onboardingCompleted = onboardingCompleted
        self.username = username
        self.displayName = displayName
        self.blockedUserIds = blockedUserIds
        self.hasCreatedContent = hasCreatedContent
        self.creatorStats = creatorStats
        self.currentSubscriptionTier = currentSubscriptionTier
        self.subscriptionExpirationDate = subscriptionExpirationDate
        self.subscriptionStartDate = subscriptionStartDate
        self.hasUsedFreeTrial = hasUsedFreeTrial
        self.isAdmin = isAdmin
        self.isDeveloper = isDeveloper
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case firstName
        case creationDate
        case lastLogin
        case linkedProgressData
        case settings
        case disclaimerAccepted
        case disclaimerAcceptedTimestamp
        case disclaimerVersion
        case streak
        case earnedBadges
        case selectedRoutineId
        case consentRecords
        case initialMethodId
        case initialAssessmentResult
        case initialAssessmentDate
        case preferredPracticeMode
        case practicePreferenceSetAt
        case hasCompletedAppTour
        case hasSeenAppTour
        case hasSkippedAppTour
        case tourCompletedAt
        case tourSkippedAt
        case onboardingCompleted
        case username
        case displayName
        case blockedUserIds
        case hasCreatedContent
        case creatorStats
        case currentSubscriptionTier
        case subscriptionExpirationDate
        case subscriptionStartDate
        case hasUsedFreeTrial
    }
    
    // MARK: - Firestore Conversion
    
    /// Creates a User from a Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { 
            Logger.error("User init: No data in document")
            return nil 
        }
        
        // Try to get userId from document data first, fallback to document ID
        let userId = data["userId"] as? String ?? data["uid"] as? String ?? document.documentID
        
        // Extract fields with appropriate type conversion - make timestamps optional for better compatibility
        let creationTimestamp = data["creationDate"] as? Timestamp ?? data["createdAt"] as? Timestamp
        let lastLoginTimestamp = data["lastLogin"] as? Timestamp ?? data["updatedAt"] as? Timestamp
        
        // Validate required fields
        guard !userId.isEmpty else {
            Logger.error("User init: Empty userId from document: \(document.documentID)")
            return nil
        }
        
        self.id = userId
        self.firstName = data["firstName"] as? String
        self.creationDate = creationTimestamp?.dateValue() ?? Date()
        self.lastLogin = lastLoginTimestamp?.dateValue() ?? Date()
        self.linkedProgressData = data["linkedProgressData"] as? [String: String]
        
        // Parse settings or use default
        if let settingsData = data["settings"] as? [String: Any],
           let notificationsEnabled = settingsData["notificationsEnabled"] as? Bool,
           let privacyLevelString = settingsData["privacyLevel"] as? String,
           let privacyLevel = PrivacyLevel(rawValue: privacyLevelString) {
            
            let reminderTimestamp = settingsData["reminderTime"] as? Timestamp
            let reminderTime = reminderTimestamp?.dateValue()
            
            self.settings = UserSettings(
                notificationsEnabled: notificationsEnabled,
                reminderTime: reminderTime,
                privacyLevel: privacyLevel
            )
        } else {
            // Default settings if parsing fails
            self.settings = UserSettings(
                notificationsEnabled: false,
                reminderTime: nil,
                privacyLevel: .medium
            )
        }
        
        self.disclaimerAccepted = data["disclaimerAccepted"] as? Bool
        if let ts = data["disclaimerAcceptedTimestamp"] as? Timestamp {
            self.disclaimerAcceptedTimestamp = ts.dateValue()
        } else {
            self.disclaimerAcceptedTimestamp = nil
        }
        self.disclaimerVersion = data["disclaimerVersion"] as? String
        // Parse streak (default to 0 if missing)
        self.streak = data["streak"] as? Int ?? 0
        // Parse earned badges (default to empty array if missing)
        self.earnedBadges = data["earnedBadges"] as? [String] ?? []
        // Parse selected routine ID (default to nil if missing)
        self.selectedRoutineId = data["selectedRoutineId"] as? String
        
        // Parse consent records
        if let consentData = data["consentRecords"] as? [[String: Any]] {
        self.consentRecords = consentData.compactMap { recordData in
            guard let documentId = recordData["documentId"] as? String,
                  let documentVersion = recordData["documentVersion"] as? String,
                  let acceptedAtTimestamp = recordData["acceptedAt"] as? Timestamp else {
                return nil
            }
            return ConsentRecord(
                documentId: documentId,
                documentVersion: documentVersion,
                acceptedAt: acceptedAtTimestamp.dateValue(),
                ipAddress: recordData["ipAddress"] as? String
            )
        }
    } else {
        self.consentRecords = nil
    }
    
    // Parse initial assessment fields
    self.initialMethodId = data["initialMethodId"] as? String
    self.initialAssessmentResult = data["initialAssessmentResult"] as? String
    if let assessmentTimestamp = data["initialAssessmentDate"] as? Timestamp {
        self.initialAssessmentDate = assessmentTimestamp.dateValue()
    } else {
        self.initialAssessmentDate = nil
    }
    
    // Parse practice preference fields
    self.preferredPracticeMode = data["preferredPracticeMode"] as? String
    if let practicePreferenceTimestamp = data["practicePreferenceSetAt"] as? Timestamp {
        self.practicePreferenceSetAt = practicePreferenceTimestamp.dateValue()
    } else {
        self.practicePreferenceSetAt = nil
    }
    
    // Parse app tour fields
    self.hasCompletedAppTour = data["hasCompletedAppTour"] as? Bool
    self.hasSeenAppTour = data["hasSeenAppTour"] as? Bool
    self.hasSkippedAppTour = data["hasSkippedAppTour"] as? Bool
    if let tourCompletedTimestamp = data["tourCompletedAt"] as? Timestamp {
        self.tourCompletedAt = tourCompletedTimestamp.dateValue()
    } else {
        self.tourCompletedAt = nil
    }
    if let tourSkippedTimestamp = data["tourSkippedAt"] as? Timestamp {
        self.tourSkippedAt = tourSkippedTimestamp.dateValue()
    } else {
        self.tourSkippedAt = nil
    }
    
    // Parse onboarding completed flag
    self.onboardingCompleted = data["onboardingCompleted"] as? Bool
    
    // Parse community/creator fields
    self.username = data["username"] as? String
    self.displayName = data["displayName"] as? String
    self.blockedUserIds = data["blockedUserIds"] as? [String]
    self.hasCreatedContent = data["hasCreatedContent"] as? Bool
    
    // Parse creator stats
    if let statsData = data["creatorStats"] as? [String: Any] {
        let firstSharedTimestamp = statsData["firstSharedDate"] as? Timestamp
        self.creatorStats = CreatorStats(
            routinesShared: statsData["routinesShared"] as? Int ?? 0,
            totalDownloads: statsData["totalDownloads"] as? Int ?? 0,
            firstSharedDate: firstSharedTimestamp?.dateValue()
        )
    } else {
        self.creatorStats = nil
    }
    
    // Parse subscription fields
    if let tierString = data["currentSubscriptionTier"] as? String {
        self.currentSubscriptionTier = SubscriptionTier(rawValue: tierString)
    } else {
        self.currentSubscriptionTier = nil
    }
    
    if let expirationTimestamp = data["subscriptionExpirationDate"] as? Timestamp {
        self.subscriptionExpirationDate = expirationTimestamp.dateValue()
    } else {
        self.subscriptionExpirationDate = nil
    }
    
    if let startTimestamp = data["subscriptionStartDate"] as? Timestamp {
        self.subscriptionStartDate = startTimestamp.dateValue()
    } else {
        self.subscriptionStartDate = nil
    }
    
    self.hasUsedFreeTrial = data["hasUsedFreeTrial"] as? Bool
    
    // Parse admin and developer fields
    self.isAdmin = data["isAdmin"] as? Bool
    self.isDeveloper = data["isDeveloper"] as? Bool
    }
    
    /// Converts the User to a dictionary for Firestore
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": id,
            "creationDate": Timestamp(date: creationDate),
            "lastLogin": Timestamp(date: lastLogin),
            "settings": [
                "notificationsEnabled": settings.notificationsEnabled,
                "privacyLevel": settings.privacyLevel.rawValue
            ] as [String: Any]
        ]
        
        // Add optional fields
        if let firstName = firstName {
            data["firstName"] = firstName
        }
        
        if let linkedData = linkedProgressData {
            data["linkedProgressData"] = linkedData
        }
        
        if let reminderTime = settings.reminderTime {
            (data["settings"] as? NSMutableDictionary)?["reminderTime"] = Timestamp(date: reminderTime)
        }
        
        if let disclaimerAccepted = disclaimerAccepted {
            data["disclaimerAccepted"] = disclaimerAccepted
        }
        if let disclaimerAcceptedTimestamp = disclaimerAcceptedTimestamp {
            data["disclaimerAcceptedTimestamp"] = Timestamp(date: disclaimerAcceptedTimestamp)
        }
        if let disclaimerVersion = disclaimerVersion {
            data["disclaimerVersion"] = disclaimerVersion
        }
        
        if streak > 0 {
            data["streak"] = streak
        }
        if !earnedBadges.isEmpty {
            data["earnedBadges"] = earnedBadges
        }
        
        if let selectedRoutineId = selectedRoutineId {
            data["selectedRoutineId"] = selectedRoutineId
        }
        
        if let consentRecords = consentRecords, !consentRecords.isEmpty {
            data["consentRecords"] = consentRecords.map { record in
                var recordData: [String: Any] = [
                    "documentId": record.documentId,
                    "documentVersion": record.documentVersion,
                    "acceptedAt": Timestamp(date: record.acceptedAt)
                ]
                if let ipAddress = record.ipAddress {
                    recordData["ipAddress"] = ipAddress
                }
                return recordData
            }
        }
        
        // Add initial assessment fields
        if let initialMethodId = initialMethodId {
            data["initialMethodId"] = initialMethodId
        }
        if let initialAssessmentResult = initialAssessmentResult {
            data["initialAssessmentResult"] = initialAssessmentResult
        }
        if let initialAssessmentDate = initialAssessmentDate {
            data["initialAssessmentDate"] = Timestamp(date: initialAssessmentDate)
        }
        
        // Add practice preference fields
        if let preferredPracticeMode = preferredPracticeMode {
            data["preferredPracticeMode"] = preferredPracticeMode
        }
        if let practicePreferenceSetAt = practicePreferenceSetAt {
            data["practicePreferenceSetAt"] = Timestamp(date: practicePreferenceSetAt)
        }
        
        // Add app tour fields
        if let hasCompletedAppTour = hasCompletedAppTour {
            data["hasCompletedAppTour"] = hasCompletedAppTour
        }
        if let hasSeenAppTour = hasSeenAppTour {
            data["hasSeenAppTour"] = hasSeenAppTour
        }
        if let hasSkippedAppTour = hasSkippedAppTour {
            data["hasSkippedAppTour"] = hasSkippedAppTour
        }
        if let tourCompletedAt = tourCompletedAt {
            data["tourCompletedAt"] = Timestamp(date: tourCompletedAt)
        }
        if let tourSkippedAt = tourSkippedAt {
            data["tourSkippedAt"] = Timestamp(date: tourSkippedAt)
        }
        
        // Add onboarding completed flag
        if let onboardingCompleted = onboardingCompleted {
            data["onboardingCompleted"] = onboardingCompleted
        }
        
        // Add community/creator fields
        if let username = username {
            data["username"] = username
        }
        if let displayName = displayName {
            data["displayName"] = displayName
        }
        if let blockedUserIds = blockedUserIds {
            data["blockedUserIds"] = blockedUserIds
        }
        if let hasCreatedContent = hasCreatedContent {
            data["hasCreatedContent"] = hasCreatedContent
        }
        if let creatorStats = creatorStats {
            var statsData: [String: Any] = [
                "routinesShared": creatorStats.routinesShared,
                "totalDownloads": creatorStats.totalDownloads
            ]
            if let firstSharedDate = creatorStats.firstSharedDate {
                statsData["firstSharedDate"] = Timestamp(date: firstSharedDate)
            }
            data["creatorStats"] = statsData
        }
        
        // Add subscription fields
        if let tier = currentSubscriptionTier {
            data["currentSubscriptionTier"] = tier.rawValue
        }
        
        if let expirationDate = subscriptionExpirationDate {
            data["subscriptionExpirationDate"] = Timestamp(date: expirationDate)
        }
        
        if let startDate = subscriptionStartDate {
            data["subscriptionStartDate"] = Timestamp(date: startDate)
        }
        
        if let hasUsedFreeTrial = hasUsedFreeTrial {
            data["hasUsedFreeTrial"] = hasUsedFreeTrial
        }
        
        // Add admin and developer fields
        if let isAdmin = isAdmin {
            data["isAdmin"] = isAdmin
        }
        if let isDeveloper = isDeveloper {
            data["isDeveloper"] = isDeveloper
        }
        
        return data
    }
}

/// Settings and preferences for a user
struct UserSettings: Codable {
    /// Whether push notifications are enabled
    let notificationsEnabled: Bool
    
    /// Time of day for daily reminders (if enabled)
    let reminderTime: Date?
    
    /// Privacy level setting for user data
    let privacyLevel: PrivacyLevel
}

/// Privacy level options for user data
enum PrivacyLevel: String, Codable {
    /// High privacy - minimal data collection and sharing
    case high
    
    /// Medium privacy - balanced data collection and sharing
    case medium
    
    /// Low privacy - more extensive data collection and sharing
    case low
}

/// Statistics for content creators
struct CreatorStats: Codable {
    /// Number of routines shared by this creator
    let routinesShared: Int
    
    /// Total downloads across all shared routines
    let totalDownloads: Int
    
    /// Date when the user first shared content
    let firstSharedDate: Date?
} 