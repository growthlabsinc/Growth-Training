# Live Activity Development Setup Guide

## Date: 2025-09-10

## Overview
Complete setup for Live Activity development with proper APNS configuration, diagnostic tools, and monitoring.

## Development APNS Configuration

### Keys Available
- **Development Key**: `AuthKey_55LZB28UY2.p8` (for Xcode builds)
- **Production Key**: `AuthKey_DQ46FN4PQU.p8` (for TestFlight/App Store)

### Key Details
- **Team ID**: X3GR4M63VQ
- **Bundle ID**: com.growthlabs.growthmethod
- **Topic**: com.growthlabs.growthmethod.push-type.liveactivity

## Environment Detection

The app automatically detects the environment:

```swift
private func getCurrentAPNSEnvironment() -> String {
    #if DEBUG
    return "development"  // Uses api.development.push.apple.com
    #else
    // TestFlight or App Store
    return "production"   // Uses api.push.apple.com
    #endif
}
```

## Setup Instructions

### 1. Configure Firebase Secrets
```bash
# Run the setup script
./setup_dev_apns.sh

# Or manually set secrets
firebase functions:secrets:set APNS_AUTH_KEY_55LZB28UY2 < functions/AuthKey_55LZB28UY2.p8
firebase functions:secrets:set APNS_KEY_ID "55LZB28UY2"
firebase functions:secrets:set APNS_TEAM_ID "X3GR4M63VQ"
```

### 2. Deploy Firebase Functions
```bash
cd functions
firebase deploy --only functions
```

### 3. Run in Xcode
1. Select **Debug** build configuration
2. Build and run on physical device (Live Activities don't work in simulator)
3. The app will automatically use development APNS server

## Diagnostic Tools

### 1. Live Activity Diagnostic
```bash
# Run comprehensive diagnostics
./diagnose_live_activity.sh
```

This checks:
- ✅ Info.plist configuration
- ✅ APNS keys presence
- ✅ Firebase configuration
- ✅ Live Activity logs
- ✅ Push notification logs

### 2. Real-Time Monitor
```bash
# Monitor Live Activity in real-time with color coding
./monitor_live_activity.sh
```

Features:
- 🔴 Red: Errors and failures
- 🟢 Green: Success messages
- 🟡 Yellow: Push notifications
- 🔵 Blue: Timer actions
- 🟣 Purple: Live Activity events
- 🔑 Cyan: Token events

### 3. Manual Log Monitoring
```bash
# Live Activity specific logs
log stream --predicate 'subsystem == "com.apple.ActivityKit"' --style compact --info --debug

# Widget extension logs
log stream --predicate 'process == "GrowthTimerWidget"' --style compact --info --debug

# Push notification logs
log stream --predicate 'subsystem == "com.apple.pushkit"' --style compact --info --debug
```

## Common Issues & Solutions

### Issue 1: Push Token Not Received
**Symptoms**: No push token in logs
**Solution**:
1. Ensure physical device (not simulator)
2. Check push notification permissions
3. Verify entitlements include push notifications

### Issue 2: BadDeviceToken Error
**Symptoms**: Firebase logs show "BadDeviceToken"
**Solution**:
1. Wrong environment - development token sent to production server
2. Fix: Ensure DEBUG build uses development server

### Issue 3: Live Activity Not Appearing
**Symptoms**: Timer starts but no Live Activity
**Solution**:
1. Check Info.plist has `NSSupportsLiveActivities = YES`
2. Verify iOS 16.1+ device
3. Check Activity creation logs for errors

### Issue 4: Pause/Resume Not Working
**Symptoms**: Buttons don't respond after 2-3 cycles
**Solution**:
1. Token persistence issue - already fixed
2. Check frequent updates enabled in Info.plist
3. Monitor push delivery in Firebase logs

## Log Patterns to Watch

### Successful Flow
```
✅ Live Activity started: E23D9E8A-4DC8-478B-98BA-77498BDCDD63
🔑 New Live Activity push token received
📤 Sending push update via Firebase
✅ Push update sent successfully
⏱️ Timer paused in Live Activity
```

### Error Patterns
```
❌ Failed to start Live Activity: ActivityKit not available
❌ Failed to sync push token: network error
❌ Push update failed: INTERNAL
```

## Testing Checklist

### Development Build
- [ ] Build with Debug configuration
- [ ] Deploy to physical device
- [ ] Start monitoring: `./monitor_live_activity.sh`
- [ ] Start timer in app
- [ ] Verify Live Activity appears
- [ ] Test pause/resume 10+ times
- [ ] Check logs for errors

### Push Notification Flow
- [ ] Token generated and logged
- [ ] Token synced to Firebase
- [ ] Push updates sent successfully
- [ ] Live Activity updates visually

### Environment Verification
- [ ] Logs show "development" environment
- [ ] Using api.development.push.apple.com
- [ ] Development key ID: 55LZB28UY2

## Firebase Functions Configuration

The functions automatically detect environment:

```javascript
// In liveActivityUpdates.js
const devKey = process.env.APNS_AUTH_KEY_55LZB28UY2;  // Development
const prodKey = process.env.APNS_AUTH_KEY_DQ46FN4PQU; // Production

// Select based on token environment
if (tokenData?.environment === 'development') {
    // Use development server and key
    apnsHost = 'api.development.push.apple.com';
    apnsKey = devKey;
}
```

## Quick Commands

```bash
# Start monitoring
./monitor_live_activity.sh

# Run diagnostics
./diagnose_live_activity.sh

# Check Firebase logs
firebase functions:log --lines 50

# Deploy functions
firebase deploy --only functions

# Filter for Live Activity errors
log stream --predicate 'eventMessage CONTAINS "Live Activity" AND eventMessage CONTAINS[c] "error"'
```

## Summary

The development environment is now properly configured with:
- ✅ Development APNS key (55LZB28UY2)
- ✅ Automatic environment detection
- ✅ Diagnostic tools for troubleshooting
- ✅ Real-time monitoring with color coding
- ✅ Comprehensive error handling
- ✅ Token persistence across sessions

Run `./monitor_live_activity.sh` while testing to see real-time Live Activity behavior with color-coded logs.