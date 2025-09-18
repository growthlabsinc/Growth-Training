# Live Activity Pause Issue Confirmed

## Issue Observed in Firebase Logs

When the Live Activity pause button is pressed:

1. **Timer pauses correctly in main app**:
   ```
   🟡 [PAUSE] TimerService.pause() called at 2025-07-25 19:21:31 +0000
   - State changed to: paused
   ```

2. **Live Activity gets initial pause update**:
   ```
   - pausedAt: Optional(2025-07-25 19:21:31 +0000)
   Updating content for activity 4F38D5F5-7B6C-4275-A4FF-7F58BCF3AA47
   ```

3. **Race condition error appears**:
   ```
   GTMSessionFetcher 0x121e01680 (https://us-central1-growth-70a85.cloudfunctions.net/updateLiveActivitySimplified) was already running
   ```

4. **Second update overwrites with nil pausedAt**:
   ```
   🔍 TimerActivityAttributes.ContentState decoding...
   - pausedAt: nil
   Updating content for activity 4F38D5F5-7B6C-4275-A4FF-7F58BCF3AA47
   ```

## Root Cause

The code reverted to commit 123f498f lacks the race condition fixes:

1. **No debouncing** - Multiple Firebase function calls can execute concurrently
2. **No task cancellation** - New updates don't cancel pending ones
3. **No delays** - Updates fire immediately without waiting for state to persist

## What's Happening

1. User presses pause button in Live Activity
2. `TimerControlIntent` posts Darwin notification
3. `TimerService` receives notification and calls `pause()`
4. `pause()` calls `LiveActivityManagerSimplified.shared.pauseTimer()`
5. `pauseTimer()` updates local activity AND sends push update
6. Multiple updates conflict, causing the "already running" error
7. The second update (with nil pausedAt) wins, showing the timer as still running

## Solution

The race condition was fixed in commit 9e9680f4 by:
- Adding debouncing mechanism
- Implementing task cancellation
- Adding strategic delays between operations

## Current State

With the code reverted to 123f498f, the Live Activity pause button will exhibit this race condition on iOS 18+ devices when deployed via TestFlight.