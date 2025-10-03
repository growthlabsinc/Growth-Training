import Foundation
import ActivityKit

// Simple extension to integrate Live Activities with TimerService
extension TimerService {
    
    // Start Live Activity when timer starts
    func startLiveActivityIfEnabled() {
        guard #available(iOS 16.1, *) else { return }
        
        let methodName = currentMethodName ?? "Training"
        let sessionType: SessionType
        
        switch timerMode {
        case .stopwatch:
            // For stopwatch, we'll use countdown with a large duration
            sessionType = .countdown
        case .countdown:
            sessionType = .countdown
        case .interval:
            sessionType = .interval
        }
        
        let targetDuration: TimeInterval
        if timerMode == .countdown {
            targetDuration = targetDurationValue > 0 ? targetDurationValue : 300 // Default to 5 minutes if 0 or negative
        } else {
            targetDuration = 3600 // Default to 1 hour for stopwatch/interval
        }
        
        // Use the LiveActivityManager
        LiveActivityManager.shared.startActivity(
            methodId: currentMethodId ?? "",
            methodName: methodName,
            duration: targetDuration,
            sessionType: sessionType
        )
    }
    
    // Update Live Activity when timer pauses
    func pauseLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        Task { @MainActor in
            await LiveActivityManager.shared.pauseTimer()
        }
    }
    
    // Update Live Activity when timer resumes
    func resumeLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        Task { @MainActor in
            await LiveActivityManager.shared.resumeTimer()
        }
    }
    
    // End Live Activity when timer stops
    func stopLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        Task { @MainActor in
            await LiveActivityManager.shared.stopTimer()
        }
    }
    
    // Helper to determine method type
    private func determineMethodType() -> String {
        guard let methodId = currentMethodId else { return "other" }
        
        if methodId.contains("jelq") {
            return "jelqing"
        } else if methodId.contains("stretch") {
            return "stretching"
        } else if methodId.contains("pump") {
            return "pumping"
        } else {
            return "other"
        }
    }
    
    // Setup observers for widget actions
    func setupLiveActivityObservers() {
        // Pause from widget
        NotificationCenter.default.addObserver(
            forName: .pauseTimerFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.state == .running {
                    self?.pause()
                }
            }
        }
        
        // Resume from widget
        NotificationCenter.default.addObserver(
            forName: .resumeTimerFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.state == .paused {
                    self?.resume()
                }
            }
        }
        
        // Stop from widget
        NotificationCenter.default.addObserver(
            forName: .stopTimerFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
            }
        }
    }
}

// Notification names
extension Notification.Name {
    static let pauseTimerFromWidget = Notification.Name("pauseTimerFromWidget")
    static let resumeTimerFromWidget = Notification.Name("resumeTimerFromWidget")
    static let stopTimerFromWidget = Notification.Name("stopTimerFromWidget")
}