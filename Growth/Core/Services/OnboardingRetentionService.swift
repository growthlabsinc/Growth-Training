//
//  OnboardingRetentionService.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Service for managing onboarding retention and re-engagement logic
class OnboardingRetentionService {
    
    // MARK: - Singleton
    static let shared = OnboardingRetentionService()
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Re-engagement Trigger Points
    enum OnboardingStage: String {
        case notStarted = "not_started"
        case accountCreated = "account_created"
        case disclaimerAccepted = "disclaimer_accepted"
        case privacyAccepted = "privacy_accepted"
        case assessmentCompleted = "assessment_completed"
        case practicePreferenceSet = "practice_preference_set"
        case notificationPreferenceSet = "notification_preference_set"
        case completed = "completed"
    }
    
    // MARK: - Public Methods
    
    /// Check if user has completed onboarding
    func isOnboardingComplete(for userId: String) -> Bool {
        // Check UserDefaults for onboarding completion
        let onboardingKey = "onboardingStep"
        let stepRaw = UserDefaults.standard.integer(forKey: onboardingKey)
        // Consider onboarding complete if user has reached or passed the celebration step
        return stepRaw >= OnboardingStep.celebration.rawValue
    }
    
    /// Get current onboarding stage for a user
    func getCurrentOnboardingStage(for user: User) -> OnboardingStage {
        // Determine stage based on user properties
        // Consider complete if user has set notification preferences in settings
        if user.settings.notificationsEnabled && user.preferredPracticeMode != nil {
            return .completed
        } else if user.preferredPracticeMode != nil {
            return .practicePreferenceSet
        } else if user.initialAssessmentResult != nil {
            return .assessmentCompleted
        } else if user.consentRecords?.contains(where: { $0.documentId == "privacy_policy" }) == true {
            return .privacyAccepted
        } else if user.disclaimerAccepted == true {
            return .disclaimerAccepted
        } else if !user.id.isEmpty {
            return .accountCreated
        } else {
            return .notStarted
        }
    }
    
    /// Check if user has abandoned onboarding and needs re-engagement
    func shouldTriggerReengagement(for user: User, lastActiveDate: Date?) -> Bool {
        let currentStage = getCurrentOnboardingStage(for: user)
        
        // Don't re-engage if onboarding is complete
        if currentStage == .completed {
            return false
        }
        
        // Don't re-engage if user hasn't started
        if currentStage == .notStarted {
            return false
        }
        
        // Check time since last active
        guard let lastActive = lastActiveDate else {
            return false
        }
        
        let hoursSinceActive = Date().timeIntervalSince(lastActive) / 3600
        
        // Re-engagement thresholds based on stage
        switch currentStage {
        case .accountCreated:
            // Re-engage after 2 hours if only account created
            return hoursSinceActive > 2
        case .disclaimerAccepted, .privacyAccepted:
            // Re-engage after 6 hours if consents given but assessment not done
            return hoursSinceActive > 6
        case .assessmentCompleted:
            // Re-engage after 12 hours if assessment done but no practice preference
            return hoursSinceActive > 12
        case .practicePreferenceSet:
            // Re-engage after 24 hours if practice set but notifications not configured
            return hoursSinceActive > 24
        default:
            return false
        }
    }
    
    /// Get re-engagement message based on abandonment stage
    func getReengagementMessage(for stage: OnboardingStage) -> (title: String, body: String) {
        switch stage {
        case .accountCreated:
            return (
                "Complete Your Setup",
                "You're just a few steps away from starting your growth journey. Tap to continue where you left off."
            )
        case .disclaimerAccepted, .privacyAccepted:
            return (
                "Find Your Starting Point",
                "Let's quickly assess where to begin your personalized growth journey."
            )
        case .assessmentCompleted:
            return (
                "Choose Your Practice Style",
                "Will you follow a structured routine or practice at your own pace? Let's finish setting up."
            )
        case .practicePreferenceSet:
            return (
                "One Last Step!",
                "Enable reminders to stay consistent with your growth practice."
            )
        default:
            return ("", "")
        }
    }
    
    /// Track onboarding progress in user profile
    func updateOnboardingProgress(userId: String, stage: OnboardingStage) {
        let progressData: [String: Any] = [
            "onboardingStage": stage.rawValue,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).updateData([
            "onboardingProgress": progressData
        ]) { error in
            if let error = error {
                Logger.error("Error updating onboarding progress: \(error)")
            }
        }
    }
    
    /// Check if user has seen dashboard for the first time
    func hasSeenDashboard(userId: String) -> Bool {
        let key = "hasSeenDashboard_\(userId)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Mark that user has seen dashboard
    func markDashboardSeen(userId: String) {
        let key = "hasSeenDashboard_\(userId)"
        UserDefaults.standard.set(true, forKey: key)
        
        // Also update onboarding as complete if not already
        updateOnboardingProgress(userId: userId, stage: .completed)
    }
    
    // MARK: - Private Methods
    
    private init() {}
}

// MARK: - Re-engagement Notification Logic Documentation
/*
 Re-engagement Notification Implementation Guide:
 
 1. Local Notifications:
    - Schedule local notifications when user abandons onboarding
    - Use UNUserNotificationCenter to schedule based on stage
    - Cancel scheduled notifications when user returns
 
 2. Push Notifications (Future):
    - Use Firebase Cloud Messaging for server-triggered notifications
    - Create Cloud Function to monitor user activity
    - Trigger based on Firestore onboardingProgress field
 
 3. Trigger Points:
    - Account Created: 2 hours
    - Disclaimer/Privacy Accepted: 6 hours
    - Assessment Completed: 12 hours
    - Practice Preference Set: 24 hours
 
 4. Implementation Steps:
    - Track app background/foreground transitions
    - Schedule notification on background if onboarding incomplete
    - Cancel notification on foreground return
    - Deep link notification to appropriate onboarding step
 
 5. Analytics:
    - Track re-engagement notification effectiveness
    - Monitor completion rates by abandonment stage
    - A/B test notification timing and messaging
 */