const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Map to track active monitoring (not intervals anymore)
const activeMonitors = new Map();

// Map to track last known states
const lastKnownStates = new Map();

// APNs configuration
const APNS_CONFIG = {
    APNS_HOST_DEV: 'api.development.push.apple.com',
    APNS_PORT: 443,
    APNS_PATH_PREFIX: '/3/device/'
};

/**
 * Generate APNs JWT token
 */
function generateAPNsToken() {
    const keyId = process.env.APNS_KEY_ID?.trim();
    const teamId = process.env.APNS_TEAM_ID?.trim();
    const authKey = process.env.APNS_AUTH_KEY;
    
    console.log('🔐 Generating APNs JWT:', {
        keyId,
        teamId,
        hasAuthKey: !!authKey,
        authKeyLength: authKey ? authKey.length : 0
    });
    
    if (!keyId || !teamId || !authKey) {
        console.error('❌ Missing APNs credentials:', { keyId, teamId, hasAuthKey: !!authKey });
        throw new Error('Missing APNs credentials');
    }
    
    const token = jwt.sign({}, authKey, {
        algorithm: 'ES256',
        header: {
            alg: 'ES256',
            kid: keyId
        },
        issuer: teamId,
        expiresIn: '1h'
    });
    
    console.log('✅ JWT token generated, length:', token.length);
    
    return token;
}

/**
 * Send APNs push notification directly
 */
async function sendAPNsPush(pushToken, payload) {
    const token = generateAPNsToken();
    const payloadString = JSON.stringify(payload);
    
    return new Promise((resolve, reject) => {
        const client = http2.connect(`https://${APNS_CONFIG.APNS_HOST_DEV}:${APNS_CONFIG.APNS_PORT}`);
        
        client.on('error', (err) => {
            console.error('HTTP/2 client error:', err);
            reject(err);
        });

        const req = client.request({
            ':method': 'POST',
            ':path': `${APNS_CONFIG.APNS_PATH_PREFIX}${pushToken}`,
            'authorization': `bearer ${token}`,
            'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
            'apns-push-type': 'liveactivity',
            'apns-priority': '10',
            'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
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
            console.log(`📱 APNs Response:`, {
                statusCode,
                headers: responseHeaders,
                body: responseBody,
                pushToken: pushToken.substring(0, 20) + '...'
            });
            
            if (statusCode === 200) {
                console.log(`✅ Live Activity update sent successfully`);
                resolve({ success: true, response: responseBody });
            } else {
                console.error(`❌ APNs error: ${statusCode} - ${responseBody}`);
                
                // Log specific error details
                if (responseBody.includes('BadDeviceToken')) {
                    console.error('🚨 BadDeviceToken - Token format or environment mismatch');
                } else if (responseBody.includes('InvalidProviderToken')) {
                    console.error('🚨 InvalidProviderToken - JWT token issue');
                } else if (statusCode === 410) {
                    console.error('🚨 410 Gone - Token no longer valid');
                }
                
                reject(new Error(`APNs error: ${statusCode} - ${responseBody}`));
            }
        });

        req.on('error', (error) => {
            console.error(`❌ APNs request error:`, error.message);
            client.close();
            reject(error);
        });

        req.write(payloadString);
        req.end();
    });
}

/**
 * Optimized Live Activity update manager
 * Based on the startedAt/pausedAt approach from the article
 * Only sends push notifications for state changes, not timer updates
 */
exports.manageLiveActivityUpdates = onCall({
    region: 'us-central1',
    maxInstances: 10,
    memory: '256MB',
    timeoutSeconds: 540,
    consumeAppCheckToken: false,
    secrets: ['APNS_AUTH_KEY', 'APNS_KEY_ID', 'APNS_TEAM_ID', 'APNS_TOPIC']
}, async (request) => {
    const { action, activityId, userId, pushToken } = request.data;
    
    console.log('📲 [manageLiveActivityUpdates-Optimized] Called with:', {
        action,
        activityId,
        userId,
        hasPushToken: !!pushToken
    });
    
    // Prevent function timeout - stop monitoring after 9 minutes
    setTimeout(() => {
        stopMonitoring(activityId);
    }, 540000); // 9 minutes
    
    try {
        switch (action) {
            case 'startPushUpdates':
                // Store token and monitor for state changes only
                await startStateMonitoring(activityId, userId, pushToken);
                return { success: true, message: 'State monitoring started' };
                
            case 'stopPushUpdates':
                await stopMonitoring(activityId);
                return { success: true, message: 'Monitoring stopped' };
                
            case 'sendStateUpdate':
                // For immediate state changes (pause/resume/stop)
                await sendStateChangeUpdate(activityId, userId);
                return { success: true, message: 'State update sent' };
                
            default:
                throw new HttpsError('invalid-argument', 'Invalid action');
        }
    } catch (error) {
        console.error('Error managing Live Activity updates:', error);
        throw new HttpsError('internal', error.message);
    }
});

/**
 * Start monitoring for state changes only
 * No periodic updates - iOS handles timer display natively
 */
