# Practice Progress Bar Fix

## Issue
When a user activates timer for first method and it ends, today's progress bar shows 33%. When second method timer is started, progress bar resets to 0% with no fill.

## Root Cause
The progress bar in PracticeTabView calculates progress based on `nextMethodIndex` from the routine progress. However, when a method was completed through the timer:
1. The `nextMethodIndex` was not being incremented
2. The notification to refresh the UI was not being posted
3. The timer service resets its elapsed time when stopping between methods, causing the progress calculation to show 0%

## Solution
1. Added a new method `incrementMethodIndex` to `RoutineProgressService` that increments the `nextMethodIndex` when a method is completed
2. Updated `DailyRoutineView` to call this method when a timer completes and post the `routineProgressUpdated` notification
3. Added routine progress refresh functionality to `PracticeTabViewModel` with proper UI updates
4. Made `PracticeTabView` listen for routine progress updates to refresh the display
5. Added debug logging to track progress calculation issues

## Code Changes

### 1. RoutineProgressService.swift
Added new method to increment the method index:
```swift
/// Increment the nextMethodIndex when a method is completed
func incrementMethodIndex(userId: String, routineId: String, completion: ((RoutineProgress?) -> Void)? = nil) {
    fetchProgress(userId: userId, routineId: routineId) { [weak self] progress in
        guard var progress = progress else {
            completion?(nil)
            return
        }
        
        // Increment the method index
        progress.nextMethodIndex += 1
        progress.updatedAt = Date()
        
        // Mark as started if not already
        if progress.startedDate == nil {
            progress.startedDate = Date()
        }
        
        print("RoutineProgressService: Incremented nextMethodIndex to \(progress.nextMethodIndex)")
        
        self?.saveProgress(progress) { error in
            if let error = error {
                print("RoutineProgressService: Error saving incremented progress: \(error)")
                completion?(nil)
            } else {
                completion?(progress)
            }
        }
    }
}
```

### 2. DailyRoutineView.swift
- Added `routinesViewModel` as a parameter
- Updated `handleTimerCompletion()` to increment the method index:
```swift
// Update routine progress to increment nextMethodIndex
if let userId = Auth.auth().currentUser?.uid,
   let routineId = routinesViewModel.selectedRoutineId {
    RoutineProgressService.shared.incrementMethodIndex(userId: userId, routineId: routineId) { updatedProgress in
        if let progress = updatedProgress {
            print("DailyRoutineView: Updated routine progress - nextMethodIndex: \(progress.nextMethodIndex)")
            // Update the routinesViewModel's progress
            DispatchQueue.main.async {
                self.routinesViewModel.routineProgress = progress
            }
        }
    }
}
```

### 3. PracticeTabViewModel.swift
Added refresh method:
```swift
/// Refresh the current progress from the service
func refreshProgress() {
    loadCurrentRoutineDay()
}
```

### 4. PracticeTabView.swift
- Updated to pass `routinesViewModel` to `DailyRoutineView`
- Added listener for routine progress updates:
```swift
.onReceive(NotificationCenter.default.publisher(for: .routineProgressUpdated)) { _ in
    // Refresh the progress when routine progress is updated
    viewModel.refreshProgress()
}
```

## Result
Now when a user completes a method via timer:
1. The `nextMethodIndex` is incremented in the routine progress
2. The progress bar maintains its filled state (e.g., 33% after first method)
3. Starting the second method timer doesn't reset the progress bar
4. The progress continues to increase smoothly during the second method

## Testing
1. Start a multi-method routine
2. Complete the first method timer - progress bar should show 33%
3. Start the second method timer - progress bar should remain at 33% and increase from there
4. Complete all methods to see 100% progress