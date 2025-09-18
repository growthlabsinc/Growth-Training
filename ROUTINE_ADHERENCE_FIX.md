# Routine Adherence Update Fix

## Issue
After completing a session, the routine adherence percentage wasn't updating throughout the app, particularly in the RoutineAdherenceView component.

## Root Cause
The `RoutineAdherenceView` component was only loading adherence data:
1. On initial appear
2. When the time range selector changed
3. When the app came to foreground

It was NOT refreshing when:
- A new session was logged (`sessionLogged` notification)
- Routine progress was updated (`routineProgressUpdated` notification)

## Fix Applied

### RoutineAdherenceView.swift
Added notification listeners to refresh adherence data when sessions are logged:

```swift
.onReceive(NotificationCenter.default.publisher(for: .sessionLogged)) { _ in
    // Reload adherence data when a session is logged
    loadAdherenceData()
}
.onReceive(NotificationCenter.default.publisher(for: .routineProgressUpdated)) { _ in
    // Reload adherence data when routine progress is updated
    loadAdherenceData()
}
```

## Notification Flow

1. **Session Completion**: User completes a session
2. **SessionCompletionViewModel**: 
   - Saves session to Firestore
   - Posts `sessionLogged` notification
   - Updates routine progress if needed
   - Posts `routineProgressUpdated` notification when day is completed

3. **Views that now update**:
   - **RoutineAdherenceView** ✅ (fixed) - Shows adherence percentage and calendar
   - **TodayViewViewModel** ✅ (already working) - Refreshes weekly progress data
   - **ProgressViewModel** ✅ (already working) - Refreshes all progress data  
   - **PracticeTabView** ✅ (already working) - Updates practice progress

## Testing
1. Start a routine with scheduled sessions
2. Complete a session from today's routine
3. Save the session in the completion sheet
4. Verify adherence percentage updates in:
   - Current Routine view (RoutineAdherenceView)
   - Home/Today view (weekly adherence)
   - Progress tab (overall stats)

## Why This Works
- All adherence calculations are done fresh from Firestore data
- The `RoutineAdherenceService.calculateAdherence()` method:
  - Fetches latest session logs
  - Compares with expected sessions for the time range
  - Returns updated adherence percentage
- Notifications ensure UI refreshes immediately after session is saved