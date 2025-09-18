# Quick Practice Timer Background Fix

## Problem
After fixing the circular dependency issue, the quick practice timer stopped working in the background because state persistence was disabled for it, which also disabled the automatic background handling.

## Solution

### 1. Separated Background Timer Tracking from State Persistence
- The quick practice timer uses `onDisappear` to save background state (with `isQuickPractice: true`)
- This works independently of the TimerService's state persistence

### 2. Added Public `restoreFromBackground` Method
- Added a public method to TimerService that can be called manually:
  ```swift
  func restoreFromBackground(isQuickPractice: Bool = false) -> Bool
  ```
- This allows views to manually restore background state

### 3. Added App Foreground Notification Handler
- QuickPracticeTimerView now listens for `UIApplication.willEnterForegroundNotification`
- When the app returns from background, it checks for saved quick practice state
- If found, it restores the timer state

### 4. Refactored onAppear Logic
- Moved the restoration logic to a `handleOnAppear()` method
- This method is called both on initial appear and when returning from background

## How It Works Now

### Main Timer (Daily Routine)
1. Uses automatic background handling via `applicationDidEnterBackground`
2. State persistence is enabled (`enableStatePersistence = true`)
3. Saves and restores state automatically

### Quick Practice Timer
1. Manual background handling via view's `onDisappear`/`onAppear`
2. State persistence is disabled (`enableStatePersistence = false`)
3. Uses BackgroundTimerTracker with `isQuickPractice: true` flag
4. Listens for foreground notifications to restore state

### Key Points
- Both timers can run in the background independently
- They use separate storage keys (`backgroundTimerState` vs `quickPracticeTimerState`)
- They cannot run simultaneously (enforced by UI checks)
- Background notifications work for both timers

## Testing
1. Start quick practice timer
2. Background the app
3. Wait for notifications
4. Return to app
5. Timer should restore with correct elapsed time