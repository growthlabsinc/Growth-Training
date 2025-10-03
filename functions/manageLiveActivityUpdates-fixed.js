const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Define the secrets
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');
const apnsTopicSecret = defineSecret('APNS_TOPIC');

// Apple Push Notification Service (APNs) configuration
const APNS_HOST = process.env.APNS_HOST || 'api.development.push.apple.com';
const TEAM_ID = process.env.APNS_TEAM_ID?.trim() || '62T6J77P6R';
const KEY_ID = process.env.APNS_KEY_ID?.trim() || '55LZB28UY2'; // Sandbox key for development server

// Generate APNs authentication token
function generateAPNsToken() {
    const APNS_KEY = process.env.APNS_AUTH_KEY;
    
    if (!APNS_KEY) {
        console.error('❌ [APNs] Authentication key not found in environment');
        return null;
    }
    
    if (KEY_ID === 'YOUR_KEY_ID' || TEAM_ID === 'YOUR_TEAM_ID') {
        console.warn('APNs configuration incomplete. Please set APNS_KEY_ID and APNS_TEAM_ID environment variables.');
        return null;
    }
    
    try {
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
        console.log('✅ [APNs] Generated JWT token successfully');
        return token;
    } catch (error) {
        console.error('❌ [APNs] Failed to generate JWT token:', error.message);
        return null;
    }
}

// Map to store active intervals for each activity
const activeIntervals = new Map();

// Map to track recent requests to prevent duplicate processing
const recentRequests = new Map();

/**
 * Manage Live Activity updates - start/stop server-side push updates
 */
exports.manageLiveActivityUpdates = onCall(
    { 
        region: 'us-central1',
        secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret],
        consumeAppCheckToken: false
    },
    async (request) => {
        console.log('📥 manageLiveActivityUpdates called with:', {
            hasAuth: !!request.auth,
            userId: request.auth?.uid || request.data?.userId,
            activityId: request.data?.activityId,
            action: request.data?.action
        });
        
        const { activityId, userId, action } = request.data;
        
        if (!activityId || !action) {
            console.error('❌ Missing required parameters:', { activityId, action });
            throw new HttpsError('invalid-argument', 'Missing required parameters');
        }
        
        // Debounce duplicate requests
        const requestKey = `${activityId}-${action}`;
        const lastRequest = recentRequests.get(requestKey);
        const now = Date.now();
        
        if (lastRequest && (now - lastRequest) < 5000) {
            console.log(`⚠️ Ignoring duplicate request for ${requestKey} (last request was ${now - lastRequest}ms ago)`);
            return { success: true, message: 'Request already being processed' };
        }
        
        recentRequests.set(requestKey, now);
        
        // Clean up old entries after 10 seconds
        setTimeout(() => {
            recentRequests.delete(requestKey);
        }, 10000);
    
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
    if (activeIntervals.has(activityId)) {
        console.log(`⚠️ Push updates already active for activity: ${activityId}, skipping duplicate start`);
        return;
    }
    
    stopPushUpdates(activityId);
    
    console.log(`Starting push updates for activity: ${activityId}, user: ${userId}`);
    
    // Send immediate update
    await sendTimerUpdate(activityId, userId);
    
    // Set up periodic updates every second
    let updateCount = 0;
    const intervalId = setInterval(async () => {
        try {
            updateCount++;
            console.log(`🔵 [Push Interval] Update #${updateCount} for activity ${activityId} at ${new Date().toISOString()}`);
            await sendTimerUpdate(activityId, userId);
        } catch (error) {
            console.error(`Error sending update for activity ${activityId}:`, error);
            if (error.message.includes('not found') || error.message.includes('expired')) {
                stopPushUpdates(activityId);
            }
        }
    }, 100); // Update every 100ms for smooth Live Activity updates
    
    activeIntervals.set(activityId, intervalId);
    console.log(`✅ Interval started for activity ${activityId}, total active intervals: ${activeIntervals.size}`);
}

/**
 * Stop periodic push updates for a Live Activity
 */
