import Foundation
import SwiftUI
import Combine

/// View model for the RecommendedRoutineCardView that handles fetching method details for the next day's session
@MainActor
class RecommendedRoutineCardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var nextDaySchedule: DaySchedule?
    @Published private(set) var nextMethod: GrowthMethod?
    @Published private(set) var isLoadingMethod: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - Properties
    private let routine: Routine?
    private let methodService = GrowthMethodService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(routine: Routine?) {
        self.routine = routine
        loadNextDaySchedule()
    }
    
    // MARK: - Public Methods
    
    /// Load the method details for the selected routine's next day
    func loadMethodDetails(forceRefresh: Bool = false) {
        guard let nextDay = nextDaySchedule, let methodIds = nextDay.methodIds, !methodIds.isEmpty, !nextDay.isRestDay else {
            // No methods to load or rest day
            self.nextMethod = nil
            return
        }
        
        // Use the first method in the list for now
        let methodId = methodIds[0]
        
        isLoadingMethod = true
        errorMessage = nil
        
        methodService.fetchMethod(withId: methodId, forceRefresh: forceRefresh) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMethod = false
                
                switch result {
                case .success(let method):
                    self.nextMethod = method
                    Logger.debug("RecommendedRoutineCardViewModel: Loaded method: \(method.title)")
                case .failure(let error):
                    self.errorMessage = "Failed to load method: \(error.localizedDescription)"
                    Logger.debug("RecommendedRoutineCardViewModel: \(self.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate and set the next day schedule based on the routine's creation date
    private func loadNextDaySchedule() {
        nextDaySchedule = getNextScheduleDay(of: routine)
        loadMethodDetails()
    }
    
    /// Returns the next `DaySchedule` in the routine based on the number of days elapsed since the routine was created.
    /// If the routine is nil or has no schedule, returns nil.
    private func getNextScheduleDay(of routine: Routine?) -> DaySchedule? {
        guard let routine = routine, !routine.schedule.isEmpty else { return nil }

        // Calculate days elapsed since routine creation (rounded down)
        let startDate = Calendar.current.startOfDay(for: routine.createdAt)
        let today = Calendar.current.startOfDay(for: Date())
        guard let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: today).day else {
            return routine.schedule.first
        }

        // Determine index in schedule using modulo to cycle every week (or schedule.count days)
        let index = daysElapsed % routine.schedule.count
        return routine.schedule[index]
    }
    
    // MARK: - Computed Properties
    
    /// Returns whether today is a rest day
    var isRestDay: Bool {
        return nextDaySchedule?.isRestDay ?? false
    }
    
    /// Returns a descriptive message about the method status
    var methodStatusMessage: String {
        if isLoadingMethod {
            return "Loading method details..."
        }
        
        if errorMessage != nil {
            return "Error loading method details"
        }
        
        if isRestDay {
            return "Today is a rest day"
        }
        
        if nextMethod == nil && nextDaySchedule?.methodIds?.isEmpty == false {
            return "Method details not available"
        }
        
        return ""
    }
} 