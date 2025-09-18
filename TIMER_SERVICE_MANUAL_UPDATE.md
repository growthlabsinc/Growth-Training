# TimerService Manual Update Guide

Since the patch file has formatting issues, here are the manual changes to make to `TimerService.swift`:

## 1. Update Live Activity Manager References

### Find and Replace:
- Find: `LiveActivityManager.shared`
- Replace with: `LiveActivityManagerSimplified.shared`

## 2. Update the start() Method

### Find this section around line 327:
```swift
if #available(iOS 16.1, *) {
    // If we're resuming from paused, just update the existing activity
    if wasPausedState && LiveActivityManager.shared.currentActivity != nil {
        print("  📱 Updating existing Live Activity to running state")
        LiveActivityManager.shared.updateActivity(isPaused: false)
        
        // Sync resume state to Firestore
        TimerStateSync.shared.updatePauseState(isPaused: false)
    } else {
        // Otherwise start a new Live Activity
        print("  📱 Starting new Live Activity")
        startLiveActivity()
    }
}
```

### Replace with:
```swift
if #available(iOS 16.1, *) {
    // If we're resuming from paused, just update the existing activity
    if wasPausedState && LiveActivityManagerSimplified.shared.currentActivity != nil {
        print("  📱 Resuming Live Activity")
        Task {
            await LiveActivityManagerSimplified.shared.resumeTimer()
        }
    } else {
        // Otherwise start a new Live Activity
        print("  📱 Starting new Live Activity")
        let sessionType: TimerActivityAttributes.ContentState.SessionType = 
            currentTimerMode == .countdown ? .countdown : .countup
        
        LiveActivityManagerSimplified.shared.startTimerActivity(
            methodId: currentMethodId ?? "",
            methodName: currentMethodName ?? "Timer",
            duration: targetDurationValue,
            sessionType: sessionType,
            timerType: isQuickPracticeTimer ? "quick" : "main"
        )
    }
}
```

## 3. Update the pause() Method

### Find this section around line 475:
```swift
if #available(iOS 16.1, *) {
    // Check if the activity is showing completion state
    if !LiveActivityManager.shared.isActivityShowingCompletion {
        print("  📱 Updating Live Activity to paused state")
        LiveActivityManager.shared.updateActivity(isPaused: true)
        
        // Sync pause state to Firestore
        TimerStateSync.shared.updatePauseState(isPaused: true, pausedAt: Date())
    } else {
        print("  ℹ️ Skipping Live Activity update (activity is showing completion)")
    }
}
```

### Replace with:
```swift
if #available(iOS 16.1, *) {
    Task {
        await LiveActivityManagerSimplified.shared.pauseTimer()
    }
}
```

## 4. Update the resume() Method

### Find this section around line 507:
```swift
if #available(iOS 16.1, *) {
    print("  📱 Updating Live Activity to running state")
    LiveActivityManager.shared.updateActivity(isPaused: false)
    
    // Also update in the TimerStateSync (done in start() method via updatePauseState)
}
```

### Replace with:
```swift
if #available(iOS 16.1, *) {
    Task {
        await LiveActivityManagerSimplified.shared.resumeTimer()
    }
}
```

## 5. Update the stop() Method

### Find this section around line 568:
```swift
if #available(iOS 16.1, *) {
    Task {
        await LiveActivityManager.shared.endCurrentActivity(immediately: true)
    }
    
    // Stop syncing timer state
    TimerStateSync.shared.stopSyncing()
}
```

### Replace with:
```swift
if #available(iOS 16.1, *) {
    Task {
        await LiveActivityManagerSimplified.shared.stopTimer()
    }
}
```

## 6. Update the completeTimer() Method

