//
//  LiveActivityManager.swift
//  Growth
//
//  Built from scratch based on research from:
//  - expo-live-activity-timer architecture
//  - Apple Live Activity best practices
//  - startedAt/pausedAt pattern research
//

import Foundation
import ActivityKit
import UIKit


@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {
        setupNotificationObservers()
    }
    
    // MARK: - Core Functionality (Based on Research)
    
    /// Check if Live Activities are available - from Apple documentation
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    /// Start a new Live Activity - must be called from foreground
    func startActivity(methodId: String, methodName: String, duration: TimeInterval = 1800, sessionType: SessionType = .countup) {
        print("🚀 LiveActivityManager.startActivity called:")
        print("  - methodId: \(methodId)")
        print("  - methodName: \(methodName)")
        print("  - duration: \(duration)")
        print("  - sessionType: \(sessionType)")
        print("  - Thread: \(Thread.current)")
        print("  - areActivitiesEnabled: \(areActivitiesEnabled)")
        
        guard areActivitiesEnabled else {
            print("❌ Live Activities not enabled - check Settings > Privacy & Security > Live Activities")
            print("❌ Please go to Settings > Privacy & Security > Live Activities and enable them")
            print("❌ Also check that Live Activities are enabled for this app specifically")
            return
        }
        
        print("✅ Activities are enabled, proceeding with Live Activity creation...")
        print("📱 Current available activities: \(Activity<TimerActivityAttributes>.activities)")
        print("📱 Device time: \(Date())")
        print("📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        Task {
            do {
                print("🔄 Preparing to start new Live Activity...")
                print("📊 Current activities count: \(Activity<TimerActivityAttributes>.activities.count)")
                print("📊 Has current activity: \(currentActivity != nil)")
                
                // Force cleanup of all activities
                await forceCleanupAllActivities()
                
                print("📊 After cleanup - activities count: \(Activity<TimerActivityAttributes>.activities.count)")
                
                
                print("🏗️ Creating TimerActivityAttributes...")
                // Create attributes and initial state - based on research pattern
                let attributes = TimerActivityAttributes(
                    methodId: methodId,
                    timerType: "main"
                )
                
                print("🏗️ Creating initial ContentState...")
                let initialState = TimerActivityAttributes.ContentState(
                    startedAt: Date(),
                    pausedAt: nil,
                    duration: duration,
                    methodName: methodName,
                    sessionType: sessionType
                )
                
                print("📱 Requesting Live Activity from ActivityKit...")
                print("  - Using attributes: methodId='\(attributes.methodId)', timerType='\(attributes.timerType)'")
                print("  - Using initialState: startedAt=\(initialState.startedAt), duration=\(initialState.duration)")
                print("  - SessionType: \(initialState.sessionType)")
                
                // Request activity - following research patterns
                let activity: Activity<TimerActivityAttributes>
                if #available(iOS 16.2, *) {
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        content: .init(
                            state: initialState,
                            staleDate: Date().addingTimeInterval(28800) // 8 hours - from research
                        ),
                        pushType: nil
                    )
                } else {
                    // iOS 16.1 fallback - use the basic request method without content wrapper
                    activity = try Activity<TimerActivityAttributes>.request(
                        attributes: attributes,
                        contentState: initialState
                    )
                }
                
                self.currentActivity = activity
                print("✅ Live Activity started successfully!")
                print("  - Activity ID: \(activity.id)")
                print("  - Activity State: \(activity.activityState)")
                if #available(iOS 16.2, *) {
                    print("  - Content State startedAt: \(activity.content.state.startedAt)")
                    print("  - Content State methodName: \(activity.content.state.methodName)")
                    print("  - Content State duration: \(activity.content.state.duration)")
                    print("  - Content State sessionType: \(activity.content.state.sessionType)")
                    print("  - Content State isPaused: \(activity.content.state.isPaused)")
                } else {
                    print("  - Content State details: [iOS 16.2+ required]")
                }
                print("  - Total activities now: \(Activity<TimerActivityAttributes>.activities.count)")
                
                // Give the system time to register the activity
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                print("📱 Live Activity should now be visible on Lock Screen/Dynamic Island")
                
            } catch {
                print("❌ Failed to start Live Activity:")
                print("  - Error: \(error)")
                print("  - Error type: \(type(of: error))")
                if let nsError = error as NSError? {
                    print("  - Error code: \(nsError.code)")
                    print("  - Error domain: \(nsError.domain)")
                    print("  - Error description: \(nsError.localizedDescription)")
                }
            }
        }
    }
    
    /// Pause the timer - using startedAt/pausedAt pattern from research
    func pauseTimer() {
        guard let activity = currentActivity else { return }
        
        Task {
            if #available(iOS 16.2, *) {
                // Based on expo-live-activity-timer pattern - just set pausedAt
                var updatedState = activity.content.state
                updatedState.pausedAt = Date()
                
                await updateActivity(with: updatedState)
                print("⏸️ Timer paused")
            } else {
                print("⚠️ Timer pause requires iOS 16.2+")
            }
        }
    }
    
    /// Resume the timer - adjust startedAt to account for pause duration
    func resumeTimer() {
        guard let activity = currentActivity else { return }
        
        Task {
            if #available(iOS 16.2, *) {
                var updatedState = activity.content.state
                
                // From expo-live-activity-timer research: adjust startedAt by pause duration
                if let pausedAt = updatedState.pausedAt {
                    let pauseDuration = Date().timeIntervalSince(pausedAt)
                    updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
                    updatedState.pausedAt = nil
                }
                
                await updateActivity(with: updatedState)
                print("▶️ Timer resumed")
            } else {
                print("⚠️ Timer resume requires iOS 16.2+")
            }
        }
    }
    
    /// Stop and end the timer
    func stopTimer() {
        Task {
            await endCurrentActivity()
            print("⏹️ Timer stopped")
        }
    }
    
    // MARK: - Internal Methods (Based on Research Patterns)
    
    private func updateActivity(with state: TimerActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }
        
        if #available(iOS 16.2, *) {
            // Update with long stale date - from research on performance
            await activity.update(ActivityContent(
                state: state,
                staleDate: Date().addingTimeInterval(28800), // 8 hours
                relevanceScore: state.isRunning ? 100.0 : 50.0
            ))
        } else {
            print("⚠️ Activity updates require iOS 16.2+")
        }
    }
    
    private func endCurrentActivity() async {
        guard let activity = currentActivity else {
            print("⚠️ No current activity to end")
            return
        }
        
        print("🛑 Ending Live Activity: \(activity.id)")
        
        if #available(iOS 16.2, *) {
            // Create final "completed" state using iOS 16.2+ content property
            let currentState = activity.content.state
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: currentState.startedAt,
                pausedAt: Date(), // Mark as stopped
                duration: currentState.duration,
                methodName: currentState.methodName,
                sessionType: .completed // Use completed session type
            )
            
            print("🛑 Ending activity with immediate dismissal policy")
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate // Use immediate dismissal
            )
            print("✅ Live Activity ended successfully")
        } else {
            // iOS 16.1 fallback - create basic completed state
            print("⚠️ Using iOS 16.1 fallback for activity ending")
            let finalState = TimerActivityAttributes.ContentState(
                startedAt: Date(), // Use current time as we can't access content.state
                pausedAt: Date(), // Mark as stopped
                duration: 0, // Default duration
                methodName: "Timer", // Default name
                sessionType: .completed // Use completed session type
            )
            
            // iOS 16.1 uses the basic end method without dismissalPolicy
            await activity.end(using: finalState)
        }
        
        await MainActor.run {
            self.currentActivity = nil
        }
        print("🛑 Live Activity reference cleared")
    }
    
    /// Clean up stale activities on app launch - from research recommendations
    func cleanupStaleActivities() {
        Task {
            await cleanupAllActivities()
        }
    }
    
    /// Clean up all activities immediately
    private func forceCleanupAllActivities() async {
        print("🧹 Force cleaning up all Live Activities...")
        
        // First end our current activity if it exists
        if let activity = currentActivity {
            print("🧹 Ending current tracked activity: \(activity.id)")
            if #available(iOS 16.2, *) {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                let completedState = TimerActivityAttributes.ContentState(
                    startedAt: Date(),
                    pausedAt: Date(),
                    duration: 0,
                    methodName: "Timer",
                    sessionType: .completed
                )
                await activity.end(using: completedState)
            }
            currentActivity = nil
        }
        
        // Then end all system-tracked activities
        let allActivities = Activity<TimerActivityAttributes>.activities
        print("🧹 Found \(allActivities.count) total activities to clean up")
        
        for (index, activity) in allActivities.enumerated() {
            print("🧹 Force ending activity \(index + 1)/\(allActivities.count): \(activity.id)")
            
            if #available(iOS 16.2, *) {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                let completedState = TimerActivityAttributes.ContentState(
                    startedAt: Date(),
                    pausedAt: Date(),
                    duration: 0,
                    methodName: "Timer",
                    sessionType: .completed
                )
                await activity.end(using: completedState)
            }
            print("✅ Successfully ended activity \(activity.id)")
        }
        
        // Clear our reference
        await MainActor.run {
            currentActivity = nil
        }
        
        print("🧹 Force cleanup completed")
    }
    
    private func cleanupAllActivities() async {
        let allActivities = Activity<TimerActivityAttributes>.activities
        print("🧹 Cleaning up all activities (found \(allActivities.count) activities)")
        
        for (index, activity) in allActivities.enumerated() {
            print("🧹 Ending activity \(index + 1)/\(allActivities.count): \(activity.id)")
            
            if #available(iOS 16.2, *) {
                let currentState = activity.content.state
                await activity.end(
                    ActivityContent(state: currentState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                // iOS 16.1 fallback - use basic end method without dismissalPolicy
                let completedState = TimerActivityAttributes.ContentState(
                    startedAt: Date(),
                    pausedAt: Date(),
                    duration: 0,
                    methodName: "Timer",
                    sessionType: .completed
                )
                await activity.end(using: completedState)
            }
        }
        print("🧹 Cleaned up \(allActivities.count) activities")
        
        await MainActor.run {
            currentActivity = nil
        }
    }
    
    // MARK: - Widget Interaction (Based on expo-live-activity-timer pattern)
    
    private func setupNotificationObservers() {
        // Based on expo-live-activity-timer pattern using NotificationCenter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWidgetAction),
            name: Notification.Name("timerControlFromWidget"),
            object: nil
        )
    }
    
    @objc private func handleWidgetAction(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? String else { return }
        
        switch action {
        case "pause":
            pauseTimer()
        case "resume":
            resumeTimer()
        case "stop":
            stopTimer()
        default:
            break
        }
    }
    
    // MARK: - State Properties
    
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
    
    var currentActivityId: String? {
        return currentActivity?.id
    }
    
    // MARK: - Compatibility Methods (for existing TimerService integration)
    
    /// Compatibility method for TimerService integration
    func startTimerActivity(
        methodId: String,
        methodName: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        sessionType: SessionType,
        timerType: String
    ) {
        print("🚀 LiveActivityManager.startTimerActivity called:")
        print("  - methodId: '\(methodId)'")
        print("  - methodName: '\(methodName)'")
        print("  - startTime: \(startTime)")
        print("  - endTime: \(endTime)")
        print("  - duration: \(duration)")
        print("  - sessionType: \(sessionType)")
        print("  - timerType: '\(timerType)'")
        print("  - Thread: \(Thread.current)")
        print("  - App State: \(UIApplication.shared.applicationState.rawValue)")
        
        // Check prerequisite conditions
        print("🔍 Pre-flight checks:")
        print("  - areActivitiesEnabled: \(areActivitiesEnabled)")
        print("  - Current activities count: \(Activity<TimerActivityAttributes>.activities.count)")
        
        // Use our simplified startActivity method based on research
        // Default to countup with 30-minute duration
        let timerSessionType: SessionType = sessionType == SessionType.countdown ? .countdown : .countup
        print("📱 Delegating to startActivity with sessionType: \(timerSessionType)")
        startActivity(methodId: methodId, methodName: methodName, duration: duration, sessionType: timerSessionType)
    }
    
    /// Compatibility method for TimerService integration
    func updateTimerActivity(elapsedTime: TimeInterval, isRunning: Bool, isPaused: Bool) {
        // Based on research - use our simplified pause/resume pattern
        if isPaused && hasActiveActivity {
            pauseTimer()
        } else if isRunning && hasActiveActivity {
            // Only resume if we were paused
            if #available(iOS 16.2, *) {
                if let activity = currentActivity, activity.content.state.pausedAt != nil {
                    resumeTimer()
                }
            } else {
                print("⚠️ Activity state checking requires iOS 16.2+")
            }
        }
    }
    
    /// Compatibility method for TimerService integration
    func endTimerActivity() {
        stopTimer()
    }
    
    // MARK: - Debug Methods
    
    /// Test method to verify Live Activity system works independently
    func testLiveActivitySystem() {
        print("🧪 Testing Live Activity System...")
        print("🧪 iOS Version: \(UIDevice.current.systemVersion)")
        print("🧪 areActivitiesEnabled: \(areActivitiesEnabled)")
        
        guard areActivitiesEnabled else {
            print("❌ Live Activities are not enabled. Cannot test.")
            print("❌ Go to Settings > Privacy & Security > Live Activities")
            return
        }
        
        // Test starting a simple Live Activity
        print("🧪 Attempting to start test Live Activity...")
        startActivity(
            methodId: "test-\(UUID().uuidString.prefix(8))",
            methodName: "Test Timer",
            duration: 300, // 5 minutes
            sessionType: .countdown
        )
    }
    
    /// Debug method to print current Live Activity state
    func debugPrintCurrentState() {
        print("🔍 LiveActivityManager Debug State:")
        print("  - areActivitiesEnabled: \(areActivitiesEnabled)")
        print("  - hasActiveActivity: \(hasActiveActivity)")
        print("  - currentActivityId: \(currentActivityId ?? "none")")
        
        if let activity = currentActivity {
            print("  - Activity State: \(activity.activityState)")
            if #available(iOS 16.2, *) {
                print("  - Content State: \(activity.content.state)")
            } else {
                print("  - Content State: [iOS 16.2+ required]")
            }
            print("  - Attributes: methodId=\(activity.attributes.methodId), timerType=\(activity.attributes.timerType)")
        } else {
            print("  - No active Live Activity")
        }
        
        if #available(iOS 16.2, *) {
            let allActivities = Activity<TimerActivityAttributes>.activities
            print("  - Total activities: \(allActivities.count)")
            for (index, activity) in allActivities.enumerated() {
                print("    Activity \(index): \(activity.id) - \(activity.activityState)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}