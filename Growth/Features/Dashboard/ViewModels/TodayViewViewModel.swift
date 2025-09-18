//
//  TodayViewViewModel.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation
import Combine
import FirebaseAuth

enum TodayFocusState: Equatable {
    case routineDay(DaySchedule)
    case quickPractice
    case restDay(String)
    case completed
    case loading
    case noRoutine
    
    static func == (lhs: TodayFocusState, rhs: TodayFocusState) -> Bool {
        switch (lhs, rhs) {
        case (.routineDay(let lhsSchedule), .routineDay(let rhsSchedule)):
            return lhsSchedule.id == rhsSchedule.id
        case (.quickPractice, .quickPractice),
             (.completed, .completed),
             (.loading, .loading),
             (.noRoutine, .noRoutine):
            return true
        case (.restDay(let lhsMessage), .restDay(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

class TodayViewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todayFocusState: TodayFocusState = .loading
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published var selectedDate: Date = Date()
    
    // Weekly Progress Data
    @Published var currentStreak: Int = 0
    @Published var totalWeeklyMinutes: Int = 0
    @Published var routineAdherencePercent: Int = 0
    @Published var isLoadingWeeklyData: Bool = true
    
    // MARK: - Dependencies
    private let routinesViewModel: RoutinesViewModel
    private let progressViewModel: ProgressViewModel
    private let streakTracker = StreakTracker.shared
    private let adherenceService = RoutineAdherenceService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Access to Progress Data
    var dailyMinutes: [Date: Int] {
        progressViewModel.dailyMinutes
    }
    
    // MARK: - Current User
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Initialization
    init(routinesViewModel: RoutinesViewModel, progressViewModel: ProgressViewModel) {
        self.routinesViewModel = routinesViewModel
        self.progressViewModel = progressViewModel

        setupSubscriptions()
        loadTodayFocusState()
        // Don't load weekly progress data until we have fetched the logged dates
        // It will be triggered by the subscription when dailyMinutes is populated
    }
    
    // MARK: - Public Methods
    func refresh() {
        // If no routine is selected but we're in loading state, try fetching again
        if routinesViewModel.selectedRoutineId == nil && !routinesViewModel.userId.isEmpty {
            Logger.debug("TodayViewViewModel: No routine selected, fetching from Firebase...")
            routinesViewModel.fetchSelectedRoutineId()
        }

        loadTodayFocusState()
        // Always trigger progress data fetch to ensure we have latest data
        progressViewModel.fetchLoggedDates()
        // Load weekly progress data after a short delay to ensure data is fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadWeeklyProgressData()
        }
    }
    
    func updateFocusForDate(_ date: Date) {
        selectedDate = date
        loadTodayFocusState()
    }
    
    func getTodayActionTitle() -> String {
        switch todayFocusState {
        case .routineDay(_):
            return "Start Today's Routine"
        case .quickPractice, .noRoutine:
            return "Start Quick Practice"
        case .restDay(_):
            return "Log Rest Day Activity"
        case .completed:
            return "Log Additional Practice"
        case .loading:
            return "Loading..."
        }
    }
    
    func shouldShowQuickActions() -> Bool {
        switch todayFocusState {
        case .loading:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Listen to routines and progress changes
        routinesViewModel.$selectedRoutineId
            .combineLatest(routinesViewModel.$routines, routinesViewModel.$routineProgress, routinesViewModel.$isLoading)
            .sink { [weak self] selectedId, routines, progress, isLoading in
                // Only update focus state when not loading and we have data
                if !isLoading {
                    self?.loadTodayFocusState()
                }
            }
            .store(in: &cancellables)

        progressViewModel.$dailyMinutes
            .sink { [weak self] dailyMinutes in
                // Only update if we have data
                if !dailyMinutes.isEmpty {
                    // Update weekly minutes whenever dailyMinutes changes
                    self?.updateWeeklyMinutes()
                    // Also update streak since new data might affect it
                    self?.loadCurrentStreak()
                    // Update routine adherence as well
                    self?.loadRoutineAdherence()
                }
            }
            .store(in: &cancellables)

        // Listen for routine progress updates
        NotificationCenter.default.publisher(for: .routineProgressUpdated)
            .sink { [weak self] _ in
                self?.loadTodayFocusState()
                self?.loadRoutineAdherence()
            }
            .store(in: &cancellables)

        // Listen for session logged notifications to refresh weekly data
        NotificationCenter.default.publisher(for: .sessionLogged)
            .sink { [weak self] _ in
                // Refresh weekly progress data when a new session is logged
                // Add delay to ensure data is persisted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.loadWeeklyProgressData()
                    // Also trigger progress view model to fetch latest data
                    self?.progressViewModel.fetchLoggedDates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadTodayFocusState() {
        isLoading = true
        todayFocusState = .loading

        guard let userId = currentUserID else {
            error = "User not authenticated"
            isLoading = false
            todayFocusState = .noRoutine
            return
        }

        // If routines are still loading, wait for them
        if routinesViewModel.isLoading {
            // Wait a bit and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadTodayFocusState()
            }
            return
        }

        // Check if user has a selected routine
        guard let routineId = routinesViewModel.selectedRoutineId,
              let routine = routinesViewModel.routines.first(where: { $0.id == routineId }) else {
            // Check if user prefers routine mode but hasn't selected one yet
            UserService.shared.fetchUser(userId: userId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .success(let user) = result,
                       user.preferredPracticeMode == "routine" {
                        // User wants routine but hasn't selected one
                        self?.todayFocusState = .noRoutine
                    } else {
                        // User prefers quick practice mode
                        self?.todayFocusState = .quickPractice
                    }
                }
            }
            return
        }
        
        let isToday = Calendar.current.isDateInToday(selectedDate)
        
        if isToday {
            // For today, show the current routine day based on progress
            loadTodayBasedOnProgress(userId: userId, routine: routine)
        } else {
            // For future/past dates, show what's scheduled on that date
            loadScheduledDayForDate(userId: userId, routine: routine, date: selectedDate)
        }
    }
    
    private func loadTodayBasedOnProgress(userId: String, routine: Routine) {
        // First check if we need to advance to the next day
        RoutineProgressService.shared.checkAndAdvanceToNextDayIfNeeded(userId: userId, routine: routine) { [weak self] _ in
            // Then get the current routine day based on actual progress tracking
            RoutineProgressService.shared.getCurrentRoutineDay(userId: userId, routine: routine) { [weak self] daySchedule, progress in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // If no progress exists yet, initialize it
                    if progress == nil && daySchedule != nil {
                        RoutineProgressService.shared.initializeProgress(userId: userId, routine: routine) { _ in
                            self.loadTodayFocusState() // Reload after initialization
                        }
                        return
                    }
                
                guard let currentDay = daySchedule else {
                    self.isLoading = false
                    self.todayFocusState = .quickPractice
                    return
                }
                
                // Check if it's a rest day
                if currentDay.isRestDay {
                    self.isLoading = false
                    self.todayFocusState = .restDay(currentDay.description)
                    return
                }
                
                // Check if today's routine is already completed
                RoutineProgressService.shared.isRoutineDayCompleted(userId: userId, routineId: routine.id, date: Date()) { isCompleted in
                    DispatchQueue.main.async {
                        if isCompleted {
                            self.isLoading = false
                            self.todayFocusState = .completed
                        } else {
                            // Show the current routine day
                            self.isLoading = false
                            self.todayFocusState = .routineDay(currentDay)
                        }
                    }
                }
            }
        }
    }
}
    
    private func loadScheduledDayForDate(userId: String, routine: Routine, date: Date) {
        // For non-today dates, calculate what day of the routine schedule it would be
        let calendar = Calendar.current
        
        // Get the routine start date from progress or use routine creation date
        RoutineProgressService.shared.fetchProgress(userId: userId, routineId: routine.id) { [weak self] progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let startDate = progress?.startDate ?? routine.startDate ?? Date()
                
                // Calculate the number of days between start date and selected date
                let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0
                
                // Handle past dates
                if daysBetween < 0 {
                    self.isLoading = false
                    self.todayFocusState = .quickPractice
                    return
                }
                
                // Calculate which day in the routine schedule this would be
                let scheduleIndex = daysBetween % routine.schedule.count
                
                guard routine.schedule.indices.contains(scheduleIndex) else {
                    self.isLoading = false
                    self.todayFocusState = .quickPractice
                    return
                }
                
                let scheduledDay = routine.schedule[scheduleIndex]
                
                // Check if it's a rest day
                if scheduledDay.isRestDay {
                    self.isLoading = false
                    self.todayFocusState = .restDay(scheduledDay.description)
                    return
                }
                
                // For future dates, always show as routine day (not completed)
                // For past dates, check if it was completed
                if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending {
                    // Past date - check if completed
                    RoutineProgressService.shared.isRoutineDayCompleted(userId: userId, routineId: routine.id, date: date) { isCompleted in
                        DispatchQueue.main.async {
                            if isCompleted {
                                self.isLoading = false
                                self.todayFocusState = .completed
                            } else {
                                self.isLoading = false
                                self.todayFocusState = .routineDay(scheduledDay)
                            }
                        }
                    }
                } else {
                    // Future date - show as scheduled
                    self.isLoading = false
                    self.todayFocusState = .routineDay(scheduledDay)
                }
            }
        }
    }
    
    private func isRoutineCompletedForDate(_ schedule: DaySchedule, date: Date) -> Bool {
        // Check if user has completed all methods for the selected date
        // This is a simplified check - in a real app, you'd track completion per method
        
        guard let methodIds = schedule.methodIds, !methodIds.isEmpty else {
            return false
        }
        
        // Check if there's a logged session for the selected date
        let targetDate = Calendar.current.startOfDay(for: date)
        let hasSessionOnDate = progressViewModel.dailyMinutes[targetDate] ?? 0 > 0
        
        // For now, consider it completed if there's any session logged on that date
        // In Epic 17, this would be more sophisticated routine progress tracking
        return hasSessionOnDate
    }
    
    private func loadWeeklyProgressData() {
        isLoadingWeeklyData = true

        // Use a dispatch group to track all async operations
        let group = DispatchGroup()

        // Load current streak
        group.enter()
        loadCurrentStreak {
            group.leave()
        }

        // Calculate weekly minutes (synchronous)
        updateWeeklyMinutes()

        // Load routine adherence
        group.enter()
        loadRoutineAdherence {
            group.leave()
        }

        // Set loading to false once all operations complete
        group.notify(queue: .main) { [weak self] in
            self?.isLoadingWeeklyData = false
        }
    }
    
    private func loadCurrentStreak(completion: (() -> Void)? = nil) {
        // First refresh the streak data to ensure it's up to date
        streakTracker.refreshStreakData { [weak self] success, error in
            if let error = error {
                Logger.debug("TodayViewViewModel: Error refreshing streak data: \(error.localizedDescription)")
            }

            // Then get the current streak
            self?.streakTracker.getCurrentStreak { [weak self] count, error in
                DispatchQueue.main.async {
                    if let error = error {
                        Logger.debug("TodayViewViewModel: Error loading streak: \(error.localizedDescription)")
                        self?.currentStreak = 0
                    } else {
                        Logger.debug("TodayViewViewModel: Current streak is \(count) days")
                        self?.currentStreak = count
                    }
                    completion?()
                }
            }
        }
    }
    
    private func updateWeeklyMinutes() {
        let calendar = Calendar.current
        let today = Date()

        // Get start of current week - using gregorian calendar with Monday as first day
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday

        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: today) else {
            Logger.debug("TodayViewViewModel: Failed to get week interval")
            totalWeeklyMinutes = 0
            return
        }

        let weekStart = cal.startOfDay(for: weekInterval.start)

        // Debug: Log the week start date and available data
        Logger.debug("TodayViewViewModel: Week starts on \(weekStart)")
        Logger.debug("TodayViewViewModel: Available data for \(progressViewModel.dailyMinutes.count) days")

        // Also log a sample of available dates
        if !progressViewModel.dailyMinutes.isEmpty {
            let sampleDates = Array(progressViewModel.dailyMinutes.keys.prefix(3))
            Logger.debug("TodayViewViewModel: Sample data dates: \(sampleDates)")
        }

        // Calculate total minutes for this week
        var totalMinutes = 0
        var daysWithData = 0
        for dayOffset in 0..<7 {
            if let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart) {
                let startOfDay = cal.startOfDay(for: day)
                let dayMinutes = progressViewModel.dailyMinutes[startOfDay] ?? 0
                if dayMinutes > 0 {
                    daysWithData += 1
                    Logger.debug("TodayViewViewModel: \(startOfDay) has \(dayMinutes) minutes")
                }
                totalMinutes += dayMinutes
            }
        }

        Logger.debug("TodayViewViewModel: Week total: \(totalMinutes) minutes across \(daysWithData) days")
        totalWeeklyMinutes = totalMinutes
    }
    
