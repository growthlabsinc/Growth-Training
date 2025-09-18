# Live Activity Token Persistence Fix

## Date: 2025-09-10

### Problem Identified
The Live Activity pause/resume functionality stops working after 2-3 cycles. The issue was that the push token required for sending updates to the Live Activity was being lost from memory.

### Root Cause
1. **Token stored only in memory**: The `currentPushToken` was only kept in a class property
2. **Token observation task cancelled**: When starting new activities or during certain operations, the push token observation task was being cancelled
3. **No token persistence**: After 2-3 pause/resume cycles, the token was no longer available when needed for push updates

### Symptoms
- First 2-3 pause/resume cycles work correctly
- After that, push updates fail silently (no token available)
- Live Activity stops responding to pause/resume buttons
- Firebase logs show push updates being sent but without valid tokens

## Fixes Applied

### 1. Token Persistence in UserDefaults
Store push tokens in App Group UserDefaults for persistence across app sessions and memory pressure:

```swift
// Store token in UserDefaults as backup
let appGroupIdentifier = "group.com.growthlabs.growthmethod"
if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
    sharedDefaults.set(tokenString, forKey: "liveActivityPushToken_\(activity.id)")
    sharedDefaults.synchronize()
}
```

### 2. Multi-Source Token Retrieval
Implement fallback mechanism to retrieve tokens from multiple sources:

```swift
// Priority order:
// 1. Memory (currentPushToken)
// 2. UserDefaults (fast local storage)
// 3. Firebase (network fallback)

var tokenToUse = currentPushToken
if tokenToUse == nil {
    // Check UserDefaults
    if let storedToken = sharedDefaults.string(forKey: "liveActivityPushToken_\(activity.id)") {
        tokenToUse = storedToken
    } else {
        // Fallback to Firebase
        tokenToUse = await fetchPushTokenFromFirebase(activityId: activity.id)
    }
}
```

### 3. Improved Token Observation
Only cancel token observation when switching to a different activity:

```swift
// Only cancel if we have a different activity
if let existingTask = pushTokenObservationTask,
   currentActivity?.id != activity.id {
    existingTask.cancel()
}
```

### 4. Firebase Token Fetch Function
Added function to retrieve token from Firebase when local sources fail:

```swift
private func fetchPushTokenFromFirebase(activityId: String) async -> String? {
    let result = try await functions.httpsCallable("getLiveActivityPushToken").call(data)
    // Extract and cache token
    return token
}
```

## Why This Fixes the Issue

1. **Token Always Available**: Even if the app is backgrounded or memory is cleared, the token can be retrieved from UserDefaults or Firebase

2. **No More Lost Tokens**: The token observation task is not unnecessarily cancelled, maintaining the token stream

3. **Redundant Storage**: Three layers of token storage ensure reliability:
   - Memory (fastest)
   - UserDefaults (persistent, fast)
   - Firebase (network backup)

4. **Activity-Specific Tokens**: Each Live Activity's token is stored with its unique ID, preventing token mixups

## Testing Verification

After applying these fixes:
1. Start a timer and begin Live Activity
2. Pause and resume 5+ times (beyond the previous 2-3 cycle limit)
3. Each pause/resume should work consistently
4. Check logs for:
   - "✅ Retrieved push token from UserDefaults" (when memory fails)
   - "📱 New Live Activity push token received" (token updates)
   - No "Push token not available" errors

## Firebase Function Requirement

The fix assumes a Firebase function `getLiveActivityPushToken` exists or will be created:

```javascript
exports.getLiveActivityPushToken = functions.https.onCall(async (data, context) => {
    const { activityId } = data;
    
    // Fetch token from Firestore
    const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();
    
    if (tokenDoc.exists) {
        return { token: tokenDoc.data().token };
    }
    
    throw new functions.https.HttpsError('not-found', 'Token not found');
});
```

## Additional Improvements

1. **Token Expiry Handling**: Consider adding timestamp to stored tokens and refreshing if older than 24 hours
2. **Token Validation**: Validate token format before using
3. **Analytics**: Track token retrieval source for debugging
4. **Cleanup**: Remove old tokens from UserDefaults when activities end

## Related Files
- `LiveActivityManager.swift` - Main Live Activity management
- `TimerControlIntent.swift` - Widget button actions
- `liveActivityUpdates.js` - Firebase push notification handler
- `AppGroupConstants.swift` - Shared data keys