async function startStateMonitoring(activityId, userId, pushToken) {
    if (activeMonitors.has(activityId)) {
        console.log(`⚠️ Already monitoring activity: ${activityId}`);
        return;
    }
    
    console.log(`🚀 Starting state monitoring for activity: ${activityId}`);
    
    // Store push token if provided
    if (pushToken) {
        await storePushToken(activityId, userId, pushToken);
    }
    
    // Send initial state
    await sendStateChangeUpdate(activityId, userId);
    
    // Mark as active (no interval needed)
    activeMonitors.set(activityId, { userId, startTime: Date.now() });
    
    console.log(`✅ State monitoring active for activity: ${activityId}`);
}

/**
 * Send update only when state changes
 * This should be called by other Firebase functions when timer state changes
 */
async function sendStateChangeUpdate(activityId, userId) {
    console.log(`📊 Sending state change update for activity: ${activityId}`);
    
    if (!admin.apps.length) {
        admin.initializeApp();
    }
    
    const db = admin.firestore();
    
    // Get push token
    let pushToken = null;
    try {
        const tokenDoc = await db.collection('liveActivityTokens').doc(activityId).get();
        if (tokenDoc.exists) {
            const tokenData = tokenDoc.data();
            pushToken = tokenData.pushToken;
            if (!userId) {
                userId = tokenData.userId;
            }
        }
    } catch (error) {
        console.error('Error fetching push token:', error);
    }
    
    if (!pushToken) {
        console.error(`No push token found for activity: ${activityId}`);
        throw new Error(`No push token found for activity: ${activityId}`);
    }
    
    // Get the timer state
    const timerDoc = await db.collection('activeTimers').doc(userId).get();
    
    if (!timerDoc.exists) {
        console.log(`Timer not found for user ${userId}, stopping monitoring`);
        stopMonitoring(activityId);
        return;
    }
    
    const timerData = timerDoc.data();
    
    // Check if timer is stopped
    if (timerData.action === 'stop') {
        console.log(`Timer stopped for activity ${activityId}`);
        stopMonitoring(activityId);
        // Send final update
        await sendFinalUpdate(pushToken, timerData);
        return;
    }
    
    // Extract contentState
    const contentState = timerData.contentState || {};
    
    // Check if this is actually a state change
    const currentState = {
        isPaused: contentState.isPaused || false,
        action: timerData.action,
        startTime: contentState.startTime,
        endTime: contentState.endTime
    };
    
    const lastState = lastKnownStates.get(activityId);
    const isStateChange = !lastState || 
        lastState.isPaused !== currentState.isPaused ||
        lastState.action !== currentState.action;
    
    if (!isStateChange) {
        console.log(`✅ No state change for ${activityId}, skipping update`);
        return;
    }
    
    console.log(`🔄 State change detected for ${activityId}:`, {
        from: lastState,
        to: currentState
    });
    
    // Update last known state
    lastKnownStates.set(activityId, currentState);
    
    // Debug log the raw contentState
    console.log(`📊 Raw contentState from Firestore:`, JSON.stringify(contentState, null, 2));
    
    // Convert timestamps to Unix timestamps (seconds since 1970)
    const startTime = convertFirestoreTimestamp(contentState.startTime);
    const endTime = convertFirestoreTimestamp(contentState.endTime);
    const lastUpdateTime = convertFirestoreTimestamp(contentState.lastUpdateTime || contentState.startTime);
    const lastKnownGoodUpdate = convertFirestoreTimestamp(contentState.lastKnownGoodUpdate || contentState.startTime);
    
    // Debug log converted timestamps
    console.log(`🔍 Converted timestamps:`, {
        startTime: `${startTime} (${startTime.getTime() / 1000})`,
        endTime: `${endTime} (${endTime.getTime() / 1000})`,
        lastUpdateTime: `${lastUpdateTime} (${lastUpdateTime.getTime() / 1000})`,
        lastKnownGoodUpdate: `${lastKnownGoodUpdate} (${lastKnownGoodUpdate.getTime() / 1000})`
    });
    
    // Prepare update payload with ISO strings to avoid timestamp conversion issues
    // iOS ActivityKit seems to convert numeric timestamps to NSDate reference
    const updatePayload = {
        ...contentState,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        lastUpdateTime: lastUpdateTime.toISOString(),
        lastKnownGoodUpdate: lastKnownGoodUpdate.toISOString(),
        updateSource: 'firebase-optimized-state-change'
    };
    
    // Send the update via APNs
    try {
        // Prepare the APNs payload
        const apnsPayload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'update',
                'content-state': updatePayload,
                'stale-date': Math.floor(Date.now() / 1000) + 3600,
                'relevance-score': 100,
                alert: {
                    title: 'Timer Update',
                    body: updatePayload.isPaused ? 'Timer paused' : 'Timer resumed'
                }
            }
        };
        
        const result = await sendAPNsPush(pushToken, apnsPayload);
        
        console.log(`✅ State change update sent for activity ${activityId}`);
        return result;
    } catch (error) {
        console.error(`❌ Failed to send state update for activity ${activityId}:`, error);
        throw error;
    }
}