    // MARK: - Helper Methods for UI
    func getRoutineDayMethodCount() -> Int {
        if case .routineDay(let schedule) = todayFocusState {
            return schedule.methodIds?.count ?? 0
        }
        return 0
    }
    
    func getRestDayMessage() -> String {
        if case .restDay(let message) = todayFocusState {
            return message
        }
        return "Rest and Recovery Day"
    }
    
    func isRoutineDay() -> Bool {
        if case .routineDay(_) = todayFocusState {
            return true
        }
        return false
    }
    
    func isRestDay() -> Bool {
        if case .restDay(_) = todayFocusState {
            return true
        }
        return false
    }
    
    // MARK: - Routine Adherence
    
    private func loadRoutineAdherence(completion: (() -> Void)? = nil) {
        Task { @MainActor in
            guard let userId = currentUserID,
                  let routineId = routinesViewModel.selectedRoutineId,
                  let routine = routinesViewModel.routines.first(where: { $0.id == routineId }) else {
                routineAdherencePercent = 0
                completion?()
                return
            }

            do {
                let adherenceData = try await adherenceService.calculateAdherence(
                    for: routine,
                    timeRange: .week,
                    userId: userId
                )

                routineAdherencePercent = Int(adherenceData.adherencePercentage)
            } catch {
                Logger.debug("Error calculating adherence: \(error.localizedDescription)")
                routineAdherencePercent = 0
            }
            completion?()
        }
    }
}