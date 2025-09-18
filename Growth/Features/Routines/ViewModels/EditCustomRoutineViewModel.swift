import SwiftUI
import Combine
import FirebaseAuth
import Foundation  // For Logger

class EditCustomRoutineViewModel: ObservableObject {
    @Published var routine: Routine?
    @Published var routineName = ""
    @Published var routineDescription = ""
    @Published var selectedDifficulty: RoutineDifficulty = .intermediate
    @Published var selectedDuration = 14
    @Published var shareWithCommunity = false
    @Published var selectedMethods: [GrowthMethod] = []
    @Published var daySchedules: [DaySchedule] = []
    @Published var methodSchedulingConfigs: [String: MethodSchedulingConfig] = [:]
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var isSaving = false
    @Published var saveSuccess = false
    
    private let routineService = RoutineService.shared
    private let growthMethodService = GrowthMethodService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadRoutine(_ routine: Routine) {
        self.routine = routine
        
        // Pre-populate fields
        self.routineName = routine.name
        self.routineDescription = routine.description
        self.selectedDifficulty = routine.difficulty
        self.selectedDuration = routine.duration
        self.shareWithCommunity = routine.shareWithCommunity ?? false
        self.daySchedules = routine.schedule
        
        // Load methods from the routine
        loadMethodsFromRoutine(routine)
    }
    
