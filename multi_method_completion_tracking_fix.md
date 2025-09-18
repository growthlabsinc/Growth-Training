# Multi-Method Session Completion Tracking Fix

## Issue
After completing the second method in a multi-method session, the completion sheet was showing "1 of 3 methods completed" instead of "2 of 3 methods completed". Additionally, the method list was not being displayed on the completion sheet.

## Root Causes
1. **Session Progress Reset**: The `completeLogging()` method was resetting `sessionProgress = nil` after logging each method, causing the session to lose track of previously completed methods
2. **Method List Display**: The completion sheet was only showing methods where `started = true`, and the pre-populated methods weren't being properly marked as started
3. **Session Recreation**: The session tracking was being reset between methods, losing the accumulated progress

## Solutions Implemented

### 1. Fixed Session Progress Reset
Modified `SessionCompletionViewModel.completeLogging()` to only reset session progress when all methods are complete:

```swift
private func completeLogging() {
    isLoggingSession = false
    isShowingCompletionPrompt = false
    
    // Only reset session progress if we've completed all methods or it's not a multi-method session
    if let progress = sessionProgress {
        if progress.sessionType != .multiMethod || 
           progress.completedMethods >= progress.totalMethods {
            sessionProgress = nil
            navigationService.completePracticeFlow()
        } else {
            // Keep session progress for remaining methods
        }
    }
}
```

### 2. Fixed Method Started Tracking
Updated `markMethodStarted()` to properly update existing pre-populated methods:

```swift
if let index = progress.methodDetails.firstIndex(where: { $0.methodId == methodId }) {
    // Update existing method to mark as started
    progress.methodDetails[index].started = true
} else {
    // Add new method if it doesn't exist
    // ...
}
```

### 3. Updated Method List Display
Modified `SessionCompletionPromptView` to show all methods, not just started ones:

```swift
ForEach(sessionProgress.methodDetails, id: \.methodId) { method in
    HStack {
        Image(systemName: method.completed ? "checkmark.circle.fill" : "circle")
        Text(method.methodName)
        // Show all methods with appropriate styling
    }
}
```

## Result
Now when completing methods in a multi-method session:
1. **First method completion**: Shows "1 of 3 methods completed" with full method list
2. **Second method completion**: Shows "2 of 3 methods completed" with updated checkmarks
3. **Third method completion**: Shows "All 3 methods completed" with all checkmarks
4. Session progress persists throughout the entire routine
5. Method list is always visible showing completion status

## Testing Steps
1. Start a 3-method routine
2. Complete first method → Completion sheet shows "1 of 3" with method list
3. Log and continue → Progress persists
4. Complete second method → Completion sheet shows "2 of 3" with updated list
5. Complete third method → Shows final completion with all methods checked