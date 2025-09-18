# Live Activity Production Sync Fix

## Problem in Production
- First pause works (both Live Activity and app timer pause)
- Resume updates Live Activity but NOT the app timer
- Subsequent pause/resume only affects Live Activity, not app

## Root Cause
The `TimerIntentObserver` polling mechanism wasn't reliable in production because:
1. Timer wasn't on the correct run loop
2. Polling stopped when app went to background
3. Action detection window was too short (2 seconds)
4. No unique action ID to prevent duplicate processing

## Fixes Applied

### 1. Improved Timer Reliability
- Timer now runs on main run loop with `.common` mode
- Continues running even during UI scrolling
- Faster polling interval (0.3s instead of 0.5s)

### 2. App Lifecycle Management
- Observer restarts when app becomes active
- Stops polling when app enters background (saves battery)
- Immediately checks for pending actions on app activation

### 3. Better Action Detection
- Extended detection window to 10 seconds (was 2 seconds)
- Unique action ID prevents duplicate processing
- Cleans up old action data automatically

### 4. Enhanced Logging
- Detailed state logging for debugging
- Tracks why actions are or aren't processed
- Shows current timer state before attempting changes

## Key Code Changes

### TimerIntentObserver.swift
```swift
// Unique action ID to prevent duplicates
let actionId = "\(action)_\(timeInterval)"
if lastProcessedActionId == actionId {
    return  // Already processed
}

// Timer on main run loop
RunLoop.main.add(timer, forMode: .common)

// App lifecycle awareness
NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
    .sink { _ in
        self?.startObserving()
        self?.checkForIntentActions()
    }
```

### AppSceneDelegate.swift
```swift
func sceneDidBecomeActive(_ scene: UIScene) {
    // Check for pending Live Activity actions immediately
    TimerIntentObserver.shared.checkPendingActions()
    // ... rest of the code
}
```

## Testing in Production

1. **Build for TestFlight**
   - Ensure all intent files are in both targets
   - Archive with production scheme
   - Upload to TestFlight

2. **Test Sequence**
   - Start timer in app
   - Pause from Live Activity → Both should pause
   - Resume from Live Activity → Both should resume
   - Background the app
   - Pause/resume from Live Activity
   - Open app → Timer should sync to correct state
   - Stop from Live Activity → App opens with completion sheet

3. **What to Monitor**
   - Console logs will show:
     - "TimerIntentObserver: Detected [action] action"
     - "TimerIntentObserver: Processing [action] for main timer"
     - Current timer state before/after actions

## Why This Works

### Polling Approach (vs Darwin Notifications)
- Darwin notifications are blocked in production due to sandboxing
- SharedUserDefaults polling works across process boundaries
- App Group allows widget and app to share data

### RunLoop Configuration
- Main run loop ensures timer runs on UI thread
- `.common` mode keeps timer running during scrolling
- Lifecycle management prevents battery drain

### Action Deduplication
- Unique ID based on action + timestamp
- Prevents same action from being processed multiple times
- Critical for reliable pause/resume toggling

## If Issues Persist

1. **Check Xcode Target Membership**
   - All three intent files must be in BOTH targets
   - Clean build folder and rebuild

2. **Verify App Group**
   - Ensure `group.com.growthlabs.growthmethod` is configured
   - Check entitlements for both app and widget

3. **Monitor Console Logs**
   - Filter by "TimerIntentObserver" to see action flow
   - Check if actions are being detected but not processed

4. **Force Sync on App Launch**
   - App now checks for pending actions when becoming active
   - This catches any actions that occurred while backgrounded