# Quick Timer Countdown Fix

## Problem
The quick practice timer was stuck at 5:00 and not advancing when started. The timer would be configured for countdown mode but wouldn't actually count down.

## Root Cause
The `QuickPracticeTimerView` was using a computed property `timerService` that returned the internal timer service from `QuickPracticeTimerService`. However, all timer operations (configure, start, pause, etc.) were being called on this computed property instead of the observable `quickTimerService` instance.

This meant that:
1. Timer updates weren't properly triggering SwiftUI view updates
2. The published properties in `QuickPracticeTimerService` weren't being used
3. The view wasn't receiving proper notifications when timer state changed

## Solution
Updated all references from `timerService` to `quickTimerService` throughout the view:

### Key Changes:
1. **Timer configuration**: `quickTimerService.configure(...)` instead of `timerService.configure(...)`
2. **Timer control**: `quickTimerService.start/pause/resume/stop()` instead of `timerService.start/pause/resume/stop()`
3. **State checks**: `quickTimerService.state` instead of `timerService.state`
4. **Time values**: `quickTimerService.elapsedTime/remainingTime` instead of `timerService.elapsedTime/remainingTime`
5. **Background saves**: Pass `quickTimerService.timerService` to BackgroundTimerTracker

### Files Modified:
- `/Users/tradeflowj/Desktop/Growth/Growth/Features/Stats/Views/QuickPracticeTimerView.swift`
  - Replaced ~40 instances of `timerService` with `quickTimerService`
  - Ensured all timer operations use the observable service

## Result
The quick practice timer now properly:
- Counts down from the selected duration (5:00, 10:00, etc.)
- Updates the UI in real-time
- Maintains state across navigation
- Works with background state restoration
- Integrates with Live Activities

## Technical Details
The `QuickPracticeTimerService` singleton properly publishes:
- `@Published var elapsedTime: TimeInterval`
- `@Published var remainingTime: TimeInterval`
- `@Published var timerState: TimerState`
- `@Published var overallProgress: Double`

These published properties are synced with the internal timer service via Combine subscriptions, ensuring UI updates happen when timer state changes.