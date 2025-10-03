# APNs Setup for Live Activity Push Updates

This guide explains how to configure Apple Push Notification service (APNs) for Live Activity push updates in the Growth app.

## Prerequisites

You need:
- Apple Developer account with APNs enabled
- APNs authentication key (.p8 file)
- Your Team ID and Key ID from Apple Developer portal

## Your Configuration

Based on the information provided:
- **Team ID**: `62T6J77P6R`
- **Key ID**: `3G84L8G52R`
- **Key File**: `AuthKey_3G84L8G52R.p8`

## Setup Steps

### 1. Navigate to Functions Directory
```bash
cd /Users/tradeflowj/Desktop/Growth/functions
```

### 2. Run the Setup Script
```bash
./setup-apns.sh /Users/tradeflowj/Downloads/AuthKey_3G84L8G52R.p8
```

This script will:
- Set Firebase Functions configuration
- Create a local .env file for testing
- Configure the APNs authentication

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

### 4. Verify Configuration
After deployment, your Live Activities should receive push updates when:
- Timer state changes (start, pause, resume, stop)
- Timer updates while running
- App goes to background

## Manual Setup (Alternative)

If you prefer manual setup:

### 1. Set Firebase Functions Config
```bash
firebase functions:config:set \
  apns.team_id="62T6J77P6R" \
  apns.key_id="3G84L8G52R" \
  apns.topic="com.growth.GrowthTimerWidget.push-type.liveactivity"
```

### 2. Upload APNs Key
```bash
# Read the key file
KEY_CONTENT=$(cat /Users/tradeflowj/Downloads/AuthKey_3G84L8G52R.p8)

# Set the key in config (be careful with special characters)
firebase functions:config:set apns.auth_key="$KEY_CONTENT"
```

### 3. Deploy
```bash
firebase deploy --only functions
```

## Troubleshooting

### Common Issues

1. **"INTERNAL" errors in logs**
   - APNs key not properly configured
   - Check Firebase Functions logs: `firebase functions:log`

2. **"UNAUTHENTICATED" errors**
   - Wrong Team ID or Key ID
   - Expired or revoked APNs key

3. **Live Activity not updating**
   - Check if push token is being saved to Firestore
   - Verify topic matches widget bundle ID
   - Ensure device has internet connection

### Debug Commands

View current configuration:
```bash
firebase functions:config:get
```

View function logs:
```bash
firebase functions:log --only updateLiveActivity
```

Test locally with emulator:
```bash
firebase emulators:start --only functions
```

## Security Notes

- Never commit your .p8 file to version control
- Keep your Team ID and Key ID secure
- Use Firebase Functions config or Secret Manager for production
- Rotate APNs keys periodically

## Widget Bundle IDs

Make sure the topic matches your widget bundle ID:

- **Production**: `com.growth.GrowthTimerWidget.push-type.liveactivity`
- **Development**: `com.growth.dev.GrowthTimerWidget.push-type.liveactivity`
- **Staging**: `com.growth.staging.GrowthTimerWidget.push-type.liveactivity`

The topic format is: `[widget-bundle-id].push-type.liveactivity`