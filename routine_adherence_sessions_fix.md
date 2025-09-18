# Routine Adherence Sessions Count Fix

## Issue
Routine adherence was showing "1 of 1 sessions" when 3 sessions were completed on the same day. The system was counting days with activities instead of individual sessions/methods.

## Root Cause
The `calculateExpectedSessions` method in RoutineAdherenceService was counting each scheduled day as 1 expected session, regardless of how many methods were scheduled for that day. Similarly, completed sessions were being counted by days rather than individual sessions.

## Fix Applied

### 1. Updated Expected Sessions Calculation
Changed the logic to count individual methods per day:

```swift
// OLD: Counted each day as 1 session
if routine.schedule.contains(where: { $0.day == dayNumber }) {
    expectedCount += 1
}

// NEW: Counts actual methods scheduled per day
if let daySchedule = routine.schedule.first(where: { $0.day == dayNumber }) {
    if daySchedule.isRestDay {
        expectedCount += 1  // Rest days count as 1
    } else {
        let methodCount = daySchedule.methods.count
        expectedCount += methodCount  // Count each method
    }
}
```

### 2. Updated Completed Sessions Calculation
Changed from counting days with sessions to counting actual session logs:

```swift
// OLD: Counted days with any sessions
let completedSessions = sessionDetails.values.filter { $0 }.count

// NEW: Counts actual logged sessions
let completedSessions = sessionLogs.count
```

## Expected Result
- If a routine has 3 methods scheduled for a day, it will show "0 of 3 sessions" initially
- As each method is completed, it will update: "1 of 3", "2 of 3", "3 of 3"
- The adherence percentage will correctly reflect the ratio of completed sessions to expected sessions
- Rest days continue to count as 1 expected session and are automatically marked complete

## Note
The `sessionDetails` dictionary still tracks completion by day for calendar visualization, but the actual counts now reflect individual sessions rather than days.