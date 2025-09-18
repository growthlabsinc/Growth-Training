# Update APNs Authentication Key Instructions

## Problem
The APNs authentication key in your Firebase functions is from your old personal developer account and is no longer valid after:
- Converting to business developer account (Team ID: 62T6J77P6R)
- Changing bundle ID to `com.growthlabs.growthmethod`
- Creating new certificates

## Solution Steps

### 1. Create New APNs Authentication Key

1. Go to [Apple Developer - Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Click the "+" button to create a new key
3. Name it something like "Growth Method APNs Key"
4. Check "Apple Push Notifications service (APNs)"
5. Click "Continue" then "Register"
6. **IMPORTANT**: Download the `.p8` file immediately (you can only download it once!)
7. Note the Key ID (it will be different from your old `KD9A39PBA7`)

### 2. Update Firebase Functions

Once you have the new key, update `/Users/tradeflowj/Desktop/Dev/growth-fresh/functions/manageLiveActivityUpdates.js`:

```javascript
// Replace the KEY_ID with your new key ID
const KEY_ID = process.env.APNS_KEY_ID || 'YOUR_NEW_KEY_ID_HERE';

// Replace the APNS_KEY with the contents of your new .p8 file
const APNS_KEY = `-----BEGIN PRIVATE KEY-----
[PASTE THE CONTENTS OF YOUR NEW .P8 FILE HERE]
-----END PRIVATE KEY-----`;
```

### 3. Update Environment Files

Also update `/Users/tradeflowj/Desktop/Dev/growth-fresh/functions/.env`:

```
APNS_KEY_ID=YOUR_NEW_KEY_ID_HERE
```

### 4. Deploy the Updated Function

```bash
cd /Users/tradeflowj/Desktop/Dev/growth-fresh/functions
firebase deploy --only functions:manageLiveActivityUpdates
```

### 5. Test

After deployment, the Live Activity timer should start counting down properly instead of staying at 1:00.

## Current Configuration (for reference)
- Team ID: `62T6J77P6R` (correct)
- Bundle ID: `com.growthlabs.growthmethod` (correct)
- Widget Bundle ID: `com.growthlabs.growthmethod.GrowthTimerWidget` (correct)
- APNs Topic: `com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity` (correct)
- **APNs Key: OLD KEY - NEEDS UPDATE**