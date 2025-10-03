import Foundation
import Combine
import FirebaseAuth
import SwiftUI

/// ViewModel managing the state of the 7-day calendar that appears on the Dashboard (Story 12.6).
@MainActor
final class WeekCalendarViewModel: ObservableObject {
    // MARK: - Theme Manager
    @ObservedObject private var themeManager = ThemeManager.shared
    // MARK: - Published Properties
    /// Array of `DayViewModel` items representing the current 7-day slice being shown.
    @Published var days: [DayViewModel] = []

    /// Currently selected date in the calendar (defaults to today).
    @Published var selectedDate: Date = Date() {
        didSet { refreshSelected() }
    }

    /// Human-readable description of the visible week (e.g. "May 12 – May 18").
    @Published var weekRangeDescription: String = ""
    
    /// Dictionary of dates with session data
    @Published var sessionDates: [Date: Int] = [:] // Date -> minutes practiced

    /// Computed property for the uppercase month and year header (e.g., "MARCH 2025")
    var monthYearHeader: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).uppercased()
    }

    // MARK: - Private Properties
    private var calendar: Calendar { 
        var cal = Calendar.current
        cal.firstWeekday = ThemeManager.shared.firstDayOfWeek
        return cal
    }
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        buildDays(around: Date())
        loadSessionDataInternal()
        loadRoutineData()
        
        // Observe changes to firstDayOfWeek
        // Since firstDayOfWeek triggers objectWillChange in its didSet,
        // we can use that to detect changes
        themeManager.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Rebuild calendar to reflect any theme changes including firstDayOfWeek
                DispatchQueue.main.async {
                    self.rebuildCalendar()
                }
            }
            .store(in: &cancellables)
    }
    
    private func rebuildCalendar() {
        buildDays(around: selectedDate)
        loadSessionDataInternal()
        loadRoutineData()
    }

    // MARK: - Public Helpers
    /// Navigate to the previous 7-day period.
    func goToPreviousWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) else { return }
        buildDays(around: newDate)
        loadSessionDataInternal()
        loadRoutineData()
    }

    /// Navigate to the next 7-day period.
    func goToNextWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) else { return }
        buildDays(around: newDate)
        loadSessionDataInternal()
        loadRoutineData()
    }

    /// Select a specific day cell.
    func select(date: Date) {
        selectedDate = date
    }
    
    /// Load session data for the current week (public method)
    func loadSessionData() {
        loadSessionDataInternal()
    }

    // MARK: - Private Helpers
    /// Returns the start of the week (Monday) for a given date
    private func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    private func buildDays(around reference: Date) {
        let startOfWeek = self.startOfWeek(for: reference)
        var generated: [DayViewModel] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            let isToday = calendar.isDateInToday(date)
            // Placeholder logic for workout vs. rest: weekdays are workout days, weekends are rest.
            let weekday = calendar.component(.weekday, from: date)
            let isWorkoutDay = !(weekday == 1 || weekday == 7) // Sunday (1) or Saturday (7) => rest
            generated.append(
                DayViewModel(
                    date: date,
                    isToday: isToday,
                    isSelected: calendar.isDate(date, inSameDayAs: reference),
                    isWorkoutDay: isWorkoutDay
                )
            )
        }
        withAnimation(.easeInOut) {
            self.days = generated
            self.selectedDate = reference
        }
        updateWeekRangeDescription(from: startOfWeek)
    }

    private func refreshSelected() {
        days = days.map { day in
            var updated = day
            updated.isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
            return updated
        }
    }

    private func updateWeekRangeDescription(from startOfWeek: Date) {
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        weekRangeDescription = "\(formatter.string(from: startOfWeek)) – \(formatter.string(from: endOfWeek))"
    }
    
    private func loadSessionDataInternal() {
        guard let userId = Auth.auth().currentUser?.uid else {
            Logger.debug("WeekCalendarViewModel: No user ID available")
            return
        }

        // Get the date range for the current week
        guard let firstDay = days.first?.date,
              let lastDay = days.last?.date else {
            Logger.debug("WeekCalendarViewModel: No days available for week")
            return
        }

        Logger.debug("WeekCalendarViewModel: Loading sessions from \(firstDay) to \(lastDay)")

        // Fetch session logs for the week
        firestoreService.fetchSessionLogs(forUserId: userId, from: firstDay, to: lastDay) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let sessions):
                Logger.debug("WeekCalendarViewModel: Fetched \(sessions.count) sessions for the week")

                // Create a dictionary of date -> total minutes
                var dateSessions: [Date: Int] = [:]

                for session in sessions {
                    let sessionDate = self.calendar.startOfDay(for: session.startTime)
                    Logger.debug("WeekCalendarViewModel: Session on \(sessionDate): \(session.duration) minutes")

                    // Only count sessions that were likely completed (5+ minutes)
                    // This filters out very short sessions that were likely interrupted/incomplete
                    if session.duration >= 5 {
                        dateSessions[sessionDate, default: 0] += session.duration
                    } else {
                        Logger.debug("WeekCalendarViewModel: Skipping short session (\(session.duration) min)")
                    }
                }

                Logger.debug("WeekCalendarViewModel: Processed sessions for \(dateSessions.count) days")

                DispatchQueue.main.async {
                    self.sessionDates = dateSessions
                    self.updateDaysWithSessionData()
                }

            case .failure(let error):
                Logger.debug("WeekCalendarViewModel: Error loading session data: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateDaysWithSessionData() {
        days = days.map { day in
            var updated = day
            let dayStart = calendar.startOfDay(for: day.date)
            updated.hasSession = sessionDates[dayStart] != nil
            updated.sessionMinutes = sessionDates[dayStart] ?? 0
            return updated
        }
    }
    
    private func loadRoutineData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get the user's selected routine
        UserService().fetchSelectedRoutineId(userId: userId) { [weak self] routineId in
            guard let self = self, let routineId = routineId else { return }
            
            // Fetch the routine details (checking both custom and main collections)
            RoutineService.shared.fetchRoutineFromAnySource(by: routineId, userId: userId) { result in
                switch result {
                case .success(let routine):
                    // Get routine progress to know the actual start date
                    RoutineProgressService.shared.fetchProgress(userId: userId, routineId: routineId) { progress in
                        DispatchQueue.main.async {
                            self.updateDaysWithRoutineData(routine: routine, progress: progress)
                        }
                    }
                case .failure(let error):
                    Logger.debug("Error loading routine: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateDaysWithRoutineData(routine: Routine, progress: RoutineProgress?) {
        let startDate = progress?.startDate ?? routine.startDate ?? Date()
        let today = calendar.startOfDay(for: Date())
        
        // Commented out verbose routine data logging
        // Logger.debug("WeekCalendarViewModel: Updating days with routine data")
        
        days = days.map { day in
            var updated = day
            let dayStart = calendar.startOfDay(for: day.date)
            
            // Check if this day is in the future
            let isInFuture = dayStart > today
            
            // Calculate the number of days between start date and this day
            let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: dayStart).day ?? 0
            
            // If before start date or in the future, no routine scheduled
            if daysBetween < 0 || isInFuture {
                updated.isRoutineDay = false
                updated.isRestDay = false
                return updated
            }
            
            // Calculate which day in the routine schedule this would be
            let scheduleIndex = daysBetween % routine.schedule.count
            
            if routine.schedule.indices.contains(scheduleIndex) {
                let scheduledDay = routine.schedule[scheduleIndex]
                updated.isRoutineDay = !scheduledDay.isRestDay
                updated.isRestDay = scheduledDay.isRestDay
                
                // Add routine day info for debugging
                // let dayOfWeek = calendar.component(.weekday, from: day.date)
                // let weekdayName = DateFormatter().weekdaySymbols[dayOfWeek - 1]
                // Logger.debug("  - \(weekdayName) \(day.dayNumber): Day \(scheduledDay.day) (daysBetween: \(daysBetween), scheduleIndex: \(scheduleIndex))")
            }
            
            return updated
        }
    }
}

/// Lightweight representation of a day inside the 7-day calendar component.
struct DayViewModel: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var isToday: Bool
    var isSelected: Bool
    /// Whether this date is considered a workout day (vs. rest day).
    /// Placeholder logic: Monday–Friday = workout, Saturday/Sunday = rest.
    var isWorkoutDay: Bool
    /// Whether this date has a logged session
    var hasSession: Bool = false
    /// Total minutes practiced on this date
    var sessionMinutes: Int = 0
    /// Whether this date is a rest day in the routine
    var isRestDay: Bool = false
    /// Whether this date has a scheduled routine
    var isRoutineDay: Bool = false

    /// Formatted values for the UI
    var weekdaySymbol: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E" // Mon, Tue …
        return formatter.string(from: date)
    }

    var dayNumber: String {
        let day = Calendar.current.component(.day, from: date)
        return String(day)
    }
} 