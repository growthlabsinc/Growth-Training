//
//  TimerIntentObserver.swift
//  Growth
//
//  Monitors timer control actions from Live Activity App Intents via SharedUserDefaults
//  Follows Apple's EmojiRangers pattern - no Darwin notifications needed
//

import Foundation
import Combine
import UIKit

/// Monitors timer state changes from Live Activity App Intents
class TimerIntentObserver {
    static let shared = TimerIntentObserver()
    
    private var cancellables = Set<AnyCancellable>()
    private var observationTimer: Timer?
    private let appGroupIdentifier = "group.com.growthlabs.growthmethod"
    private var lastActionTime: Date?
    private var lastProcessedActionId: String?
    
    private init() {
        startObserving()
        setupNotificationObservers()
    }
    
    deinit {
        observationTimer?.invalidate()
    }
    
    private func setupNotificationObservers() {
        // Re-start monitoring when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startObserving()
                // Immediately check for any pending actions
                self?.checkForIntentActions()
            }
            .store(in: &cancellables)
        
        // Stop monitoring when app goes to background to save resources
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopObserving()
            }
            .store(in: &cancellables)
    }
    
    private func startObserving() {
        // Stop any existing timer
        stopObserving()
        
        // Use a timer on the main run loop for reliability
        observationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkForIntentActions()
        }
        
        // Ensure timer runs even when scrolling
        if let timer = observationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        print("TimerIntentObserver: Started monitoring SharedUserDefaults for Live Activity actions")
    }
    
    private func stopObserving() {
        observationTimer?.invalidate()
        observationTimer = nil
    }
    
    private func checkForIntentActions() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        // Check for recent timer actions from Live Activity
        // Try to get as TimeInterval (current format)
        guard let timeInterval = sharedDefaults.object(forKey: "lastActionTime") as? TimeInterval else {
            return
        }
        let actionTime = Date(timeIntervalSince1970: timeInterval)
        
        // Create a unique action ID based on action and time
        guard let action = sharedDefaults.string(forKey: "lastTimerAction") else { return }
        let timerType = sharedDefaults.string(forKey: "lastTimerType") ?? "main"
        let actionId = "\(action)_\(timeInterval)"
        
        // Check if we've already processed this exact action
        if lastProcessedActionId == actionId {
            return
        }
        
        // Only process recent actions (within last 10 seconds)
        guard actionTime.timeIntervalSinceNow > -10.0 else {
            // Clean up old action data
            sharedDefaults.removeObject(forKey: "lastActionTime")
            sharedDefaults.removeObject(forKey: "lastTimerAction")
            sharedDefaults.synchronize()
            return
        }
        
        // Mark as processed
        lastProcessedActionId = actionId
        lastActionTime = actionTime
        
        // Log the action
        print("TimerIntentObserver: Detected \(action) action for \(timerType) timer at \(actionTime)")
        
        // Handle the action
        if timerType == "quick" {
            handleQuickTimerAction(action)
        } else {
            handleMainTimerAction(action)
        }
    }
    
    private func handleMainTimerAction(_ action: String) {
        Task { @MainActor in
            switch action {
            case "pause":
                print("TimerIntentObserver: Processing pause for main timer")
                // Check current timer state first
                if TimerService.shared.timerState == .running {
                    print("TimerIntentObserver: Timer is running, pausing now")
                    TimerService.shared.pause()
                } else {
                    print("TimerIntentObserver: Timer already paused or stopped, state: \(TimerService.shared.timerState)")
                }
                
            case "resume":
                print("TimerIntentObserver: Processing resume for main timer")
                // Check current timer state first
                if TimerService.shared.timerState == .paused {
                    print("TimerIntentObserver: Timer is paused, resuming now")
                    TimerService.shared.resume()
                } else {
                    print("TimerIntentObserver: Timer not paused, state: \(TimerService.shared.timerState)")
                }
                
            case "stop":
                print("TimerIntentObserver: Processing stop for main timer")
                
                // Capture state before stopping
                let capturedElapsedTime = TimerService.shared.elapsedTime
                let capturedStartTime = TimerService.shared.startTime ?? Date().addingTimeInterval(-capturedElapsedTime)
                let methodName = TimerService.shared.currentMethodName ?? "Practice"
                
                // Save completion data to UserDefaults for later processing
                if capturedElapsedTime > 0 {
                    let completionData: [String: Any] = [
                        "elapsedTime": capturedElapsedTime,
                        "startTime": capturedStartTime.timeIntervalSince1970,
                        "methodName": methodName,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                        sharedDefaults.set(completionData, forKey: "pendingTimerCompletion")
                        sharedDefaults.synchronize()
                    }
                    print("TimerIntentObserver: Saved pending timer completion data")
                }
                
                // Stop the timer
                TimerService.shared.stop()
                
                // Post notification to trigger completion flow in TimerViewModel
                let userInfo: [String: Any] = [
                    "elapsedTime": capturedElapsedTime,
                    "startTime": capturedStartTime,
                    "methodName": methodName
                ]
                NotificationCenter.default.post(
                    name: Notification.Name("timerStoppedFromLiveActivity"), 
                    object: nil, 
                    userInfo: userInfo
                )
                print("TimerIntentObserver: Posted timerStoppedFromLiveActivity notification")
                
            default:
                print("TimerIntentObserver: Unknown action for main timer: \(action)")
            }
        }
    }
    
    private func handleQuickTimerAction(_ action: String) {
        Task { @MainActor in
            let quickTimer = QuickPracticeTimerService.shared.timerService
            
            switch action {
            case "pause":
                print("TimerIntentObserver: Processing pause for quick timer")
                if quickTimer.timerState == .running {
                    quickTimer.pause()
                }
                
            case "resume":
                print("TimerIntentObserver: Processing resume for quick timer")
                if quickTimer.timerState == .paused {
                    quickTimer.resume()
                }
                
            case "stop":
                print("TimerIntentObserver: Processing stop for quick timer")
                quickTimer.stop()
                
            default:
                print("TimerIntentObserver: Unknown action for quick timer: \(action)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Force check for pending actions (called when app becomes active)
    func checkPendingActions() {
        checkForIntentActions()
    }
    
    /// Handle stop action from App Group notification
    func handleStopAction(timerType: String) {
        print("TimerIntentObserver: Handling stop action for \(timerType) timer")
        
        if timerType == "quick" {
            handleQuickTimerAction("stop")
        } else {
            handleMainTimerAction("stop")
        }
    }
}