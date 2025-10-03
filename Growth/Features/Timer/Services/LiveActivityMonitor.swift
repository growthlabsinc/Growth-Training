import Foundation
import ActivityKit
import Combine

/// Monitors Live Activity state changes and updates
@available(iOS 16.1, *)
class LiveActivityMonitor: ObservableObject {
    static let shared = LiveActivityMonitor()
    
    private var activityStateObservers: [String: Task<Void, Never>] = [:]
    private var updateTimer: Timer?
    
    private init() {}
    
    /// Start monitoring a specific activity
    func startMonitoring(activity: Activity<TimerActivityAttributes>) {
        let activityId = activity.id
        print("\n🔍 LiveActivityMonitor: Starting monitoring for activity \(activityId)")
        
        // Monitor activity state changes
        let stateTask = Task {
            print("📊 LiveActivityMonitor: Setting up state observer for \(activityId)")
            for await state in activity.activityStateUpdates {
                print("\n🔄 LiveActivityMonitor: Activity state changed")
                print("  - Activity ID: \(activityId)")
                print("  - New state: \(state)")
                print("  - Timestamp: \(Date())")
                
                switch state {
                case .active:
                    print("  ✅ Activity is ACTIVE")
                case .ended:
                    print("  🔴 Activity ENDED")
                    self.stopMonitoring(activityId: activityId)
                case .dismissed:
                    print("  ❌ Activity DISMISSED")
                    self.stopMonitoring(activityId: activityId)
                case .stale:
                    print("  ⚠️ Activity is STALE")
                @unknown default:
                    print("  ❓ Unknown state")
                }
            }
            print("⚠️ LiveActivityMonitor: State updates stream ended for \(activityId)")
        }
        
        activityStateObservers[activityId] = stateTask
        
        // Start periodic update checks
        startPeriodicUpdateCheck(for: activity)
    }
    
    /// Stop monitoring a specific activity
    func stopMonitoring(activityId: String) {
        print("\n🛑 LiveActivityMonitor: Stopping monitoring for activity \(activityId)")
        activityStateObservers[activityId]?.cancel()
        activityStateObservers[activityId] = nil
    }
    
    /// Stop all monitoring
    func stopAllMonitoring() {
        print("\n🛑 LiveActivityMonitor: Stopping all monitoring")
        for (id, task) in activityStateObservers {
            print("  - Cancelling monitor for \(id)")
            task.cancel()
        }
        activityStateObservers.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Periodically check if Live Activity is updating
    private func startPeriodicUpdateCheck(for activity: Activity<TimerActivityAttributes>) {
        updateTimer?.invalidate()
        
        guard #available(iOS 16.2, *) else {
            print("⚠️ LiveActivityMonitor: Periodic updates require iOS 16.2+")
            return
        }
        
        var lastEndTime = activity.content.state.endTime
        var lastCheckTime = Date()
        var updateCount = 0
        
        print("\n⏱ LiveActivityMonitor: Starting periodic update check")
        print("  - Initial end time: \(lastEndTime)")
        print("  - Session type: \(activity.content.state.sessionType)")
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let now = Date()
            let timeSinceLastCheck = now.timeIntervalSince(lastCheckTime)
            lastCheckTime = now
            
            print("\n🔄 LiveActivityMonitor: Periodic check #\(updateCount + 1)")
            print("  - Current time: \(now)")
            print("  - Time since last check: \(timeSinceLastCheck)s")
            
            // Check if the activity still exists
            guard Activity<TimerActivityAttributes>.activities.contains(where: { $0.id == activity.id }) else {
                print("  ❌ Activity no longer exists!")
                self.updateTimer?.invalidate()
                return
            }
            
            // Get fresh activity data
            if let currentActivity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activity.id }) {
                let currentEndTime = currentActivity.content.state.endTime
                let currentState = currentActivity.content.state
                
                print("  - Current state:")
                print("    - isPaused: \(currentState.isPaused)")
                print("    - endTime: \(currentEndTime)")
                print("    - Time until end: \(currentEndTime.timeIntervalSince(now))s")
                
                // Check if end time has changed (indicating an update)
                if currentEndTime != lastEndTime {
                    print("  ✅ End time changed - Activity was updated!")
                    print("    - Old end time: \(lastEndTime)")
                    print("    - New end time: \(currentEndTime)")
                    lastEndTime = currentEndTime
                } else if !currentState.isPaused && currentState.sessionType == .countdown {
                    // For countdown timers that aren't paused, the end time should be updating
                    print("  ⚠️ End time hasn't changed for active countdown timer")
                    print("    - This might indicate the Live Activity is not receiving updates")
                }
                
                // Check activity staleness
                if currentActivity.activityState == .stale {
                    print("  ⚠️ Activity is marked as STALE")
                }
                
                updateCount += 1
            }
        }
        
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
}