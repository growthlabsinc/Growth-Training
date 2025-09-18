# Darwin Notifications Re-enabled for Live Activity Controls

## Issue
- Only the first pause button press worked in Live Activity
- Subsequent button presses didn't trigger any updates
- Firebase logs showed push updates were being sent successfully

## Root Cause
The Live Activity widget buttons use Darwin notifications to communicate with the main app. When we disabled Darwin notifications, the widget's `TimerControlIntent` was posting notifications that weren't being observed by the main app.

## Solution
Re-enabled Darwin notifications specifically for Live Activity button controls:

### 1. Re-enabled Darwin Notification Setup in LiveActivityManager
**File:** `Growth/Features/Timer/Services/LiveActivityManager.swift` (Line 429)
```swift
// Setup Darwin notification observers for widget button controls
// Note: These are needed for the Live Activity buttons to communicate with the main app
setupDarwinNotificationObservers()
```

### 2. Re-enabled TimerIntentObserver Initialization
**File:** `Growth/Application/AppDelegate.swift` (Line 47)
```swift
// Initialize TimerIntentObserver for widget button communication
_ = TimerIntentObserver.shared
```

## How It Works Now

1. **User presses button in Live Activity** (pause/resume/stop)
2. **Widget's TimerControlIntent**:
   - Updates shared UserDefaults with action details
   - Posts Darwin notification to alert main app
3. **Main app receives Darwin notification** via:
   - `LiveActivityManager.setupDarwinNotificationObservers()`
   - `TimerIntentObserver` 
4. **Main app processes the action**:
   - Calls appropriate timer service method (pause/resume/stop)
   - Sends push notification to update Live Activity UI

## Why Darwin Notifications Are Needed

- **Cross-process communication**: Widget extension and main app are separate processes
- **Real-time responsiveness**: Darwin notifications provide immediate IPC (Inter-Process Communication)
- **iOS 17+ App Intents**: The button controls use App Intents which rely on Darwin notifications to trigger main app actions
- **Push notifications alone aren't sufficient**: They update the UI but don't trigger app logic

## Note
While we use Firebase push notifications to update the Live Activity UI, Darwin notifications are essential for the widget buttons to communicate user actions back to the main app. This is a standard iOS pattern for widget-to-app communication.