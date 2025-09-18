//
//  LiveActivityBackgroundTaskManager.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation
import BackgroundTasks
import ActivityKit
import FirebaseAuth

/// Manages background tasks for Live Activity updates
@available(iOS 16.1, *)
class LiveActivityBackgroundTaskManager {
    static let shared = LiveActivityBackgroundTaskManager()
    
    // Background task identifiers
    static let refreshTaskIdentifier = "com.growthlabs.growthmethod.timer.refresh"
    static let processingTaskIdentifier = "com.growthlabs.growthmethod.timer.processing"
    
    private init() {}
    
    /// Register background tasks with the system
    func registerBackgroundTasks() {
        // Register app refresh task for periodic updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register processing task for long-running timers
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { task in
            self.handleProcessing(task: task as! BGProcessingTask)
        }
    }
    
    /// Schedule an app refresh task
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ LiveActivityBackgroundTaskManager: App refresh scheduled")
        } catch {
            print("❌ LiveActivityBackgroundTaskManager: Failed to schedule app refresh - \(error)")
        }
    }
    
    /// Schedule a processing task for long-running timers
    func scheduleProcessingTask(duration: TimeInterval) {
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: min(duration / 2, 30 * 60)) // Half duration or 30 min max
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ LiveActivityBackgroundTaskManager: Processing task scheduled")
        } catch {
            print("❌ LiveActivityBackgroundTaskManager: Failed to schedule processing task - \(error)")
        }
    }
    
    /// Handle app refresh task
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()
        
        // Create a task to update Live Activities
        let updateTask = Task {
            // Update all active Live Activities
            for activity in Activity<TimerActivityAttributes>.activities where activity.activityState == .active {
                // With the new simplified approach, updates happen automatically via ProgressView(timerInterval:)
                // We only need to send state changes, not periodic updates
                print("📱 Active Live Activity found: \(activity.id)")
            }
            
            task.setTaskCompleted(success: true)
        }
        
        // Set expiration handler
        task.expirationHandler = {
            updateTask.cancel()
        }
    }
    
    /// Handle processing task for long-running timers
    private func handleProcessing(task: BGProcessingTask) {
        // Create a task to handle long-running timer updates
        let processingTask = Task {
            // Check if user is authenticated
            guard Auth.auth().currentUser != nil else {
                task.setTaskCompleted(success: false)
                return
            }
            
            // Get all active Live Activities
            let activities = Activity<TimerActivityAttributes>.activities.filter { $0.activityState == .active }
            
            // With the new simplified approach, updates happen automatically
            // We don't need to send periodic updates
            print("📱 Found \(activities.count) active Live Activities")
            
            // Just verify they're still active
            for activity in activities {
                print("  - Activity \(activity.id) is active")
                
                // Check if task is about to expire
                if task.expirationHandler != nil {
                    break
                }
            }
            
            // Schedule next processing task if activities still exist
            if !activities.isEmpty {
                scheduleProcessingTask(duration: 3600) // 1 hour
            }
            
            task.setTaskCompleted(success: true)
        }
        
        // Set expiration handler
        task.expirationHandler = {
            processingTask.cancel()
            
            // Try to schedule another task before expiring
            self.scheduleProcessingTask(duration: 3600)
        }
    }
    
    /// Cancel all scheduled background tasks
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
    }
    
    /// Debug: Force launch background tasks (development only)
    func debugLaunchBackgroundTasks() {
        #if DEBUG
        // Use this in simulator with debugger command:
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.growthlabs.growthmethod.timer.refresh"]
        print("🔍 LiveActivityBackgroundTaskManager: To test background tasks in simulator, use:")
        print("e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@\"\(Self.refreshTaskIdentifier)\"]")
        #endif
    }
}