# Live Activity Timestamp Fix - January 2025

## Issues Fixed

### 1. Timestamp Format Issue
**Problem**: Firebase was sending timestamps in various formats (Firestore timestamps with `seconds` and `nanoseconds` fields), but iOS expects ISO 8601 strings.

**Solution**: Updated all Firebase functions to convert timestamps to ISO 8601 format before sending to iOS:
- Added comprehensive `toISOString()` helper that handles:
  - Firestore timestamps (with `.toDate()` method)
  - Firestore JSON timestamps (with `seconds` or `_seconds` properties)
  - Unix timestamps (both seconds and milliseconds)
  - Date objects
  - Existing ISO strings

### 2. Remaining Time Calculation Issue
**Problem**: When resuming a paused timer, the remaining time showed 3594 seconds (nearly 1 hour) instead of the actual remaining time.

**Root Cause**: The Firebase functions were using Unix timestamps (seconds since 1970) which iOS was interpreting as NSDate reference timestamps (seconds since 2001), causing a ~31 year offset.

**Solution**: 
1. Changed all timestamp fields in push notifications to use ISO 8601 strings
2. Updated the iOS decoder to properly handle ISO strings from Firebase
3. Ensured consistent timestamp format across all Live Activity updates

## Files Modified

### Firebase Functions
1. **functions/liveActivityUpdates.js**
   - Updated `toISOString()` helper to handle Firestore timestamp objects
   - Changed all timestamp conversions to use ISO strings instead of Unix timestamps
   - Added support for `seconds` property in Firestore timestamps

2. **functions/manageLiveActivityUpdates.js**
   - Changed `pushContentState` to use ISO strings for all date fields
   - Updated completion state to use ISO strings
   - Fixed timestamp conversions in `sendTimerUpdate()`

### iOS App
- **GrowthTimerWidget/TimerActivityAttributes.swift** already has proper ISO string handling in the decoder

## Technical Details

### Before (Unix timestamps):
```javascript
startTime: Math.floor(startTime.getTime() / 1000),  // e.g., 1737000000
endTime: Math.floor(endTime.getTime() / 1000),      // Unix seconds
```

### After (ISO strings):
```javascript
startTime: startTime.toISOString(),  // e.g., "2025-01-17T12:00:00.000Z"
endTime: endTime.toISOString(),      // ISO 8601 format
```

## Testing

To verify the fix:
1. Start a timer in the app
2. Check Live Activity displays correct times
3. Pause the timer
4. Resume the timer - remaining time should be accurate
5. Let timer complete - completion state should show properly

## Deployment

Functions have been deployed:
- updateLiveActivity
- updateLiveActivityTimer
- onTimerStateChange
- manageLiveActivityUpdates

No iOS app changes required - the existing ISO string decoder handles the new format correctly.
