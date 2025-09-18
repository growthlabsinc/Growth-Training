# Live Activity APNs Configuration Fix

## Problem
Getting 500 error from `updateLiveActivity` cloud function. This is likely due to missing APNs authentication key configuration.

## Root Cause
The cloud function needs an APNs authentication key to send push notifications to Live Activities, but it's not finding the key in the environment.

## Solution

### Step 1: Check if APNs Key Exists
First, check if you have the APNs auth key file:
```bash
ls -la ~/Desktop/Dev/growth-fresh/AuthKey*.p8
```

### Step 2: Set Firebase Functions Config
If you have the auth key, set it in Firebase Functions config:

```bash
# Read the auth key file
APNS_KEY=$(cat ~/Desktop/Dev/growth-fresh/AuthKey_3G84L8G52R.p8)

# Set in Firebase config
firebase functions:config:set apns.auth_key="$APNS_KEY" \
  apns.key_id="3G84L8G52R" \
  apns.team_id="62T6J77P6R"

# Deploy the config
firebase deploy --only functions
```

### Step 3: Alternative - Use Environment Variable
If Firebase config doesn't work, use environment variables:

1. Create `.env` file in functions directory:
```bash
cd functions
echo "APNS_AUTH_KEY=\"$(cat ~/Desktop/Dev/growth-fresh/AuthKey_3G84L8G52R.p8)\"" > .env
echo "APNS_KEY_ID=3G84L8G52R" >> .env
echo "APNS_TEAM_ID=62T6J77P6R" >> .env
```

2. Update `liveActivityUpdates.js` to load from .env:
```javascript
require('dotenv').config();
```

3. Deploy functions:
```bash
firebase deploy --only functions
```

### Step 4: Verify Configuration
Check Firebase Functions logs:
```bash
firebase functions:log --only updateLiveActivity
```

Look for:
- "✅ Successfully loaded APNs configuration"
- Or error: "❌ Failed to load APNs configuration"

## APNs Key Details
Based on the code, these are the expected values:
- Key ID: `3G84L8G52R`
- Team ID: `62T6J77P6R`
- Bundle ID: `com.growthlabs.growthmethod`
- Widget Bundle ID: `com.growthlabs.growthmethod.GrowthTimerWidget`
- Topic: `com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity`

## Testing
After configuring:
1. Start a timer in the app
2. Check console for Live Activity token
3. Pause/resume timer
4. Check Firebase Functions logs for success/errors

## If You Don't Have the APNs Key
1. Go to Apple Developer Portal
2. Navigate to Keys
3. Create a new key with "Apple Push Notifications service (APNs)" capability
4. Download the .p8 file
5. Note the Key ID
6. Follow steps above with your new key