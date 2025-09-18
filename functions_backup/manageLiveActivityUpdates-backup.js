const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Apple Push Notification Service (APNs) configuration
const APNS_HOST = 'api.push.apple.com';
const APNS_PORT = 443;
const APNS_PATH_PREFIX = '/3/device/';

// APNs credentials - these are configured in Firebase config
// firebase functions:config:get shows they're already set
const TEAM_ID = '62T6J77P6R';
const KEY_ID = '3G84L8G52R';
const APNS_KEY = `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgUPGzxd5Ylut/PEg/
Svun7BvcBDwebSioaCTNzcKvHZWgCgYIKoZIzj0DAQehRANCAARrfZIL/p336Evv
DRifFfVgsZ35KjCBaB84dIKt1jHqvO5/w8iDaRREDzs2nTwBcpF3CnDvNBFe6Z+K
NIJuAR7N
-----END PRIVATE KEY-----`;

// Generate APNs authentication token
function generateAPNsToken() {
    console.log('APNs Configuration Check:');
    console.log(`- TEAM_ID: ${TEAM_ID}`);
    console.log(`- KEY_ID: ${KEY_ID}`);
    console.log(`- APNS_KEY configured: Yes`);
    
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

// Map to store active intervals for each activity
const activeIntervals = new Map();

/**
 * Manage Live Activity updates - start/stop server-side push updates
 */
exports.manageLiveActivityUpdates = onCall(
    { 
        region: 'us-central1',
        timeoutSeconds: 60,
        memory: '256MiB'
    },
    async (request) => {
        const { activityId, userId, action } = request.data;
        
        if (!activityId || !action) {
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
    
    try {
        switch (action) {
            case 'startPushUpdates':
                await startPushUpdates(activityId, userId);
                return { success: true, message: 'Push updates started' };
                
            case 'stopPushUpdates':
                await stopPushUpdates(activityId, userId);
                return { success: true, message: 'Push updates stopped' };
                
            default:
                throw new HttpsError('invalid-argument', 'Invalid action');
        }
    } catch (error) {
        console.error('Error managing Live Activity updates:', error);
        throw new HttpsError('internal', error.message);
    }
});

/**
 * Start periodic push updates for a Live Activity
 */
async function startPushUpdates(activityId, userId) {
    // Stop any existing interval for this activity
    stopPushUpdates(activityId);
    
    console.log(`Starting push updates for activity: ${activityId}, user: ${userId}`);
    
    // Send immediate update
    await sendTimerUpdate(activityId, userId);
    
    // Set up periodic updates every second
    const intervalId = setInterval(async () => {
        try {
            await sendTimerUpdate(activityId, userId);
        } catch (error) {
            console.error(`Error sending update for activity ${activityId}:`, error);
            // If we get an error (e.g., activity no longer exists), stop the interval
            if (error.message.includes('not found') || error.message.includes('expired')) {
                stopPushUpdates(activityId);
            }
        }
    }, 1000); // Update every second
    
    // Store the interval ID
    activeIntervals.set(activityId, intervalId);
}

/**
 * Stop periodic push updates for a Live Activity
 */
function stopPushUpdates(activityId) {
    const intervalId = activeIntervals.get(activityId);
    if (intervalId) {
        clearInterval(intervalId);
        activeIntervals.delete(activityId);
        console.log(`Stopped push updates for activity: ${activityId}`);
    }
}

/**
 * Send a timer update to a specific Live Activity
 */
async function sendTimerUpdate(activityId, userId) {
    const db = admin.firestore();
    
    // Get the push token
    const tokenDoc = await db.collection('liveActivityTokens').doc(activityId).get();
    let pushToken = null;
    
    if (tokenDoc.exists) {
        const tokenData = tokenDoc.data();
        pushToken = tokenData.pushToken;
        
        // Use the provided userId or fallback to the one in token data
        if (!userId) {
            userId = tokenData.userId;
        }
    }
    
    // Ensure we have a userId
    if (!userId) {
        console.error(`No userId provided and no token data found for activity: ${activityId}`);
        throw new Error(`Cannot determine userId for activity: ${activityId}`);
    }
    
    // Get the timer state from Firestore using the user ID
    const timerDoc = await db.collection('activeTimers').doc(userId).get();
    if (!timerDoc.exists) {
        throw new Error(`Timer state not found for user: ${userId}`);
    }
    
    const timerData = timerDoc.data();
    
    // Check if timer is stopped
    if (timerData.action === 'stop') {
        stopPushUpdates(activityId);
        return;
    }
    
    // Calculate current timer values
    const now = new Date();
    const lastUpdateTime = new Date(timerData.lastUpdateTime);
    const timeSinceLastUpdate = (now - lastUpdateTime) / 1000; // in seconds
    
    let elapsedTime, remainingTime;
    
    if (timerData.isPaused) {
        // If paused, use the stored values
        elapsedTime = timerData.elapsedTimeAtLastUpdate;
        remainingTime = timerData.remainingTimeAtLastUpdate;
    } else {
        // If running, calculate based on time passed
        elapsedTime = timerData.elapsedTimeAtLastUpdate + timeSinceLastUpdate;
        
        if (timerData.sessionType === 'countdown') {
            remainingTime = Math.max(0, timerData.remainingTimeAtLastUpdate - timeSinceLastUpdate);
            
            // Check if timer has completed
            if (remainingTime <= 0) {
                // Send completion update
                if (pushToken) {
                    const completionState = {
                        startTime: timerData.startTime,
                        endTime: new Date().toISOString(),
                        methodName: timerData.methodName,
                        sessionType: timerData.sessionType,
                        isPaused: false,
                        lastUpdateTime: now.toISOString(),
                        elapsedTimeAtLastUpdate: timerData.totalDuration,
                        remainingTimeAtLastUpdate: 0,
                        lastKnownGoodUpdate: now.toISOString(),
                        expectedEndTime: now.toISOString(),
                        isCompleted: true,
                        completionMessage: `Great job completing your ${timerData.methodName} session!`
                    };
                    
                    await sendPushNotification(pushToken, activityId, completionState);
                }
                
                // Mark as completed in Firestore
                await db.collection('activeTimers').doc(userId).update({
                    action: 'stop',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                
                stopPushUpdates(activityId);
                return;
            }
        } else {
            // For countup, there's no limit
            remainingTime = 0;
        }
    }
    
    // Prepare the content state for the push update
    const contentState = {
        startTime: timerData.startTime,
        endTime: timerData.endTime,
        methodName: timerData.methodName,
        sessionType: timerData.sessionType,
        isPaused: timerData.isPaused,
        lastUpdateTime: now.toISOString(),
        elapsedTimeAtLastUpdate: elapsedTime,
        remainingTimeAtLastUpdate: remainingTime,
        lastKnownGoodUpdate: now.toISOString(),
        expectedEndTime: timerData.sessionType === 'countdown' ? timerData.endTime : null
    };
    
    // Send the push notification if we have a token
    if (pushToken) {
        await sendPushNotification(pushToken, activityId, contentState);
    } else {
        console.log(`Skipping push notification for activity ${activityId} - no push token available yet`);
    }
}

/**
 * Send push notification to update Live Activity using HTTP/2
 */
async function sendPushNotification(pushToken, activityId, contentState) {
    try {
        const authToken = generateAPNsToken();
        
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

            // Create request with proper headers for APNs
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
                    resolve({ success: false, error: `${statusCode} - ${responseBody}` });
                }
            });

            req.on('error', (error) => {
                console.error('Request error:', error);
                client.close();
                resolve({ success: false, error: error.message });
            });

            // Send the payload
            req.write(payloadString);
            req.end();
        });
    } catch (error) {
        console.error('Error sending push notification:', error.message);
    }
}

// Clean up intervals when function instance is terminated
process.on('SIGTERM', () => {
    console.log('Function terminating, cleaning up intervals...');
    activeIntervals.forEach((intervalId, activityId) => {
        clearInterval(intervalId);
        console.log(`Cleared interval for activity: ${activityId}`);
    });
    activeIntervals.clear();
});