### Find this section around line 841:
```swift
Task { @MainActor in
    // First, update the Live Activity push state to stop
    if let activity = LiveActivityManager.shared.currentActivity {
        await LiveActivityPushService.shared.storeTimerStateInFirestore(for: activity, action: .stop)
    }
    
    // End the Live Activity immediately
    await LiveActivityManager.shared.completeActivity()
    
    // Show session completion notification
    let methodName = currentMethodName ?? "Training"
    let duration = elapsedTime
    NotificationService.shared.showSessionCompletionNotification(
        methodName: methodName,
        duration: duration,
        elapsedTime: actualElapsedTime
    )
}
```

### Replace with:
```swift
Task { @MainActor in
    await LiveActivityManagerSimplified.shared.completeTimer()
    
    // Show session completion notification
    let methodName = currentMethodName ?? "Training"
    let duration = elapsedTime
    NotificationService.shared.showSessionCompletionNotification(
        methodName: methodName,
        duration: duration
    )
}
```

## 7. Replace Darwin Notification Handlers

### Find the registerForDarwinNotifications() method around line 1141 and replace the entire method with:

```swift
private func registerForDarwinNotifications() {
    // Pause notification
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque(),
        { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let service = Unmanaged<TimerService>.fromOpaque(observer).takeUnretainedValue()
            Task { @MainActor in
                await service.handleDarwinNotification(name: name)
            }
        },
        "com.growthlabs.growthmethod.liveactivity.pause" as CFString,
        nil,
        .deliverImmediately
    )
    
    // Resume notification
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque(),
        { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let service = Unmanaged<TimerService>.fromOpaque(observer).takeUnretainedValue()
            Task { @MainActor in
                await service.handleDarwinNotification(name: name)
            }
        },
        "com.growthlabs.growthmethod.liveactivity.resume" as CFString,
        nil,
        .deliverImmediately
    )
    
    // Stop notification
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque(),
        { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let service = Unmanaged<TimerService>.fromOpaque(observer).takeUnretainedValue()
            Task { @MainActor in
                await service.handleDarwinNotification(name: name)
            }
        },
        "com.growthlabs.growthmethod.liveactivity.stop" as CFString,
        nil,
        .deliverImmediately
    )
}

private func unregisterFromDarwinNotifications() {
    CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque()
    )
}

@MainActor
private func handleDarwinNotification(name: CFNotificationName?) async {
    guard let name = name else { return }
    let nameString = name.rawValue as String
    
    print("🔔 TimerService: Received Darwin notification: \(nameString)")
    
    // Check if we should handle the action based on App Group data
    if let fileAction = AppGroupFileManager.shared.readTimerAction() {
        print("  - File action: \(fileAction.action)")
        print("  - Timer type: \(fileAction.timerType)")
        
        // Only handle if it's for the correct timer type
        if fileAction.timerType != (isQuickPracticeTimer ? "quick" : "main") {
            print("  - Ignoring action for different timer type")
            return
        }
    }
    
    switch nameString {
    case "com.growthlabs.growthmethod.liveactivity.pause":
        if timerState == .running {
            pause()
        }
    case "com.growthlabs.growthmethod.liveactivity.resume":
        if timerState == .paused {
            resume()
        }
    case "com.growthlabs.growthmethod.liveactivity.stop":
        if timerState != .stopped {
            stop()
        }
    default:
        break
    }
}
```

## 8. Remove old handler methods

Delete these methods if they exist:
- `@objc private func handleLiveActivityPauseRequest()`
- `@objc private func handleLiveActivityResumeRequest()`
- `@objc private func handleLiveActivityStopRequest()`

## 9. Update deinit method

Add this line to the deinit method:
```swift
unregisterFromDarwinNotifications()
```

## 10. Remove this line from init

Find and remove:
```swift
await LiveActivityManager.shared.endCorruptedActivities()
```

## Summary

After making these changes:
1. Build the project to check for any remaining errors
2. Ensure LiveActivityManagerSimplified.swift is added to the project
3. Deploy the Firebase function
4. Test on a real device

All references to the old LiveActivityManager should now use LiveActivityManagerSimplified with its simplified API.