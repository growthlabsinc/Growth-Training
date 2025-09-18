const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Define secrets
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');

// APNs configuration
const APNS_HOST = process.env.APNS_HOST || 'api.development.push.apple.com'; // Development server for Xcode builds
const TEAM_ID = process.env.APNS_TEAM_ID?.trim() || '62T6J77P6R';
const KEY_ID = process.env.APNS_KEY_ID?.trim() || '55LZB28UY2';

/**
 * Simplified Live Activity update function
 * Only sends push updates for state changes (pause/resume/stop)
 * Native timer APIs handle continuous updates
 */
exports.updateLiveActivitySimplified = onCall(
    { 
        region: 'us-central1',
        // App Check is enforced by default when consumeAppCheckToken is not specified
        secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret]
    },
    async (request) => {
        const { activityId, userId, action } = request.data;
        
        if (!activityId || !userId) {
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
        
        console.log(`📱 Update Live Activity: ${activityId} - Action: ${action}`);
        
        try {
            // Get push token
            const tokenDoc = await admin.firestore()
                .collection('liveActivityTokens')
                .doc(activityId)
                .get();
                
            if (!tokenDoc.exists) {
                console.error('❌ No push token found');
                throw new HttpsError('not-found', 'Push token not found');
            }
            
            const pushToken = tokenDoc.data().pushToken;
            
            // Get current timer state
            const stateDoc = await admin.firestore()
                .collection('liveActivityTimerStates')
                .doc(activityId)
                .get();
                
            if (!stateDoc.exists) {
                console.error('❌ No timer state found');
                throw new HttpsError('not-found', 'Timer state not found');
            }
            
            const timerData = stateDoc.data();
            const contentState = timerData.contentState;
            
            // Convert Firestore timestamps to ISO strings
            const pushContentState = {
                startedAt: contentState.startedAt.toDate().toISOString(),
                pausedAt: contentState.pausedAt ? contentState.pausedAt.toDate().toISOString() : null,
                duration: contentState.duration,
                methodName: contentState.methodName,
                sessionType: contentState.sessionType,
                isCompleted: contentState.isCompleted || false,
                completionMessage: contentState.completionMessage || null
            };
            
            // Calculate stale date based on timer type and state
            let staleDate;
            if (contentState.sessionType === 'countdown' && !contentState.pausedAt) {
                // For running countdown timers, stale date is end time + buffer
                const endTime = contentState.startedAt.toDate().getTime() + (contentState.duration * 1000);
                staleDate = Math.floor(endTime / 1000) + 10;
            } else {
                // For paused or count-up timers, stale date is 1 minute from now
                staleDate = Math.floor(Date.now() / 1000) + 60;
            }
            
            // Create APNs payload
            const payload = {
                aps: {
                    timestamp: Math.floor(Date.now() / 1000),
                    event: 'update',
                    'content-state': pushContentState,
                    'stale-date': staleDate
                }
            };
            
            // Send push notification
            await sendPushNotification(pushToken, activityId, payload);
            
            return { success: true, message: 'Push update sent' };
            
        } catch (error) {
            console.error('❌ Error:', error);
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError('internal', error.message);
        }
    }
);

/**
 * Generate APNs JWT token
 */
function generateAPNsToken() {
    // Access secrets through the process.env with the secret names
    const APNS_KEY = apnsAuthKeySecret.value() || process.env.APNS_AUTH_KEY;
    const actualKeyId = apnsKeyIdSecret.value() || process.env.APNS_KEY_ID || KEY_ID;
    const actualTeamId = apnsTeamIdSecret.value() || process.env.APNS_TEAM_ID || TEAM_ID;
    
    if (!APNS_KEY) {
        console.error('❌ APNs key not found in secrets or environment');
        return null;
    }
    
    try {
        const token = jwt.sign(
            {
                iss: actualTeamId,
                iat: Math.floor(Date.now() / 1000),
            },
            APNS_KEY,
            {
                algorithm: 'ES256',
                header: {
                    alg: 'ES256',
                    kid: actualKeyId,
                },
            }
        );
        console.log('✅ Generated APNs JWT token successfully');
        return token;
    } catch (error) {
        console.error('❌ Failed to generate JWT:', error.message);
        return null;
    }
}

/**
 * Send push notification via APNs
 */
async function sendPushNotification(pushToken, activityId, payload) {
    const authToken = generateAPNsToken();
    
    if (!authToken) {
        console.log('⚠️ Skipping push - APNs not configured');
        return;
    }
    
    console.log(`📤 Sending push to activity: ${activityId}`);
    console.log('Payload:', JSON.stringify(payload, null, 2));
    
    const payloadString = JSON.stringify(payload);
    
    return new Promise((resolve, reject) => {
        const client = http2.connect(`https://${APNS_HOST}:443`);
        
        client.on('error', (err) => {
            console.error('HTTP/2 client error:', err);
            reject(err);
        });

        const req = client.request({
            ':method': 'POST',
            ':path': `/3/device/${pushToken}`,
            'authorization': `bearer ${authToken}`,
            'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
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
                console.log('✅ Push sent successfully');
                resolve({ success: true });
            } else {
                console.error(`❌ APNs error: ${statusCode} - ${responseBody}`);
                reject(new Error(`APNs error: ${statusCode}`));
            }
        });

        req.on('error', (error) => {
            console.error('Request error:', error);
            client.close();
            reject(error);
        });

        req.write(payloadString);
        req.end();
    });
}