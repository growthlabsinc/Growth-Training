# Current APNS Configuration

## Active Key Details
- **Key ID**: 55LZB28UY2
- **Key Name**: Growth Method Dev Token
- **Environment**: Sandbox/Development
- **Team ID**: 62T6J77P6R
- **Bundle ID**: com.growthlabs.growthmethod

## Server Configuration
- **APNs Host**: api.development.push.apple.com (Sandbox server)
- **Topic**: com.growthlabs.growthmethod.push-type.liveactivity

## Firebase Configuration
All APNS configuration is stored in Firebase secrets:
- `APNS_AUTH_KEY`: The .p8 private key content
- `APNS_KEY_ID`: 55LZB28UY2
- `APNS_TEAM_ID`: 62T6J77P6R
- `APNS_TOPIC`: com.growthlabs.growthmethod.push-type.liveactivity

## Key Usage
Since we're using the **sandbox key** (55LZB28UY2), we must use:
- **Development APNs server**: `api.development.push.apple.com`
- This is correct for:
  - Development builds
  - TestFlight builds
  - Debug builds from Xcode

## Production Switch
When ready to switch to production (using the DQ46FN4PQU key):
1. Update Firebase secrets:
   ```bash
   firebase functions:secrets:set APNS_KEY_ID
   # Enter: DQ46FN4PQU
   
   firebase functions:secrets:set APNS_AUTH_KEY < /path/to/AuthKey_DQ46FN4PQU.p8
   ```

2. Update any environment-specific configurations to use:
   - Server: `api.push.apple.com`
   - Key: DQ46FN4PQU (Production key)

## Verification
To verify current configuration:
```bash
# Check current key ID
firebase functions:secrets:access APNS_KEY_ID

# Check all APNS secrets
firebase functions:secrets:access APNS_KEY_ID APNS_TEAM_ID APNS_TOPIC
```

## Important Notes
1. **Key-Server Matching**: Sandbox keys MUST use development server, production keys MUST use production server
2. **TestFlight**: Uses sandbox environment, so current configuration is correct
3. **App Store**: Will require production key and server

## Files Updated
- `/functions/.env` - Documentation updated
- `/functions/manageLiveActivityUpdates-fixed.js` - Corrected fallback key
- `/functions/test-dual-key-apns.js` - Corrected test key

All active functions are now consistent with the sandbox key configuration.