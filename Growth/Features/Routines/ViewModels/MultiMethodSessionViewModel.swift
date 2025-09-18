//
//  MultiMethodSessionViewModel.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import Foundation
import SwiftUI
import Combine

/// Manages the state and flow of multi-method practice sessions
class MultiMethodSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current method index (0-based)
    @Published var currentMethodIndex: Int = 0
    
    /// Total number of methods in the session
    @Published var totalMethods: Int = 0
    
    /// Array of all methods in the session
    @Published var methods: [GrowthMethod] = []
    
    /// Method schedules with custom durations
    private var methodSchedules: [MethodSchedule] = []
    
    /// Current method being practiced
    @Published var currentMethod: GrowthMethod?
    
    /// Next method in queue (nil if on last method)
    @Published var nextMethod: GrowthMethod?
    
    /// Total session time in minutes
    @Published var totalSessionTime: Int = 0
    
    /// Total time remaining in session (seconds)
    @Published var totalTimeRemaining: Int = 0
    
    /// Current method time remaining (seconds)
    @Published var currentMethodTimeRemaining: Int = 0
    
    /// Whether auto-progression is enabled
    /// Note: This MUST default to false to prevent unwanted auto-advancement
    @Published var autoProgressionEnabled: Bool = false
    
    /// Whether to show the up-next preview
    @Published var showUpNextPreview: Bool = false
    
    /// Whether the entire session is complete
    @Published var isSessionComplete: Bool = false
    
    /// Whether methods are currently being loaded
    @Published var isLoadingMethods: Bool = true
    
    /// Track which methods have been started/completed
    @Published var methodCompletionStatus: [String: MethodStatus] = [:]
    
    // MARK: - Private Properties
    
    private let schedule: DaySchedule
    private let growthMethodService: GrowthMethodService
    private var cancellables = Set<AnyCancellable>()
    private var upNextTimer: Timer?
    
    // MARK: - Nested Types
    
    struct MethodStatus {
        var started: Bool = false
        var completed: Bool = false
        var duration: TimeInterval = 0
    }
    
    // MARK: - Computed Properties
    
    /// Whether we can go to previous method
    var canGoPrevious: Bool {
        currentMethodIndex > 0
    }
    
    /// Whether we can go to next method
    var canGoNext: Bool {
        currentMethodIndex < methods.count - 1
    }
    
    /// Progress through the session (0.0 to 1.0)
    var sessionProgress: Double {
        guard totalMethods > 0 else { return 0 }
        
        // Calculate base progress from completed methods
        let completedMethods = methodsCompleted
        let baseProgress = Double(completedMethods) / Double(totalMethods)
        
        // Add current method progress if timer is running
        if currentMethodIndex < methods.count,
           currentMethodIndex < methodSchedules.count {
            // Use custom duration from method schedule
            let methodDuration = methodSchedules[currentMethodIndex].duration
            if methodDuration > 0 {
                // Calculate how much of the current method is complete
                let methodTotalSeconds = Double(methodDuration * 60)
                let methodElapsedSeconds = methodTotalSeconds - Double(currentMethodTimeRemaining)
                let methodProgress = max(0, min(1, methodElapsedSeconds / methodTotalSeconds))
                
                // Add the current method's contribution to overall progress
                let currentMethodContribution = methodProgress / Double(totalMethods)
                return min(1.0, baseProgress + currentMethodContribution)
            }
        }
        
        return baseProgress
    }
    
    /// Human-readable session progress text
    var sessionProgressText: String {
        "Method \(currentMethodIndex + 1) of \(totalMethods)"
    }
    
    /// Total elapsed time in session (seconds)
    var totalElapsedTime: Int {
        let totalSeconds = totalSessionTime * 60
        return totalSeconds - totalTimeRemaining
    }
    
    /// Number of methods that have been started
    var methodsStarted: Int {
        methodCompletionStatus.values.filter { $0.started }.count
    }
    
    /// Number of methods that have been completed
    var methodsCompleted: Int {
        methodCompletionStatus.values.filter { $0.completed }.count
    }
    
    /// Whether session has partial progress
    var hasPartialProgress: Bool {
        methodsStarted > 0 && methodsCompleted < totalMethods
    }
    
    // MARK: - Initialization
    
    init(schedule: DaySchedule, growthMethodService: GrowthMethodService = .shared) {
        self.schedule = schedule
        self.growthMethodService = growthMethodService
        
        // Explicitly set auto-progression to false on init
        self.autoProgressionEnabled = false
        
        setupSession()
        syncCompletionStateFromCache()
        
        // Listen for session reset notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionsReset),
            name: Notification.Name("sessionsReset"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Move to the next method in the session
    func goToNextMethod() {
        guard canGoNext else { return }
        
        currentMethodIndex += 1
        updateCurrentMethod()
        resetMethodTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Move to the previous method in the session
    func goToPreviousMethod() {
        guard canGoPrevious else { return }
        
        currentMethodIndex -= 1
        updateCurrentMethod()
        resetMethodTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Called when current method timer completes
    func onMethodComplete() {
        if autoProgressionEnabled && canGoNext {
            // Auto-progress to next method
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.goToNextMethod()
            }
        } else if !canGoNext {
            // Session complete
            completeSession()
        }
    }
    
    /// Update the current method time remaining
    func updateMethodTime(_ timeRemaining: Int) {
        currentMethodTimeRemaining = timeRemaining
        updateTotalTimeRemaining()
        checkUpNextPreview()
        
        // Force UI update when time changes to ensure progress bar updates smoothly
        objectWillChange.send()
    }
    
    /// Complete the entire session
    func completeSession() {
        
        isSessionComplete = true
        cancelUpNextTimer()
        
        // Success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Mark a method as started
    func markMethodStarted(_ methodId: String) {
        if methodCompletionStatus[methodId] == nil {
            methodCompletionStatus[methodId] = MethodStatus()
        }
        methodCompletionStatus[methodId]?.started = true
    }
    
    /// Mark a method as completed
    func markMethodCompleted(_ methodId: String, duration: TimeInterval) {
        if methodCompletionStatus[methodId] == nil {
            methodCompletionStatus[methodId] = MethodStatus()
        }
        methodCompletionStatus[methodId]?.completed = true
        methodCompletionStatus[methodId]?.duration = duration
        
        // Save to cache immediately when marked as completed
        saveCompletedMethodsToCache()
        
        // Force UI update when method is marked as completed
        objectWillChange.send()
    }
    
    /// Reset completion state for a method (used when dismissing without logging)
    func resetMethodCompletion(_ methodId: String) {
        if var status = methodCompletionStatus[methodId] {
            status.completed = false
            status.duration = 0
            methodCompletionStatus[methodId] = status
            
            // Save updated state to cache
            saveCompletedMethodsToCache()
            
            // Force UI update when method completion is reset
            objectWillChange.send()
        }
    }
    
    /// Clear all completion status (used when sessions are reset)
    func clearAllCompletionStatus() {
        methodCompletionStatus.removeAll()
        currentMethodIndex = 0
        updateCurrentMethod()
        resetMethodTimer()
        objectWillChange.send()
    }
    
    @objc private func handleSessionsReset() {
        // Clear all in-memory completion status
        clearAllCompletionStatus()
        
        // Reload from cache (which should be empty now)
        syncCompletionStateFromCache()
    }
    
    /// Get completion status for all methods
    func getCompletionDetails() -> [(methodId: String, methodName: String, status: MethodStatus)] {
        methods.compactMap { method in
            guard let methodId = method.id,
                  let status = methodCompletionStatus[methodId] else { return nil }
            return (methodId, method.title, status)
        }
    }
    
    /// Get custom duration for a method at the given index
    func getCustomDuration(for index: Int) -> Int? {
        guard index >= 0 && index < methodSchedules.count else { 
            return nil 
        }
        let duration = methodSchedules[index].duration
        return duration
    }
    
    /// Get custom duration for the current method
    func getCurrentMethodCustomDuration() -> Int? {
        let duration = getCustomDuration(for: currentMethodIndex)
        return duration
    }
    
    // MARK: - Cache Management
    
    /// Save completed methods to UserDefaults cache
    func saveCompletedMethodsToCache() {
        // Get today's date string for cache key
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Include routine ID to handle routine changes
        let routineId = schedule.id
        let cacheKey = "completedMethods_\(dateString)_\(routineId)"
        
        // Get completed method IDs
        let completedMethodIds = methodCompletionStatus
            .filter { $0.value.completed }
            .map { $0.key }
        
        // Save to UserDefaults
        UserDefaults.standard.set(completedMethodIds, forKey: cacheKey)
        UserDefaults.standard.synchronize()
        
        print("💾 Saved \(completedMethodIds.count) completed methods to cache for key: \(cacheKey)")
    }
    
    /// Load completed methods from UserDefaults cache
    func loadCompletedMethodsFromCache() {
        // Get today's date string for cache key
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Include routine ID to handle routine changes
        let routineId = schedule.id
        let cacheKey = "completedMethods_\(dateString)_\(routineId)"
        
        // Check if cache exists
        if let methodIdsArray = UserDefaults.standard.array(forKey: cacheKey) as? [String] {
            print("📱 Loading \(methodIdsArray.count) completed methods from cache for key: \(cacheKey)")
            
            // Mark each method as completed
            for methodId in methodIdsArray {
                // Find the method in our schedule
                if schedule.methods.contains(where: { $0.methodId == methodId }) {
                    if methodCompletionStatus[methodId] == nil {
                        methodCompletionStatus[methodId] = MethodStatus()
                    }
                    methodCompletionStatus[methodId]?.completed = true
                }
            }
            
            // Force UI update
            objectWillChange.send()
        } else {
            print("📱 No cached completed methods found for key: \(cacheKey)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Sync completion state from cache to restore progress after app restart
    private func syncCompletionStateFromCache() {
        // Get today's cache key
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)
        
        // Check multiple possible cache keys including routine-specific ones
        var methodIdsArray: [String]? = nil
        
        // First check for any routine-specific keys
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.starts(with: "completedMethods_\(dateString)") {
                if let cached = UserDefaults.standard.array(forKey: key) as? [String], !cached.isEmpty {
                    methodIdsArray = cached
                    print("📱 Found cached methods with key: \(key)")
                    break
                }
            }
        }
        
        // If not found, check generic keys
        if methodIdsArray == nil {
            let possibleKeys = [
                "completedMethods_\(dateString)",
                "completedMethods_\(dateString)_none"
            ]
            
            for key in possibleKeys {
                if let cached = UserDefaults.standard.array(forKey: key) as? [String], !cached.isEmpty {
                    methodIdsArray = cached
                    print("📱 Found cached methods with key: \(key)")
                    break
                }
            }
        }
        
        // Check if cache exists
        if let methodIdsArray = methodIdsArray {
            // Mark each method as completed
            for methodId in methodIdsArray {
                if schedule.methods.contains(where: { $0.methodId == methodId }) {
                    markMethodCompleted(methodId, duration: 0)
                }
            }
            
            // Find the first uncompleted method and set currentMethodIndex to it
            // This needs to happen after methods are loaded
            Task { @MainActor in
                // Wait for methods to be loaded
                while isLoadingMethods {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
                // Now find the appropriate method index
                var targetIndex = 0
                for (index, method) in methods.enumerated() {
                    if let methodId = method.id,
                       let status = methodCompletionStatus[methodId],
                       status.completed {
                        // This method is completed, move to the next one
                        targetIndex = min(index + 1, methods.count - 1)
                    } else {
                        // Found the first uncompleted method
                        break
                    }
                }
                
                // Set the current method index to the first uncompleted method
                if targetIndex != currentMethodIndex && targetIndex < methods.count {
                    currentMethodIndex = targetIndex
                    updateCurrentMethod()
                    resetMethodTimer()
                    
                    // Force UI update
                    objectWillChange.send()
                }
            }
        }
    }
    
    private func setupSession() {
        // Handle rest days gracefully
        if schedule.isRestDay {
            totalMethods = 0
            methods = []
            methodSchedules = []
            isLoadingMethods = false
            return
        }
        
        let methodSchedules = schedule.methods
        guard !methodSchedules.isEmpty else {
            totalMethods = 0
            methods = []
            isLoadingMethods = false
            return
        }
        
        // Sort methods by order to respect user's custom ordering
        let sortedMethodSchedules = methodSchedules.sorted { $0.order < $1.order }
        self.methodSchedules = sortedMethodSchedules
        let methodIds = sortedMethodSchedules.map { $0.methodId }
        
        
        totalMethods = methodIds.count
        
        // Load all methods for the session
        Task { @MainActor in
            do {
                var loadedMethods: [GrowthMethod] = []
                
                // Load methods sequentially to preserve order
                for methodId in methodIds {
                    // Use callback-based API and convert to async
                    let method = try await withCheckedThrowingContinuation { continuation in
                        growthMethodService.fetchMethod(withId: methodId) { result in
                            switch result {
                            case .success(let method):
                                continuation.resume(returning: method)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    loadedMethods.append(method)
                }
                
                // Methods are already in the correct order from sequential loading
                self.methods = loadedMethods
                
                
                self.calculateTotalSessionTime()
                self.updateCurrentMethod()
                self.isLoadingMethods = false
                
                // Load any cached completion state for today
                self.loadCompletedMethodsFromCache()
                
            } catch {
                Logger.debug("Error loading methods: \(error)")
                self.isLoadingMethods = false
            }
        }
    }
    
    private func calculateTotalSessionTime() {
        // Use custom durations from method schedules
        totalSessionTime = methodSchedules.reduce(0) { total, schedule in
            total + schedule.duration
        }
        totalTimeRemaining = totalSessionTime * 60
        
    }
    
    private func updateCurrentMethod() {
        guard currentMethodIndex < methods.count else { return }
        
        currentMethod = methods[currentMethodIndex]
        
        // Mark current method as started
        if let methodId = currentMethod?.id {
            markMethodStarted(methodId)
        }
        
        // Update next method
        if currentMethodIndex < methods.count - 1 {
            nextMethod = methods[currentMethodIndex + 1]
        } else {
            nextMethod = nil
        }
        
        // Reset up-next preview
        showUpNextPreview = false
        cancelUpNextTimer()
    }
    
    private func resetMethodTimer() {
        // Use custom duration from method schedule
        if currentMethodIndex < methodSchedules.count {
            let customDuration = methodSchedules[currentMethodIndex].duration
            currentMethodTimeRemaining = customDuration * 60
        } else if let duration = currentMethod?.estimatedDurationMinutes {
            // Fallback to default duration if schedule not available
            currentMethodTimeRemaining = duration * 60
        }
    }
    
    private func updateTotalTimeRemaining() {
        // Calculate time remaining based on current method progress
        var remainingTime = currentMethodTimeRemaining
        
        // Add time for remaining methods using custom durations
        for i in (currentMethodIndex + 1)..<methodSchedules.count {
            remainingTime += methodSchedules[i].duration * 60
        }
        
        totalTimeRemaining = remainingTime
    }
    
    private func checkUpNextPreview() {
        // Show preview when 30 seconds remain in current method
        if currentMethodTimeRemaining <= 30 && currentMethodTimeRemaining > 0 && nextMethod != nil {
            if !showUpNextPreview {
                showUpNextPreview = true
                
                // Hide preview after 20 seconds
                cancelUpNextTimer()
                upNextTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.showUpNextPreview = false
                    }
                }
            }
        }
    }
    
    private func cancelUpNextTimer() {
        upNextTimer?.invalidate()
        upNextTimer = nil
    }
    
    deinit {
        cancelUpNextTimer()
    }
}