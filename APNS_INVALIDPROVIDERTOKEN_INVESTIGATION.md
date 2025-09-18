# APNs InvalidProviderToken (403) Investigation

## Current Issue
Firebase functions are receiving `InvalidProviderToken` (403) errors when attempting to send push notifications for Live Activities.

## Current Configuration
- **APNs Key ID**: 66LQV834DU (stored in APNS_KEY_ID secret)
- **Team ID**: 62T6J77P6R (stored in APNS_TEAM_ID secret)
- **APNs Topic**: com.growthlabs.growthmethod.push-type.liveactivity
- **Bundle ID**: com.growthlabs.growthmethod
- **APNs Environment**: production (in both app and widget entitlements)
- **Key File**: AuthKey_66LQV834DU.p8 (content stored in APNS_AUTH_KEY secret version 11)

## Verification Steps Completed
1. ✅ Verified APNS_AUTH_KEY secret contains the correct key file content
2. ✅ Verified JWT token generation works locally with the key
3. ✅ Verified bundle ID matches in GoogleService-Info.plist
4. ✅ Verified entitlements are set to "production" for both app and widget
5. ✅ Verified APNs topic format is correct for Live Activities

## Error Details from Firebase Logs
```
❌ Forbidden - Invalid authentication token {
  statusCode: 403,
  response: '{"reason":"InvalidProviderToken"}',
  headers: {
    ':status': 403,
    'apns-id': '7F3ADF7C-D120-5845-0EC6-E2E82219FB6B'
  }
}
```

## Possible Root Causes
Based on Apple's documentation and the Stack Overflow link provided:

1. **APNs Key Not Valid for App**
   - The key (66LQV834DU) might not be configured in Apple Developer portal for this app
   - The key might have been revoked or regenerated
   
2. **Team ID Mismatch**
   - The Team ID (62T6J77P6R) might not match the one associated with the APNs key
   
3. **Bundle ID Configuration**
   - The app's bundle ID in Apple Developer portal might not match com.growthlabs.growthmethod
   
4. **Key Permissions**
   - The APNs key might not have the correct permissions for push notifications

## Next Steps to Verify in Apple Developer Portal

1. **Verify APNs Key Status**
   - Log into Apple Developer portal
   - Go to Certificates, Identifiers & Profiles > Keys
   - Find key with ID: 66LQV834DU
   - Verify it's active and has "Apple Push Notifications service (APNs)" enabled
   
2. **Verify Team ID**
   - In Apple Developer portal, verify the Team ID is: 62T6J77P6R
   
3. **Verify App ID Configuration**
   - Go to Identifiers > App IDs
   - Find the app with bundle ID: com.growthlabs.growthmethod
   - Verify Push Notifications capability is enabled
   - Verify it's configured for Production APNs
   
4. **Consider Creating New APNs Key**
   - If the current key cannot be verified, create a new APNs authentication key
   - Download the .p8 file
   - Update Firebase secrets with new key ID and content

## Testing Command
Once Apple Developer portal is verified, test the connection:
```bash
firebase functions:shell
testAPNsConnection()
```

## Alternative Solution
If the issue persists, consider switching to Firebase Cloud Messaging (FCM) for regular push notifications and only use direct APNs for Live Activities, as suggested in the user's FCM documentation links.