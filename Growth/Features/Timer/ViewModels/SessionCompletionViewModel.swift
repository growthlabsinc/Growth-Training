//
//  SessionCompletionViewModel.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import Combine
import FirebaseAuth
import os

@MainActor
class SessionCompletionViewModel: ObservableObject {
    @Published var sessionLog: SessionLog?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showCompletionPrompt: Bool = false
    @Published var perceivedDifficulty: Int = 5
    @Published var notes: String = ""
    @Published var isSaving: Bool = false
    @Published var saveComplete: Bool = false

    // Story 8.4 & 10.2: Pre-session capture
    @Published var preMood: Mood?
    @Published var preMeasurements: [MeasurementType: Double]?

    // Post-session measurements for yield tracking
    @Published var postMeasurements: [MeasurementType: Double]?

    // Store the actual elapsed time in seconds for the completion view
    private var actualElapsedTimeInSeconds: TimeInterval = 0
    
    private let sessionService = SessionService.shared
    private let firestoreService = FirestoreService.shared
    private let progressionService = ProgressionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var sessionDuration: Int {
        sessionLog?.duration ?? 0
    }
    
    var formattedDuration: String {
        // sessionDuration is already in minutes
        let hours = sessionDuration / 60
        let minutes = sessionDuration % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    var methodName: String {
        sessionLog?.variation ?? "Practice Session"
    }
    
    var elapsedTimeInSeconds: TimeInterval {
        actualElapsedTimeInSeconds
    }
    
    init(sessionLog: SessionLog? = nil) {
        self.sessionLog = sessionLog
    }
    
    // MARK: - Exit Handling
    
    func handleExitRequest() -> Bool {
        // If session is in progress and has meaningful duration, show prompt
        if let log = sessionLog, log.duration > 0 {
            showCompletionPrompt = true
            return false // Don't exit yet
        }
        return true // OK to exit
    }
    
    // MARK: - Progress Updates
    
    func updateMethodProgress(methodId: String, methodName: String, completed: Bool = false) {
        // Update session log with method progress
        sessionLog?.methodId = methodId
        sessionLog?.variation = methodName
    }
    
    func startSession(
        type: SessionType,
        methodId: String? = nil,
        methodName: String? = nil,
        totalMethods: Int? = nil,
        methods: [TrainingProtocol]? = nil
    ) {
        // Store session metadata for later use
        // This method is called when a session starts to prepare for completion
    }

    // MARK: - Story 8.4 & 10.2: Pre-session Capture

    func setPreSessionMood(_ mood: Mood?) {
        preMood = mood
    }

    func setPreSessionMeasurements(_ measurements: [MeasurementType: Double]?) {
        preMeasurements = measurements
    }

    func setPostSessionMeasurements(_ measurements: [MeasurementType: Double]?) {
        postMeasurements = measurements
    }

    func completeSession(
        methodId: String?,
        duration: TimeInterval,
        startTime: Date,
        variation: String? = nil,
        stage: Int? = nil,
        preMeasurements: [MeasurementType: Double]? = nil  // Story 10.2
    ) {
        Logger.debug("📊 SessionCompletionViewModel.completeSession called")
        Logger.debug("  - methodId: \(methodId ?? "nil")")
        Logger.debug("  - duration: \(duration)")
        Logger.debug("  - showCompletionPrompt before: \(showCompletionPrompt)")

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            Logger.error("❌ Error: User not authenticated")
            return
        }

        // Store the actual elapsed time in seconds
        self.actualElapsedTimeInSeconds = duration

        // Create session log
        // Use parameter preMeasurements if provided, otherwise use stored self.preMeasurements
        let measurementsToUse = preMeasurements ?? self.preMeasurements
        let log = SessionLog(
            id: UUID().uuidString,
            userId: userId,
            duration: Int(duration / 60), // Convert seconds to minutes
            startTime: startTime,
            endTime: Date(),
            userNotes: notes.isEmpty ? nil : notes,
            methodId: methodId,
            intensity: perceivedDifficulty,
            variation: variation,
            preMeasurements: measurementsToUse,  // Story 10.2
            postMeasurements: self.postMeasurements  // Include post-session measurements
        )

        self.sessionLog = log
        showCompletionPrompt = true
        Logger.debug("  - showCompletionPrompt after: \(showCompletionPrompt)")
        Logger.debug("  - sessionLog created: \(log.id)")
    }
    
