# Live Activity Timer Synchronization Fix

## Problem
The Live Activity updates work and can control the app timer, but when trying to pause from the app, it doesn't update the Live Activity timer. After resuming from Live Activity, the timer gets stuck in a paused state with continuous "TICK Skipped - state is paused" messages.

## Root Cause Analysis
The issue was caused by multiple race conditions:

1. **Multiple calls to checkStateOnAppBecomeActive()**: The function was being called from 3 different places (AppSceneDelegate, GrowthAppApp, and TimerViewModel) when the app became active, causing potential duplicate processing of timer actions.

2. **Dual action storage systems**: Timer actions were being stored in both UserDefaults (by TimerControlIntent) and App Group files (by other components), leading to confusion about which actions to process.

3. **Stale action processing**: Old timer actions (>30 seconds) were still being processed, causing the timer to revert to previous states.

## Fixes Applied

### 1. Added Debouncing to checkStateOnAppBecomeActive()
**File**: `Growth/Features/Timer/Services/TimerService.swift`
- Added `lastStateCheckTime` and `stateCheckDebounceInterval` to prevent multiple calls within 0.5 seconds
- Reduced action timeout from 30 seconds to 5 seconds to avoid processing stale actions
- Added better logging to track action processing
- Always clear actions after reading them, even if they're too old

### 2. Removed Duplicate UserDefaults Processing
**File**: `Growth/Application/AppSceneDelegate.swift`
- Removed the UserDefaults-based timer action processing from `sceneDidBecomeActive`
- This prevents conflicts with the App Group file-based system
- Timer actions are now handled exclusively through TimerService.checkStateOnAppBecomeActive()

### 3. Direct Timer Service Calls from Live Activity
**File**: `GrowthTimerWidget/TimerControlIntent.swift`
- Since LiveActivityIntent runs in the app process (not widget process), changed to directly call timer services
- Removed intermediate storage in UserDefaults or App Group files
- This ensures immediate, reliable action processing without race conditions

## How It Works Now

1. **Live Activity Button Press** → TimerControlIntent performs → Directly calls TimerService.pause()/resume()/stop()
2. **App Becomes Active** → checkStateOnAppBecomeActive() is debounced to run only once
3. **Background/Foreground Transitions** → Handled by existing background state restoration without interference

## Benefits
- Eliminates race conditions from multiple state check calls
- Removes confusion between UserDefaults and App Group file actions
- Ensures timer state remains synchronized between app and Live Activity
- Prevents processing of stale actions that could revert timer state

## Testing Recommendations
1. Test pause/resume from Live Activity buttons
2. Test pause/resume from main app UI
3. Test background/foreground transitions
4. Test rapid button presses in Live Activity
5. Verify timer doesn't get stuck in paused state after resume