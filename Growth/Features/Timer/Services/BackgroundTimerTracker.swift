//
//  BackgroundTimerTracker.swift
//  Growth
//
//  Tracks timer state during background transitions
//

import Foundation
import UserNotifications

class BackgroundTimerTracker {
    static let shared = BackgroundTimerTracker()
    private let stateKey = "timerBackgroundState"
    
    private init() {}
    
    struct BackgroundState: Codable {
        let elapsedTime: TimeInterval
        let remainingTime: TimeInterval
        let state: TimerState
        let mode: String
        let backgroundedAt: Date
        let methodId: String?
        let methodName: String?
        let totalDuration: TimeInterval?
    }
    
    func saveState(elapsedTime: TimeInterval, remainingTime: TimeInterval, 
                   state: TimerState, mode: String, methodId: String?, 
                   methodName: String?, totalDuration: TimeInterval?) {
        
        let backgroundState = BackgroundState(
            elapsedTime: elapsedTime,
            remainingTime: remainingTime,
            state: state,
            mode: mode,
            backgroundedAt: Date(),
            methodId: methodId,
            methodName: methodName,
            totalDuration: totalDuration
        )
        
        if let encoded = try? JSONEncoder().encode(backgroundState) {
            UserDefaults.standard.set(encoded, forKey: stateKey)
            print("BackgroundTimerTracker: Saved state - elapsed: \(elapsedTime), state: \(state)")
        }
    }
    
    func restoreState() -> BackgroundState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(BackgroundState.self, from: data) else {
            return nil
        }
        
        // Clear the saved state after restoration
        clearState()
        
        return state
    }
    
    /// Peek at the saved state without clearing it
    func peekTimerState() -> BackgroundState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(BackgroundState.self, from: data) else {
            return nil
        }
        
        return state
    }
    
    func clearState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
        print("BackgroundTimerTracker: Cleared saved state")
    }
    
    func hasValidState() -> Bool {
        return restoreState() != nil
    }
    
    @MainActor
    func restoreTimerState(to timerService: TimerService, isQuickPractice: Bool) -> (isRunning: Bool, elapsedTime: TimeInterval)? {
        guard let state = restoreState() else { return nil }
        
        // Calculate time elapsed while backgrounded
        let backgroundDuration = Date().timeIntervalSince(state.backgroundedAt)
        var adjustedElapsedTime = state.elapsedTime
        
        // If timer was running, add background time
        if state.state == .running {
            adjustedElapsedTime += backgroundDuration
        }
        
        // Restore timer state
        timerService.elapsedTime = adjustedElapsedTime
        timerService.remainingTime = state.remainingTime
        timerService.currentTimerMode = TimerMode(rawValue: state.mode) ?? .stopwatch
        timerService.currentMethodId = state.methodId
        timerService.currentMethodName = state.methodName
        
        if let totalDuration = state.totalDuration {
            timerService.targetDurationValue = totalDuration
        }
        
        return (isRunning: state.state == .running, elapsedTime: adjustedElapsedTime)
    }
    
    func cancelAllTimerNotifications() {
        // Cancel any pending timer notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("BackgroundTimerTracker: Cancelled all timer notifications")
    }
    
    func hasActiveBackgroundTimer() -> Bool {
        // Check if there's an active background timer state
        return hasValidState()
    }
    
    func clearSavedState() {
        clearState()
    }
    
    @MainActor
    func saveTimerState(from timerService: TimerService, methodName: String, isQuickPractice: Bool) {
        // Save the current timer state for background tracking
        saveState(
            elapsedTime: timerService.elapsedTime,
            remainingTime: timerService.remainingTime,
            state: timerService.timerState,
            mode: timerService.currentTimerMode.rawValue,
            methodId: timerService.currentMethodId,
            methodName: timerService.currentMethodName,
            totalDuration: timerService.targetDurationValue
        )
        
        print("BackgroundTimerTracker: Saved timer state for background tracking")
        print("  - Method: \(methodName)")
        print("  - Is Quick Practice: \(isQuickPractice)")
        print("  - Elapsed: \(timerService.elapsedTime)")
        print("  - State: \(timerService.timerState)")
    }
}