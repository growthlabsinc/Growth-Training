# Firebase APNs Secrets Status

## Current Configuration

| Secret | Value | Status | Notes |
|--------|-------|--------|-------|
| **APNS_KEY_ID** | `DQ46FN4PQU` | ✅ Correct | Version 12 |
| **APNS_TEAM_ID** | `62T6J77P6R` | ✅ Correct | Version 3 |
| **APNS_TOPIC** | `com.growthlabs.growthmethod` | ✅ Fixed | Version 4 (just updated) |
| **APNS_AUTH_KEY** | (Key contents) | ✅ Loaded | Version 17 |

## Recent Changes

1. **APNS_TOPIC** was just updated from:
   - Old: `com.growthlabs.growthmethod.push-type.liveactivity` ❌
   - New: `com.growthlabs.growthmethod` ✅

2. Functions need redeployment to use the new APNS_TOPIC value

## APNs Configuration Summary

- **Key ID**: DQ46FN4PQU (Development/Sandbox key)
- **Team ID**: 62T6J77P6R
- **Bundle ID**: com.growthlabs.growthmethod
- **APNs Server**: api.development.push.apple.com (configured for development)

## Known Issues

1. **InvalidProviderToken (403)**: The DQ46FN4PQU key is not being accepted by Apple's APNs servers
   - This needs to be resolved with Apple Developer Support
   - The key configuration appears correct on our end

2. **TestFlight Consideration**: When uploaded to TestFlight, the app will receive production push tokens
   - Current configuration uses development server
   - May need to switch to production server for TestFlight builds

## Next Steps

1. Deploy functions to use the corrected APNS_TOPIC:
   ```bash
   firebase deploy --only functions
   ```

2. For TestFlight, you may need a production APNs key or a key that works with both environments

3. Contact Apple Developer Support with:
   - Error details (403 InvalidProviderToken)
   - Confirm the key has APNs capability enabled
   - Verify key is associated with correct Team ID and app