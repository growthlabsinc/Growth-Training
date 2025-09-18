# Quick Timer Background Resume Fix

## Issue
When the Quick Practice timer was running and the app went to background, the timer would be paused when returning to foreground instead of continuing to run.

## Root Cause
The BackgroundTimerTracker.restoreTimerState() method intentionally sets the timer state to `.paused` (line 123) and expects the calling code to resume it. However, the QuickPracticeTimerView wasn't resuming the timer after restoration.

## Solution
Modified QuickPracticeTimerView.handleOnAppear() to:
1. Peek at the background state BEFORE calling restoreFromBackground (which clears the saved state)
2. Check if the timer was running in background
3. If it was running and is now paused after restoration, explicitly call timerService.resume()

## Code Changes
In QuickPracticeTimerView.swift, lines 846-864:
- Added: Peek at background state before restoration
- Added: Check wasRunning flag
- Added: Conditional resume if timer was running but is now paused

## Result
The Quick Practice timer now correctly continues running when the app returns from background, maintaining the expected behavior for users who temporarily leave the app during a practice session.