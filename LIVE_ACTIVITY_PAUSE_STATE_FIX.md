# Live Activity Pause State Fix

## Issue
From the logs, the pause button works initially but then the Live Activity reverts to running state:
1. 18:55:28 - Pause processed correctly, Live Activity shows paused
2. 18:55:31 - A push update arrives with `pausedAt: nil`, reverting to running state

## Root Cause
The Firebase function is reading stale data from Firestore due to:
1. Race condition between Firestore write and Firebase function read
2. Possible push token re-registration triggering updates with old state

## Solution Applied

### 1. Added Propagation Delay
Added a 200ms delay after Firestore write to ensure data propagates:
```swift
// Store state in Firestore
await storeTimerStateInFirestore(
    activityId: activityId,
    contentState: contentState,
    action: action
)

// Add a small delay to ensure Firestore write has propagated
// This prevents the Firebase function from reading stale data
try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

// Trigger push via Firebase Function
```

### 2. Additional Recommendations

#### Option A: Update Firebase Function to Check Action
The Firebase function should respect the action parameter and not override pause state:
```javascript
// In updateLiveActivitySimplified.js
if (action === 'pause' && !contentState.pausedAt) {
    // Force pause state if action is pause but state shows running
    pushContentState.pausedAt = new Date().toISOString();
}
```

#### Option B: Prevent Duplicate Push Updates
Add logic to prevent push updates that would revert state:
```swift
// Only send push updates that match current local state
if contentState.isPaused == activity.content.state.isPaused {
    await sendPushUpdateInternal(contentState: contentState, action: action)
}
```

## Testing
1. Start timer
2. Press pause button
3. Live Activity should stay paused
4. No reversion to running state after 3-5 seconds

## Files Modified
- `/Growth/Features/Timer/Services/LiveActivityManagerSimplified.swift`
  - Added 200ms delay after Firestore write