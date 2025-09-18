# Quick Practice Timer Isolation Fix

## Problem
When the daily routine practice timer is running and the app is backgrounded/resumed, the QuickPracticeTimerView was incorrectly starting its timer automatically. This was causing interference between the main timer and quick practice timer.

## Root Cause
1. The QuickPracticeTimerView was syncing with shared timer state on `onAppear`
2. TimerService instances were restoring saved state from UserDefaults regardless of which timer they belonged to
3. Background/foreground notifications were affecting all timer instances

## Fixes Applied

### 1. Isolated QuickPracticeTimerTracker Timer Service
- Modified `QuickPracticeTimerTracker` to create its timer service with `skipStateRestore: true`
- This prevents the quick practice timer from loading any saved state on initialization
- Ensures complete isolation from the main timer

### 2. Added `skipStateRestore` Parameter to TimerService
- Added optional `skipStateRestore` parameter to TimerService init
- When true, skips the `restoreState()` call during initialization
- Used by QuickPracticeTimerTracker to prevent unwanted state restoration

### 3. Fixed onAppear Logic in QuickPracticeTimerView
- Removed the sync with any existing timer state
- Added explicit check if timer has unexpected state and clears it
- Only restores state if there's a saved quick practice state specifically

### 4. Isolated State Save/Restore to Main Timer Only
- Modified `saveStateOnPauseOrBackground()` to only save for `TimerService.shared`
- Modified `restoreState()` to only restore for `TimerService.shared`
- Modified `clearSavedState()` to only clear for `TimerService.shared`
- Modified background/foreground handlers to only affect main timer

### 5. Separated Background Timer Tracking
- Background timer tracking already uses separate keys for main and quick practice timers
- Modified `applicationDidEnterBackground` to only save background state for main timer
- Modified `applicationWillEnterForeground` to only restore for main timer

## Testing
1. Start daily routine practice timer
2. Exit the app (go to home screen)
3. Return to the app
4. The daily routine timer should continue running
5. Navigate to Quick Practice - it should NOT automatically start
6. The quick practice timer should be in stopped state

## Result
The quick practice timer is now completely isolated from the main timer and won't interfere with daily routine practice sessions.