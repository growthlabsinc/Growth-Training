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
    @Published var selectedProtocolId: String? // Store ID to allow nil selection text
    @Published var durationMinutes: String = ""
    @Published var notes: String = ""
    @Published var moodBefore: Mood = .neutral
    @Published var moodAfter: Mood = .neutral

    // Story 12.3: Enhanced tracking fields
    @Published var intensity: Int = 3 // Default mid-level intensity (1-5)
    @Published var variation: String = ""

    // For Protocol Picker
    @Published var protocols: [TrainingProtocol] = []
    @Published var isLoadingProtocols: Bool = true

    // State Management
    @Published var isSaving: Bool = false
    @Published var errorAlert: ErrorAlert? // Changed from String? to ErrorAlert?
    @Published var saveSuccess: Bool = false

    // Story 8.6: Journaling Prompt
    @Published var currentPrompt: JournalingPrompt?

    var isEditMode: Bool
    private var editingLog: SessionLog? // The log being edited, if any
    private var originalProtocol: TrainingProtocol? // The protocol of the log being edited

    private var firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    private let promptService = JournalingPromptService.shared

    // Initializer for creating a new log (protocol passed in)
    init(protocolToLog: TrainingProtocol) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalProtocol = protocolToLog
        self.selectedProtocolId = protocolToLog.id
        // No need to load protocols if one is directly provided for logging
        self.protocols = [protocolToLog]
        self.isLoadingProtocols = false
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }
    
    // Story 7.4: Add initializer with pre-filled duration from timer
    init(protocolToLog: TrainingProtocol, durationMinutes: Int, preMoodBefore: Mood? = nil) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalProtocol = protocolToLog
        self.selectedProtocolId = protocolToLog.id
        // Pre-fill the duration from the timer
        self.durationMinutes = String(durationMinutes)
        // Pre-fill mood before if provided
        if let preMood = preMoodBefore {
            self.moodBefore = preMood
        }
        // No need to load protocols if one is directly provided for logging
        self.protocols = [protocolToLog]
        self.isLoadingProtocols = false
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }

    // Initializer for editing an existing log
    init(sessionLogToEdit: SessionLog, growthProtocol: TrainingProtocol) {
        self.isEditMode = true
        self.editingLog = sessionLogToEdit
        self.originalProtocol = growthProtocol

        // Pre-populate fields
        self.sessionDate = sessionLogToEdit.startTime
        self.selectedProtocolId = sessionLogToEdit.methodId
        self.durationMinutes = String(sessionLogToEdit.duration)
        self.notes = sessionLogToEdit.userNotes ?? ""
        self.moodBefore = sessionLogToEdit.moodBefore
        self.moodAfter = sessionLogToEdit.moodAfter

        // Load all protocols for the picker, but ensure the current one is selected
        // The view will use `originalProtocol` if protocols list is empty initially.
        self.loadProtocols(ensureSelectedId: sessionLogToEdit.methodId)
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
    
    // Initializer for creating a new log from scratch (no pre-selected protocol)
    // This might be used if LogSessionView is accessed from a generic "+" button
    init() {
        self.isEditMode = false
        self.editingLog = nil
        self.originalProtocol = nil
        self.loadProtocols()
        // Load an initial journaling prompt
        currentPrompt = promptService.randomPrompt()
    }
    
    // Initializer for wellness activity logging (Story 16.3)
    init(wellnessActivity: WellnessActivity) {
        self.isEditMode = false
        self.editingLog = nil
        self.originalProtocol = nil
        self.selectedProtocolId = nil // No protocol for wellness activities
        self.durationMinutes = String(wellnessActivity.duration)
        self.notes = wellnessActivity.notes ?? ""
        self.moodBefore = .neutral
        self.moodAfter = .positive
        self.variation = "wellness_\(wellnessActivity.type.rawValue)"
        self.protocols = []
        self.isLoadingProtocols = false
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
        // For wellness activities, protocolId can be nil (stored in variation field)
        let isWellnessActivity = variation.hasPrefix("wellness_")
        if !isWellnessActivity {
            guard selectedProtocolId != nil else { return false }
        }
        guard let minutes = Int(durationMinutes), minutes > 0 else { return false }
        return true
    }

    func loadProtocols(ensureSelectedId: String? = nil) {
        isLoadingProtocols = true
        firestoreService.getAllGrowthMethods { [weak self] (protocols, error) in
            DispatchQueue.main.async {
                self?.isLoadingProtocols = false
                if let error = error {
                    self?.errorAlert = ErrorAlert(message: "Failed to load protocols: \(error.localizedDescription)")
                } else {
                    self?.protocols = protocols
                    // If an ID to ensure selection was passed (e.g. in edit mode after loading all)
                    // and selectedProtocolId is not already set (e.g. initial load for new log)
                    if let idToSelect = ensureSelectedId, self?.selectedProtocolId == nil {
                         self?.selectedProtocolId = idToSelect
                    } else if self?.selectedProtocolId == nil && !(self?.protocols.isEmpty ?? true) {
                        // If not edit mode and no protocol pre-selected from constructor, default to first if available
                        // This line might need adjustment based on desired UX for new logs from scratch
                        // self?.selectedProtocolId = self?.protocols.first?.id
                    }
                }
            }
        }
    }
    
    func getProtocolTitle(protocolId: String?) -> String {
        guard let id = protocolId else { return "Select a protocol" }
        return protocols.first(where: { $0.id == id })?.title ?? originalProtocol?.title ?? "Unknown Protocol"
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
        
        // For wellness activities, protocolId can be nil
        let isWellnessActivity = variation.hasPrefix("wellness_")
        if !isWellnessActivity && selectedProtocolId == nil {
            errorAlert = ErrorAlert(message: "Protocol selection is required for non-wellness activities.")
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
            methodId: selectedProtocolId, // Can be nil for wellness activities
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
                        
                        // Update routine progress if this was a routine protocol
                        if let protocolId = sessionLog.methodId,
                           let userId = Auth.auth().currentUser?.uid {
                            self?.updateRoutineProgressIfNeeded(userId: userId, protocolId: protocolId)
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
    private func updateRoutineProgressIfNeeded(userId: String, protocolId: String) {
        // Get the user's selected routine
        UserService().fetchSelectedRoutineId(userId: userId) { routineId in
            guard let routineId = routineId else { return }

            // Fetch the routine (checking both custom and main collections)
            RoutineService.shared.fetchRoutineFromAnySource(by: routineId, userId: userId) { result in
                switch result {
                case .success(let routine):
                    // Check if this protocol is part of today's routine
                    RoutineProgressService.shared.getCurrentRoutineDay(userId: userId, routine: routine) { daySchedule, progress in
                        guard let daySchedule = daySchedule,
                              let methodIds = daySchedule.methodIds,
                              methodIds.contains(protocolId),
                              let progress = progress else { return }

                        // Mark the routine day as started if this is the first day and hasn't been completed
                        if progress.currentDayNumber == 1 && progress.completedDays.isEmpty {
                            RoutineProgressService.shared.markRoutineDayStarted(userId: userId, routineId: routineId) { _ in }
                        }

                        // Check if this was the last protocol for the day
                        if let currentProtocolIndex = methodIds.firstIndex(of: protocolId),
                           currentProtocolIndex >= methodIds.count - 1 {
                            // This was the last protocol, mark the day as complete
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