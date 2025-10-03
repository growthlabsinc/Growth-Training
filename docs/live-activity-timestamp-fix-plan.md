# Live Activity Timestamp Fix Plan

## Root Cause Analysis

The Live Activity is failing due to timestamp encoding issues:

1. **Main App**: Uses `timeIntervalSince1970` (Unix timestamps)
   - Example: 1752628500 (July 16, 2025)

2. **Widget**: Interprets timestamps as `timeIntervalSinceReferenceDate` (NSDate reference)
   - Example: 774321300 (July 16, 1994)
   - Difference: 978307200 seconds (between 1970 and 2001)

3. **Push Notifications**: Send Unix timestamps in seconds
   - Firebase function sends timestamps correctly
   - Widget fails to decode them properly

## The Issue Flow

1. Main app creates Live Activity with Date objects
2. ActivityKit encodes dates using NSDate reference (2001)
3. Widget receives and decodes using Unix reference (1970)
4. Validation fails (dates appear to be from 1994)
5. Widget falls back to current date + 1 hour
6. Timer shows 1:00:00 instead of 0:01:00
7. Live Activity gets dismissed due to decoding errors

## Solution

### Option 1: Force Unix Timestamps Everywhere
- Ensure all date encoding uses `timeIntervalSince1970`
- Modify TimerActivityAttributes to handle this consistently

### Option 2: Use ISO8601 Date Strings
- Encode dates as strings to avoid reference date issues
- Parse them in both main app and widget

### Option 3: Fix the Decoding Logic
- Detect and convert between reference dates
- Add 978307200 when needed

## Recommended Fix

Use Option 1 - Force Unix timestamps everywhere:

1. **Main App**: Already uses Unix timestamps
2. **Widget**: Update decoding to expect Unix timestamps
3. **Push Notifications**: Already use Unix timestamps

This ensures consistency across all components.