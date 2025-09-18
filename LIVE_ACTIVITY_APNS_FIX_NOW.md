# URGENT: Live Activity APNs Fix Required

## Current Issue
The Live Activity push updates are failing with a 500 error because the APNs authentication key is not properly configured in Firebase Functions.

Error:
```
⚠️ LiveActivityPushService: updateLiveActivity failed on attempt 2: FunctionsError(code: FirebaseFunctions.FunctionsErrorCode, errorUserInfo: ["NSLocalizedDescription": "INTERNAL"])
```

## What's Missing
The Firebase Functions config has APNs settings but is missing the actual P8 key content:
```javascript
// Current config (missing auth_key):
{
  "apns": {
    "team_id": "62T6J77P6R",
    "key_id": "3G84L8G52R",
    "bundle_id": "com.growth", 
    "topic": "com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity"
  }
}
```

## Fix Options

### Option 1: Use Environment Variables (Recommended)

1. Create a `.env` file in the functions directory:
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-fresh/functions

# Create .env file with placeholder
cat > .env << 'EOF'
# APNs Configuration
APNS_AUTH_KEY="-----BEGIN PRIVATE KEY-----
YOUR_P8_KEY_CONTENT_HERE
-----END PRIVATE KEY-----"
APNS_KEY_ID=3G84L8G52R
APNS_TEAM_ID=62T6J77P6R
EOF
```

2. Replace `YOUR_P8_KEY_CONTENT_HERE` with your actual P8 key content.

3. Deploy functions:
```bash
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer
```

### Option 2: Download APNs Key from Apple Developer

If you don't have the P8 key:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click on your key (Key ID: 3G84L8G52R) 
3. If you can't download it, create a new key:
   - Click "+" to create new key
   - Name: "Growth Push Notifications"
   - Enable "Apple Push Notifications service (APNs)"
   - Download the .p8 file
   - Note the new Key ID

4. Once you have the P8 file, read its content:
```bash
cat ~/Downloads/AuthKey_XXXXXXXX.p8
```

5. Follow Option 1 to add it to .env file

### Option 3: Temporary Workaround (Not Recommended)

If you need immediate testing without push updates:
- Live Activities will still work locally on the device
- The timer will update every second using the system's built-in timer
- You just won't get remote push updates for pause/resume

## Verification

After deploying with the APNs key:

1. Check Firebase Functions logs:
```bash
firebase functions:log --only updateLiveActivity
```

Look for: "✅ Successfully loaded APNs configuration"

2. Test a timer in the app and verify no more 500 errors

## Important Notes

- The P8 key is sensitive - never commit it to git
- The .env file is already in .gitignore
- Each P8 key can only be downloaded once from Apple
- If lost, you must create a new key in Apple Developer Portal