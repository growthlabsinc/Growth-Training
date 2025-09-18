# Firebase Module Error Fix

## Problem
The error "Missing required module 'GoogleUtilities_NSData'" occurred when trying to import the main app module (`Growth`) into the widget extension to directly call timer services.

## Root Cause
Widget extensions cannot directly access Firebase dependencies from the main app. When we added `import Growth` to TimerControlIntent.swift, it tried to bring in all the main app's dependencies, including Firebase, which aren't available in the widget extension context.

## Solution
Instead of directly calling timer services from the widget, we implemented cross-process communication using:

1. **UserDefaults in App Group**: Store timer actions in shared UserDefaults
2. **Darwin Notifications**: Send notifications to wake up the main app
3. **Observer Pattern**: Main app listens for Darwin notifications and processes actions

## Implementation Details

### TimerControlIntent.swift (Widget Extension)
```swift
// Store action in shared UserDefaults
sharedDefaults.set(action.rawValue, forKey: "widgetTimerAction")
sharedDefaults.set(timerType, forKey: "widgetTimerType")
sharedDefaults.set(Date(), forKey: "widgetActionTime")

// Send Darwin notification to wake app
let notificationName = "com.growthlabs.growthmethod.timerAction.\(action.rawValue)"
CFNotificationCenterPostNotification(...)
```

### TimerService.swift (Main App)
```swift
// Set up Darwin notification observers
private func setupDarwinNotificationObservers() {
    for action in ["pause", "resume", "stop"] {
        CFNotificationCenterAddObserver(...)
    }
}

// Process widget actions when notification received
private func processWidgetAction() {
    // Read action from UserDefaults
    // Execute appropriate timer method
    // Clear processed action
}
```

## Benefits
- No Firebase dependencies in widget extension
- Clean separation between widget and app code
- Reliable cross-process communication
- Actions are processed even when app is in background

## Key Lesson
Widget extensions have limited access to app dependencies. Always use proper IPC (Inter-Process Communication) mechanisms like:
- App Groups (UserDefaults/Files)
- Darwin Notifications
- Push Notifications
Rather than trying to directly import and use main app code.