# Live Activity Button Implementation - Apple Best Practices Fix

## Date: 2025-09-10

### Problem Analysis

1. **Firebase Function Error**: "INTERNAL" error prevents push notifications
2. **Permission Dialog Freeze**: iOS 17+ LiveActivityIntent permission causes freeze
3. **Multiple Update Paths**: Conflicting local and push updates

### Apple's Official Best Practices

According to Apple's documentation and WWDC 2023:

## Solution 1: Push-Only Updates (Recommended by Apple)

Apple recommends using **push notifications exclusively** for Live Activity updates when buttons are involved. Here's why:

1. **No permission dialog** - Push updates don't trigger permission requests
2. **Better performance** - Avoids local/remote conflicts
3. **Cross-device sync** - Works with paired Apple Watch

### Implementation Changes Required

#### 1. Remove Local Updates from TimerControlIntent

```swift
// TimerControlIntent.swift
@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Control Timer"
    static var openAppWhenRun: Bool = false
    
    // IMPORTANT: Remove isDiscoverable to allow system handling
    // static var isDiscoverable: Bool = false // REMOVE THIS
    
    func perform() async throws -> some IntentResult {
        // Only update shared state and notify main app
        // DO NOT update Live Activity locally
        updateSharedState()
        notifyMainApp()
        
        // Return immediately - no local updates
        return .result()
    }
    
    private func updateSharedState() {
        // Keep existing shared state update logic
        // This ensures app state is synchronized
    }
    
    private func notifyMainApp() {
        // Send Darwin notification to trigger push update
        // The main app will handle the push notification
    }
}
```

#### 2. Fix Firebase Function Error

The "INTERNAL" error in Firebase Functions often indicates:
- **Timeout issues** - Live Activity updates timing out
- **Payload size** - Content exceeding 4KB limit
- **Authentication** - APNS key issues

Add better error handling in `liveActivityUpdates.js`:

```javascript
// Add timeout and retry logic
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

async function sendWithRetry(payload, options, retries = 0) {
    try {
        return await apn.send(payload, options);
    } catch (error) {
        if (retries < MAX_RETRIES) {
            await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
            return sendWithRetry(payload, options, retries + 1);
        }
        throw error;
    }
}
```

#### 3. Implement Proper Push Token Handling

```swift
// LiveActivityManager.swift
func sendPushUpdateForCurrentActivity(action: String) async {
    guard let activity = currentActivity else { return }
    
    // Ensure we have a valid push token
    guard let pushToken = currentPushToken else {
        Logger.warning("No push token available, requesting update without token")
        // Fallback: Try to get token from activity
        for await token in activity.pushTokenUpdates {
            currentPushToken = token
            break
        }
        return
    }
    
    // Send push update via Firebase
    let data: [String: Any] = [
        "activityId": activity.id,
        "action": action,
        "pushToken": pushToken,
        // Don't include contentState here - let server build it
    ]
    
    do {
        _ = try await functions.httpsCallable("updateLiveActivity").call(data)
    } catch {
        Logger.error("Failed to send push update: \(error)")
    }
}
```

## Solution 2: Alternative - Deep Link Approach (No Permissions)

If push notifications continue to fail, use deep links instead:

```swift
// In Live Activity View
Link(destination: URL(string: "growth://timer/pause/\(activityId)")!) {
    HStack {
        Image(systemName: "pause.fill")
        Text("Pause")
    }
    .buttonStyle(.plain)
}

// In main app
.onOpenURL { url in
    handleTimerAction(from: url)
}
```

## Solution 3: Fix Permission Dialog Handling

For the current implementation, handle the permission properly:

```swift
@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    // Add these properties for better permission handling
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var isEligibleForPrediction = false
    static var isEligibleForWidgets = false
    
    func perform() async throws -> some IntentResult {
        // Check if we're in a valid state
        guard Activity<TimerActivityAttributes>.activities.count > 0 else {
            throw IntentError.activityNotFound
        }
        
        // Perform action
        updateSharedState()
        
        // Use main actor for UI updates
        await MainActor.run {
            notifyMainApp()
        }
        
        return .result()
    }
}

enum IntentError: Error {
    case activityNotFound
    case updateFailed
}
```

## Testing Checklist

### Permission Dialog Testing
1. **First install**: Delete app, reinstall, start timer
2. **Permission prompt**: Tap pause button on Lock Screen
3. **Select "Always Allow"**: Should not freeze
4. **Verify functionality**: Pause/resume should work

### Push Notification Testing
1. **Check Firebase logs**: Verify no "INTERNAL" errors
2. **Monitor push delivery**: Use Console.app
3. **Verify token sync**: Check Firestore for push tokens
4. **Test on physical device**: Live Activities require real hardware

## Deployment Steps

1. **Update Firebase Functions**:
```bash
cd functions
npm run deploy
firebase functions:log --only updateLiveActivity
```

2. **Update iOS Code**:
- Remove local updates from TimerControlIntent
- Implement push-only updates
- Test on physical device

3. **Monitor Production**:
- Check Firebase Function logs
- Monitor crash reports
- Track Live Activity success rate

## Key Takeaways

1. **Apple recommends push-only updates** for Live Activity buttons
2. **Permission dialogs are system-level** - we can't bypass them
3. **Local updates conflict with push updates** - use one or the other
4. **Firebase Functions need proper error handling** for APNS
5. **Always test on physical devices** - simulator doesn't support Live Activities

## References

- [Apple: Update Live Activities with push notifications (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10185/)
- [Apple: ActivityKit Push Notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications)
- [Firebase: Live Activity Support](https://firebase.google.com/docs/cloud-messaging/ios/live-activity)