    private func loadMethodsFromRoutine(_ routine: Routine) {
        isLoading = true
        
        // Extract unique method IDs from all day schedules
        let methodIds = Set(routine.schedule.flatMap { day in
            day.methods.map { $0.methodId }
        })
        
        // Create method scheduling configs from existing schedule
        for day in routine.schedule {
            for methodSchedule in day.methods {
                if methodSchedulingConfigs[methodSchedule.methodId] == nil {
                    methodSchedulingConfigs[methodSchedule.methodId] = MethodSchedulingConfig(
                        methodId: methodSchedule.methodId,
                        selectedDays: [],
                        frequency: .custom,
                        duration: methodSchedule.duration
                    )
                }
                methodSchedulingConfigs[methodSchedule.methodId]?.selectedDays.insert(day.day)
            }
        }
        
        // Load all methods
        var loadedMethods: [GrowthMethod] = []
        let group = DispatchGroup()
        
        for methodId in methodIds {
            group.enter()
            growthMethodService.fetchMethod(withId: methodId) { result in
                switch result {
                case .success(let method):
                    loadedMethods.append(method)
                case .failure(let error):
                    Logger.debug("Failed to load method \(methodId): \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.selectedMethods = loadedMethods.sorted { $0.id < $1.id }
            self?.isLoading = false
        }
    }
    
    @MainActor
    func syncMethodConfigsFromSchedule() {
        // Update methodSchedulingConfigs based on current daySchedules
        // This ensures frequency and duration are preserved
        
        // First, clear selectedDays for all configs
        for key in methodSchedulingConfigs.keys {
            methodSchedulingConfigs[key]?.selectedDays.removeAll()
        }
        
        // Then update based on current schedule
        for day in daySchedules {
            for methodSchedule in day.methods {
                if methodSchedulingConfigs[methodSchedule.methodId] != nil {
                    // Update duration from schedule
                    methodSchedulingConfigs[methodSchedule.methodId]?.duration = methodSchedule.duration
                    // Add this day to selectedDays
                    methodSchedulingConfigs[methodSchedule.methodId]?.selectedDays.insert(day.day)
                } else {
                    // Create new config if it doesn't exist
                    methodSchedulingConfigs[methodSchedule.methodId] = MethodSchedulingConfig(
                        methodId: methodSchedule.methodId,
                        selectedDays: [day.day],
                        frequency: .custom,
                        duration: methodSchedule.duration
                    )
                }
            }
        }
        
        // Update frequency based on selected days pattern
        for (methodId, _) in methodSchedulingConfigs {
            guard var config = methodSchedulingConfigs[methodId] else { continue }
            let days = Array(config.selectedDays).sorted()
            
            // Determine frequency based on pattern
            if days.count == selectedDuration {
                config.frequency = .everyDay
            } else if days.count > 1 {
                // Check for every other day pattern
                let isEveryOtherDay = days.enumerated().allSatisfy { index, day in
                    index == 0 || day == days[index - 1] + 2
                }
                if isEveryOtherDay && days.first == 1 {
                    config.frequency = .everyOtherDay
                } else {
                    // Check for every 2 days pattern (every 3rd day)
                    let isEvery2Days = days.enumerated().allSatisfy { index, day in
                        index == 0 || day == days[index - 1] + 3
                    }
                    if isEvery2Days && days.first == 1 {
                        config.frequency = .every2Days
                    } else {
                        // Check for every 3 days pattern (every 4th day)
                        let isEvery3Days = days.enumerated().allSatisfy { index, day in
                            index == 0 || day == days[index - 1] + 4
                        }
                        if isEvery3Days && days.first == 1 {
                            config.frequency = .every3Days
                        } else {
                            config.frequency = .custom
                        }
                    }
                }
            } else {
                config.frequency = .custom
            }
            
            methodSchedulingConfigs[methodId] = config
        }
    }
    
    func updateRoutine() async throws {
        guard let originalRoutine = routine else {
            throw NSError(domain: "EditRoutineViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No routine to update"])
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EditRoutineViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Ensure user owns this routine
        guard originalRoutine.createdBy == userId else {
            throw NSError(domain: "EditRoutineViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "You can only edit your own routines"])
        }
        
        // Sync configs from schedule before saving (must be on main thread)
        await MainActor.run {
            syncMethodConfigsFromSchedule()
        }
        
        // Create updated routine
        let updatedRoutine = Routine(
            id: originalRoutine.id,
            name: routineName,
            description: routineDescription,
            difficulty: selectedDifficulty,
            duration: selectedDuration,
            focusAreas: extractFocusAreas(),
            stages: extractStages(),
            createdDate: originalRoutine.createdDate,
            lastUpdated: Date(),
            schedule: daySchedules,
            isCustom: true,
            createdBy: userId,
            shareWithCommunity: shareWithCommunity,
            creatorUsername: originalRoutine.creatorUsername,
            creatorDisplayName: originalRoutine.creatorDisplayName
        )
        
        // Update version if significant changes
        var versionedRoutine = updatedRoutine
        versionedRoutine.version = (originalRoutine.version) + 1
        
        try await routineService.updateCustomRoutine(versionedRoutine, userId: userId)
        
        // Capture values before async closure
        let routineId = versionedRoutine.id
        let finalRoutine = versionedRoutine
        
        await MainActor.run {
            self.routine = finalRoutine
            self.saveSuccess = true
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .routineUpdated, object: routineId)
        }
    }
    
    private func extractFocusAreas() -> [String] {
        // Extract unique focus areas from selected methods
        let areas = Set(selectedMethods.flatMap { $0.categories })
        return Array(areas)
    }
    
    private func extractStages() -> [Int] {
        // Extract unique stages from selected methods
        let stages = Set(selectedMethods.map { $0.stage })
        return Array(stages).sorted()
    }
    
    func regenerateSchedule() {
        // Don't regenerate if we already have a schedule - update it instead
        if !daySchedules.isEmpty {
            updateExistingScheduleWithNewMethods()
            return
        }
        
        // Clear existing schedules
        daySchedules.removeAll()
        
        // Create new day schedules based on selected methods and configurations
        for dayNumber in 1...selectedDuration {
            var methodsForDay: [MethodSchedule] = []
            var orderIndex = 0
            
            // Add methods scheduled for this day
            for method in selectedMethods {
                guard let methodId = method.id else { continue }
                if let config = methodSchedulingConfigs[methodId],
                   config.selectedDays.contains(dayNumber) {
                    let methodSchedule = MethodSchedule(
                        methodId: methodId,
                        duration: config.duration,
                        order: orderIndex
                    )
                    methodsForDay.append(methodSchedule)
                    orderIndex += 1
                }
            }
            
            // Create day schedule
            let isRestDay = methodsForDay.isEmpty
            let daySchedule = DaySchedule(
                day: dayNumber,
                isRestDay: isRestDay,
                methods: methodsForDay,
                notes: isRestDay ? "Rest and recovery day" : ""
            )
            
            daySchedules.append(daySchedule)
        }
    }
    
    private func updateExistingScheduleWithNewMethods() {
        // Get all method IDs currently in the schedule
        let existingMethodIds = Set(daySchedules.flatMap { day in
            day.methods.map { $0.methodId }
        })
        
        // Find newly selected methods that aren't in the schedule yet
        let newMethodIds = selectedMethods.compactMap { $0.id }.filter { methodId in
            !existingMethodIds.contains(methodId)
        }
        
        // Log all available configs
        Logger.debug("Available methodSchedulingConfigs: \(methodSchedulingConfigs.keys)")
        for (methodId, config) in methodSchedulingConfigs {
            Logger.debug("Config for \(methodId): frequency=\(config.frequency.rawValue), duration=\(config.duration), selectedDays=\(config.selectedDays)")
        }
        
        // If there are new methods, add them to appropriate days
        if !newMethodIds.isEmpty {
            Logger.debug("Adding \(newMethodIds.count) new methods to existing schedule")
            Logger.debug("New method IDs: \(newMethodIds)")
            
            // Process each new method based on its scheduling configuration
            for methodId in newMethodIds {
                // Check if there's a scheduling configuration for this method
                if let config = methodSchedulingConfigs[methodId] {
                    Logger.debug("Found config for method \(methodId): frequency=\(config.frequency.rawValue), duration=\(config.duration)")
                    
                    // Use the configured days
                    let daysToAdd = determineDaysForMethod(config: config)
                    Logger.debug("Days to add for method \(methodId): \(daysToAdd)")
                    
                    for dayNumber in daysToAdd {
                        // Find the day schedule with this day number
                        if let dayIndex = daySchedules.firstIndex(where: { $0.day == dayNumber }) {
                            // Skip if it's a rest day
                            guard !daySchedules[dayIndex].isRestDay else { continue }
                            
                            // Find the default duration for this method
                            let duration = config.duration > 0 ? config.duration : 
                                         (selectedMethods.first(where: { $0.id == methodId })?.estimatedDurationMinutes ?? 20)
                            
                            // Create new method schedule
                            let newMethodSchedule = MethodSchedule(
                                methodId: methodId,
                                duration: duration,
                                order: daySchedules[dayIndex].methods.count
                            )
                            
                            // Update the day schedule
                            var updatedDay = daySchedules[dayIndex]
                            updatedDay.methods.append(newMethodSchedule)
                            daySchedules[dayIndex] = updatedDay
                            
                            Logger.debug("Added method \(methodId) to day \(updatedDay.day)")
                        }
                    }
                } else {
                    // No config, add to first non-rest day as fallback
                    Logger.debug("No config found for method \(methodId), using fallback")
                    if let firstNonRestDayIndex = daySchedules.firstIndex(where: { !$0.isRestDay }) {
                        let defaultDuration = selectedMethods.first(where: { $0.id == methodId })?.estimatedDurationMinutes ?? 20
                        
                        let newMethodSchedule = MethodSchedule(
                            methodId: methodId,
                            duration: defaultDuration,
                            order: daySchedules[firstNonRestDayIndex].methods.count
                        )
                        
                        var updatedDay = daySchedules[firstNonRestDayIndex]
                        updatedDay.methods.append(newMethodSchedule)
                        daySchedules[firstNonRestDayIndex] = updatedDay
                        
                        Logger.debug("Added method \(methodId) to day \(updatedDay.day) (no config, using first non-rest day)")
                    }
                }
            }
        }
        
        // Remove methods from schedule that are no longer selected
        let selectedMethodIds = Set(selectedMethods.compactMap { $0.id })
        for (index, daySchedule) in daySchedules.enumerated() {
            var updatedDay = daySchedule
            updatedDay.methods = daySchedule.methods.filter { methodSchedule in
                selectedMethodIds.contains(methodSchedule.methodId)
            }
            // Re-order methods after filtering
            updatedDay.methods = updatedDay.methods.enumerated().map { idx, method in
                var reorderedMethod = method
                reorderedMethod.order = idx
                return reorderedMethod
            }
            daySchedules[index] = updatedDay
        }
    }
    
    private func determineDaysForMethod(config: MethodSchedulingConfig) -> [Int] {
        let totalDays = daySchedules.count
        var days: [Int] = []
        
        // Check the frequency enum value
        switch config.frequency {
        case .everyDay:
            // Add to all days
            days = Array(1...totalDays)
            Logger.debug("Method scheduled for every day")
            
        case .everyOtherDay:
            // Add to odd days (1, 3, 5, 7, ...)
            days = stride(from: 1, through: totalDays, by: 2).map { $0 }
            Logger.debug("Method scheduled for every other day: \(days)")
            
        case .every2Days:
            // Add every 3 days (1, 4, 7, 10, ...)
            days = stride(from: 1, through: totalDays, by: 3).map { $0 }
            Logger.debug("Method scheduled every 2 days: \(days)")
            
        case .every3Days:
            // Add every 4 days (1, 5, 9, 13, ...)
            days = stride(from: 1, through: totalDays, by: 4).map { $0 }
            Logger.debug("Method scheduled every 3 days: \(days)")
            
        case .custom:
            // Use the specific days selected
            days = Array(config.selectedDays).sorted()
            Logger.debug("Method scheduled for custom days: \(days)")
        }
        
        // Filter to only include days that exist in the schedule
        return days.filter { $0 <= totalDays }
    }
}