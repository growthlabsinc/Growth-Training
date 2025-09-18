//
//  SessionCompletionService.swift
//  Growth
//
//  Service to manage global session completion state
//

import Foundation
import SwiftUI
import Combine

/// Service to manage session completion prompts globally across the app
@MainActor
class SessionCompletionService: ObservableObject {
    static let shared = SessionCompletionService()
    
    @Published var showCompletionPrompt: Bool = false
    @Published var sessionProgress: SessionProgress?
    @Published var pendingCompletion: PendingCompletion?
    
    private init() {}
    
    struct PendingCompletion {
        let sessionProgress: SessionProgress
        let completionViewModel: SessionCompletionViewModel
        let sessionViewModel: MultiMethodSessionViewModel?
        let timerService: TimerService
        let configureTimerForMethod: ((GrowthMethod) -> Void)?
        let hasHandledTimerCompletion: Binding<Bool>?
        let isShowingCompletionPrompt: Binding<Bool>?
    }
    
    /// Show the completion prompt with the given session progress
    func showCompletion(
        sessionProgress: SessionProgress,
        completionViewModel: SessionCompletionViewModel,
        sessionViewModel: MultiMethodSessionViewModel? = nil,
        timerService: TimerService,
        configureTimerForMethod: ((GrowthMethod) -> Void)? = nil,
        hasHandledTimerCompletion: Binding<Bool>? = nil,
        isShowingCompletionPrompt: Binding<Bool>? = nil
    ) {
        self.sessionProgress = sessionProgress
        self.pendingCompletion = PendingCompletion(
            sessionProgress: sessionProgress,
            completionViewModel: completionViewModel,
            sessionViewModel: sessionViewModel,
            timerService: timerService,
            configureTimerForMethod: configureTimerForMethod,
            hasHandledTimerCompletion: hasHandledTimerCompletion,
            isShowingCompletionPrompt: isShowingCompletionPrompt
        )
        self.showCompletionPrompt = true
        
        // Also set the completion view model's flag on the main actor
        Task { @MainActor in
            completionViewModel.showCompletionPrompt = true
        }
    }
    
    /// Hide the completion prompt
    func hideCompletion() {
        self.showCompletionPrompt = false
        self.sessionProgress = nil
        self.pendingCompletion = nil
    }
    
    /// Check if there's a pending completion
    var hasPendingCompletion: Bool {
        pendingCompletion != nil && showCompletionPrompt
    }
}