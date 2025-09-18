# Apple Developer Support Request

**Subject: InvalidProviderToken 403 Error After Account Migration - Live Activities Push Notifications**

Hello Apple Developer Support,

I'm experiencing persistent InvalidProviderToken (403) errors with APNs after migrating from a personal Apple Developer account to a business developer account. This issue is preventing Live Activity push notifications from working in our iOS app.

**Background:**
- App Name: Growth Method
- Bundle ID: com.growthlabs.growthmethod
- Team ID: 62T6J77P6R
- Team Name: GrowthMethodLive
- Issue Started: After account migration (previously working without errors)

**Current Configuration:**
- APNs Authentication Key ID: 378FZMBP8L (Development Key)
- Using JWT token-based authentication with ES256 algorithm
- Firebase Cloud Functions for backend
- Live Activity topic: com.growthlabs.growthmethod.push-type.liveactivity

**Specific Error:**
```
StatusCode: 403
Response: {"reason":"InvalidProviderToken"}
APNs-ID: [various IDs]
Endpoint: api.development.push.apple.com
```

**What I've Verified:**
1. JWT token generation is correct (ES256 algorithm, proper headers)
2. Team ID (62T6J77P6R) matches in both JWT and Developer portal
3. Bundle ID matches exactly
4. Entitlements set to "development" in both app and widget
5. Using correct APNs topic format for Live Activities
6. Token timestamps are current (not expired)

**What Changed:**
- Migrated from personal developer account to business account
- Previously, Live Activities worked without any InvalidProviderToken errors
- No code changes were made - only account/key changes
- Created new APNs keys after migration

**Attempted Solutions:**
1. Deleted all old keys and created new ones
2. Tried multiple APNs keys (ALXPNBM7S9, then 378FZMBP8L)
3. Switched from production to development key
4. Updated all Firebase secrets with new credentials
5. Verified JWT token structure and encoding

**Questions:**
1. Are there special requirements for APNs keys after account migration?
2. Does the development key (378FZMBP8L) have any restrictions that would prevent Live Activity usage?
3. Is Push Notifications capability properly transferred/enabled for our App ID after migration?
4. Could there be lingering configuration from the personal account causing conflicts?
5. Should we create a universal APNs key instead of a development-specific one?

**Impact:**
This is blocking a critical feature (timer Live Activities) for our fitness app users. The app uses Live Activities to show workout timers in Dynamic Island and Lock Screen, which stopped working after the account migration.

Any guidance on resolving InvalidProviderToken errors specifically related to account migration would be greatly appreciated. I can provide additional logs, JWT tokens, or configuration details as needed.

Thank you for your assistance.

Best regards,
[Your Name]

---

**Additional Technical Details:**
- iOS Deployment Target: 16.0+
- Using ActivityKit for Live Activities
- Firebase Admin SDK: Latest version
- Previous working configuration used personal account provisioning

**Recent Error Logs:**
```
2025-07-13T02:43:48.339548Z APNs Environment Detection:
- Environment: dev
- Bundle ID: com.growthlabs.growthmethod
- Using DEVELOPMENT APNs server first

2025-07-13T02:43:48.343607Z Forbidden - Invalid authentication token {
  statusCode: 403,
  response: '{"reason":"InvalidProviderToken"}',
  headers: {
    ':status': 403,
    'apns-id': '8E478634-93DC-0160-B592-456C62E61956'
  }
}
```

**Firebase Function Configuration:**
- Using Firebase secrets for APNs credentials
- JWT token generation with jsonwebtoken library
- HTTP/2 connection to APNs servers
- Proper error handling and retry logic

**What Works:**
- JWT token generation (verified structure)
- Connection to APNs servers
- Firebase function execution
- Environment detection (dev/production)

**What Fails:**
- Authentication with APNs (InvalidProviderToken)
- Same error with both production and development endpoints
- Occurs with multiple different APNs keys