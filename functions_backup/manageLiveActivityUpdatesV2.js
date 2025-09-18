const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// This is a fixed version of manageLiveActivityUpdates using HTTP/2

// Apple Push Notification Service (APNs) configuration
const APNS_HOST = 'api.push.apple.com';
const APNS_PORT = 443;
const APNS_PATH_PREFIX = '/3/device/';
const TEAM_ID = process.env.APNS_TEAM_ID || '62T6J77P6R';
const KEY_ID = process.env.APNS_KEY_ID || '3G84L8G52R';
let APNS_KEY = process.env.APNS_AUTH_KEY || `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgUPGzxd5Ylut/PEg/
Svun7BvcBDwebSioaCTNzcKvHZWgCgYIKoZIzj0DAQehRANCAARrfZIL/p336Evv
DRifFfVgsZ35KjCBaB84dIKt1jHqvO5/w8iDaRREDzs2nTwBcpF3CnDvNBFe6Z+K
NIJuAR7N
-----END PRIVATE KEY-----`;

// Replace escaped newlines with actual newlines
if (APNS_KEY && APNS_KEY.includes('\\n')) {
    APNS_KEY = APNS_KEY.replace(/\\n/g, '\n');
}

// Generate APNs authentication token
function generateAPNsToken() {
    const token = jwt.sign(
        {
            iss: TEAM_ID,
            iat: Math.floor(Date.now() / 1000),
        },
        APNS_KEY,
        {
            algorithm: 'ES256',
            header: {
                alg: 'ES256',
                kid: KEY_ID,
            },
        }
    );
    return token;
}

/**
 * Simplified function that just sends a single push update
 */
exports.manageLiveActivityUpdatesV2 = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { activityId, userId } = request.data;
        
        if (!activityId || !userId) {
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
    
        try {
            // Get the push token
            const tokenDoc = await admin.firestore()
                .collection('liveActivityTokens')
                .doc(activityId)
                .get();
            
            if (!tokenDoc.exists) {
                throw new HttpsError('not-found', 'Live Activity token not found');
            }
            
            const tokenData = tokenDoc.data();
            const pushToken = tokenData.pushToken;
            
            // Get timer state
            const timerDoc = await admin.firestore()
                .collection('activeTimers')
                .doc(userId)
                .get();
            
            if (!timerDoc.exists) {
                throw new HttpsError('not-found', 'Timer state not found');
            }
            
            const timerData = timerDoc.data();
            
            // Send push update
            const contentState = {
                startTime: timerData.startTime,
                endTime: timerData.endTime,
                methodName: timerData.methodName,
                sessionType: timerData.sessionType,
                isPaused: timerData.isPaused,
                lastUpdateTime: new Date().toISOString(),
                elapsedTimeAtLastUpdate: timerData.elapsedTimeAtLastUpdate || 0,
                remainingTimeAtLastUpdate: timerData.remainingTimeAtLastUpdate || 0
            };
            
            const payload = {
                aps: {
                    timestamp: Math.floor(Date.now() / 1000),
                    event: 'update',
                    'content-state': contentState,
                    'stale-date': Math.floor(Date.now() / 1000) + 60
                }
            };
            
            const authToken = generateAPNsToken();
            const payloadString = JSON.stringify(payload);
            
            const result = await new Promise((resolve) => {
                const client = http2.connect(`https://${APNS_HOST}:${APNS_PORT}`);
                
                client.on('error', (err) => {
                    console.error('HTTP/2 client error:', err);
                    resolve({ success: false, error: err.message });
                });

                const req = client.request({
                    ':method': 'POST',
                    ':path': `${APNS_PATH_PREFIX}${pushToken}`,
                    'authorization': `bearer ${authToken}`,
                    'apns-topic': 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity',
                    'apns-push-type': 'liveactivity',
                    'apns-priority': '10',
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
                        resolve({ success: false, error: `${statusCode} - ${responseBody}` });
                    }
                });

                req.on('error', (error) => {
                    console.error('Request error:', error);
                    client.close();
                    resolve({ success: false, error: error.message });
                });

                req.write(payloadString);
                req.end();
            });
            
            return result;
            
        } catch (error) {
            console.error('Error in V2 function:', error);
            throw new HttpsError('internal', error.message);
        }
    }
);