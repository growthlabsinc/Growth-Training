# APNs Environment Fix Deployed

## Issue Identified
The Firebase function was receiving `environment: "dev"` from the iOS app but was checking for `environment === "development"`, causing it to always use the production APNs server with a development key.

## Fix Applied
Updated `functions/liveActivityUpdates.js` to check for both "dev" and "development":
```javascript
const isDevelopment = tokenData?.environment === 'dev' || 
                     tokenData?.environment === 'development' ||
                     tokenData?.bundleId?.includes('.dev');
```

## Deployment Status
✅ Function deployed at 02:25 UTC (January 13, 2025)

## Expected Behavior
When you start a new timer:
1. The app stores push token with `environment: "dev"`
2. Firebase function detects this and uses development APNs server
3. You should see in logs:
   ```
   🔧 APNs Environment Detection:
   - Environment: dev
   - Bundle ID: com.growthlabs.growthmethod
   - Using DEVELOPMENT APNs server first
   
   📱 Using APNs host: api.development.push.apple.com (development)
   ```

## Testing Steps
1. **Clean and rebuild** the app in Xcode with Debug configuration
2. **Start a new timer** (existing timers still have old tokens)
3. **Check logs**: `firebase functions:log --only updateLiveActivity --lines 20`
4. Look for "Using APNs host: api.development.push.apple.com"

## Important Notes
- The iOS app is already forcing `environment: "dev"` in LiveActivityManager.swift
- Entitlements are set to "development"
- Using development APNs key: 378FZMBP8L
- The fix only affects NEW timers (existing tokens won't update)

## If Still Getting 403 Errors
If you still see InvalidProviderToken with the development server:
1. Verify the dev key (378FZMBP8L) in Apple Developer portal
2. Check it has APNs permission enabled
3. Ensure it's not revoked
4. Make sure you're testing with a Debug build on a real device