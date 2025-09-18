# Live Activity Race Condition Fix

## Issue
The Live Activity timer shows 1:00 and doesn't count down because of a race condition:
1. `LiveActivityPushService.startPushUpdates` stores timer state asynchronously
2. `triggerServerSidePushUpdates` is called immediately after
3. Firebase function tries to read timer state before it's written
4. Function returns "Timer state not found for user"

## Solution

Update `/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Timer/Services/LiveActivityPushService.swift`:

### Fix the race condition in `startPushUpdates`:

```swift
/// Start sending periodic push updates for a Live Activity
func startPushUpdates(for activity: Activity<TimerActivityAttributes>, interval: TimeInterval = 1.0) {
    print("🚀 LiveActivityPushService: startPushUpdates called for activity \(activity.id)")
    stopPushUpdates()
    
    currentActivityId = activity.id
    
    // Store initial timer state in Firestore for server-side management
    // IMPORTANT: This must complete before triggering server-side updates
    Task {
        print("🚀 LiveActivityPushService: Storing initial timer state with action .start")
        // Wait for the timer state to be stored before continuing
        // This ensures the Firebase function can find the timer state
        await storeTimerStateInFirestore(for: activity, action: .start)
        print("✅ LiveActivityPushService: Initial timer state stored")
        
        // NOW trigger server-side updates after the state is stored
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ LiveActivityPushService: No authenticated user")
            return
        }
        
        print("🚀 LiveActivityPushService: Triggering server-side push updates")
        await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
    }
    
    // The actual periodic updates will be handled by Firebase Functions
    // This local timer is just a backup to ensure Firestore stays updated
    updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
        Task {
            guard let activityId = self?.currentActivityId,
                  let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
                return
            }
            await self?.storeTimerStateInFirestore(for: activity, action: .update)
        }
    }
}
```

### Remove the duplicate trigger from `storeTimerStateInFirestore`:

```swift
func storeTimerStateInFirestore(for activity: Activity<TimerActivityAttributes>, action: TimerAction = .update) async {
    guard let userId = Auth.auth().currentUser?.uid else {
        print("❌ LiveActivityPushService: No authenticated user to store timer state")
        return
    }
    
    let state = activity.content.state
    
    // Match the structure that TimerStateSync uses
    let contentState: [String: Any] = [
        "startTime": Timestamp(date: state.startTime),
        "endTime": Timestamp(date: state.endTime),
        "methodName": state.methodName,
        "sessionType": state.sessionType.rawValue,
        "isPaused": state.isPaused
    ]
    
    let timerData: [String: Any] = [
        "activityId": activity.id,
        "userId": userId,
        "methodId": activity.attributes.methodId,
        "contentState": contentState,
        "action": action.rawValue,
        "platform": "ios",
        "updatedAt": FieldValue.serverTimestamp()
    ]
    
    do {
        print("📤 LiveActivityPushService: Storing timer state (\(action.rawValue)) in Firestore")
        try await db.collection("activeTimers").document(userId).setData(timerData)
        print("✅ LiveActivityPushService: Timer state stored successfully")
        
        // REMOVE THIS - The trigger should only happen once in startPushUpdates
        // if action == .start || action == .resume {
        //     print("🚀 LiveActivityPushService: Action is .\(action.rawValue), triggering server-side push updates")
        //     await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
        // }
    } catch {
        print("❌ LiveActivityPushService: Failed to store timer state - \(error)")
    }
}
```

## Testing
After applying this fix:
1. Build and run the app
2. Start a timer
3. Check the console logs for the correct sequence:
   - "Storing initial timer state with action .start"
   - "Timer state stored successfully"
   - "Triggering server-side push updates"
4. The Live Activity should now count down properly

## Root Cause
The issue was that `triggerServerSidePushUpdates` was being called in two places:
1. Immediately in `startPushUpdates` (before timer state was stored)
2. Again in `storeTimerStateInFirestore` after storing

This caused the Firebase function to run before the timer state was available in Firestore.