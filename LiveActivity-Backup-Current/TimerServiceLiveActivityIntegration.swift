import Foundation
import ActivityKit

// Simple extension to integrate Live Activities with TimerService
extension TimerService {
    
    // Start Live Activity when timer starts
    func startLiveActivityIfEnabled() {
        guard #available(iOS 16.2, *) else { return }
        
        let methodName = currentMethodName ?? "Training"
        let sessionType: String
        
        switch timerMode {
        case .stopwatch:
            sessionType = "stopwatch"
        case .countdown:
            sessionType = "countdown"
        case .interval:
            sessionType = "interval"
        }
        
        let targetDuration: TimeInterval
        if timerMode == .countdown {
            targetDuration = targetDurationValue > 0 ? targetDurationValue : 300 // Default to 5 minutes if 0 or negative
        } else {
            targetDuration = 3600 // Default to 1 hour for countup/stopwatch
        }
        
        SimpleLiveActivityManager.shared.startActivity(
            methodId: currentMethodId ?? "",
            methodName: methodName,
            sessionType: sessionType,
            targetDuration: targetDuration
        )
    }
    
    // Update Live Activity when timer pauses
    func pauseLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        SimpleLiveActivityManager.shared.pauseActivity()
    }
    
    // Update Live Activity when timer resumes
    func resumeLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        SimpleLiveActivityManager.shared.resumeActivity()
    }
    
    // End Live Activity when timer stops
    func stopLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        SimpleLiveActivityManager.shared.endActivity()
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
            if self?.state == .running {
                self?.pause()
            }
        }
        
        // Resume from widget
        NotificationCenter.default.addObserver(
            forName: .resumeTimerFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.state == .paused {
                self?.resume()
            }
        }
        
        // Stop from widget
        NotificationCenter.default.addObserver(
            forName: .stopTimerFromWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }
}

// Notification names
extension Notification.Name {
    static let pauseTimerFromWidget = Notification.Name("pauseTimerFromWidget")
    static let resumeTimerFromWidget = Notification.Name("resumeTimerFromWidget")
    static let stopTimerFromWidget = Notification.Name("stopTimerFromWidget")
}