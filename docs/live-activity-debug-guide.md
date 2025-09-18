# Live Activity Debug Guide

## Debug Messages Added to Firebase Functions

The Firebase Functions now include comprehensive debug logging to help identify and resolve APNs token issues. Here's what to look for in the logs:

### Token Environment Detection
```
🔍 Token environment detection: dev -> Using SANDBOX APNs
```
This message shows which environment was detected and which APNs endpoint will be used.

### APNs Configuration
```
📱 APNs Configuration:
   - Host: api.sandbox.push.apple.com (SANDBOX)
   - Environment: dev
   - Topic: com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity
   - Token (first 20 chars): 8009e6e59f21cbe995d9...
   - Activity ID: 8872E9C1-09D0-4C09-90E2-E736FC55BD76
```
This shows the complete APNs configuration being used for each push notification.

### Error Details
When a BadDeviceToken error occurs:
```
❌ Bad request - invalid payload or headers
  💡 BadDeviceToken - Debug Info:
     - APNs endpoint used: PRODUCTION
     - Environment from token data: dev
     - Topic used: com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity
     - Token (first 20 chars): 8009e6e59f21cbe995d9...

  🚨 Common causes:
     1. Token/endpoint mismatch (dev token → prod endpoint or vice versa)
     2. Wrong topic for the app bundle ID
     3. Token has expired or been invalidated

  📋 To fix for production:
     - Ensure app is built with production provisioning profile
     - Token data should have environment: "production"
     - Topic should match production bundle ID
```

## Environment Mapping

The functions now correctly map these environments to APNs endpoints:

- `dev` → SANDBOX endpoint ✅
- `development` → SANDBOX endpoint
- `staging` → SANDBOX endpoint  
- `production` → PRODUCTION endpoint
- (not specified) → PRODUCTION endpoint

## Production Readiness

When ready to deploy to production:

1. **Ensure production builds send correct environment:**
   - Token data should include `environment: "production"`
   - Bundle ID should be `com.growthtraining.Growth`
   - Widget bundle ID should be `com.growthtraining.Growth.GrowthTimerWidget`

2. **Monitor logs for successful updates:**
   ```
   ✅ Live Activity update sent successfully
      - Activity: 8872E9C1-09D0-4C09-90E2-E736FC55BD76
      - APNs endpoint: PRODUCTION
      - Response: OK
   ```

3. **Known Issues:**
   - Debug builds may show production bundle ID but still need sandbox APNs
   - Always check the `environment` field in token data for correct routing

## Viewing Logs

To view the debug logs:
```bash
# View recent function logs
firebase functions:log -n 100

# Filter for APNs configuration
firebase functions:log -n 100 | grep -A5 -B5 "APNs Configuration"

# Filter for errors
firebase functions:log -n 100 | grep -A10 "BadDeviceToken"
```