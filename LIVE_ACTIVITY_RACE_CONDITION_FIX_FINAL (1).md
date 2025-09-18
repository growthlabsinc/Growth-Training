# Live Activity Race Condition Fix - January 2025

## Problem Summary
A race condition was occurring where the `updateLiveActivity` Firebase function was being called before the push token was stored in Firestore, resulting in "Live Activity token not found" errors.

## Root Cause
The sequence of events causing the race condition:
1. iOS app starts a Live Activity and receives push token from Apple
2. `LiveActivityManager` begins writing the token to Firestore (async operation)
3. **Simultaneously**, `LiveActivityPushService` calls the `updateLiveActivity` function
4. The function tries to read the token from Firestore but finds nothing
5. Result: "Live Activity token not found for activity: [ID]" error

## Solution Implemented

### 1. Token Availability Check in LiveActivityPushService
Added explicit checks to ensure push token exists in Firestore before calling `updateLiveActivity`:

```swift
// LiveActivityPushService.swift - lines 281-306
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
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
            }
        } catch {
            print("❌ LiveActivityPushService: Error checking for push token: \(error)")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
        }
    }
    
    if !tokenFound {
        print("❌ LiveActivityPushService: Push token not found after 3 attempts, skipping update")
        return
    }
}
```

### 2. Push Token Ready Notification
Added notification when token is successfully stored in `LiveActivityManager`:

```swift
// LiveActivityManager.swift - lines 510-515
NotificationCenter.default.post(
    name: Notification.Name("LiveActivityPushTokenReady"),
    object: nil,
    userInfo: ["activityId": activityId, "userId": userId]
)
```

### 3. Delayed Server-Side Updates
Enhanced `startPushUpdates` to wait for push token availability:

```swift
// LiveActivityPushService.swift - lines 112-134
print("⏳ LiveActivityPushService: Waiting for push token to be stored...")
var tokenAvailable = false
for attempt in 1...5 {
    let tokenDoc = try await db.collection("liveActivityTokens").document(activity.id).getDocument()
    if tokenDoc.exists {
        print("✅ LiveActivityPushService: Push token available on attempt \(attempt)")
        tokenAvailable = true
        break
    } else {
        print("⏳ LiveActivityPushService: Push token not yet available (attempt \(attempt)/5)")
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
    }
}
```

### 4. SSL Error Handling
Added better error handling for SSL errors during auth token refresh:

```swift
// GrowthAppApp.swift - lines 129-135
if let nsError = error as NSError?,
   nsError.domain == NSURLErrorDomain,
   nsError.code == NSURLErrorSecureConnectionFailed {
    print("⚠️ SSL connection error - this may be a temporary network issue")
    print("⚠️ Try: 1) Check network connection, 2) Restart simulator, 3) Test on real device")
}
```

## Key Changes Made

1. **LiveActivityPushService.swift**:
   - Added token availability check in `callPushUpdateFunction` (3 retry attempts)
   - Enhanced `startPushUpdates` to wait for token storage (5 retry attempts)
   - Increased Firestore propagation delay to 2 seconds
   - Added verification that timer state exists before triggering updates

2. **LiveActivityManager.swift**:
   - Added notification post when push token is successfully stored
   - Enhanced error logging for Firestore write operations

3. **GrowthAppApp.swift**:
   - Added SSL error detection and helpful debugging messages
   - Non-critical error handling for auth token refresh

## Testing Notes

1. **Physical Device Required**: Live Activity push tokens are not available on simulator
2. **Notification Permissions**: Ensure app has notification permissions enabled
3. **iOS Version**: Requires iOS 16.2+ for push token support
4. **Firestore Delays**: Allow 2-3 seconds for Firestore writes to propagate

## Verification Steps

1. Start a Live Activity and monitor logs for:
   - "✅ Live Activity push token received"
   - "✅ LiveActivityManager: Successfully stored Live Activity push token"
   - "✅ LiveActivityPushService: Push token found in Firestore"

2. Check Firebase logs for successful function calls without "token not found" errors

3. Verify Live Activity updates are received on the device

## Production Configuration

- **APNs Team ID**: 62T6J77P6R
- **APNs Key ID**: FM3P8KLCJQ (Production key)
- **Bundle ID**: com.growthlabs.growthmethod
- **APNs Topic**: com.growthlabs.growthmethod.push-type.liveactivity

## Future Improvements

1. Consider using Cloud Firestore listeners instead of polling
2. Implement exponential backoff for retries
3. Add metrics to track token storage latency
4. Consider using Firestore transactions for atomic operations