    func saveSession() {
        guard var sessionLog = sessionLog else {
            Logger.warning("⚠️ saveSession - no sessionLog, returning")
            return
        }

        // Update sessionLog with latest postMeasurements if available
        if let postMeasurements = self.postMeasurements {
            sessionLog.postMeasurements = postMeasurements
        }

        Logger.debug("💾 saveSession called")
        Logger.debug("  - sessionLog id: \(sessionLog.id)")
        Logger.debug("  - preMeasurements: \(String(describing: sessionLog.preMeasurements))")
        Logger.debug("  - postMeasurements: \(String(describing: sessionLog.postMeasurements))")
        Logger.debug("  - showCompletionPrompt before save: \(showCompletionPrompt)")

        isSaving = true
        errorMessage = nil

        // Save session log
        sessionService.saveSessionLog(sessionLog) { [weak self] error in
            Logger.debug("💾 saveSessionLog callback")

            if let error = error {
                Logger.error("❌ Error saving session: \(error.localizedDescription)")
                self?.errorMessage = error.localizedDescription
                self?.isSaving = false
                return
            }

            Logger.debug("✅ Session saved successfully")

            // Post session logged notification
            // Include sessionType to differentiate between routine and quick practice sessions
            var notificationInfo: [String: Any] = [:]

            // Determine session type based on whether methodId exists
            // Sessions with methodId are routine sessions, without are quick practice
            let sessionType: SessionType = sessionLog.methodId != nil ? .multiMethod : .quickPractice
            notificationInfo["sessionType"] = sessionType.rawValue


            // Post notification on main thread for immediate UI updates
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sessionLogged,
                    object: sessionLog,
                    userInfo: notificationInfo
                )
            }

            // Update routine progress if this was a routine method
            if let methodId = sessionLog.methodId,
               let userId = Auth.auth().currentUser?.uid {
                self?.updateRoutineProgressIfNeeded(userId: userId, methodId: methodId)
            }

            // Update progression if method ID exists
            if let methodId = sessionLog.methodId {
                Logger.debug("🔄 Updating progression for methodId: \(methodId)")
                self?.updateProgression(methodId: methodId, sessionLog: sessionLog)
            } else {
                Logger.debug("ℹ️ No methodId, marking save complete")
                self?.isSaving = false
                self?.saveComplete = true
                // REMOVED: Don't dismiss the completion prompt here
                // self?.showCompletionPrompt = false
                Logger.debug("📋 showCompletionPrompt NOT changed (keeping sheet visible)")
            }
        }
    }
    
    private func updateProgression(methodId: String, sessionLog: SessionLog) {
        guard Auth.auth().currentUser?.uid != nil else {
            Logger.warning("⚠️ updateProgression - no authenticated user")
            return
        }

        Logger.debug("🔄 updateProgression called for methodId: \(methodId)")

        // First fetch the growth method
        TrainingProtocolService.shared.fetchMethod(withId: methodId) { [weak self] result in
            switch result {
            case .success(let method):
                Logger.debug("✅ Method fetched successfully: \(method.title)")
                // Get current progression snapshot
                self?.progressionService.evaluateReadiness(for: method) { snapshot in
                    // Progress the user based on session completion
                    self?.progressionService.progressUser(for: method, latestSnapshot: snapshot) { success, error in
                        self?.isSaving = false
                        if success {
                            Logger.debug("✅ Progression updated successfully")
                            self?.saveComplete = true
                            // REMOVED: Don't dismiss the completion prompt here
                            // self?.showCompletionPrompt = false
                            Logger.debug("📋 showCompletionPrompt NOT changed (keeping sheet visible)")
                        } else {
                            Logger.error("❌ Failed to update progression: \(error?.localizedDescription ?? "Unknown error")")
                            self?.errorMessage = error?.localizedDescription ?? "Failed to update progression"
                        }
                    }
                }
            case .failure(let error):
                Logger.error("❌ Failed to fetch method: \(error.localizedDescription)")
                self?.isSaving = false
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func skipLogging() {
        showCompletionPrompt = false
        sessionLog = nil
    }
    
    func reset() {
        sessionLog = nil
        perceivedDifficulty = 5
        notes = ""
        errorMessage = nil
        saveComplete = false
        showCompletionPrompt = false
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