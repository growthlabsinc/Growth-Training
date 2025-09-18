import SwiftUI
import Combine
import FirebaseAuth

// Define ErrorAlert struct for identifiable error messages
struct ErrorAlert: Identifiable {
    let id = UUID()
    let message: String
}

class LogSessionViewModel: ObservableObject {
    // For Form Fields
    @Published var sessionDate = Date()
    @Published var selectedMethodId: String? // Store ID to allow nil selection text
    @Published var durationMinutes: String = ""
    @Published var notes: String = ""
    @Published var moodBefore: Mood = .neutral
    @Published var moodAfter: Mood = .neutral

    // Story 12.3: Enhanced tracking fields
    @Published var intensity: Int = 3 // Default mid-level intensity (1-5)
    @Published var variation: String = ""

    // For Method Picker
    @Published var methods: [GrowthMethod] = []
    @Published var isLoadingMethods: Bool = true

    // State Management
    @Published var isSaving: Bool = false
    @Published var errorAlert: ErrorAlert? // Changed from String? to ErrorAlert?
    @Published var saveSuccess: Bool = false

    // Story 8.6: Journaling Prompt
    @Published var currentPrompt: JournalingPrompt?

    var isEditMode: Bool
    private var editingLog: SessionLog? // The log being edited, if any
    private var originalMethod: GrowthMethod? // The method of the log being edited

    private var firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    private let promptService = JournalingPromptService.shared

