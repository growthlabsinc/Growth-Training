# Live Activity 1994 Date Issue - Debugging and Fix Summary

## Problem Description
When the pause button is pressed in the Live Activity, the content state contains dates from 1994 (e.g., "lastKnownGoodUpdate":"1994-07-15T21:41:44Z"), causing "Unable to decode content state" errors.

## Root Cause
The issue stems from several factors:
1. The widget's `TimerActivityAttributes` didn't have proper date validation in its decoder
2. When Live Activities are backgrounded or restored, dates can be corrupted or uninitialized
3. Unix timestamps near 0 create dates around 1970, which can be further corrupted to 1994

## Fixes Applied

### 1. Added DateValidationHelper
Created `GrowthTimerWidget/Helpers/DateValidationHelper.swift` to:
- Validate dates (reject anything before Jan 1, 2020)
- Repair invalid dates by replacing them with current date
- Validate time intervals (0-24 hours range)

### 2. Enhanced LiveActivityPushService
Updated `sendStateChangeUpdate` to:
- Log all incoming date values for debugging
- Validate dates before creating updated state
- Ensure dates are never from 1994 when sending to Firebase
- Added comprehensive validation before encoding

### 3. Updated TimerActivityAttributes Decoding
Both main app and widget versions now:
- Validate Unix timestamps during decoding (reject < 1577836800)
- Validate Date objects after decoding
- Replace invalid dates with sensible defaults
- Log when invalid dates are detected and fixed

### 4. Enhanced Firebase Function
Updated `liveActivityUpdates-no-optional-secrets.js` to:
- Log and validate incoming date fields
- Detect dates from 1994 or earlier
- Report invalid dates in function logs

### 5. Fixed Widget's TimerActivityAttributes
Added custom decoder to widget's version to:
- Match the main app's validation logic
- Prevent 1994 dates from being decoded
- Ensure all dates are validated on widget side

## Debugging Tools Added

### Debug Script
Created `scripts/debug-timer-dates.sh` to find:
- Small timestamp values that could cause 1994 dates
- Problematic Date initializations
- Zero TimeInterval values
- Epoch date references

## Key Validation Points

1. **Minimum Valid Date**: January 1, 2020 (timestamp: 1577836800)
2. **Maximum Reasonable Elapsed Time**: 24 hours
3. **Default Duration for Invalid Countdown**: 1 hour

## Testing the Fix

1. Start a timer and let the Live Activity appear
2. Press the pause button in the Live Activity
3. Check logs for any 1994 date warnings
4. Verify the timer pauses correctly
5. Resume and verify dates are still valid

## Monitoring

Look for these log messages:
- `⚠️ DateValidationHelper: Invalid date detected`
- `⚠️ Decoded invalid [field]: [date], using current date`
- `⚠️ LiveActivityPushService: [field] still invalid, using current time`
- `❌ [updateLiveActivity] Invalid dates detected`

## Prevention

1. Always use `Date()` instead of `Date(timeIntervalSince1970: 0)`
2. Validate all dates from external sources (push notifications, decoders)
3. Use DateValidationHelper when handling Live Activity state
4. Add logging to track date values through the system