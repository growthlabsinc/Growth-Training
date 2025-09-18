# Collect APNs Diagnostic Data for Apple Support

Based on Jon Webb's response from Apple Developer Support, here's how to collect the required diagnostic information for our InvalidProviderToken issue.

## Script to Collect Required Data

### 1. Create Enhanced Logging Function

Create `functions/collectAPNsDiagnostics.js`:

```javascript
const { onCall } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');
const dns = require('dns');
const { promisify } = require('util');

const lookup = promisify(dns.lookup);

exports.collectAPNsDiagnostics = onCall(
  { 
    region: 'us-central1',
    secrets: ['APNS_AUTH_KEY', 'APNS_KEY_ID', 'APNS_TEAM_ID'],
    consumeAppCheckToken: false
  },
  async (request) => {
    const diagnostics = {
      timestamp: new Date().toISOString(),
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      bundleId: 'com.growthlabs.growthmethod',
      keyId: process.env.APNS_KEY_ID,
      teamId: process.env.APNS_TEAM_ID
    };
    
    try {
      // Get server IP
      const serverInfo = await lookup('api.development.push.apple.com');
      diagnostics.apnsServerIP = serverInfo.address;
      
      // Get our public IP (Firebase Functions)
      const response = await fetch('https://api.ipify.org?format=json');
      const ipData = await response.json();
      diagnostics.ourPublicIP = ipData.ip;
      
      // Generate JWT
      const token = jwt.sign(
        {
          iss: process.env.APNS_TEAM_ID,
          iat: Math.floor(Date.now() / 1000)
        },
        process.env.APNS_AUTH_KEY,
        {
          algorithm: 'ES256',
          header: {
            alg: 'ES256',
            kid: process.env.APNS_KEY_ID
          }
        }
      );
      
      diagnostics.jwtToken = token.substring(0, 50) + '...';
      
      // Test push token from request
      const { pushToken, activityId } = request.data;
      diagnostics.pushToken = pushToken;
      diagnostics.activityId = activityId;
      
      // Prepare test payload
      const payload = {
        aps: {
          timestamp: Math.floor(Date.now() / 1000),
          event: 'update',
          'content-state': {
            startTime: new Date().toISOString(),
            endTime: new Date(Date.now() + 3600000).toISOString(),
            methodName: 'Diagnostic Test',
            isPaused: false
          }
        }
      };
      
      diagnostics.payload = payload;
      
      // Capture full HTTP/2 exchange
      const client = http2.connect('https://api.development.push.apple.com:443');
      
      const headers = {
        ':method': 'POST',
        ':path': `/3/device/${pushToken}`,
        'authorization': `bearer ${token}`,
        'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
        'apns-push-type': 'liveactivity',
        'apns-priority': '10',
        'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
        'content-type': 'application/json'
      };
      
      diagnostics.requestHeaders = headers;
      
      return new Promise((resolve) => {
        const req = client.request(headers);
        
        let responseHeaders = {};
        let responseBody = '';
        
        req.on('response', (headers) => {
          responseHeaders = headers;
          diagnostics.responseHeaders = headers;
        });
        
        req.on('data', (chunk) => {
          responseBody += chunk;
        });
        
        req.on('end', () => {
          client.close();
          
          diagnostics.responseBody = responseBody;
          diagnostics.statusCode = responseHeaders[':status'];
          
          // Log everything
          console.log('=== APNs DIAGNOSTIC DATA ===');
          console.log(JSON.stringify(diagnostics, null, 2));
          console.log('=== END DIAGNOSTIC DATA ===');
          
          resolve({
            success: true,
            diagnostics
          });
        });
        
        req.on('error', (error) => {
          diagnostics.error = error.message;
          client.close();
          resolve({
            success: false,
            diagnostics
          });
        });
        
        req.write(JSON.stringify(payload));
        req.end();
      });
      
    } catch (error) {
      diagnostics.error = error.message;
      return {
        success: false,
        diagnostics
      };
    }
  }
);
```

### 2. Deploy and Run Diagnostic Collection

```bash
# Deploy the diagnostic function
firebase deploy --only functions:collectAPNsDiagnostics

# Call it from your app or Firebase console
# Make sure to pass a recent pushToken and activityId
```

### 3. Format Data for Apple Support

Once collected, format the diagnostic data as follows:

```
=== APNs Push Notification Diagnostic Report ===

REQUIRED INFORMATION:

1. Exact time and date of push request:
   - Time: [timestamp from diagnostics]
   - Timezone: [timezone from diagnostics]

2. Bundle ID: com.growthlabs.growthmethod

3. Push Token: [pushToken from diagnostics]

4. Error Status and Message:
   - Status Code: 403
   - Error: InvalidProviderToken

5. Full HTTP/2 Headers:
   Request Headers:
   [Copy requestHeaders from diagnostics]
   
   Response Headers:
   [Copy responseHeaders from diagnostics]

6. Full Payload:
   [Copy payload from diagnostics]

ADDITIONAL INFORMATION:

- Push Provider: Firebase Cloud Functions (Google Cloud Platform)
- Our Server IP: [ourPublicIP from diagnostics]
- APNs Server IP: [apnsServerIP from diagnostics]
- Push Topic: com.growthlabs.growthmethod.push-type.liveactivity
- Push Type: liveactivity
- APNs ID: [from response headers]
- Key ID: 378FZMBP8L
- Team ID: 62T6J77P6R

CONTEXT:
- Issue started after migrating from personal to business developer account
- Previously working without errors
- Using JWT authentication with ES256 algorithm
- Development APNs key being used with development endpoint
```

## Next Steps

1. Deploy the diagnostic function
2. Trigger a Live Activity to get a fresh push token
3. Run the diagnostic function with that token
4. Collect the output from Firebase logs
5. Format according to the template above
6. Submit to Apple Developer Support

This will provide Apple with all the required information to diagnose the InvalidProviderToken issue.