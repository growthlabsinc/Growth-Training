# APNs Diagnostic Report for Apple Developer Support

## Summary
We are experiencing **InvalidProviderToken (403)** errors when attempting to send push notifications to Live Activities. This issue began after migrating from a personal Apple Developer account to a business account.

## Environment Details
- **Date/Time**: 2025-07-13T17:02:12.625Z (UTC)
- **Bundle ID**: com.growthlabs.growthmethod
- **Team ID**: 62T6J77P6R
- **Key ID**: 378FZMBP8L
- **Environment**: Development (using development push tokens)
- **APNs Server**: 2620:149:149:1022::15
- **Our Server IP**: 34.96.44.255

## Request Details

### JWT Token
```
eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjM3OEZaTUJQOEwKIn0.eyJpc3MiOiI2MlQ2Sjc3UDZSIiwiaWF0IjoxNzUyNDI2MTMyfQ.oSq1YJojKf0Jqp0ZAxDUgOkymyq89nD0sES9f5GZb7pXMR1_hGmpgH1HP79JLbCE92-6VUlFjn91dmQcZAd57Q
```
- Token Length: 202 characters
- Algorithm: ES256
- Type: JWT
- Key ID in header: 378FZMBP8L (note: contains newline character)

### HTTP/2 Request Headers
```
:method: POST
:path: /3/device/801003ba001eb0f19f11bce3b057d0d69dc1c959c7eeb16a3156008452e4d781cac311e2c279c4dae7b05fb921a9bd5cd2b6f6c959d1e1b459159070e7dab6762c18fc75c05405d21551c1666ca2a29b
authorization: bearer [JWT_TOKEN]
apns-topic: com.growthlabs.growthmethod.push-type.liveactivity
apns-push-type: liveactivity
apns-priority: 10
apns-expiration: 1752429732
content-type: application/json
content-length: 291
```

### Push Token
```
801003ba001eb0f19f11bce3b057d0d69dc1c959c7eeb16a3156008452e4d781cac311e2c279c4dae7b05fb921a9bd5cd2b6f6c959d1e1b459159070e7dab6762c18fc75c05405d21551c1666ca2a29b
```

### Live Activity ID
```
9FFAEB73-FEFC-4CB7-BE64-F57BCB9D9477
```

### Payload (291 bytes)
```json
{
  "aps": {
    "timestamp": 1752426132,
    "event": "update",
    "content-state": {
      "startTime": "2025-07-13T17:02:12.806Z",
      "endTime": "2025-07-13T18:02:12.806Z",
      "methodName": "Diagnostic Test",
      "sessionType": "countdown",
      "isPaused": false
    },
    "alert": {
      "title": "Diagnostic Test",
      "body": "Testing Live Activity Update"
    }
  }
}
```

## Response Details

### Status Code: 403
### Response Headers
```
:status: 403
apns-id: BAA62BE6-BCA1-BD0A-97E2-612E7F717F20
```

### Response Body
```json
{"reason":"InvalidProviderToken"}
```

### Request Duration: 145ms

## Error Interpretation
APNs rejected the authentication token. This typically means:
1. The key is not valid for this app
2. The Team ID is incorrect
3. The key has been revoked
4. The key does not have APNs permission enabled

## Additional Context

### Account Migration Details
- Previously working with personal Apple Developer account
- Recently migrated to business account (Team ID: 62T6J77P6R)
- APNs authentication key was recreated after migration
- Key ID: 378FZMBP8L
- Bundle ID remains: com.growthlabs.growthmethod

### Firebase Configuration
- Using Firebase Cloud Functions for backend
- Secrets configured in Firebase:
  - APNS_AUTH_KEY (version 13)
  - APNS_KEY_ID (version 8)
  - APNS_TEAM_ID (version 3)

### Notable Issue
The Key ID in the JWT header contains a newline character: `378FZMBP8L\n`
This may be contributing to the authentication failure.

### App Configuration
- App uses Firebase SDK with App Check enabled
- Live Activities are properly configured in Info.plist
- Push notifications entitlement is enabled
- App Group: group.com.growthlabs.growthmethod

## Questions for Apple Support

1. Is the InvalidProviderToken error related to the recent account migration from personal to business?
2. Should the APNs authentication key created under the business account work immediately, or is there a propagation delay?
3. Is the newline character in the Key ID header causing the authentication failure?
4. Are there any additional steps required when migrating APNs keys from a personal to business account?
5. Can you verify that our Team ID (62T6J77P6R) and Key ID (378FZMBP8L) are correctly associated in your systems?

## What We've Tried
1. Recreated APNs authentication key multiple times
2. Verified Team ID matches the business account
3. Confirmed bundle ID hasn't changed
4. Updated all Firebase secrets with new values
5. Tested with both development and production environments

The issue persists despite these efforts. We would appreciate your assistance in resolving this authentication problem.