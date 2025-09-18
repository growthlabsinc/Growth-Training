# Live Activity Correct Architecture Fix

## Summary

Based on Apple's Live Activity architecture, the current implementation is fundamentally wrong. The app should NEVER update Live Activities directly - only push notifications should update them.

## The Correct Flow

1. **User presses pause in Live Activity**
2. **Widget sends request to server** (not to the app)
3. **Server updates state and sends push notification**
4. **Push notification updates the Live Activity**
5. **App observes the Live Activity state change**

## Implementation Changes

### 1. Fix TimerControlIntent.swift

The widget should only communicate with the server, not the app:

```swift
@available(iOS 16.0, *)
func performTimerAction(action: TimerAction, activityId: String, timerType: String) async throws -> some IntentResult & ProvidesDialog {
    print("🔵 TimerControlIntent: Performing action \(action.rawValue) for activity \(activityId)")
    
    // ONLY send to server - don't notify the app
    guard let userId = getCurrentUserId() else {
        throw IntentError.generic
    }
    
    let functions = Functions.functions()
    let data: [String: Any] = [
        "activityId": activityId,
        "userId": userId,
        "action": action.rawValue,
        "timerType": timerType
    ]
    
    do {
        // Call Firebase function to handle the action
        _ = try await functions.httpsCallable("handleLiveActivityAction").call(data)
        print("✅ Action sent to server")
    } catch {
        print("❌ Failed to send action to server: \(error)")
        throw IntentError.generic
    }
    
    // Return empty result - no UI feedback needed
    return .result(dialog: IntentDialog(""))
}
```

### 2. Create Server-Side Handler

Create a new Firebase function `handleLiveActivityAction.js`:

```javascript
exports.handleLiveActivityAction = onCall(
    { 
        region: 'us-central1',
        secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret]
    },
    async (request) => {
        const { activityId, userId, action, timerType } = request.data;
        
        if (!activityId || !userId || !action) {
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
        
        console.log(`📱 Handle Live Activity action: ${action} for ${activityId}`);
        
        try {
            // Get current timer state from Firestore
            const stateDoc = await admin.firestore()
                .collection('liveActivityTimerStates')
                .doc(activityId)
                .get();
                
            if (!stateDoc.exists) {
                throw new HttpsError('not-found', 'Timer state not found');
            }
            
            const currentState = stateDoc.data().contentState;
            let newState;
            
            // Calculate new state based on action
            switch (action) {
                case 'pause':
                    if (currentState.pausedAt) {
                        // Already paused
                        return { success: true, message: 'Already paused' };
                    }
                    
                    newState = {
                        ...currentState,
                        pausedAt: admin.firestore.Timestamp.now()
                    };
                    break;
                    
                case 'resume':
                    if (!currentState.pausedAt) {
                        // Not paused
                        return { success: true, message: 'Not paused' };
                    }
                    
                    // Calculate pause duration
                    const pauseDuration = Date.now() - currentState.pausedAt.toMillis();
                    const adjustedStartTime = new Date(currentState.startedAt.toMillis() + pauseDuration);
                    
                    newState = {
                        ...currentState,
                        startedAt: admin.firestore.Timestamp.fromDate(adjustedStartTime),
                        pausedAt: null
                    };
                    break;
                    
                case 'stop':
                    newState = {
                        ...currentState,
                        isCompleted: true,
                        completionMessage: 'Timer stopped'
                    };
                    break;
                    
                default:
                    throw new HttpsError('invalid-argument', 'Unknown action');
            }
            
            // Update state in Firestore
            await admin.firestore()
                .collection('liveActivityTimerStates')
                .doc(activityId)
                .update({
                    contentState: newState,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            
            // Send push notification to update Live Activity
            await sendLiveActivityUpdate(activityId, newState);
            
            // Also update the main timer state for app synchronization
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .collection('timerSessions')
                .doc('current')
                .update({
                    state: action === 'stop' ? 'stopped' : (newState.pausedAt ? 'paused' : 'running'),
                    isPaused: !!newState.pausedAt,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            
            return { success: true, message: `Action ${action} processed` };
            
        } catch (error) {
            console.error('❌ Error:', error);
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError('internal', error.message);
        }
    }
);
```

### 3. Fix LiveActivityManagerSimplified.swift

Remove ALL local updates and only handle push token registration:

