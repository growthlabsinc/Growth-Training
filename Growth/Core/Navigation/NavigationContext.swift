//
//  NavigationContext.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation
import SwiftUI
import Combine

/// Represents the destination for smart navigation returns
enum ReturnDestination: Equatable {
    case dashboard
    case practiceTab
    case progressTab
    case routineDetail(routineId: String)
}

/// Manages app-wide navigation context for smart navigation and breadcrumb display
class NavigationContext: ObservableObject {
    // MARK: - Published Properties
    
    /// The current day number in a routine (e.g., Day 5)
    @Published var routineDayNumber: Int?
    
    /// The current method index within a day (1-based)
    @Published var currentMethodIndex: Int?
    
    /// Total number of methods in the current day
    @Published var totalMethods: Int?
    
    /// Where to return after completing a flow
    @Published var returnDestination: ReturnDestination = .dashboard
    
    /// Whether a practice flow is currently active
    @Published var practiceFlowActive: Bool = false
    
    /// The routine ID for context (used for smart returns)
    @Published var currentRoutineId: String?
    
    /// The day name for display (e.g., "Day 5: Heavy Training")
    @Published var currentDayName: String?
    
    /// Whether the current session is a multi-method session
    @Published var isMultiMethodSession: Bool = false
    
    /// The current method being practiced
    @Published var currentMethodName: String?
    
    // MARK: - Computed Properties
    
    /// Generates the breadcrumb text based on current context
    var breadcrumbText: String? {
        guard let dayNumber = routineDayNumber else { return nil }
        
        // For multi-method sessions, only show method progress
        if let currentMethod = currentMethodIndex,
           let total = totalMethods,
           total > 1 {
            return "Method \(currentMethod) of \(total)"
        }
        
        // For single method sessions, show day context
        var text = "Day \(dayNumber)"
        
        // Only add the full day name if it's not redundant
        if let dayName = currentDayName,
           !dayName.lowercased().starts(with: "day \(dayNumber)") {
            text = dayName
        }
        
        return text
    }
    
    /// Whether breadcrumb should be shown
    var showBreadcrumb: Bool {
        return practiceFlowActive && routineDayNumber != nil
    }
    
    // MARK: - Methods
    
    /// Sets up context for a routine practice session
    func setupRoutineContext(dayNumber: Int, dayName: String?, totalMethods: Int, routineId: String?) {
        self.routineDayNumber = dayNumber
        self.currentDayName = dayName
        self.totalMethods = totalMethods
        self.currentRoutineId = routineId
        self.currentMethodIndex = 1
        self.practiceFlowActive = true
        self.returnDestination = .dashboard
        self.isMultiMethodSession = totalMethods > 1
    }
    
    /// Sets up context for a quick practice session
    func setupQuickPracticeContext() {
        self.routineDayNumber = nil
        self.currentDayName = nil
        self.totalMethods = nil
        self.currentRoutineId = nil
        self.currentMethodIndex = nil
        self.practiceFlowActive = true
        self.returnDestination = .practiceTab
    }
    
    /// Updates the current method index
    func updateMethodProgress(to index: Int) {
        self.currentMethodIndex = index
    }
    
    /// Updates the current method name
    func updateCurrentMethod(name: String?) {
        self.currentMethodName = name
    }
    
    /// Clears all navigation context
    func clearContext() {
        self.routineDayNumber = nil
        self.currentDayName = nil
        self.currentMethodIndex = nil
        self.totalMethods = nil
        self.currentRoutineId = nil
        self.practiceFlowActive = false
        self.isMultiMethodSession = false
        self.currentMethodName = nil
        // Preserve return destination for smart returns
    }
    
    /// Determines the appropriate return destination based on context
    func determineReturnDestination() -> ReturnDestination {
        // If we have a routine context, consider returning to routine detail
        if currentRoutineId != nil {
            // For now, return to dashboard for routine completions
            // Could be enhanced to return to routine detail in some cases
            return .dashboard
        }
        
        // Return to wherever the flow was initiated from
        return returnDestination
    }
}