//
//  SmartNavigationService.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation
import SwiftUI

/// Service for managing smart navigation returns and flow transitions
class SmartNavigationService: ObservableObject {
    // MARK: - Singleton
    static let shared = SmartNavigationService()
    
    // MARK: - Published Properties
    @Published var pendingNavigation: PendingNavigation?
    
    // MARK: - Private Properties
    private let navigationContext: NavigationContext
    
    // MARK: - Types
    struct PendingNavigation {
        let destination: ReturnDestination
        let delay: TimeInterval
    }
    
    // MARK: - Initialization
    init(navigationContext: NavigationContext = NavigationContext()) {
        self.navigationContext = navigationContext
    }
    
    // MARK: - Public Methods
    
    /// Executes a smart return based on the current navigation context
    func executeSmartReturn() {
        let destination = navigationContext.determineReturnDestination()
        
        // Clear practice flow context
        navigationContext.practiceFlowActive = false
        
        // Post notification for tab switching if needed
        switch destination {
        case .dashboard:
            NotificationCenter.default.post(
                name: Notification.Name("switchToHomeTab"),
                object: nil
            )
        case .practiceTab:
            // Already on practice tab in most cases
            break
        case .progressTab:
            NotificationCenter.default.post(
                name: Notification.Name("switchToProgressTab"),
                object: nil
            )
        case .routineDetail(let routineId):
            NotificationCenter.default.post(
                name: Notification.Name("navigateToRoutineDetail"),
                object: nil,
                userInfo: ["routineId": routineId]
            )
        }
        
        // Set pending navigation for views to handle
        pendingNavigation = PendingNavigation(destination: destination, delay: 0.3)
        
        // Clear pending navigation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.pendingNavigation = nil
        }
    }
    
    /// Prepares for a method-to-method transition
    func prepareMethodTransition(from currentIndex: Int, to nextIndex: Int) {
        // Update context
        navigationContext.updateMethodProgress(to: nextIndex)
        
        // Could add transition animations or effects here
        provideHapticFeedback()
    }
    
    /// Completes the current practice flow
    func completePracticeFlow() {
        // Add any completion effects
        provideSuccessHapticFeedback()
        
        // Always return to practice tab after timer completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Clear practice flow context
            self?.navigationContext.practiceFlowActive = false
            
            // Always navigate to practice tab
            NotificationCenter.default.post(
                name: Notification.Name("switchToPracticeTab"),
                object: nil
            )
            
            // Set pending navigation
            self?.pendingNavigation = PendingNavigation(destination: .practiceTab, delay: 0.3)
            
            // Clear pending navigation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.pendingNavigation = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func provideHapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func provideSuccessHapticFeedback() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
    static let switchToPracticeTab = Notification.Name("switchToPracticeTab")
    static let switchToProgressTab = Notification.Name("switchToProgressTab")
    static let switchToRoutinesTab = Notification.Name("switchToRoutinesTab")
    static let navigateToRoutineDetail = Notification.Name("navigateToRoutineDetail")
}