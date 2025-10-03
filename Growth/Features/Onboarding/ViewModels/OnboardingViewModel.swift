//
//  OnboardingViewModel.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete: Bool = false
    @Published var isCheckingStatus: Bool = true
    @Published var selectedGoals: Set<String> = []
    @Published var selectedExperience: ExperienceLevel = .beginner
    @Published var selectedRoutineId: String?
    @Published var acceptedDisclaimer: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldExitOnboarding: Bool = false  // Track when user wants to exit onboarding
    
    private let onboardingService = OnboardingService.shared
    private let userService = UserService.shared
    private let routineService = RoutineService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // OnboardingStep and ExperienceLevel moved to Models/OnboardingStep.swift
    
    init() {
        // Don't check status here - MainView will call checkOnboardingStatus when appropriate
    }
    
    func checkOnboardingStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            Logger.debug("OnboardingViewModel: No authenticated user when checking status")
            isCheckingStatus = false
            return 
        }
        
        Logger.debug("OnboardingViewModel: Checking onboarding status for user: \(userId)")
        isCheckingStatus = true
        
        // Check if user has completed onboarding by checking user data
        userService.fetchUser(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    let isComplete = user.onboardingCompleted ?? false
                    Logger.debug("OnboardingViewModel: User onboarding status - completed: \(isComplete)")
                    self?.isOnboardingComplete = isComplete
                    self?.isCheckingStatus = false
                case .failure(let error):
                    Logger.debug("OnboardingViewModel: Failed to fetch user: \(error)")
                    self?.isOnboardingComplete = false
                    self?.isCheckingStatus = false
                }
            }
        }
    }
    
    func nextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue + 1 }) else {
            completeOnboarding()
            return
        }
        currentStep = OnboardingStep.allCases[nextIndex]
    }
    
    // Alias for nextStep() to maintain compatibility
    func advance() {
        // Skip paywall step if paywalls are disabled
        if !FeatureFlags.showPaywallInOnboarding && currentStep == .initialAssessment {
            // Jump directly from initialAssessment to routineGoalSelection, skipping paywall
            currentStep = .routineGoalSelection
        } else {
            nextStep()
        }
    }
    
    func previousStep() {
        guard let previousIndex = OnboardingStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue - 1 }) else {
            return
        }
        currentStep = OnboardingStep.allCases[previousIndex]
    }
    
    // Alias for previousStep() to maintain compatibility
    func regress() {
        // If at the welcome screen, exit onboarding to go back to sign-up
        if currentStep == .welcome {
            exitOnboarding()
        } else {
            // Skip paywall when going backwards if it's disabled
            if !FeatureFlags.showPaywallInOnboarding && currentStep == .routineGoalSelection {
                // Jump directly back to initialAssessment, skipping paywall
                currentStep = .initialAssessment
            } else {
                previousStep()
            }
        }
    }
    
    func exitOnboarding() {
        // Sign out the user and return to authentication flow
        Logger.debug("OnboardingViewModel: User requested to exit onboarding")
        shouldExitOnboarding = true
        
        // Sign out the user to return to authentication
        do {
            try Auth.auth().signOut()
            Logger.debug("OnboardingViewModel: Successfully signed out user")
        } catch {
            Logger.error("OnboardingViewModel: Failed to sign out user: \(error)")
            errorMessage = "Failed to exit onboarding: \(error.localizedDescription)"
        }
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    func selectGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    func acceptDisclaimer() {
        acceptedDisclaimer = true
        nextStep()
    }
    
    func selectRoutine(_ routineId: String) {
        selectedRoutineId = routineId
    }
    
    private func completeOnboarding() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            Logger.debug("OnboardingViewModel: No authenticated user when completing onboarding")
            return 
        }
        
        Logger.debug("OnboardingViewModel: Completing onboarding for user: \(userId)")
        
        isLoading = true
        errorMessage = nil
        
        // Save user preferences
        let preferences: [String: Any] = [
            "goals": Array(selectedGoals),
            "experienceLevel": selectedExperience.rawValue,
            "onboardingCompleted": true,
            "onboardingCompletedDate": Date()
        ]
        
        Logger.debug("OnboardingViewModel: Saving onboarding completion with preferences: \(preferences)")
        
        userService.updateUserFields(userId: userId, fields: preferences) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            
            // Set selected routine if any
            if let routineId = self?.selectedRoutineId {
                self?.userService.updateSelectedRoutine(userId: userId, routineId: routineId) { error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if error == nil {
                            self?.isOnboardingComplete = true
                            // Onboarding completion is already marked in preferences
                        } else {
                            self?.errorMessage = error?.localizedDescription
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    Logger.debug("OnboardingViewModel: Onboarding completed successfully (no routine selected)")
                    self?.isOnboardingComplete = true
                    self?.isCheckingStatus = false
                    // Onboarding completion is already marked in preferences
                }
            }
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .themeSelection:
            return true
        case .disclaimer:
            return acceptedDisclaimer
        case .privacy:
            return true
        case .initialAssessment:
            return true
        case .paywall:
            return true
        case .routineGoalSelection:
            return selectedRoutineId != nil
        case .notificationPermissions:
            return true
        case .profileSetup:
            return true
        case .celebration:
            return true
        }
    }
    
    var progressPercentage: Double {
        let totalSteps = Double(OnboardingStep.allCases.count)
        let currentStepIndex = Double(currentStep.rawValue)
        return (currentStepIndex + 1) / totalSteps
    }
}