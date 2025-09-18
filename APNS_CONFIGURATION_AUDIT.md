# APNs Configuration Audit Results

## Current State Analysis

### 1. **Key Inventory**
Your Apple Developer account has two APNs keys:
- **`55LZB28UY2`** - "Growth Method Dev Token" (Sandbox)
- **`DQ46FN4PQU`** - "Growth Method Token" (Production)

### 2. **Firebase Configuration Conflicts**

#### Firebase Config (`functions:config:get`):
```json
{
  "key_id": "DQ46FN4PQU",  // Production key
  "team_id": "62T6J77P6R",
  "bundle_id": "com.growthlabs.growthmethod"
}
```

#### Firebase Secrets:
- **APNS_KEY_ID**: `55LZB28UY2` (Sandbox key)
- **APNS_AUTH_KEY**: Version 21 (should be AuthKey_55LZB28UY2.p8)
- **APNS_TEAM_ID**: Version 3

### 3. **Function Configurations**

| Function | Default Key | Server | Status |
|----------|------------|--------|---------|
| `updateLiveActivitySimplified.js` | `55LZB28UY2` | development | ✅ Correct |
| `manageLiveActivityUpdates.js` | `DQ46FN4PQU` | development | ❌ Mismatch |
| `liveActivityUpdates.js` | No default | development | ✅ Uses env |

### 4. **Issues Found**

1. **Config vs Secret Mismatch**:
   - Firebase config has production key (`DQ46FN4PQU`)
   - Firebase secret has sandbox key (`55LZB28UY2`)
   - This creates confusion about which key is actually used

2. **Key/Server Mismatch**:
   - `manageLiveActivityUpdates.js` defaults to production key but uses development server
   - This would cause authentication failures

3. **APNs Key Not Found Error**:
   - Recent logs show "APNs key not found"
   - Function may not be accessing the secret correctly

### 5. **References to Non-Existent Keys**
- `FM3P8KLCJQ` - Still referenced in:
  - Comment in `LiveActivityPushService.swift`
  - Backup files (not active)

### 6. **Correct Configuration Should Be**

For development/sandbox:
```javascript
// Server
const APNS_HOST = 'api.development.push.apple.com';

// Keys
const KEY_ID = '55LZB28UY2';
const TEAM_ID = '62T6J77P6R';

// Auth key file
AuthKey_55LZB28UY2.p8
```

For production:
```javascript
// Server
const APNS_HOST = 'api.push.apple.com';

// Keys
const KEY_ID = 'DQ46FN4PQU';
const TEAM_ID = '62T6J77P6R';

// Auth key file
AuthKey_DQ46FN4PQU.p8
```

## Recommendations

1. **Immediate Actions**:
   - Update Firebase config to match secrets: `firebase functions:config:set apns.key_id="55LZB28UY2"`
   - Fix `manageLiveActivityUpdates.js` to use sandbox key as default
   - Verify auth key secret contains the correct key file

2. **Clean Up**:
   - Remove references to `FM3P8KLCJQ`
   - Standardize all functions to use same defaults
   - Consider implementing environment-based configuration

3. **Testing**:
   - After fixes, test Live Activity push updates
   - Monitor logs for successful JWT generation
   - Verify no more "APNs key not found" errors