    // Initializer for creating a new log (method passed in)
    init(methodToLog: GrowthMethod) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalMethod = methodToLog
        self.selectedMethodId = methodToLog.id
        // No need to load methods if one is directly provided for logging
        self.methods = [methodToLog]
        self.isLoadingMethods = false
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }
    
    // Story 7.4: Add initializer with pre-filled duration from timer
    init(methodToLog: GrowthMethod, durationMinutes: Int, preMoodBefore: Mood? = nil) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalMethod = methodToLog
        self.selectedMethodId = methodToLog.id
        // Pre-fill the duration from the timer
        self.durationMinutes = String(durationMinutes)
        // Pre-fill mood before if provided
        if let preMood = preMoodBefore {
            self.moodBefore = preMood
        }
        // No need to load methods if one is directly provided for logging
        self.methods = [methodToLog]
        self.isLoadingMethods = false
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }

    // Initializer for editing an existing log
    init(sessionLogToEdit: SessionLog, growthMethod: GrowthMethod) {
        self.isEditMode = true
        self.editingLog = sessionLogToEdit
        self.originalMethod = growthMethod

        // Pre-populate fields
        self.sessionDate = sessionLogToEdit.startTime
        self.selectedMethodId = sessionLogToEdit.methodId
        self.durationMinutes = String(sessionLogToEdit.duration)
        self.notes = sessionLogToEdit.userNotes ?? ""
        self.moodBefore = sessionLogToEdit.moodBefore
        self.moodAfter = sessionLogToEdit.moodAfter
        
        // Load all methods for the picker, but ensure the current one is selected
        // The view will use `originalMethod` if methods list is empty initially.
        self.loadMethods(ensureSelectedId: sessionLogToEdit.methodId)
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()

        // Story 12.3: prefill enhanced fields if present
        if let existingIntensity = sessionLogToEdit.intensity {
            self.intensity = existingIntensity
        }
        if let existingVariation = sessionLogToEdit.variation {
            self.variation = existingVariation
        }
    }
    
    // Initializer for creating a new log from scratch (no pre-selected method)
    // This might be used if LogSessionView is accessed from a generic "+" button
    init() {
        self.isEditMode = false
        self.editingLog = nil
        self.originalMethod = nil
        self.loadMethods()
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }
    
    // Initializer for wellness activity logging (Story 16.3)
    init(wellnessActivity: WellnessActivity) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalMethod = nil
        self.selectedMethodId = nil // No method for wellness activities
        self.durationMinutes = String(wellnessActivity.duration)
        self.notes = wellnessActivity.notes ?? ""
        self.moodBefore = .neutral
        self.moodAfter = .positive
        self.variation = "wellness_\(wellnessActivity.type.rawValue)"
        self.methods = []
        self.isLoadingMethods = false
        // Load wellness-focused journaling prompt
        currentPrompt = promptService.randomPrompt(for: .wellness)
    }

    var navigationTitle: String {
        isEditMode ? "Edit Session" : "Log Session"
    }

    var saveButtonText: String {
        isEditMode ? "Save Changes" : "Log Session"
    }

    var formIsValid: Bool {
        // For wellness activities, methodId can be nil (stored in variation field)
        let isWellnessActivity = variation.hasPrefix("wellness_")
        if !isWellnessActivity {
            guard selectedMethodId != nil else { return false }
        }
        guard let minutes = Int(durationMinutes), minutes > 0 else { return false }
        return true
    }

    func loadMethods(ensureSelectedId: String? = nil) {
        isLoadingMethods = true
        firestoreService.getAllGrowthMethods { [weak self] (methods, error) in
            DispatchQueue.main.async {
                self?.isLoadingMethods = false
                if let error = error {
                    self?.errorAlert = ErrorAlert(message: "Failed to load methods: \(error.localizedDescription)")
                } else {
                    self?.methods = methods
                    // If an ID to ensure selection was passed (e.g. in edit mode after loading all)
                    // and selectedMethodId is not already set (e.g. initial load for new log)
                    if let idToSelect = ensureSelectedId, self?.selectedMethodId == nil {
                         self?.selectedMethodId = idToSelect
                    } else if self?.selectedMethodId == nil && !(self?.methods.isEmpty ?? true) {
                        // If not edit mode and no method pre-selected from constructor, default to first if available
                        // This line might need adjustment based on desired UX for new logs from scratch
                        // self?.selectedMethodId = self?.methods.first?.id
                    }
                }
            }
        }
    }
    
    func getMethodTitle(methodId: String?) -> String {
        guard let id = methodId else { return "Select a method" }
        return methods.first(where: { $0.id == id })?.title ?? originalMethod?.title ?? "Unknown Method"
    }

    func saveSession() {
        guard formIsValid else {
            errorAlert = ErrorAlert(message: "Please fill all required fields correctly.")
            return
        }
        guard let user = Auth.auth().currentUser else {
            errorAlert = ErrorAlert(message: "You must be logged in.")
            return
        }
        guard let minutes = Int(durationMinutes) else {
            errorAlert = ErrorAlert(message: "Duration is invalid.")
            return
        }
        
        // For wellness activities, methodId can be nil
        let isWellnessActivity = variation.hasPrefix("wellness_")
        if !isWellnessActivity && selectedMethodId == nil {
            errorAlert = ErrorAlert(message: "Method selection is required for non-wellness activities.")
            return
        }

        isSaving = true
        let logId = isEditMode ? (editingLog?.id ?? UUID().uuidString) : UUID().uuidString // Use existing ID if editing

        let sessionLog = SessionLog(
            id: logId,
            userId: user.uid,
            duration: minutes,
            startTime: sessionDate,
            endTime: sessionDate.addingTimeInterval(Double(minutes) * 60),
            userNotes: notes.isEmpty ? nil : notes,
            methodId: selectedMethodId, // Can be nil for wellness activities
            sessionIndex: nil,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            intensity: intensity,
            variation: variation.isEmpty ? nil : variation
        )

        firestoreService.saveSessionLog(log: sessionLog) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error = error {
                    self?.errorAlert = ErrorAlert(message: "Failed to save session: \(error.localizedDescription)")
                } else {
                    self?.saveSuccess = true
                    if self?.isEditMode ?? false {
                        NotificationCenter.default.post(name: .sessionLogUpdated, object: sessionLog)
                    } else {
                        // Story 7.4: Notify about new session log creation
                        NotificationCenter.default.post(name: .sessionLogCreated, object: sessionLog)

                        // Story 8.5: Trigger affirmation for session completion
                        _ = AffirmationService.shared.randomAffirmation(for: .sessionCompletion)
                        
                        // Update routine progress if this was a routine method
                        if let methodId = sessionLog.methodId,
                           let userId = Auth.auth().currentUser?.uid {
                            self?.updateRoutineProgressIfNeeded(userId: userId, methodId: methodId)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Prompt Helpers
    func refreshPrompt(category: PromptCategory = .general) {
        currentPrompt = promptService.randomPrompt(for: category)
    }
    
    // MARK: - Routine Progress Update
    private func updateRoutineProgressIfNeeded(userId: String, methodId: String) {
        // Get the user's selected routine
        UserService().fetchSelectedRoutineId(userId: userId) { routineId in
            guard let routineId = routineId else { return }
            
            // Fetch the routine (checking both custom and main collections)
            RoutineService.shared.fetchRoutineFromAnySource(by: routineId, userId: userId) { result in
                switch result {
                case .success(let routine):
                    // Check if this method is part of today's routine
                    RoutineProgressService.shared.getCurrentRoutineDay(userId: userId, routine: routine) { daySchedule, progress in
                        guard let daySchedule = daySchedule,
                              let methodIds = daySchedule.methodIds,
                              methodIds.contains(methodId),
                              let progress = progress else { return }
                        
                        // Mark the routine day as started if this is the first day and hasn't been completed
                        if progress.currentDayNumber == 1 && progress.completedDays.isEmpty {
                            RoutineProgressService.shared.markRoutineDayStarted(userId: userId, routineId: routineId) { _ in }
                        }
                        
                        // Check if this was the last method for the day
                        if let currentMethodIndex = methodIds.firstIndex(of: methodId),
                           currentMethodIndex >= methodIds.count - 1 {
                            // This was the last method, mark the day as complete
                            RoutineProgressService.shared.markRoutineDayCompleted(userId: userId, routine: routine) { updatedProgress in
                                // Post notification to update UI
                                if let updatedProgress = updatedProgress {
                                    NotificationCenter.default.post(name: .routineProgressUpdated, object: updatedProgress)
                                }
                            }
                        }
                    }
                case .failure(_):
                    // Silently fail - routine tracking is not critical to session logging
                    break
                }
            }
        }
    }
} 

// Story 7.4: Add notification name for session log creation
extension Notification.Name {
    static let sessionLogCreated = Notification.Name("sessionLogCreated")
    static let routineProgressUpdated = Notification.Name("routineProgressUpdated")
    // Note: sessionLogUpdated is already defined in SessionDetailViewModel.swift
    // and used by SessionDetailView and SessionHistoryViewModel
} 