/**
 * Send final update when timer completes
 */
async function sendFinalUpdate(pushToken, timerData) {
    const contentState = timerData.contentState || {};
    
    // Convert any Firestore timestamps in contentState to Unix timestamps
    const processedContentState = {};
    for (const [key, value] of Object.entries(contentState)) {
        if (key.includes('Time') || key.includes('time')) {
            const date = convertFirestoreTimestamp(value);
            processedContentState[key] = date.getTime() / 1000; // Unix timestamp in seconds
        } else {
            processedContentState[key] = value;
        }
    }
    
    const finalPayload = {
        ...processedContentState,
        isCompleted: true,
        completedAt: Date.now() / 1000, // Unix timestamp in seconds
        updateSource: 'firebase-completion'
    };
    
    try {
        // Set dismissal date to 1 second from now to end the activity
        const dismissalDate = new Date(Date.now() + 1000);
        
        // Prepare final APNs payload with dismissal
        const finalApnsPayload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'end',
                'dismissal-date': Math.floor(dismissalDate.getTime() / 1000),
                'content-state': finalPayload,
                'relevance-score': 0,
                alert: {
                    title: 'Timer Complete',
                    body: 'Your timer has finished'
                }
            }
        };
        
        await sendAPNsPush(pushToken, finalApnsPayload);
        console.log('✅ Final completion update sent');
    } catch (error) {
        console.error('❌ Failed to send final update:', error);
    }
}

/**
 * Stop monitoring for a Live Activity
 */
function stopMonitoring(activityId) {
    console.log(`🛑 Stopping monitoring for activity: ${activityId}`);
    
    if (activeMonitors.has(activityId)) {
        activeMonitors.delete(activityId);
        lastKnownStates.delete(activityId);
        console.log(`✅ Monitoring stopped for activity: ${activityId}`);
    }
}

/**
 * Store push token for an activity
 */
async function storePushToken(activityId, userId, pushToken) {
    if (!admin.apps.length) {
        admin.initializeApp();
    }
    
    const db = admin.firestore();
    
    try {
        await db.collection('liveActivityTokens').doc(activityId).set({
            pushToken,
            userId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            environment: pushToken.startsWith('dev_') ? 'development' : 'production'
        });
        console.log(`✅ Push token stored for activity ${activityId}`);
    } catch (error) {
        console.error('Error storing push token:', error);
    }
}

/**
 * Convert Firestore timestamp to Date
 */
function convertFirestoreTimestamp(timestamp) {
    if (!timestamp) {
        console.error('❌ No timestamp provided');
        return new Date();
    }
    
    if (timestamp instanceof Date) {
        return timestamp;
    }
    
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
        return timestamp.toDate();
    }
    
    if (timestamp._seconds !== undefined) {
        return new Date(timestamp._seconds * 1000);
    }
    
    if (typeof timestamp === 'string') {
        // Handle ISO date strings
        const date = new Date(timestamp);
        if (!isNaN(date.getTime())) {
            return date;
        }
        console.error('❌ Invalid date string:', timestamp);
        return new Date();
    }
    
    if (typeof timestamp === 'number') {
        if (timestamp < 10000000000) {
            return new Date(timestamp * 1000);
        } else {
            return new Date(timestamp);
        }
    }
    
    console.error('❌ Unknown timestamp format:', timestamp);
    return new Date();
}

/**
 * This function should be called by other Firebase functions
 * when timer state changes (pause, resume, stop)
 */
exports.notifyLiveActivityStateChange = onCall({
    region: 'us-central1',
    consumeAppCheckToken: false,
    secrets: ['APNS_AUTH_KEY', 'APNS_KEY_ID', 'APNS_TEAM_ID', 'APNS_TOPIC']
}, async (request) => {
    const { activityId, userId } = request.data;
    
    if (!activityId || !userId) {
        throw new HttpsError('invalid-argument', 'Missing activityId or userId');
    }
    
    console.log(`📢 State change notification for activity ${activityId}`);
    
    try {
        await sendStateChangeUpdate(activityId, userId);
        return { success: true, message: 'State change processed' };
    } catch (error) {
        console.error('Error processing state change:', error);
        throw new HttpsError('internal', error.message);
    }
});

// Clean up on function instance termination
process.on('SIGTERM', () => {
    console.log('⚠️ Function instance terminating, cleaning up...');
    activeMonitors.clear();
    lastKnownStates.clear();
});

/**
 * Key improvements based on the article:
 * 
 * 1. NO PERIODIC UPDATES - iOS handles timer display natively
 * 2. Only send push notifications for STATE CHANGES (pause/resume/stop)
 * 3. Use startedAt/pausedAt approach - let iOS calculate elapsed time
 * 4. Drastically reduced server load and battery usage
 * 5. Better compliance with Apple's Live Activity guidelines
 * 
 * The timer will update smoothly on the device using Text(timerInterval:)
 * without any push notifications needed for the visual updates.
 */