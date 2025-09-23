# Secure Firebase Functions v2 Authentication Solution

## Problem
Firebase Functions v2 using Cloud Run require proper IAM configuration that doesn't expose services publicly.

## Secure Solution: Convert to Firebase Functions v1

Since organization policies prevent `allUsers` access (for good security reasons), the best solution is to convert critical functions back to v1 which handle authentication internally without needing Cloud Run IAM policies.

### Implementation Steps

1. **Update package.json dependencies**:
```json
{
  "dependencies": {
    "firebase-functions": "^4.9.0",  // Use v4 for v1 functions
    "firebase-admin": "^11.11.1"
  }
}
```

2. **Convert function definitions**:

**From v2 (current - insecure with allUsers):**
```javascript
const { onCall } = require('firebase-functions/v2/https');

exports.generateAIResponse = onCall(
  {
    cors: true,
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    // ...
  }
);
```

**To v1 (secure - no allUsers needed):**
```javascript
const functions = require('firebase-functions');

exports.generateAIResponse = functions
  .region('us-central1')
  .runWith({
    memory: '256MB',
    timeoutSeconds: 60,
    maxInstances: 100
  })
  .https.onCall(async (data, context) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    // Access auth info
    const uid = context.auth.uid;
    const token = context.auth.token;

    // data contains the request payload
    const query = data.query;

    // ... rest of function logic
  });
```

3. **Update all critical functions to v1**:
   - generateAIResponse
   - registerPushToStartToken
   - registerLiveActivityPushToken
   - validateSubscriptionReceipt
   - All other authenticated functions

4. **Deploy the updated functions**:
```bash
cd functions
npm install
firebase deploy --only functions
```

## Why This Is More Secure

1. **No Public Access**: Functions v1 don't require `allUsers` IAM policy
2. **Built-in Auth**: Firebase handles authentication internally
3. **Token Validation**: Automatic Firebase ID token validation
4. **No Organization Policy Issues**: Works within security constraints
5. **Better for Sensitive Operations**: Ideal for functions handling user data

## Functions That Can Stay v2

Non-sensitive, truly public functions can remain v2 with restricted access:
- Health check endpoints
- Public webhooks (with validation)

## Alternative: Service Account Authentication

If v2 functions are required, use service account authentication:

1. **Add specific service accounts** (not allUsers):
```bash
gcloud run services add-iam-policy-binding FUNCTION_NAME \
  --region=us-central1 \
  --member="serviceAccount:firebase-adminsdk-fbsvc@PROJECT.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

2. **Use Firebase SDK** which automatically includes auth tokens

## Security Best Practices

1. **Never use `allUsers`** for sensitive functions
2. **Always check authentication** in function code
3. **Use App Check** for additional security
4. **Implement rate limiting**
5. **Log all access attempts**
6. **Use secret manager** for sensitive keys
7. **Regular security audits**

## Monitoring

Set up alerts for:
- Unauthorized access attempts
- Unusual traffic patterns
- Failed authentication
- Rate limit violations

## Reference
- [Firebase Functions v1 vs v2](https://firebase.google.com/docs/functions/version-comparison)
- [Cloud Run IAM](https://cloud.google.com/run/docs/securing/managing-access)
- [Firebase App Check](https://firebase.google.com/docs/app-check)