# Live Activity Pause Button Race Condition Fix

## Issue
The Live Activity pause button appeared to not work after TestFlight deployment, but logs showed it was actually a race condition:
1. User presses pause in Live Activity
2. App receives and processes pause correctly
3. App becomes active and calls `restoreFromBackground()`
4. Background restoration automatically resumes the timer, making it appear the pause didn't work

## Root Cause
The existing safety check in `restoreFromBackground()` only prevented restoration if the pause was within 2 seconds, but there was often a 4+ second delay between pause and app activation.

## Fix Applied
Enhanced pause tracking using App Group storage:

1. **In `pause()` method**: Store pause state in App Group
   ```swift
   // Record pause time to prevent race conditions
   lastPauseTime = timestamp
   
   // Also record in App Group for Live Activity pause detection
   if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
       defaults.set(true, forKey: "timerPausedViaLiveActivity")
       defaults.set(timestamp, forKey: "timerPauseTime")
       defaults.synchronize()
   }
   ```

2. **In `resume()` method**: Clear pause state
   ```swift
   // Clear the pause flag in App Group
   if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
       defaults.set(false, forKey: "timerPausedViaLiveActivity")
       defaults.removeObject(forKey: "timerPauseTime")
       defaults.synchronize()
   }
   ```

3. **In `stop()` method**: Also clear pause state
   ```swift
   // Clear the pause flag in App Group
   if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
       defaults.set(false, forKey: "timerPausedViaLiveActivity")
       defaults.removeObject(forKey: "timerPauseTime")
       defaults.synchronize()
   }
   ```

4. **In `restoreFromBackground()` method**: Check App Group pause state with longer time window
   ```swift
   // Also check App Group for Live Activity pause state
   if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier),
      defaults.bool(forKey: "timerPausedViaLiveActivity"),
      let pauseTime = defaults.object(forKey: "timerPauseTime") as? Date,
      Date().timeIntervalSince(pauseTime) < 10.0 {  // Increased to 10 seconds
       Logger.info("  ⚠️ Timer was paused via Live Activity \(Date().timeIntervalSince(pauseTime))s ago")
       Logger.info("  - Skipping restoration to prevent race condition")
       return
   }
   ```

## Testing
1. Build and run on device
2. Start a timer
3. Press pause in Live Activity
4. Switch away from app for 5+ seconds
5. Return to app
6. Timer should remain paused (not auto-resume)

## Files Modified
- `/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Timer/Services/TimerService.swift`

## Related Issues Fixed
- Deep link handling for iOS 16.x users (previously fixed in AppSceneDelegate)
- iOS 17.0 compatibility issues (fixed in CardButtonStyle)
- Compilation errors with QuickPracticeTimerService