function stopPushUpdates(activityId) {
    const intervalId = activeIntervals.get(activityId);
    if (intervalId) {
        clearInterval(intervalId);
        activeIntervals.delete(activityId);
        console.log(`Stopped push updates for activity: ${activityId}, remaining active intervals: ${activeIntervals.size}`);
    } else {
        console.log(`No active interval found for activity: ${activityId}`);
    }
}

/**
 * Safely convert Firestore timestamp to JavaScript Date
 */
function convertFirestoreTimestamp(timestamp) {
    if (!timestamp) {
        return new Date();
    }
    
    // If it's already a Date object
    if (timestamp instanceof Date) {
        return timestamp;
    }
    
    // If it's a string
    if (typeof timestamp === 'string') {
        return new Date(timestamp);
    }
    
    // If it has a toDate method (Firestore Timestamp)
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
        return timestamp.toDate();
    }
    
    // If it has _seconds property (Firestore Timestamp in JSON format)
    if (timestamp._seconds !== undefined) {
        // CRITICAL FIX: Ensure _seconds is a valid number
        const seconds = Number(timestamp._seconds);
        if (isNaN(seconds) || seconds < 0 || seconds > 2147483647) {
            console.error('❌ Invalid timestamp seconds:', timestamp._seconds);
            return new Date(); // Return current date as fallback
        }
        return new Date(seconds * 1000);
    }
    
    // If it's a number (assume milliseconds)
    if (typeof timestamp === 'number') {
        // Check if it's seconds or milliseconds
        if (timestamp < 10000000000) {
            // Likely seconds
            return new Date(timestamp * 1000);
        } else {
            // Likely milliseconds
            return new Date(timestamp);
        }
    }
    
    console.error('❌ Unknown timestamp format:', timestamp);
    return new Date(); // Fallback to current date
}

/**
 * Send a timer update to a specific Live Activity
 */
