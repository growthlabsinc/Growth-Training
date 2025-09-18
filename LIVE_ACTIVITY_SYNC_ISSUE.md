# Live Activity Timer Synchronization Issue

## Problem
The Live Activity timer is not properly synchronizing with the main app timer. While push updates are being sent with correct Apple reference timestamps, the timer display is drifting due to cumulative `startedAt` adjustments.

## Root Cause
Every pause/resume cycle is adjusting the `startedAt` time by adding the pause duration. This causes cumulative drift:

```
Original startedAt: 04:39:42
After Resume 1: 04:39:53 (+11s pause duration)
After Resume 2: 04:40:01 (+8s more)
After Resume 3: 04:40:05 (+4s more)
After Resume 4: 04:40:17 (+12s more)
```

This is happening in `LiveActivityManager.swift` at line 305:
```swift
updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
```

## The Issue with This Approach
1. **Cumulative Drift**: Each pause/resume adds to the previous adjustment
2. **State Inconsistency**: The `startedAt` time no longer represents the actual start time
3. **Sync Problems**: The main app timer and Live Activity have different reference points

## Correct Approach
The `startedAt` time should remain constant for the entire timer session. Instead of adjusting `startedAt`, we should:

1. **Keep Original Start Time**: Never modify `startedAt` after timer begins
2. **Track Total Pause Duration**: Maintain a cumulative pause duration
3. **Calculate Elapsed Time**: `elapsed = now - startedAt - totalPauseDuration`

## Implementation Fix Needed

### Current (Incorrect) Pattern:
```swift
// This causes cumulative drift
updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
updatedState.pausedAt = nil
```

### Correct Pattern:
```swift
// Keep original startedAt, track pause duration separately
updatedState.pausedAt = nil
// Don't modify startedAt!
// The widget should calculate elapsed time considering pause duration
```

## Why This Matters
The Live Activity widget uses `Text(timerInterval:)` which expects consistent time references. When `startedAt` keeps changing, the timer display becomes unreliable.

## Verification in Logs
The logs clearly show this issue:
1. Live Activity buttons trigger pause/resume correctly
2. Firebase sends correct Apple reference timestamps
3. But the main app keeps adjusting `startedAt` times
4. This causes the timer display to drift from actual elapsed time

## Next Steps
1. Stop modifying `startedAt` during resume operations
2. Ensure the widget properly handles pause/resume without time adjustments
3. Test that timer remains synchronized across pause/resume cycles