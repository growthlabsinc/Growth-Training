const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Apple Push Notification Service (APNs) configuration
const APNS_HOST = 'api.push.apple.com';
const APNS_PORT = 443;
const APNS_PATH_PREFIX = '/3/device/';

// APNs credentials - these are configured in Firebase config
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
        const { activityId, userId, action, pushToken } = request.data;
        
        if (!activityId || !action) {
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
    
    try {
        switch (action) {
            case 'startPushUpdates':
                await startPushUpdates(activityId, userId, pushToken);
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
async function startPushUpdates(activityId, userId, pushToken) {
    // Stop any existing interval for this activity
    stopPushUpdates(activityId);
    
    console.log(`Starting push updates for activity: ${activityId}, user: ${userId}`);
    
    // Store the push token if provided
    if (pushToken) {
        await admin.firestore()
            .collection('liveActivityTokens')
            .doc(activityId)
            .set({
                pushToken,
                userId,
                activityId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastUpdate: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
    }
    
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
    if (!tokenDoc.exists) {
        throw new Error(`Token not found for activity: ${activityId}`);
    }
    
    const tokenData = tokenDoc.data();
    const pushToken = tokenData.pushToken;
    
    // Use the provided userId or fallback to the one in token data
    if (!userId) {
        userId = tokenData.userId;
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
    const now = Date.now();
    const lastUpdateTime = timerData.lastUpdateTime ? new Date(timerData.lastUpdateTime).getTime() : now;
    const timeSinceLastUpdate = (now - lastUpdateTime) / 1000; // in seconds
    
    let elapsedTime, remainingTime;
    
    if (timerData.isPaused) {
        // If paused, use the stored values
        elapsedTime = timerData.elapsedTimeAtLastUpdate || 0;
        remainingTime = timerData.remainingTimeAtLastUpdate || 0;
    } else {
        // If running, calculate based on time passed
        elapsedTime = (timerData.elapsedTimeAtLastUpdate || 0) + timeSinceLastUpdate;
        
        if (timerData.sessionType === 'countdown') {
            remainingTime = Math.max(0, (timerData.remainingTimeAtLastUpdate || timerData.totalDuration || 0) - timeSinceLastUpdate);
            
            // Check if timer has completed
            if (remainingTime <= 0) {
                // Send completion update
                const completionState = {
                    startTime: timerData.startTime,
                    endTime: new Date().toISOString(),
                    methodName: timerData.methodName || 'Session',
                    sessionType: timerData.sessionType,
                    isPaused: false,
                    lastUpdateTime: new Date().toISOString(),
                    elapsedTimeAtLastUpdate: timerData.totalDuration || elapsedTime,
                    remainingTimeAtLastUpdate: 0,
                    isCompleted: true,
                    completionMessage: `Great job completing your ${timerData.methodName || 'training'} session!`
                };
                
                await sendPushNotification(pushToken, activityId, completionState, true);
                
                // Mark as completed in Firestore
                await db.collection('activeTimers').doc(userId).update({
                    action: 'stop',
                    isCompleted: true,
                    completedAt: admin.firestore.FieldValue.serverTimestamp()
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
        endTime: timerData.endTime || null,
        methodName: timerData.methodName || 'Training',
        sessionType: timerData.sessionType || 'countup',
        isPaused: timerData.isPaused || false,
        lastUpdateTime: new Date().toISOString(),
        elapsedTimeAtLastUpdate: Math.floor(elapsedTime),
        remainingTimeAtLastUpdate: Math.floor(remainingTime),
        totalDuration: timerData.totalDuration || 0
    };
    
    // Send the push notification
    await sendPushNotification(pushToken, activityId, contentState, false);
}

/**
 * Send push notification to update Live Activity using HTTP/2
 */
async function sendPushNotification(pushToken, activityId, contentState, isCompletion = false) {
    try {
        const authToken = generateAPNsToken();
        
        // Calculate stale date and relevance score
        let staleDate;
        let relevanceScore = 100;
        let event = 'update';
        
        if (isCompletion) {
            // For completion, stale date is 30 minutes from now
            staleDate = Math.floor(Date.now() / 1000) + (30 * 60);
            relevanceScore = 50;
            event = 'end';
        } else if (contentState.sessionType === 'countdown' && contentState.remainingTimeAtLastUpdate > 0) {
            // For countdown timers, stale date is when timer completes + 10 seconds
            const remainingMs = contentState.remainingTimeAtLastUpdate * 1000;
            staleDate = Math.floor((Date.now() + remainingMs) / 1000) + 10;
            // Higher relevance for timers closer to completion
            relevanceScore = Math.max(50, 100 - Math.floor(contentState.remainingTimeAtLastUpdate / 60));
        } else {
            // For countup timers or paused timers, stale date is 2 minutes from now
            staleDate = Math.floor(Date.now() / 1000) + 120;
            relevanceScore = contentState.isPaused ? 75 : 90;
        }
        
        const payload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: event,
                'content-state': contentState,
                'stale-date': staleDate,
                'relevance-score': relevanceScore,
                'dismissal-date': isCompletion ? staleDate + 3600 : undefined // Dismiss 1 hour after completion
            }
        };
        
        // Remove undefined values
        Object.keys(payload.aps).forEach(key => {
            if (payload.aps[key] === undefined) {
                delete payload.aps[key];
            }
        });
        
        const payloadString = JSON.stringify(payload);
        console.log(`Sending Live Activity update: ${payloadString.substring(0, 200)}...`);
        
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
                'apns-topic': 'com.growth.GrowthTimerWidget.push-type.liveactivity', // Widget bundle ID
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
                } else if (statusCode === 410) {
                    console.log(`Activity ${activityId} is no longer active (410)`);
                    stopPushUpdates(activityId);
                    resolve({ success: false, error: 'Activity no longer active' });
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
        return { success: false, error: error.message };
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