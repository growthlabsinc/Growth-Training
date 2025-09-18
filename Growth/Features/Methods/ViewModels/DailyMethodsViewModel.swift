import Foundation
import FirebaseAuth
import Combine

/// ViewModel that loads the growth methods scheduled for *today* based on the user's selected routine.
@MainActor
final class DailyMethodsViewModel: ObservableObject {
    // MARK: - Published
    @Published private(set) var methods: [GrowthMethod] = []
    @Published private(set) var scheduleForToday: DaySchedule?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var noRoutineSelected: Bool = false
    @Published private(set) var isRestDay: Bool = false

    // MARK: - Dependencies
    private let routineService = RoutineService.shared
    private let userService = UserService()
    private let methodService = GrowthMethodService.shared

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API

    /// Load or refresh today's methods for the currently signed-in user.
    func load() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil
        noRoutineSelected = false
        isRestDay = false
        methods = []
        scheduleForToday = nil

        // 1. Get the user's selected routine id
        userService.fetchSelectedRoutineId(userId: userId) { [weak self] routineId in
            Task { @MainActor in
                guard let self = self else { return }
                guard let routineId = routineId else {
                    self.noRoutineSelected = true
                    self.isLoading = false
                    return
                }

                // 2. Fetch the routine details (checking both custom and main collections)
                self.routineService.fetchRoutineFromAnySource(by: routineId, userId: userId) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .failure(let error):
                        Task { @MainActor in
                            self.errorMessage = error.localizedDescription
                            self.isLoading = false
                        }
                    case .success(let routine):
                        Task { @MainActor in
                            self.prepareSchedule(for: routine)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func prepareSchedule(for routine: Routine) {
        // Determine today's schedule using the same logic as dashboard helper
        guard let todaysSchedule = nextScheduleDay(of: routine) else {
            self.errorMessage = "Unable to determine today's schedule"
            self.isLoading = false
            return
        }
        self.scheduleForToday = todaysSchedule

        // If rest day, no methods to load
        if todaysSchedule.isRestDay {
            self.isRestDay = true
            self.isLoading = false
            return
        }

        let methodSchedules = todaysSchedule.methods
        if methodSchedules.isEmpty {
            self.isLoading = false
            return
        }

        // Fetch all methods then filter and sort by order – preserves custom ordering
        methodService.fetchAllMethods { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            case .success(let allMethods):
                Task { @MainActor in
                    // Create a dictionary for fast lookup
                    let methodsDict: [String: GrowthMethod] = Dictionary(uniqueKeysWithValues: allMethods.compactMap { method in
                        guard let id = method.id else { return nil }
                        return (id, method)
                    })
                    
                    // Sort method schedules by order and map to GrowthMethod objects
                    let sortedMethods = methodSchedules
                        .sorted { $0.order < $1.order }
                        .compactMap { schedule in methodsDict[schedule.methodId] }
                    
                    self.methods = sortedMethods
                    self.isLoading = false
                }
            }
        }
    }

    /// Logic copied from `RecommendedRoutineCardView` to choose the correct DaySchedule.
    private func nextScheduleDay(of routine: Routine) -> DaySchedule? {
        guard !routine.schedule.isEmpty else { return nil }
        let startDate = Calendar.current.startOfDay(for: routine.createdAt)
        let today = Calendar.current.startOfDay(for: Date())
        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        let index = daysElapsed % routine.schedule.count
        return routine.schedule[index]
    }
} 