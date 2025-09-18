# Timestamp Debug Guide

## The Issue
When pausing the timer, the Live Activity receives timestamps that appear to be NSDate reference timestamps (774M range) instead of Unix timestamps (1752M range).

## Debug Steps

1. **Start a timer and pause it**
2. **Check Firebase Function logs**:
   ```bash
   firebase functions:log --only manageLiveActivityUpdates --lines 50
   ```
   Look for:
   - "📊 Raw contentState from Firestore"
   - "🔍 Converted timestamps"
   - "📋 Converted contentState for iOS"

3. **Check Xcode Console**:
   Look for:
   - "🔍 TimerActivityAttributes.ContentState decoding..."
   - "⚠️ Decoded invalid Unix timestamp"

## What to Verify

### In Firebase Logs:
- Raw contentState should show Firestore Timestamp objects
- Converted timestamps should be Unix timestamps (1752M range)
- Final payload should have Unix timestamps in seconds

### In iOS Logs:
- Incoming timestamps should be in Unix format (1752M range)
- If they're in 774M range, that's NSDate reference format

## Possible Causes

1. **Double conversion**: Timestamps might be converted twice
2. **iOS SDK issue**: The push notification SDK might be converting Unix to NSDate
3. **Encoding issue**: The JSON encoding might be changing the format

## Quick Test

Run this in Firebase console to check stored timestamps:
```javascript
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Replace with your user ID
const userId = '7126AZm26LTJ2w4kfQmYeOAhEpV2';

db.collection('activeTimers').doc(userId).get().then(doc => {
  const data = doc.data();
  console.log('Raw data:', JSON.stringify(data, null, 2));
  
  if (data.contentState) {
    const cs = data.contentState;
    console.log('Start time:', cs.startTime.toDate());
    console.log('Unix timestamp:', cs.startTime.toDate().getTime() / 1000);
  }
});
```