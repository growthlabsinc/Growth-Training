# APNs Dual-Key Implementation Guide

## Overview
Firebase functions have been updated to support a dual-key strategy for APNs, allowing separate keys for development and production environments with automatic retry logic.

## Changes Made

### 1. Updated `liveActivityUpdates.js`
- Added support for optional production-specific APNs credentials
- Implemented intelligent retry logic that tries both environments
- Enhanced error handling and logging
- Automatic environment detection based on bundle ID and token data

### 2. Key Features
- **Automatic Retry**: If one environment fails, automatically tries the other
- **Environment Detection**: Intelligently determines which environment to try first
- **Dual-Key Support**: Can use different keys for dev/prod or the same key
- **Better Error Handling**: Skip retries for authentication errors (403)

## Configuration

### Firebase Secrets Structure
```bash
# Development/Default Keys (Required)
APNS_AUTH_KEY         # The .p8 key file content
APNS_KEY_ID          # Key ID (e.g., DQ46FN4PQU)
APNS_TEAM_ID         # Team ID (e.g., 62T6J77P6R)
APNS_TOPIC           # Bundle ID (com.growthlabs.growthmethod)

# Production Keys (Optional - falls back to dev if not set)
APNS_AUTH_KEY_PROD   # Production .p8 key file content
APNS_KEY_ID_PROD     # Production Key ID
```

### Setting Up Dual Keys

1. **Option 1: Same Key for Both Environments**
   - Only set the default secrets (APNS_AUTH_KEY, APNS_KEY_ID)
   - The system will use the same key for both environments
   - Will automatically retry with different servers if needed

2. **Option 2: Different Keys for Dev/Prod**
   ```bash
   # Set development key
   firebase functions:secrets:set APNS_AUTH_KEY < AuthKey_DEV.p8
   firebase functions:secrets:set APNS_KEY_ID
   # Enter: YOUR_DEV_KEY_ID
   
   # Set production key
   firebase functions:secrets:set APNS_AUTH_KEY_PROD < AuthKey_PROD.p8
   firebase functions:secrets:set APNS_KEY_ID_PROD
   # Enter: YOUR_PROD_KEY_ID
   ```

## Environment Detection Logic

The system automatically determines the preferred environment based on:

1. **Token Data Environment Field**
   - `development` or `dev` → Try development first
   - `production` or `prod` → Try production first
   - Not specified → Auto mode (try development first)

2. **Bundle ID Detection**
   - Contains `.dev` → Development environment
   - Equals `com.growthlabs.growthmethod` → Production environment
   - Other → Auto mode

## Testing

### 1. Test the Configuration
```bash
cd functions
node test-dual-key-apns.js [optional-push-token]
```

### 2. Deploy Functions
```bash
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:onTimerStateChange,functions:testAPNsConnection
```

### 3. Test via Firebase Console
Call the `testAPNsConnection` function to verify both environments.

## Error Handling

### Common Scenarios

1. **403 InvalidProviderToken**
   - The key is not valid for APNs
   - System will NOT retry with other environment
   - Contact Apple Developer Support

2. **400 BadDeviceToken**
   - Token/server mismatch (dev token with prod server or vice versa)
   - System WILL automatically retry with other environment
   - This is expected and handled gracefully

3. **410 Gone**
   - Push token is no longer valid
   - App needs to regenerate token

## Current Status

Based on the analysis:
- **Key ID**: DQ46FN4PQU
- **Error**: 403 InvalidProviderToken on both environments
- **Issue**: The key appears to have an authentication problem

## Next Steps

1. **Immediate**: Deploy the updated functions
   ```bash
   firebase deploy --only functions
   ```

2. **Testing**: Run the test script to verify configuration
   ```bash
   cd functions
   node test-dual-key-apns.js
   ```

3. **Resolution**: 
   - Contact Apple Developer Support about the 403 error
   - Create a new APNs key as backup
   - Consider setting up separate dev/prod keys

## Advantages of This Implementation

1. **Resilience**: Automatic failover between environments
2. **Flexibility**: Supports both single-key and dual-key setups
3. **Intelligence**: Smart environment detection
4. **Debugging**: Enhanced logging for troubleshooting
5. **Future-Proof**: Ready for separate dev/prod keys when needed

## Monitoring

The updated functions provide detailed logs:
- Environment detection results
- Which key/server combination is being tried
- Specific error codes and messages
- Successful environment on completion

Check logs with:
```bash
firebase functions:log --only updateLiveActivity
```