```swift
@available(iOS 16.2, *)
class LiveActivityManagerSimplified: ObservableObject {
    static let shared = LiveActivityManagerSimplified()
    
    @Published private(set) var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    // MARK: - Start Timer Activity
    
    func startTimerActivity(
        methodId: String,
        methodName: String,
        duration: TimeInterval,
        sessionType: TimerActivityAttributes.ContentState.SessionType,
        timerType: String = "main"
    ) async {
        print("🚀 Starting timer activity")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            return
        }
        
        // End any existing activity
        await endCurrentActivity()
        
        // Create attributes
        let attributes = TimerActivityAttributes(
            methodId: methodId,
            totalDuration: duration,
            timerType: timerType
        )
        
        // Create initial state
        let contentState = TimerActivityAttributes.ContentState(
            startedAt: Date(),
            pausedAt: nil,
            duration: duration,
            methodName: methodName,
            sessionType: sessionType,
            isCompleted: false,
            completionMessage: nil
        )
        
        do {
            // Request Live Activity with push support
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: .token
            )
            
            self.currentActivity = activity
            print("✅ Started Live Activity: \(activity.id)")
            
            // Register for push token
            Task {
                await registerForPushToken(activity: activity)
            }
            
            // Store initial state in server
            await storeInitialStateInServer(
                activityId: activity.id,
                contentState: contentState,
                methodId: methodId
            )
            
            // Observe state changes
            Task {
                await observeActivityState(activity: activity)
            }
            
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }
    
    // MARK: - NO MORE LOCAL UPDATES
    // Remove pauseTimer(), resumeTimer(), etc.
    // The server handles all state changes via push
    
    // MARK: - End Activity
    
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        // Just end it - no state updates
        await activity.end(
            ActivityContent(state: activity.content.state, staleDate: nil),
            dismissalPolicy: .immediate
        )
        
        self.currentActivity = nil
    }
    
    // MARK: - Observe State
    
    private func observeActivityState(activity: Activity<TimerActivityAttributes>) async {
        for await state in activity.activityStateUpdates {
            print("📱 Live Activity state changed: \(state)")
            
            switch state {
            case .active:
                // Activity is active
                break
            case .ended:
                // Activity ended
                await MainActor.run {
                    self.currentActivity = nil
                }
            case .dismissed:
                // Activity was dismissed
                await MainActor.run {
                    self.currentActivity = nil
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Push Token Registration
    
    private func registerForPushToken(activity: Activity<TimerActivityAttributes>) async {
        for await pushToken in activity.pushTokenUpdates {
            let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
            print("📱 Received push token: \(tokenString)")
            
            // Store in Firestore
            await storePushToken(
                activityId: activity.id,
                pushToken: tokenString,
                methodId: activity.attributes.methodId
            )
        }
    }
    
    private func storePushToken(activityId: String, pushToken: String, methodId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "activityId": activityId,
            "pushToken": pushToken,
            "methodId": methodId,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "platform": "ios"
        ]
        
        do {
            try await Firestore.firestore()
                .collection("liveActivityTokens")
                .document(activityId)
                .setData(data)
            print("✅ Stored push token")
        } catch {
            print("❌ Failed to store push token: \(error)")
        }
    }
    
    private func storeInitialStateInServer(
        activityId: String,
        contentState: TimerActivityAttributes.ContentState,
        methodId: String
    ) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let stateData: [String: Any] = [
            "startedAt": Timestamp(date: contentState.startedAt),
            "pausedAt": NSNull(),
            "duration": contentState.duration,
            "methodName": contentState.methodName,
            "sessionType": contentState.sessionType.rawValue,
            "isCompleted": false
        ]
        
        let data: [String: Any] = [
            "activityId": activityId,
            "userId": userId,
            "methodId": methodId,
            "contentState": stateData,
            "action": "start",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await Firestore.firestore()
                .collection("liveActivityTimerStates")
                .document(activityId)
                .setData(data)
        } catch {
            print("❌ Failed to store initial state: \(error)")
        }
    }
}
```

### 4. Fix TimerService.swift

The timer service should observe Live Activity state, not drive it:

```swift
public func pause() {
    guard timerState == .running else { return }
    
    timerState = .paused
    timer?.invalidate()
    timer = nil
    
    saveStateOnPauseOrBackground()
    
    // DO NOT update Live Activity
    // The server will handle it via push notification
}

// Add observer for Live Activity state changes
private func observeLiveActivityState() {
    if #available(iOS 16.2, *) {
        Task {
            guard let activity = LiveActivityManagerSimplified.shared.currentActivity else { return }
            
            for await content in activity.contentUpdates {
                await MainActor.run {
                    // Sync timer state with Live Activity state
                    if content.state.isPaused && timerState == .running {
                        // Live Activity was paused, pause the timer
                        pause()
                    } else if !content.state.isPaused && timerState == .paused {
                        // Live Activity was resumed, resume the timer
                        resume()
                    }
                }
            }
        }
    }
}
```

### 5. Remove Darwin Notifications

Since the server handles all state changes, we don't need Darwin notifications:

1. Remove `registerForDarwinNotifications()` from TimerService
2. Remove `CFNotificationCenterPostNotification` from TimerControlIntent
3. Remove all Darwin notification handling code

## Benefits

1. **No Race Conditions**: Single source of truth (server) for all state
2. **Follows Apple Architecture**: Push notifications drive Live Activity updates
3. **Simplified Code**: Remove complex synchronization logic
4. **Better Reliability**: Server manages all state transitions
5. **Cross-Device Sync**: All devices see the same state immediately

## Migration Steps

1. Deploy new Firebase functions first
2. Update iOS app to remove local updates
3. Test thoroughly on physical devices
4. Monitor for any issues
5. Remove old synchronization code once stable