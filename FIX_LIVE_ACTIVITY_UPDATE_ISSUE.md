# Fix Live Activity Not Updating When Timer Pauses

## Problem Identified
When the pause/resume buttons are pressed in the Live Activity:
1. ✅ Darwin notification is received
2. ✅ Timer state changes (pauses/resumes) 
3. ❌ Live Activity visual state doesn't update (continues showing running)

## Root Cause
The `updateTimerActivity` method in `LiveActivityManager` is asynchronous (uses `Task {}`), but it's called synchronously from `handleDarwinNotification`. The update might not complete properly or there's a race condition.

## Solution

### Option 1: Make Darwin Handler Async (Recommended)

Update `handleDarwinNotification` in TimerService.swift to properly await the Live Activity update:

```swift
nonisolated private func handleDarwinNotification() {
    // ... existing code ...
    
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        
        Task { @MainActor in  // Make this async
            switch action {
            case "pause":
                if self.timerState == .running {
                    self.pause()
                    // Store state
                    AppGroupConstants.storeTimerState(...)
                    
                    // Update Live Activity and wait for completion
                    if #available(iOS 16.1, *) {
                        await LiveActivityManager.shared.updateTimerActivityAsync(
                            elapsedTime: self.elapsedTime,
                            isRunning: false,
                            isPaused: true
                        )
                    }
                }
            // Similar for resume...
            }
        }
    }
}
```

### Option 2: Force Immediate Update

Add a synchronous update method to LiveActivityManager:

```swift
func updateTimerActivityImmediately(elapsedTime: TimeInterval, isRunning: Bool, isPaused: Bool) {
    guard let activity = currentActivity else { return }
    
    if #available(iOS 16.2, *) {
        let currentState = activity.content.state
        var updatedState = currentState
        
        if isPaused && currentState.pausedAt == nil {
            // Pausing - set pausedAt
            updatedState.pausedAt = Date()
        } else if isRunning && currentState.pausedAt != nil {
            // Resuming - adjust startedAt and clear pausedAt
            if let pausedAt = currentState.pausedAt {
                let pauseDuration = Date().timeIntervalSince(pausedAt)
                updatedState.startedAt = updatedState.startedAt.addingTimeInterval(pauseDuration)
                updatedState.pausedAt = nil
            }
        }
        
        // Force synchronous update
        Task.detached(priority: .userInitiated) {
            await activity.update(ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(28800),
                relevanceScore: isRunning ? 100.0 : 50.0
            ))
        }
    }
}
```

### Option 3: Debug Why Current Update Isn't Working

Add extensive logging to see what's happening:

```swift
func updateTimerActivity(elapsedTime: TimeInterval, isRunning: Bool, isPaused: Bool) {
    guard let activity = currentActivity else { 
        Logger.error("❌ No current activity to update", logger: AppLoggers.liveActivity)
        return 
    }
    
    Logger.info("📊 updateTimerActivity called:", logger: AppLoggers.liveActivity)
    Logger.info("  - elapsedTime: \(elapsedTime)", logger: AppLoggers.liveActivity)
    Logger.info("  - isRunning: \(isRunning)", logger: AppLoggers.liveActivity)
    Logger.info("  - isPaused: \(isPaused)", logger: AppLoggers.liveActivity)
    
    Task {
        if #available(iOS 16.2, *) {
            let currentState = activity.content.state
            Logger.info("  - Current pausedAt: \(String(describing: currentState.pausedAt))", logger: AppLoggers.liveActivity)
            
            // ... rest of implementation with more logging
        }
    }
}
```

## Quick Fix to Test

The simplest immediate fix is to add a small delay before updating the Live Activity to ensure the timer state change completes first:

In `handleDarwinNotification` in TimerService.swift, after pause():

```swift
case "pause":
    if self.timerState == .running {
        self.pause()
        
        // Add small delay to ensure state change completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.updateTimerActivity(
                    elapsedTime: self.elapsedTime,
                    isRunning: false,
                    isPaused: true
                )
            }
        }
    }
```

## Verification

After implementing the fix:
1. Build and archive with Growth Production scheme
2. Upload to TestFlight
3. Test on physical device
4. Watch console logs for Live Activity update confirmations

## Expected Behavior

When pause button is pressed:
- Timer should pause ✅
- Live Activity should show paused state (static time, "PAUSED" indicator)
- Progress bar should stop moving

When resume button is pressed:
- Timer should resume ✅
- Live Activity should show running state (counting time)
- Progress bar should continue from where it paused