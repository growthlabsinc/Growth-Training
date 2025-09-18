# Live Activity Stop Button Session Completion Implementation

## Overview
This document describes the implementation of showing the session completion sheet when the user presses stop on the Live Activity widget and returns to the app.

## Problem
When a user pressed the stop button on the Live Activity widget, the timer would stop but the session completion prompt would not be shown when returning to the app. The session data would be lost.

## Solution
Modified the timer flow to detect when stop was pressed from the Live Activity and trigger the session completion prompt.

## Implementation Details

### 1. TimerViewModel Changes (`Growth/Features/Timer/ViewModels/TimerViewModel.swift`)

#### Added Properties:
```swift
@Published var wasStoppedFromLiveActivity = false
private var _lastCapturedElapsedTime: TimeInterval = 0
private var _lastCapturedStartTime: Date = Date()

var lastCapturedElapsedTime: TimeInterval {
    return _lastCapturedElapsedTime
}

var lastCapturedStartTime: Date {
    return _lastCapturedStartTime
}
```

#### Modified stopTimer Method:
- Added `fromLiveActivity` parameter to distinguish between in-app stop and Live Activity stop
- Captures elapsed time, method, and start time before stopping
- Sets `wasStoppedFromLiveActivity` flag when stopped from Live Activity
- Stores captured values for later use by the completion flow

#### Updated Notification Handler:
- Modified the `.timerStopRequested` notification handler to call `stopTimer(fromLiveActivity: true)`

### 2. TimerView Changes (`Growth/Features/Timer/Views/TimerView.swift`)

#### Added onChange Observer:
```swift
.onChange(of: viewModel.wasStoppedFromLiveActivity) { wasStoppedFromLiveActivity in
    if wasStoppedFromLiveActivity {
        viewModel.wasStoppedFromLiveActivity = false
        
        if let method = viewModel.getCurrentMethod() {
            completionViewModel.completeSession(
                methodId: method.id,
                duration: viewModel.lastCapturedElapsedTime,
                startTime: viewModel.lastCapturedStartTime,
                variation: method.title
            )
        }
    }
}
```

This observer:
- Watches for the `wasStoppedFromLiveActivity` flag
- Triggers the session completion flow using captured values
- Shows the `SessionCompletionPromptView` sheet

### 3. TimerIntentObserver Changes (`Growth/Features/Timer/Services/TimerIntentObserver.swift`)

#### Simplified Stop Handling:
- Removed direct call to `TimerService.shared.stop()`
- Now only posts the notification and lets TimerViewModel handle the stop
- This ensures the elapsed time is captured before the timer is reset

## User Flow

1. User starts a timer in the app
2. App goes to background, Live Activity appears
3. User presses stop button on Live Activity
4. Live Activity sends Darwin notification
5. `TimerIntentObserver` receives notification and posts `.timerStopRequested`
6. `TimerViewModel` receives notification and calls `stopTimer(fromLiveActivity: true)`
7. Timer captures current state and sets `wasStoppedFromLiveActivity = true`
8. `TimerView` observes the flag change and triggers `completionViewModel.completeSession()`
9. Session completion sheet appears when user returns to app
10. User can log their session or dismiss

## Benefits

1. **No Lost Sessions**: Sessions stopped from Live Activity are now properly captured
2. **Consistent UX**: Same completion flow whether stopped in-app or from Live Activity
3. **Proper State Management**: Elapsed time and session data are preserved
4. **User Choice**: Users can still choose to log or dismiss their session

## Testing

To test this implementation:

1. Start a timer with a method selected
2. Put app in background to show Live Activity
3. Press stop button on Live Activity
4. Return to app
5. Verify session completion prompt appears with correct duration
6. Test both logging and dismissing the session

## Future Considerations

1. Could extend this pattern to handle pause/resume from Live Activity
2. Consider adding analytics to track how often users stop from Live Activity
3. Could show different UI for sessions stopped externally vs in-app