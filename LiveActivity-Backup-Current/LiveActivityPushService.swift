//
//  LiveActivityPushService.swift
//  Growth
//
//  Simplified version that works with new TimerActivityAttributes structure
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import ActivityKit

/// Service that handles sending push updates to Live Activities via Firebase Functions
@available(iOS 16.1, *)
class LiveActivityPushService {
    static let shared = LiveActivityPushService()
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private var updateTimer: Timer?
    private var currentActivityId: String?
    
    // Push updates are now enabled with APNs configured
    // APNs Team ID: 62T6J77P6R
    // APNs Key ID: FM3P8KLCJQ (Production key)
    private let pushUpdatesEnabled = true
    
    // Retry configuration
    private let maxRetryAttempts = 1 // Reduce retries to prevent duplicate calls
    private let retryDelayBase: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    
    private init() {}
    
    // MARK: - Retry Logic
    
    /// Generic retry function for Firebase Function calls
    private func callFunctionWithRetry(_ functionName: String, data: [String: Any]) async throws -> HTTPSCallableResult {
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                print("📤 LiveActivityPushService: Attempting \(functionName) call (attempt \(attempt)/\(maxRetryAttempts))")
                let result = try await functions.httpsCallable(functionName).call(data)
                return result
            } catch {
                lastError = error
                print("⚠️ LiveActivityPushService: \(functionName) failed on attempt \(attempt): \(error)")
                
                // Don't retry if it's an authentication error
                if let nsError = error as NSError?, 
                   nsError.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: nsError.code) ?? .internal
                    switch code {
                    case .unauthenticated, .permissionDenied:
                        print("❌ LiveActivityPushService: Authentication error, not retrying")
                        throw error
                    default:
                        break
                    }
                }
                
                // If not the last attempt, wait before retrying
                if attempt < maxRetryAttempts {
                    let delay = retryDelayBase * UInt64(attempt) // Exponential backoff
                    print("⏳ LiveActivityPushService: Waiting \(Double(delay) / 1_000_000_000) seconds before retry...")
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        print("❌ LiveActivityPushService: All retry attempts failed for \(functionName)")
        throw lastError ?? NSError(domain: FunctionsErrorDomain, 
                                  code: FunctionsErrorCode.internal.rawValue,
                                  userInfo: ["NSLocalizedDescriptionKey": "Unknown error"])
    }
    
    /// Start sending periodic push updates for a Live Activity
    func startPushUpdates(for activity: Activity<TimerActivityAttributes>, interval: TimeInterval = 1.0) {
        print("🚀 LiveActivityPushService: startPushUpdates called for activity \(activity.id)")
        stopPushUpdates()
        
        currentActivityId = activity.id
        
        // Store initial timer state in Firestore for server-side management
        Task {
            print("🚀 LiveActivityPushService: Storing initial timer state with action .start")
            await storeTimerStateInFirestore(for: activity, action: .start)
            print("✅ LiveActivityPushService: Initial timer state stored")
            
            // Wait for Firestore propagation
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            print("⏱️ LiveActivityPushService: Waited for Firestore propagation")
            
            // Trigger server-side updates
            if let userId = Auth.auth().currentUser?.uid {
                await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
            }
        }
    }
    
    /// Stop push updates
    func stopPushUpdates() {
        print("🛑 LiveActivityPushService: Stopping push updates")
        updateTimer?.invalidate()
        updateTimer = nil
        currentActivityId = nil
    }
    
    /// Send a state change update (pause/resume/stop)
    func sendStateChangeUpdate(
        for activity: Activity<TimerActivityAttributes>,
        isPaused: Bool,
        updatedState: TimerActivityAttributes.ContentState? = nil
    ) async {
        print("📤 LiveActivityPushService: sendStateChangeUpdate called - isPaused: \(isPaused)")
        
        // Use the updated state if provided, otherwise use the activity's current state
        let state: TimerActivityAttributes.ContentState
        if #available(iOS 16.2, *) {
            state = updatedState ?? activity.content.state
        } else {
            // For iOS 16.1, we need to handle this differently
            guard let updatedState = updatedState else {
                print("❌ LiveActivityPushService: Cannot access activity content on iOS < 16.2")
                return
            }
            state = updatedState
        }
        
        // Debug log all state values
        print("🔍 LiveActivityPushService: State values to send:")
        print("  - startedAt: \(state.startedAt) (\(state.startedAt.timeIntervalSince1970))")
        print("  - pausedAt: \(String(describing: state.pausedAt))")
        print("  - duration: \(state.duration)s")
        print("  - isPaused: \(state.isPaused)")
        print("  - sessionType: \(state.sessionType.rawValue)")
        print("  - currentElapsedTime: \(state.currentElapsedTime)s")
        print("  - currentRemainingTime: \(state.currentRemainingTime)s")
        
        // Store the current timer state for server-side management
        let action: TimerAction = isPaused ? .pause : .resume
        await storeTimerStateInFirestore(for: activity, action: action)
        
        // If resuming, ensure server-side push updates are started
        if action == .resume {
            print("🚀 LiveActivityPushService: Resuming timer - triggering server-side push updates")
            if let userId = Auth.auth().currentUser?.uid {
                await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
            }
        }
        
        // Send push update with the correct state
        await callPushUpdateFunction(
            activityId: activity.id,
            contentState: state,
            pushToken: nil
        )
    }
    
    /// Call the Firebase Function to send push update
    private func callPushUpdateFunction(
        activityId: String,
        contentState: TimerActivityAttributes.ContentState,
        pushToken: String?
    ) async {
        // Skip push updates if disabled
        guard pushUpdatesEnabled else {
            print("⏸️ LiveActivityPushService: Push updates temporarily disabled. Using local updates only.")
            return
        }
        
        // Wait for push token to be available
        if pushToken == nil {
            print("⏳ LiveActivityPushService: Waiting for push token to be stored in Firestore...")
            var tokenFound = false
            for attempt in 1...3 {
                do {
                    let tokenDoc = try await db.collection("liveActivityTokens").document(activityId).getDocument()
                    if tokenDoc.exists {
                        print("✅ LiveActivityPushService: Push token found in Firestore on attempt \(attempt)")
                        tokenFound = true
                        break
                    } else {
                        print("⏳ LiveActivityPushService: Push token not found on attempt \(attempt), waiting...")
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds before retry
                    }
                } catch {
                    print("❌ LiveActivityPushService: Error checking for push token: \(error)")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retry
                }
            }
            
            if !tokenFound {
                print("❌ LiveActivityPushService: Push token not found after 3 attempts, skipping update")
                return
            }
        }
        
        // Debug log what we're about to send (simplified format)
        print("🔍 LiveActivityPushService: Preparing to send contentState:")
        print("  - startedAt: \(contentState.startedAt) -> \(ISO8601DateFormatter().string(from: contentState.startedAt))")
        print("  - pausedAt: \(String(describing: contentState.pausedAt))")
        print("  - duration: \(contentState.duration)s")
        print("  - isPaused: \(contentState.isPaused)")
        
        // Prepare data for Firebase function with new simplified format
        var contentStateData: [String: Any] = [
            // New simplified format
            "startedAt": ISO8601DateFormatter().string(from: contentState.startedAt),
            "duration": contentState.duration,
            "methodName": contentState.methodName,
            "sessionType": contentState.sessionType.rawValue,
            "isCompleted": contentState.isCompleted,
            
            // Legacy format for backward compatibility
            "startTime": ISO8601DateFormatter().string(from: contentState.startTime),
            "endTime": ISO8601DateFormatter().string(from: contentState.endTime),
            "isPaused": contentState.isPaused
        ]
        
        if let pausedAt = contentState.pausedAt {
            contentStateData["pausedAt"] = ISO8601DateFormatter().string(from: pausedAt)
        }
        
        if let completionMessage = contentState.completionMessage {
            contentStateData["completionMessage"] = completionMessage
        }
        
        let data: [String: Any] = [
            "activityId": activityId,
            "contentState": contentStateData,
            "pushToken": pushToken as Any
        ]
        
        do {
            print("📤 LiveActivityPushService: Calling updateLiveActivity function")
            let result = try await callFunctionWithRetry("updateLiveActivity", data: data)
            
            if let resultData = result.data as? [String: Any],
               let success = resultData["success"] as? Bool,
               success {
                print("✅ LiveActivityPushService: Push update sent successfully")
            } else {
                print("❌ LiveActivityPushService: Push update failed")
            }
        } catch {
            print("❌ LiveActivityPushService: Error calling function - \(error)")
            // Log specific error details for debugging
            if let nsError = error as NSError?,
               nsError.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: nsError.code) ?? .internal
                print("  - Error code: \(code)")
                print("  - Error details: \(nsError.userInfo)")
                
                // If it's an INTERNAL error, it's likely due to missing APNs configuration
                if code == .internal {
                    print("⚠️ LiveActivityPushService: APNs configuration may be missing. Continuing with local updates only.")
                }
            }
            
            // Don't throw the error - allow the app to continue with local updates
            print("ℹ️ LiveActivityPushService: Continuing without push updates. Live Activity will still update locally.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Trigger server-side push updates via Firebase Function
    private func triggerServerSidePushUpdates(activityId: String, userId: String) async {
        let data: [String: Any] = [
            "activityId": activityId,
            "userId": userId,
            "action": "startPushUpdates"
        ]
        
        do {
            print("📤 LiveActivityPushService: Calling manageLiveActivityUpdates to start server-side updates")
            let result = try await callFunctionWithRetry("manageLiveActivityUpdates", data: data)
            
            if let resultData = result.data as? [String: Any],
               let success = resultData["success"] as? Bool,
               success {
                print("✅ LiveActivityPushService: Server-side push updates started successfully")
            } else {
                print("❌ LiveActivityPushService: Failed to start server-side push updates")
            }
        } catch {
            print("❌ LiveActivityPushService: Error starting server-side updates - \(error)")
        }
    }
    
    // MARK: - Types
    
    /// Action type for timer state updates
    enum TimerAction: String {
        case start = "start"
        case pause = "pause"
        case resume = "resume"
        case stop = "stop"
        case update = "update"
    }
    
    /// Store timer state in Firestore for server-side management
    func storeTimerStateInFirestore(for activity: Activity<TimerActivityAttributes>, action: TimerAction = .update) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ LiveActivityPushService: No authenticated user to store timer state")
            return
        }
        
        guard #available(iOS 16.2, *) else {
            print("⚠️ LiveActivityPushService: Timer state storage requires iOS 16.2+")
            return
        }
        
        let state = activity.content.state
        
        // Prepare content state data using the new simplified format
        var contentState: [String: Any] = [
            // New simplified format
            "startedAt": Timestamp(date: state.startedAt),
            "duration": state.duration,
            "methodName": state.methodName,
            "sessionType": state.sessionType.rawValue,
            "isCompleted": state.isCompleted,
            
            // Legacy format for backward compatibility
            "startTime": Timestamp(date: state.startTime),
            "endTime": Timestamp(date: state.endTime),
            "isPaused": state.isPaused
        ]
        
        if let pausedAt = state.pausedAt {
            contentState["pausedAt"] = Timestamp(date: pausedAt)
        }
        
        if let completionMessage = state.completionMessage {
            contentState["completionMessage"] = completionMessage
        }
        
        let timerData: [String: Any] = [
            "activityId": activity.id,
            "userId": userId,
            "methodId": activity.attributes.methodId,
            "totalDuration": activity.attributes.totalDuration,
            "timerType": activity.attributes.timerType,
            "contentState": contentState,
            "action": action.rawValue,
            "updatedAt": FieldValue.serverTimestamp(),
            "isActive": action != .stop
        ]
        
        do {
            print("📤 LiveActivityPushService: Storing timer state to Firestore with action: \(action.rawValue)")
            try await db.collection("liveActivityTimerStates").document(activity.id).setData(timerData)
            print("✅ LiveActivityPushService: Timer state stored successfully")
        } catch {
            print("❌ LiveActivityPushService: Failed to store timer state - \(error)")
        }
    }
}