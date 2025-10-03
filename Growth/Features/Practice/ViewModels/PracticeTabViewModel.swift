//
//  PracticeTabViewModel.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation
import Combine
import FirebaseAuth

// Using PracticeOption from Models/PracticeOption.swift

class PracticeTabViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedPracticeOption: PracticeOption = .guided
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedMethod: GrowthMethod?
    
    // Navigation state
    @Published var showTimerView: Bool = false
    @Published var showLogSessionView: Bool = false
    @Published var showMethodSelection: Bool = false
    
    // Current routine progress
    @Published var currentDaySchedule: DaySchedule?
    @Published var currentProgress: RoutineProgress?
    
    // Track today's completed sessions (including extra sessions beyond daily goal)
    @Published var todayCompletedSessionsCount: Int?
    
    // Track methods completed in current session (persists until routine changes)
    private var currentSessionCompletedMethods: Int = 0
    
    // Track method completion status for current session
    private var completedMethodIds: Set<String> = []
    
    // Cache today's session logs to avoid multiple fetches
    private var todaySessionLogs: [SessionLog] = []
    private var lastSessionLogsFetchDate: Date?
    
    // MARK: - Dependencies
    private let routinesViewModel: RoutinesViewModel
    private let growthMethodService = GrowthMethodService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Current User
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Initialization
    init(routinesViewModel: RoutinesViewModel) {
        self.routinesViewModel = routinesViewModel
        setupSubscriptions()
        loadCurrentRoutineDay()
        setupNotificationObservers()
        fetchTodaySessionLogs()
    }
    
    // MARK: - Public Methods
    func startPracticeSession() {
        switch selectedPracticeOption {
        case .guided:
            startGuidedSession()
        case .quick:
            startQuickSession()
        case .freestyle:
            startFreestyleSession()
        }
    }
    
    func selectMethod(_ method: GrowthMethod) {
        selectedMethod = method
        showMethodSelection = false
        
        // For quick practice, go directly to timer
        if selectedPracticeOption == .quick {
            showTimerView = true
        }
    }
    
    func getTodaySchedule() -> DaySchedule? {
        return currentDaySchedule
    }
    
    func hasActiveRoutine() -> Bool {
        return routinesViewModel.selectedRoutineId != nil
    }
    
    func canStartGuidedSession() -> Bool {
        guard hasActiveRoutine() else { return false }
        
        // Check if today's routine is already complete
        if isDailyRoutineComplete() {
            // If completed today, don't allow starting another guided session on the same day
            if let progress = currentProgress,
               let lastCompletedDate = progress.lastCompletedDate {
                let calendar = Calendar.current
                if calendar.isDateInToday(lastCompletedDate) {
                    // Already completed today, can't start again
                    return false
                }
            }
        }
        
        if let todaySchedule = getTodaySchedule() {
            return !todaySchedule.isRestDay && todaySchedule.methodIds?.isEmpty == false
        }
        
        return false
    }
    
    func isDailyRoutineComplete() -> Bool {
        guard let progress = currentProgress,
              let daySchedule = currentDaySchedule,
              let _ = daySchedule.methodIds else {
            return false
        }
        
        // Check if routine is marked as complete
        if progress.isCompleted {
            return true
        }
        
        // Check if the current day is marked as completed
        if progress.completedDays.contains(progress.currentDayNumber) {
            // If completed today, always show as complete for the rest of the day
            if let lastCompletedDate = progress.lastCompletedDate {
                let calendar = Calendar.current
                if calendar.isDateInToday(lastCompletedDate) {
                    return true
                }
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Listen to routines changes
        routinesViewModel.$selectedRoutineId
            .combineLatest(routinesViewModel.$routines)
            .sink { [weak self] _, _ in
                // Refresh state when routine changes
                self?.loadCurrentRoutineDay()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for method completion notifications
        NotificationCenter.default.publisher(for: .methodCompleted)
            .sink { [weak self] notification in
                if let methodId = notification.userInfo?["methodId"] as? String {
                    self?.handleMethodCompleted(methodId: methodId)
                }
            }
            .store(in: &cancellables)
        
        // Listen for routine progress updates
        NotificationCenter.default.publisher(for: .routineProgressUpdated)
            .sink { [weak self] notification in
                // Reset session tracking to clear any cached completion status
                self?.resetSessionTracking()
                
                // Refresh the current routine day when progress is updated
                self?.loadCurrentRoutineDay()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentRoutineDay() {
        guard let userId = currentUserID,
              let routineId = routinesViewModel.selectedRoutineId,
              let routine = routinesViewModel.routines.first(where: { $0.id == routineId }) else {
            // No user/routine found
            currentDaySchedule = nil
            currentProgress = nil
            // Reset session tracking when no routine
            resetSessionTracking()
            return
        }
        
        // Store previous day schedule to detect day changes
        let previousDaySchedule = currentDaySchedule
        
        // First check if we should advance to next day (only if it's a new calendar day)
        RoutineProgressService.shared.checkAndAdvanceToNextDayIfNeeded(userId: userId, routine: routine) { [weak self] _ in
            // Now fetch the current day
            RoutineProgressService.shared.getCurrentRoutineDay(userId: userId, routine: routine) { daySchedule, progress in
                DispatchQueue.main.async {
                    // Received progress update
                    self?.currentDaySchedule = daySchedule
                    self?.currentProgress = progress
                    
                    // Check if day changed (different day number or different routine)
                    if previousDaySchedule?.dayNumber != daySchedule?.dayNumber {
                        // New day, reset session tracking
                        self?.resetSessionTracking()
                    }
                    
                    // Fetch today's session logs to update progress
                    self?.fetchTodaySessionLogs()
                    
                    // Force UI update
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
    private func startGuidedSession() {
        guard canStartGuidedSession(),
              let todaySchedule = getTodaySchedule() else {
            error = "No guided session available for today"
            return
        }
        
        if todaySchedule.isRestDay {
            error = "Today is a rest day"
            return
        }
        
        // Don't navigate - the daily routine view is already shown inline
        // showDailyRoutineView = true
    }
    
    private func startQuickSession() {
        // Show method selection for quick practice
        showMethodSelection = true
    }
    
    private func startFreestyleSession() {
        // Show method selection for freestyle practice
        showMethodSelection = true
    }
    
    // MARK: - Helper Methods
    func getGuidedSessionTitle() -> String {
        if let todaySchedule = getTodaySchedule() {
            return todaySchedule.dayName
        }
        return "Today's Routine"
    }
    
    func getGuidedSessionDescription() -> String {
        if let todaySchedule = getTodaySchedule() {
            if todaySchedule.isRestDay {
                return "Rest day - take time to recover"
            } else if let methodCount = todaySchedule.methodIds?.count {
                return "\(methodCount) method\(methodCount == 1 ? "" : "s") planned"
            }
        }
        return "Follow your structured routine"
    }
    
    func getQuickSessionDescription() -> String {
        return "Select any method for ad-hoc practice"
    }
    
    func getCompletedSessionsCount() -> Int {
        // This counts actual completed sessions for today, including extra sessions beyond the daily goal
        guard currentUserID != nil else { 
            // No user, returning 0
            return 0 
        }
        
        // Use the stored count if available
        if let count = todayCompletedSessionsCount {
            // Returning stored count
            return count
        }
        
        // Get count from progress
        let completedCount = getCompletedSessionsFromProgress()
        
        // Update the stored count asynchronously to avoid SwiftUI warnings
        DispatchQueue.main.async { [weak self] in
            self?.todayCompletedSessionsCount = completedCount
        }
        
        // Calculated count
        return completedCount
    }
    
    /// Get completed sessions from the MultiMethodSessionViewModel if available
    func getCompletedSessionsFromActiveSession() -> Int? {
        // This method should be called by views that have access to the session view model
        return nil
    }
    
    /// Refresh the current progress from the service
    func refreshProgress() {
        // Refreshing progress
        // Clear the stored count to force recalculation from progress
        todayCompletedSessionsCount = nil
        loadCurrentRoutineDay()
        fetchTodaySessionLogs()
    }
    
    /// Clear all session data (used when sessions are reset)
    func clearAllSessions() {
        todaySessionLogs.removeAll()
        todayCompletedSessionsCount = 0
        objectWillChange.send()
    }
    
    /// Increment the completed sessions count (called when a session is logged)
    func incrementCompletedSessionsCount() {
        // Only increment if we don't already have a count set
        // This prevents double counting when methods complete individually
        if todayCompletedSessionsCount == nil {
            // Get the actual completed count from progress
            let baseCount = getCompletedSessionsFromProgress()
            todayCompletedSessionsCount = baseCount
            // Set session count from progress
        }
    }
    
    /// Get completed sessions from progress without side effects
    private func getCompletedSessionsFromProgress() -> Int {
        guard let progress = currentProgress else { 
            // No progress, return current session count based on completed methods
            return completedMethodIds.count 
        }
        
        // If the current day is completed, return the total method count for today
        if progress.completedDays.contains(progress.currentDayNumber),
           let daySchedule = currentDaySchedule,
           let methodIds = daySchedule.methodIds {
            return methodIds.count
        }
        
        // If the routine is fully completed, return the total method count
        if progress.isCompleted, let daySchedule = currentDaySchedule,
           let methodIds = daySchedule.methodIds {
            return methodIds.count
        }
        
        // Return the count of unique methods completed in current session
        return completedMethodIds.count
    }
    
    /// Called when a method is completed (from notification)
    func onMethodCompleted() {
        currentSessionCompletedMethods += 1
        // Update the stored count
        todayCompletedSessionsCount = currentSessionCompletedMethods
        // Force UI update
        objectWillChange.send()
    }
    
    /// Handle method completion with method ID
    private func handleMethodCompleted(methodId: String) {
        // Add to completed set to prevent duplicates
        completedMethodIds.insert(methodId)
        
        // Update the stored count based on unique completed methods
        todayCompletedSessionsCount = completedMethodIds.count
        
        // Force UI update
        objectWillChange.send()
        
        // Refresh session logs to ensure we have the latest data
        fetchTodaySessionLogs()
    }
    
    /// Reset session tracking when starting a new day/routine
    public func resetSessionTracking() {
        currentSessionCompletedMethods = 0
        completedMethodIds.removeAll()
        todayCompletedSessionsCount = nil
        todaySessionLogs.removeAll()
        lastSessionLogsFetchDate = nil
    }
    
    /// Fetch today's session logs from Firestore
    private func fetchTodaySessionLogs() {
        guard let userId = currentUserID else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        // Always fetch fresh logs when called to ensure we have the latest data
        // This is especially important after a session is logged
        
        FirestoreService.shared.getSessionLogsForDateRange(
            userId: userId,
            startDate: startOfDay,
            endDate: endOfDay
        ) { [weak self] logs, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    Logger.debug("PracticeTabViewModel: Error fetching today's logs: \(error)")
                }
                return
            }
            
            // Filter for sessions that have a methodId (indicating they're part of a routine)
            let filteredLogs = logs.filter { log in
                // Only count sessions that have a methodId (routine sessions)
                // Quick practice sessions typically don't have a methodId
                return log.methodId != nil
            }
            
            DispatchQueue.main.async {
                self.todaySessionLogs = filteredLogs
                self.lastSessionLogsFetchDate = Date()
                self.updateCompletedSessionsFromLogs()
                
                // Post notification to update progress UI after logs are loaded
                NotificationCenter.default.post(name: Notification.Name("sessionLogsLoaded"), object: nil)
            }
        }
    }
    
    /// Update completed sessions count from fetched logs
    private func updateCompletedSessionsFromLogs() {
        // Count unique method IDs from today's session logs
        let uniqueMethodIds = Set(todaySessionLogs.compactMap { $0.methodId })
        
        Logger.debug("PracticeTabViewModel: Today's session logs count: \(todaySessionLogs.count)")
        Logger.debug("PracticeTabViewModel: Unique method IDs from logs: \(uniqueMethodIds)")
        
        // Update completed method IDs
        completedMethodIds = uniqueMethodIds
        
        // Update the count
        todayCompletedSessionsCount = completedMethodIds.count
        
        Logger.debug("PracticeTabViewModel: Updated completed sessions count: \(todayCompletedSessionsCount ?? 0)")
        
        // Check if all methods for today are completed and mark day as complete in Firebase
        checkAndMarkDayComplete()
        
        // Force UI update
        objectWillChange.send()
    }
    
    private func checkAndMarkDayComplete() {
        guard let userId = currentUserID,
              let daySchedule = currentDaySchedule,
              let scheduledMethodIds = daySchedule.methodIds,
              !scheduledMethodIds.isEmpty else { return }
        
        // Check if all scheduled methods have been completed
        let completedIds = Set(completedMethodIds)
        let scheduledIds = Set(scheduledMethodIds)
        let allMethodsCompleted = scheduledIds.isSubset(of: completedIds)
        
        Logger.debug("PracticeTabViewModel: Checking day completion - scheduled: \(scheduledIds), completed: \(completedIds), all complete: \(allMethodsCompleted)")
        
        if allMethodsCompleted {
            // All methods completed, mark the day as complete in Firebase
            guard let routineId = routinesViewModel.selectedRoutineId,
                  let routine = routinesViewModel.routines.first(where: { $0.id == routineId }) else { return }
            
            // Check if day is already marked as complete
            if let progress = currentProgress,
               progress.completedDays.contains(progress.currentDayNumber) {
                // Already marked as complete
                return
            }
            
            Logger.debug("PracticeTabViewModel: All methods completed, marking day as complete in Firebase")
            
            RoutineProgressService.shared.markRoutineDayCompleted(userId: userId, routine: routine) { [weak self] updatedProgress in
                DispatchQueue.main.async {
                    self?.currentProgress = updatedProgress
                    Logger.debug("PracticeTabViewModel: Day marked as complete in Firebase")
                    
                    // Post notification to update UI
                    if let updatedProgress = updatedProgress {
                        NotificationCenter.default.post(name: .routineProgressUpdated, object: updatedProgress)
                    }
                }
            }
        }
    }
}