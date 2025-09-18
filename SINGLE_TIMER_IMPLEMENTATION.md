# Single Timer Implementation ✅

## Overview
Implemented logic to ensure only one timer can run at a time:
- Quick timer is blocked if main timer is running
- Main timer can override and stop quick timer

## Implementation Details

### 1. Created TimerCoordinator
New singleton class `TimerCoordinator.swift` that:
- Tracks which timers are running
- Enforces timer exclusivity rules
- Posts notifications when timers are blocked

### 2. Updated TimerService
Modified `start()` method to:
- Check with TimerCoordinator before starting
- Block quick timer if main timer is running
- Allow main timer to stop quick timer

### 3. Updated QuickPracticeTimerService  
Modified `start()` method to:
- Check with TimerCoordinator before starting
- Return early if blocked by main timer

### 4. UI Already Has Feedback
`QuickPracticeTimerView` already has:
- Alert dialog when timer is blocked
- Disabled state for play button
- Proper messaging to user

## Timer Rules
1. **Main Timer Priority**: Main timer can always start and will stop quick timer if running
2. **Quick Timer Restriction**: Quick timer cannot start if main timer is running
3. **User Feedback**: Alert shown when quick timer is blocked

## Testing
- Start main timer → Try to start quick timer → Should show alert
- Start quick timer → Start main timer → Quick timer should stop automatically
- Both timers should respect pause/resume independently when allowed to run