# Timer Service Circular Dependency Fix

## Problem
The app was crashing with a deadlock during initialization because:
1. `TimerService.shared` singleton was initializing
2. During init, it called `restoreState()`
3. `restoreState()` had a guard check `self === TimerService.shared`
4. This tried to access `TimerService.shared` before it finished initializing
5. Result: Circular dependency and deadlock

## Root Cause
The instance comparison checks (`self === TimerService.shared`) were added to prevent the quick practice timer from saving/restoring state, but they caused a circular dependency when called during the singleton's initialization.

## Solution
Instead of using instance comparison, I added a flag-based approach:

1. **Added `enableStatePersistence` property**: A private flag that controls whether the timer instance should persist state

2. **Modified init method**: 
   - Sets `enableStatePersistence = !skipStateRestore`
   - Main timer: `TimerService()` → persistence enabled
   - Quick practice: `TimerService(skipStateRestore: true)` → persistence disabled

3. **Updated all persistence methods** to check the flag instead of instance comparison:
   - `restoreState()`: `guard enableStatePersistence else { return }`
   - `saveStateOnPauseOrBackground()`: `guard enableStatePersistence else { return }`
   - `clearSavedState()`: `guard enableStatePersistence else { return }`
   - `applicationDidEnterBackground()`: `guard enableStatePersistence else { return }`
   - `applicationWillEnterForeground()`: `guard enableStatePersistence else { return }`

## Benefits
- No circular dependencies during initialization
- Clean separation between main timer and quick practice timer
- State persistence behavior is controlled at initialization time
- No runtime instance comparisons needed

## Testing
The app should now launch without the deadlock crash, and:
- Main timer continues to save/restore state as before
- Quick practice timer doesn't interfere with saved state
- Both timers can still use background tracking independently