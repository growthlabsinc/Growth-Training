# App Store Connect API Integration Setup

## Environment Variables Configuration

### Required Environment Variables
Add these to your Firebase Functions environment configuration:

```bash
# App Store Connect API Credentials
APP_STORE_CONNECT_KEY_ID=your_key_id_here
APP_STORE_CONNECT_ISSUER_ID=your_issuer_id_here
APP_STORE_CONNECT_PRIVATE_KEY_PATH=/path/to/private/key.p8

# App Store Shared Secret (for receipt validation)
APP_STORE_SHARED_SECRET=your_shared_secret_here

# Environment Configuration
FIREBASE_ENV=development
```

### Setting Environment Variables in Firebase Functions

#### Development Environment
```bash
firebase functions:config:set appstore.key_id="YOUR_KEY_ID"
firebase functions:config:set appstore.issuer_id="YOUR_ISSUER_ID"
firebase functions:config:set appstore.private_key_path="/tmp/private_key.p8"
firebase functions:config:set appstore.shared_secret="YOUR_SHARED_SECRET"
```

#### Production Environment
```bash
firebase use production
firebase functions:config:set appstore.key_id="YOUR_PROD_KEY_ID"
firebase functions:config:set appstore.issuer_id="YOUR_PROD_ISSUER_ID"
firebase functions:config:set appstore.private_key_path="/tmp/prod_private_key.p8"
firebase functions:config:set appstore.shared_secret="YOUR_PROD_SHARED_SECRET"
```

## API Rate Limits and Error Handling

### Rate Limiting Strategy
- **Limit:** 200 requests per minute (conservative)
- **Implementation:** Built-in rate limiting in AppStoreConnectClient
- **Handling:** Automatic rate limit tracking with error responses

### Error Handling Patterns

#### Authentication Errors (401)
```javascript
// Token regeneration on auth failure
if (error.status === 401) {
  // Force token regeneration
  this.token = null;
  this.tokenExpiry = null;
  // Retry request once
}
```

#### Rate Limit Errors (429)
```javascript
// Exponential backoff for rate limits
if (error.status === 429) {
  const retryAfter = error.headers['retry-after'] || 60;
  await this.delay(retryAfter * 1000);
  // Retry request
}
```

#### Network Errors
```javascript
// Retry with exponential backoff
const maxRetries = 3;
const baseDelay = 1000; // 1 second
for (let attempt = 1; attempt <= maxRetries; attempt++) {
  try {
    return await this.makeRequest(endpoint, method, data);
  } catch (error) {
    if (attempt === maxRetries) throw error;
    await this.delay(baseDelay * Math.pow(2, attempt - 1));
  }
}
```

## Security Best Practices

### Private Key Management
1. **Never commit private keys to version control**
2. **Store private key in secure Firebase environment**
3. **Use proper file permissions (600) for private key file**
4. **Implement key rotation strategy**

### Token Security
1. **Tokens expire after 20 minutes (Apple maximum)**
2. **Generate new tokens with 5-minute buffer before expiry**
3. **Log token generation for monitoring**
4. **Never log actual token values**

### Environment Separation
1. **Separate credentials for sandbox vs production**
2. **Different Firebase projects for different environments**
3. **Clear environment variable naming conventions**
4. **Audit trail for credential access**

## Testing Strategy

### Unit Tests
```javascript
// Test token generation
describe('AppStoreConnectClient', () => {
  test('generates valid JWT token', () => {
    const client = new AppStoreConnectClient();
    const token = client.generateToken();
    expect(token).toBeTruthy();
    expect(typeof token).toBe('string');
  });

  test('enforces rate limiting', () => {
    const client = new AppStoreConnectClient();
    client.requestCount = client.maxRequestsPerMinute;
    expect(() => client.checkRateLimit()).toThrow('Rate limit exceeded');
  });
});
```

### Integration Tests
```javascript
// Test API connectivity
describe('App Store Connect API Integration', () => {
  test('can authenticate with App Store Connect', async () => {
    const client = new AppStoreConnectClient();
    const response = await client.makeRequest('/apps');
    expect(response).toBeTruthy();
  });
});
```

## Monitoring and Alerting

### Key Metrics to Monitor
1. **API Request Success Rate:** >99%
2. **Authentication Success Rate:** >99.9%
3. **Average Response Time:** <2 seconds
4. **Rate Limit Hit Rate:** <5%

### Alert Conditions
```javascript
// Firebase Cloud Functions logging
const functions = require('firebase-functions');

// Log API metrics
functions.logger.info('App Store Connect API Request', {
  endpoint,
  method,
  status: 'success',
  responseTime: Date.now() - startTime,
  rateLimitStatus: client.getRateLimitStatus()
});

// Alert on failures
if (errorCount > threshold) {
  functions.logger.error('App Store Connect API Alert', {
    message: 'High error rate detected',
    errorCount,
    timeWindow: '5 minutes'
  });
}
```

## Troubleshooting Guide

### Common Issues

#### "Token generation failed"
- **Cause:** Invalid private key format or missing credentials
- **Solution:** Verify .p8 file format and environment variables

#### "Rate limit exceeded"
- **Cause:** Too many API requests in short time
- **Solution:** Implement request queuing or reduce request frequency

#### "Authentication failed"
- **Cause:** Invalid token or expired credentials
- **Solution:** Regenerate API key and update environment variables

#### "Network timeout"
- **Cause:** Slow App Store Connect API response
- **Solution:** Increase timeout value and implement retry logic

### Debug Commands
```bash
# Check Firebase Functions config
firebase functions:config:get

# Test API connectivity
npm run test-appstore-api

# Check function logs
firebase functions:log
```

---

**Created:** {CURRENT_DATE}
**Last Updated:** {CURRENT_DATE}  
**Status:** Ready for Implementation
**Dependencies:** User must provide App Store Connect API credentials