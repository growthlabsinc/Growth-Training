# Live Activity Dismissal-Date and Offline Support Implementation

## Overview
This implementation improves Live Activity reliability by using dismissal-date for graceful endings and adding offline support to handle network connectivity issues.

## Key Changes

### 1. Enhanced TimerActivityAttributes
- Added `lastKnownGoodUpdate` to track when the last successful update occurred
- Added `expectedEndTime` for countdown timers to calculate time offline
- Added `isDataStale` computed property to detect when data is outdated

### 2. Stale Date Management
- **Countdown timers**: staleDate = endTime + 10 seconds (minimal updates needed)
- **Countup timers**: staleDate = now + 60 seconds (requires periodic updates)
- Activities automatically show stale indicator after staleDate passes

### 3. Dismissal Date Usage
- Timer completion: dismissalDate = now + 6 seconds (shows completion UI)
- Manual stop: dismissalDate = now + 2 seconds (smooth transition)
- No more abrupt dismissals with `.immediate` policy

### 4. Offline Handling
- Timers continue to work based on local calculations:
  - Countdown: Uses `expectedEndTime` to show accurate remaining time
  - Countup: Uses `startTime` to calculate elapsed time
- Visual "OFFLINE" indicator appears when `isDataStale` is true
- Timer continues functioning even without network updates

### 5. Push Notification Updates
- All push notifications now include `stale-date` in payload
- Completion notifications include both `stale-date` and `dismissal-date`
- Firebase function calculates appropriate dates based on timer type

## Benefits

1. **Better Offline Experience**: Timers work without network connectivity
2. **Graceful Dismissals**: No abrupt disappearances, smooth transitions
3. **Reduced Server Load**: Countdown timers need fewer updates
4. **Visual Feedback**: Users see when data is stale but timer still works
5. **Automatic Cleanup**: Activities dismiss themselves at appropriate times

## Testing Scenarios

1. **Offline Timer Operation**
   - Start timer → Turn off network → Verify timer continues
   - Check that "OFFLINE" indicator appears after 60 seconds

2. **Pause/Resume Offline**
   - Pause timer via widget while offline
   - Resume when online → Verify state syncs correctly

3. **Timer Completion**
   - Let timer complete naturally
   - Verify 6-second completion display before dismissal

4. **Background/Foreground Transitions**
   - Background app with active timer
   - Turn off network
   - Return to foreground → Verify timer state is correct

## Implementation Details

### Files Modified

1. **TimerActivityAttributes.swift** (both app and widget)
   - Added offline support fields
   - Added stale data detection

2. **LiveActivityManager.swift**
   - Calculate and set appropriate stale dates
   - Use dismissal policies instead of immediate dismissal
   - Update all fields including offline support

3. **GrowthTimerWidgetLiveActivity.swift**
   - Show "OFFLINE" indicator when data is stale
   - Continue displaying calculated times

4. **manageLiveActivityUpdates.js**
   - Include stale-date in all push payloads
   - Use dismissal-date for completion scenarios
   - Calculate dates based on timer type

5. **LiveActivityPushService.swift**
   - Include new fields in push payloads
   - Ensure all updates include offline support data

## Future Improvements

1. Add retry logic for failed push updates
2. Queue updates to send when connectivity returns
3. Add more granular stale indicators (e.g., "Last updated 2 min ago")
4. Implement smart update intervals based on remaining time
5. Add user preference for offline behavior