async function sendTimerUpdate(activityId, userId) {
    console.log(`📊 [sendTimerUpdate] Starting update for activity: ${activityId}, user: ${userId}`);
    
    // Initialize admin if needed
    if (!admin.apps.length) {
        admin.initializeApp();
        console.log('✅ Firebase Admin SDK initialized in sendTimerUpdate');
    }
    
    const db = admin.firestore();
    
    // Get the push token
    let pushToken = null;
    let tokenData = null;
    
    try {
        const tokenDoc = await db.collection('liveActivityTokens').doc(activityId).get();
        
        if (tokenDoc.exists) {
            tokenData = tokenDoc.data();
            pushToken = tokenData.pushToken;
            console.log(`✅ [sendTimerUpdate] Found push token for activity ${activityId}`);
            
            if (!userId) {
                userId = tokenData.userId;
            }
        } else {
            console.log(`⚠️ [sendTimerUpdate] No push token found for activity ${activityId}`);
        }
    } catch (error) {
        console.error(`❌ [sendTimerUpdate] Error fetching push token:`, error);
    }
    
    // Ensure we have a userId
    if (!userId) {
        console.error(`❌ [sendTimerUpdate] No userId provided and no token data found for activity: ${activityId}`);
        throw new Error(`Cannot determine userId for activity: ${activityId}`);
    }
    
    // Get the timer state from Firestore
    let timerDoc;
    try {
        timerDoc = await db.collection('activeTimers').doc(userId).get();
    
        if (!timerDoc.exists) {
            console.log(`⏳ [sendTimerUpdate] Timer state not found on first try for user ${userId}, retrying in 1 second...`);
            await new Promise(resolve => setTimeout(resolve, 1000));
            timerDoc = await db.collection('activeTimers').doc(userId).get();
        }
        
        if (!timerDoc.exists) {
            console.error(`❌ [sendTimerUpdate] Timer state not found for user: ${userId} after retry`);
            throw new Error(`Timer state not found for user: ${userId}`);
        }
    } catch (error) {
        console.error(`❌ [sendTimerUpdate] Error fetching timer state:`, error);
        throw error;
    }
    
    const timerData = timerDoc.data();
    console.log(`📊 [Timer State Found] User: ${userId}, Activity: ${activityId}`);
    
    // Check if timer is stopped
    if (timerData.action === 'stop') {
        console.log(`⏹️ [Timer Stopped] Stopping push updates for activity ${activityId}`);
        stopPushUpdates(activityId);
        return;
    }
    
    // Extract contentState from nested structure
    const contentState = timerData.contentState || {};
    
    // Calculate current timer values
    const now = new Date();
    
    // CRITICAL FIX: Safely convert timestamps
    const startTime = convertFirestoreTimestamp(contentState.startTime);
    const endTime = convertFirestoreTimestamp(contentState.endTime);
    
    console.log(`🟡 [Timestamp Conversion] Start time: ${startTime.toISOString()}`);
    console.log(`🟡 [Timestamp Conversion] End time: ${endTime.toISOString()}`);
    console.log(`🟡 [Timestamp Conversion] Current time: ${now.toISOString()}`);
    
    // Validate dates
    const yearInMs = 365 * 24 * 60 * 60 * 1000;
    if (Math.abs(now - startTime) > yearInMs || Math.abs(now - endTime) > yearInMs) {
        console.error('❌ [Date Validation] Dates appear to be corrupted');
        console.error(`  - Start time diff from now: ${Math.abs(now - startTime) / 1000 / 60 / 60 / 24} days`);
        console.error(`  - End time diff from now: ${Math.abs(now - endTime) / 1000 / 60 / 60 / 24} days`);
        
        // Fix the dates by using reasonable defaults
        const fixedStartTime = new Date(now.getTime() - (contentState.elapsedTimeAtLastUpdate || 0) * 1000);
        const fixedEndTime = contentState.sessionType === 'countdown' 
            ? new Date(fixedStartTime.getTime() + ((contentState.elapsedTimeAtLastUpdate || 0) + (contentState.remainingTimeAtLastUpdate || 60)) * 1000)
            : new Date(now.getTime() + 8 * 60 * 60 * 1000); // 8 hours for countup
            
        console.log(`🔧 [Date Fix] Using corrected times:`);
        console.log(`  - Fixed start time: ${fixedStartTime.toISOString()}`);
        console.log(`  - Fixed end time: ${fixedEndTime.toISOString()}`);
        
        // Use the fixed times
        startTime.setTime(fixedStartTime.getTime());
        endTime.setTime(fixedEndTime.getTime());
    }
    
    // For calculating time since last update, use the updatedAt field or startTime
    const lastUpdateTime = timerData.updatedAt ? convertFirestoreTimestamp(timerData.updatedAt) : startTime;
    const timeSinceLastUpdate = (now - lastUpdateTime) / 1000; // in seconds
    
    let elapsedTime, remainingTime;
    
    // Debug logging
    console.log(`🟡 [Push Update Debug] Activity: ${activityId}, User: ${userId}`);
    console.log(`🟡 [Push Update Debug] Current time: ${now.toISOString()}`);
    console.log(`🟡 [Push Update Debug] Last update time: ${lastUpdateTime.toISOString()}`);
    console.log(`🟡 [Push Update Debug] Time since last update: ${timeSinceLastUpdate}s`);
    console.log(`🟡 [Push Update Debug] Timer is paused: ${contentState.isPaused}`);
    console.log(`🟡 [Push Update Debug] Session type: ${contentState.sessionType}`);
    
    if (contentState.isPaused) {
        // If paused, use the stored elapsed/remaining times
        elapsedTime = contentState.elapsedTimeAtPause || contentState.elapsedTimeAtLastUpdate || 0;
        remainingTime = contentState.remainingTimeAtPause || contentState.remainingTimeAtLastUpdate || 0;
        console.log(`🟡 [Push Update Debug] Paused values - elapsed: ${elapsedTime}s, remaining: ${remainingTime}s`);
    } else {
        // If running, calculate based on current time
        elapsedTime = Math.max(0, (now - startTime) / 1000);
        
        if (contentState.sessionType === 'countdown') {
            const totalDuration = Math.max(0, (endTime - startTime) / 1000);
            remainingTime = Math.max(0, (endTime - now) / 1000);
            console.log(`🟡 [Push Update Debug] Countdown - elapsed: ${elapsedTime}s, remaining: ${remainingTime}s, total: ${totalDuration}s`);
            
            // Check if timer has completed
            if (remainingTime <= 0) {
                // Send completion update
                if (pushToken) {
                    const completionState = {
                        startTime: Math.floor(startTime.getTime() / 1000),
                        endTime: Math.floor(now.getTime() / 1000),
                        methodName: contentState.methodName,
                        sessionType: contentState.sessionType,
                        isPaused: false,
                        lastUpdateTime: Math.floor(now.getTime() / 1000),
                        elapsedTimeAtLastUpdate: totalDuration,
                        remainingTimeAtLastUpdate: 0,
                        lastKnownGoodUpdate: Math.floor(now.getTime() / 1000),
                        expectedEndTime: Math.floor(now.getTime() / 1000),
                        isCompleted: true,
                        completionMessage: `Great job completing your ${contentState.methodName} session!`
                    };
                    
                    const completionStaleDate = Math.floor(Date.now() / 1000) + 300;
                    const dismissalDate = Math.floor(Date.now() / 1000) + 300;
                    
                    const payload = {
                        aps: {
                            timestamp: Math.floor(Date.now() / 1000),
                            event: 'update',
                            'content-state': completionState,
                            'stale-date': completionStaleDate,
                            'dismissal-date': dismissalDate
                        }
                    };
                    
                    await sendPushNotification(pushToken, activityId, payload);
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
    
    // Ensure reasonable values
    elapsedTime = Math.min(Math.max(0, elapsedTime), 86400); // Max 24 hours
    remainingTime = Math.min(Math.max(0, remainingTime), 86400); // Max 24 hours
    
    // Prepare the content state for the push update
    const pushContentState = {
        startTime: Math.floor(startTime.getTime() / 1000),
        endTime: Math.floor(endTime.getTime() / 1000),
        methodName: contentState.methodName,
        sessionType: contentState.sessionType,
        isPaused: contentState.isPaused,
        lastUpdateTime: Math.floor(now.getTime() / 1000),
        elapsedTimeAtLastUpdate: elapsedTime,
        remainingTimeAtLastUpdate: remainingTime,
        lastKnownGoodUpdate: Math.floor(now.getTime() / 1000),
        expectedEndTime: contentState.sessionType === 'countdown' ? Math.floor(endTime.getTime() / 1000) : null
    };
    
    // Send the push notification if we have a token
    if (pushToken) {
        const staleDate = contentState.sessionType === 'countdown' && pushContentState.expectedEndTime
            ? Math.floor(endTime.getTime() / 1000) + 10
            : Math.floor(Date.now() / 1000) + 60;
        
        const payload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'update',
                'content-state': pushContentState,
                'stale-date': staleDate
            }
        };
        
        console.log(`📤 [Has Push Token] Activity ${activityId} - Sending push notification`);
        await sendPushNotification(pushToken, activityId, payload);
    } else {
        console.log(`⚠️ [No Push Token] Skipping push notification for activity ${activityId} - no push token available yet`);
    }
}

/**
 * Send push notification to APNs
 */
async function sendPushNotification(pushToken, activityId, payload) {
    try {
        const authToken = generateAPNsToken();
        
        if (!authToken) {
            console.log(`Skipping push notification for activity ${activityId} - APNs not configured`);
            return;
        }
        
        console.log(`🟠 [Push Notification] Sending update for activity: ${activityId}`);
        console.log(`🟠 [Push Notification] Payload:`, JSON.stringify(payload, null, 2));
        
        const payloadString = JSON.stringify(payload);
        
        // Send using HTTP/2
        await new Promise((resolve, reject) => {
            const client = http2.connect(`https://${APNS_HOST}:443`);
            
            client.on('error', (err) => {
                console.error('HTTP/2 client error:', err);
                reject(err);
            });

            const req = client.request({
                ':method': 'POST',
                ':path': `/3/device/${pushToken}`,
                'authorization': `bearer ${authToken}`,
                'apns-topic': process.env.APNS_TOPIC?.trim() || 'com.growthlabs.growthmethod',
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
                    console.log(`✅ [Push Notification] Successfully sent push update for activity: ${activityId}`);
                    resolve({ success: true });
                } else {
                    console.error(`❌ [Push Notification] APNs error: ${statusCode} - ${responseBody}`);
                    reject(new Error(`APNs error: ${statusCode} - ${responseBody}`));
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