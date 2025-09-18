# URGENT: Manual Deployment Instructions

The Firebase Functions are deployed but running old code with axios instead of http2.

## Quick Fix via Google Cloud Console

1. **Go to**: https://console.cloud.google.com/functions/details/us-central1/manageLiveActivityUpdates?project=growth-70a85

2. **Click "EDIT"** at the top

3. **Find the code editor** and locate the `sendPushNotification` function (around line 327)

4. **Replace the entire `sendPushNotification` function** with this code:

```javascript
/**
 * Send push notification to update Live Activity
 */
async function sendPushNotification(pushToken, activityId, contentState) {
    try {
        const authToken = generateAPNsToken();
        
        if (!authToken) {
            console.log(`Skipping push notification for activity ${activityId} - APNs not configured`);
            return;
        }
        
        // Calculate stale date based on timer type
        let staleDate;
        if (contentState.sessionType === 'countdown' && contentState.expectedEndTime) {
            // For countdown timers, stale date is expected end time + 10 seconds
            const endTime = new Date(contentState.expectedEndTime);
            staleDate = Math.floor(endTime.getTime() / 1000) + 10;
        } else {
            // For countup timers or general updates, stale date is 60 seconds from now
            staleDate = Math.floor(Date.now() / 1000) + 60;
        }
        
        const payload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'update',
                'content-state': contentState,
                'stale-date': staleDate
            }
        };
        
        const payloadString = JSON.stringify(payload);
        
        return new Promise((resolve, reject) => {
            // Create HTTP/2 client
            const client = http2.connect(`https://${APNS_HOST}:${APNS_PORT}`);
            
            client.on('error', (err) => {
                console.error('HTTP/2 client error:', err);
                reject(err);
            });

            // Create request
            const req = client.request({
                ':method': 'POST',
                ':path': `${APNS_PATH_PREFIX}${pushToken}`,
                'authorization': `bearer ${authToken}`,
                'apns-topic': 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity',
                'apns-push-type': 'liveactivity',
                'apns-priority': '10',
                'apns-expiration': '0',
                'content-type': 'application/json',
                'content-length': Buffer.byteLength(payloadString)
            });

            let responseBody = '';
            let responseHeaders = {};

            req.on('response', (headers) => {
                responseHeaders = headers;
            });

            req.on('data', (chunk) => {
                responseBody += chunk;
            });

            req.on('end', () => {
                client.close();
                
                const statusCode = responseHeaders[':status'];
                if (statusCode === 200) {
                    console.log(`Successfully sent push update for activity: ${activityId}`);
                    resolve({ success: true });
                } else {
                    console.error(`APNs error: ${statusCode} - ${responseBody}`);
                    // Don't throw the error - let the timer continue tracking server-side
                    resolve({ success: false, error: `${statusCode} - ${responseBody}` });
                }
            });

            req.on('error', (error) => {
                console.error('Request error:', error);
                client.close();
                // Don't throw the error - let the timer continue tracking server-side
                resolve({ success: false, error: error.message });
            });

            // Send the payload
            req.write(payloadString);
            req.end();
        });
    } catch (error) {
        console.error('Error sending push notification:', error.message);
        // Don't throw the error - let the timer continue tracking server-side
        // The push notification failure shouldn't stop the timer tracking
    }
}
```

5. **Also replace** the imports at the top:
   - Change: `const axios = require('axios');`
   - To: `const http2 = require('http2');`

6. **Update the constants** near the top:
   ```javascript
   const APNS_HOST = 'api.push.apple.com';
   const APNS_PORT = 443;
   const APNS_PATH_PREFIX = '/3/device/';
   ```

7. **Click "DEPLOY"**

## Verification

After deployment, check the logs:
```bash
firebase functions:log --lines 20
```

You should see:
- ✅ "Successfully sent push update" messages
- ❌ NO MORE "Parse Error: Expected HTTP/" errors

## Why This Works

- axios doesn't support HTTP/2 protocol required by APNs
- http2 module provides native HTTP/2 support
- This fixes the "Parse Error: Expected HTTP/" error