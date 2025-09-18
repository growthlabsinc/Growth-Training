# Race Condition Fix for Live Activity Push Updates

## Problem Identified
The Firebase function `manageLiveActivityUpdates` was failing with "Timer state not found" errors because it was trying to read the timer state from Firestore before the iOS client had finished writing it. This was causing hundreds of INTERNAL errors.

## Root Causes
1. **Race Condition**: The iOS client was triggering server-side updates immediately after initiating the Firestore write, without waiting for propagation
2. **Aggressive Retries**: Multiple retry attempts were creating duplicate function calls
3. **No Debouncing**: The Firebase function wasn't filtering out duplicate requests

## Fixes Implemented

### 1. iOS Client (LiveActivityPushService.swift)
- **Increased propagation delay** from 0.5s to 2s to ensure Firestore writes are available
- **Added verification step** to check timer state exists before triggering server updates
- **Reduced retry attempts** from 2 to 1 to minimize duplicate calls
- **Increased retry delay** from 1s to 2s

### 2. Firebase Function (manageLiveActivityUpdates.js)
- **Added request debouncing** with 5-second window to ignore duplicate requests
- **Improved update frequency** to 100ms for smoother Live Activity updates (was 1s)
- **Enhanced error handling** continues from previous fixes

### 3. Key Changes

#### Before (iOS):
```swift
await storeTimerStateInFirestore(for: activity, action: .start)
try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
```

#### After (iOS):
```swift
await storeTimerStateInFirestore(for: activity, action: .start)
try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

// Verify timer state exists before proceeding
let timerDoc = try await db.collection("activeTimers").document(userId).getDocument()
if timerDoc.exists {
    await triggerServerSidePushUpdates(activityId: activity.id, userId: userId)
} else {
    // Retry after another delay
}
```

#### Firebase Function Debouncing:
```javascript
const requestKey = `${activityId}-${action}`;
const lastRequest = recentRequests.get(requestKey);
if (lastRequest && (now - lastRequest) < 5000) {
    return { success: true, message: 'Request already being processed' };
}
```

## Expected Results
1. Timer state will be available when Firebase function tries to read it
2. Duplicate function calls will be filtered out
3. Live Activity updates will be smoother (100ms intervals)
4. INTERNAL errors should be eliminated

## Next Steps
1. Deploy the updated Firebase functions
2. Test on physical device to verify fixes
3. Monitor logs for any remaining race conditions