import Foundation
import ActivityKit
import UIKit

/// Service responsible for keeping Live Activities updated when app goes to background
@available(iOS 16.1, *)
class LiveActivityUpdateService {
    static let shared = LiveActivityUpdateService()
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var updateTimer: Timer?
    private weak var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    /// Start background updates for a Live Activity
    func startBackgroundUpdates(for activity: Activity<TimerActivityAttributes>) {
        print("🔄 LiveActivityUpdateService: Starting background updates for activity \(activity.id)")
        
        // Store reference to current activity
        currentActivity = activity
        
        // Start a background task to keep the app running
        startBackgroundTask()
        
        // Start periodic updates
        startPeriodicUpdates()
    }
    
    /// Stop all background updates
    func stopBackgroundUpdates() {
        print("🛑 LiveActivityUpdateService: Stopping background updates")
        
        updateTimer?.invalidate()
        updateTimer = nil
        currentActivity = nil
        
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⚠️ LiveActivityUpdateService: Background task expiring")
            self?.endBackgroundTask()
        }
        
        print("✅ LiveActivityUpdateService: Background task started")
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        print("✅ LiveActivityUpdateService: Background task ended")
    }
    
    private func startPeriodicUpdates() {
        // Cancel any existing timer
        updateTimer?.invalidate()
        
        // Update every 1 second for smooth countdown
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateLiveActivity()
        }
        
        // Make sure timer runs in common modes
        RunLoop.current.add(updateTimer!, forMode: .common)
        
        print("✅ LiveActivityUpdateService: Started periodic updates (every 1s)")
    }
    
    private func updateLiveActivity() {
        guard let activity = currentActivity,
              activity.activityState == .active else {
            print("⚠️ LiveActivityUpdateService: No active activity to update")
            stopBackgroundUpdates()
            return
        }
        
        let currentState = activity.content.state
        
        // Don't update if paused
        guard !currentState.isPaused else {
            print("⏸ LiveActivityUpdateService: Activity is paused, skipping update")
            return
        }
        
        Task {
            // With the new simplified approach and ProgressView(timerInterval:),
            // we don't need to manually update timestamps.
            // The Live Activity will update automatically.
            
            // Check if timer has completed
            if currentState.sessionType == .countdown {
                let remaining = currentState.currentRemainingTime
                
                if remaining <= 0 {
                    print("⏰ LiveActivityUpdateService: Timer completed")
                    self.stopBackgroundUpdates()
                    return
                }
            }
            
            // For the new approach, we only update if there's an actual state change
            // The timer display updates automatically via ProgressView(timerInterval:)
            print("📱 LiveActivityUpdateService: Timer is running, display updates automatically")
            
            print("📱 LiveActivityUpdateService: Updated Live Activity")
        }
    }
}