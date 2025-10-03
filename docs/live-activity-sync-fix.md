# Live Activity Timer Synchronization Fix

## Problem
When the Live Activity pause button is tapped while the screen is locked:
1. The Live Activity pauses correctly (handled locally by the widget)
2. The main app timer remains running (app is suspended, not receiving notifications)
3. On resume from Live Activity, both timers continue but are out of sync

## Root Causes
1. **Notification Timing**: Darwin notifications from the widget are only processed when the app is in the foreground
2. **State Persistence Gap**: The widget updates App Group state, but the suspended app doesn't check this on resume
3. **Missing Synchronization**: No mechanism to reconcile Live Activity state with main app timer state

## Solution Implemented

### 1. App Group State Synchronization
Added `syncWithLiveActivityState()` method to TimerService:
- Checks App Group for Live Activity state
- Compares with current timer state
- Pauses/resumes timer to match Live Activity state

### 2. Firestore State Listener
Added `startListeningForRemoteStateChanges()` method:
- Listens for Firestore state changes from push updates
- Syncs pause/resume state from remote changes
- Ensures consistency across devices

### 3. App Lifecycle Integration
Added state checks at multiple app lifecycle points:
- `sceneWillEnterForeground`: Sync before app becomes visible
- `sceneDidBecomeActive`: Check for unprocessed actions
- `didBecomeActiveNotification`: Additional check for edge cases

### 4. Persistent Action Storage
Enhanced `TimerIntentObserver`:
- Stores Darwin notification actions in App Group file
- Processes stored actions when app becomes active
- Handles actions that arrived while app was suspended

### 5. State Check on App Active
Added `checkStateOnAppBecomeActive()` method:
- First syncs with App Group state
- Then processes any unprocessed actions
- Ensures actions within 30 seconds are processed

## How It Works

1. **Live Activity Pause Tapped (Screen Locked)**:
   - Widget updates its local state immediately
   - Widget writes pause action to App Group file
   - Widget posts Darwin notification (may not be received)
   - Push update sent to APNs (updates other devices)

2. **App Returns to Foreground**:
   - `sceneWillEnterForeground` calls `syncWithLiveActivityState()`
   - Detects Live Activity is paused but timer is running
   - Pauses the main app timer to match

3. **App Becomes Active**:
   - `sceneDidBecomeActive` calls `checkStateOnAppBecomeActive()`
   - Checks for unprocessed actions in App Group file
   - Processes any recent actions (< 30 seconds old)

4. **Firestore Updates**:
   - Push updates trigger Firestore state changes
   - Main app listens for these changes
   - Syncs pause/resume state automatically

## Benefits

1. **Reliable Synchronization**: Timer state always matches Live Activity
2. **No Lost Actions**: Actions are persisted and processed when possible
3. **Multi-Device Support**: Firestore sync ensures consistency across devices
4. **Graceful Degradation**: Multiple fallback mechanisms ensure reliability

## Testing

To test the fix:
1. Start a timer in the app
2. Lock the screen
3. Tap pause on the Live Activity
4. Unlock and return to the app
5. Verify the main timer is paused and shows the correct elapsed time
6. Resume from Live Activity and verify both timers continue in sync