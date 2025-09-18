# Timer Completion Navigation Fix

## Issue
When a timer completes and the session is logged via the completion sheet, users were being taken to the Home view instead of returning to the Practice view where they started.

## Root Cause
The `SmartNavigationService.completePracticeFlow()` method was calling `executeSmartReturn()` which used `NavigationContext.determineReturnDestination()`. This method would return `.dashboard` for routine-based sessions, causing users to be navigated away from the Practice tab.

## Solution
Modified `SmartNavigationService.completePracticeFlow()` to always navigate to the Practice tab after timer completion, regardless of the session type or origin.

### Changes in SmartNavigationService.swift
```swift
/// Completes the current practice flow
func completePracticeFlow() {
    // Add any completion effects
    provideSuccessHapticFeedback()
    
    // Always return to practice tab after timer completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        // Clear practice flow context
        self?.navigationContext.practiceFlowActive = false
        
        // Always navigate to practice tab
        NotificationCenter.default.post(
            name: Notification.Name("switchToPracticeTab"),
            object: nil
        )
        
        // Set pending navigation
        self?.pendingNavigation = PendingNavigation(destination: .practiceTab, delay: 0.3)
        
        // Clear pending navigation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self?.pendingNavigation = nil
        }
    }
}
```

## Results
- Users now always return to the Practice tab after completing a timer session
- This behavior is consistent regardless of whether they:
  - Started from a routine
  - Started from quick practice
  - Completed all methods or partial methods
  - Logged or dismissed the session
- The navigation feels more natural as users stay in the context where they were practicing

## Implementation Details
- The fix bypasses the smart return logic that would determine destination based on context
- Directly posts a notification to switch to the Practice tab
- MainView already has the listener set up for this notification
- Maintains haptic feedback for a smooth user experience