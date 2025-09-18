//
//  OnboardingStep.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case themeSelection
    case disclaimer
    case privacy
    case initialAssessment
    case paywall
    case routineGoalSelection
    case notificationPermissions
    case profileSetup
    case celebration
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .themeSelection: return "Theme Selection"
        case .disclaimer: return "Medical Disclaimer"
        case .privacy: return "Privacy & Terms"
        case .initialAssessment: return "Initial Assessment"
        case .paywall: return "Unlock Premium"
        case .routineGoalSelection: return "Choose Your Routine"
        case .notificationPermissions: return "Notifications"
        case .profileSetup: return "Profile Setup"
        case .celebration: return "Get Started"
        }
    }
}

enum ExperienceLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        switch self {
        case .beginner: return "New to vascular training"
        case .intermediate: return "Some experience with these methods"
        case .advanced: return "Experienced practitioner"
        }
    }
}