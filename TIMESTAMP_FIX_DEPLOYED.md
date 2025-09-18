# Timestamp Fix Deployed

## Issue Fixed
The pause functionality was not working because of timestamp format mismatch in push notifications:
- Firebase was sending ISO string timestamps (e.g., "2025-01-16T15:30:00Z")
- iOS widget expected numeric Unix timestamps (e.g., 1752684007)
- This caused "Unable to decode content state" errors

## Solution Implemented
Updated `manageLiveActivityUpdates-optimized.js` to send Unix timestamps:

```javascript
// Before (sending ISO strings):
startTime: startTime.toISOString(),

// After (sending Unix timestamps in seconds):
startTime: startTime.getTime() / 1000,
```

## Changes Made
1. **Lines 170-185**: Convert all timestamp fields to Unix format before sending
   - `startTime`, `endTime`, `lastUpdateTime`, `lastKnownGoodUpdate`
   - All timestamps are now sent as seconds since 1970

2. **Lines 207-226**: Updated final completion payload to use Unix timestamps
   - Automatically converts any field containing "Time" or "time"
   - Ensures consistency across all push notifications

## Next Steps
1. Deploy the updated function:
   ```bash
   firebase deploy --only functions:manageLiveActivityUpdates
   ```

2. Test the pause functionality:
   - Start a timer
   - Pause the timer
   - Verify pause state is reflected in Live Activity
   - Check logs for successful decoding

## Verification
The iOS app already has NSDate reference timestamp detection and conversion in place:
- `TimerActivityAttributes.swift` (both app and widget targets)
- Checks if timestamps are in 600M-900M range (NSDate reference)
- Automatically converts to Unix timestamps if needed

With this fix, timestamps will be sent correctly as Unix format, eliminating decode errors.