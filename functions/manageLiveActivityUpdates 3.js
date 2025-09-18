const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const axios = require('axios');
const jwt = require('jsonwebtoken');

// Apple Push Notification Service (APNs) configuration
const APNS_HOST = process.env.APNS_HOST || 'https://api.push.apple.com';
const TEAM_ID = process.env.APNS_TEAM_ID || 'YOUR_TEAM_ID';
const KEY_ID = process.env.APNS_KEY_ID || 'YOUR_KEY_ID';
let APNS_KEY = process.env.APNS_AUTH_KEY || `-----BEGIN PRIVATE KEY-----
YOUR_APNS_AUTH_KEY_HERE
-----END PRIVATE KEY-----`;

// Replace escaped newlines with actual newlines
if (APNS_KEY && APNS_KEY.includes('\\n')) {
    APNS_KEY = APNS_KEY.replace(/\\n/g, '\n');
}

// Generate APNs authentication token
function generateAPNsToken() {
    // Check if APNs is properly configured
    if (!APNS_KEY || APNS_KEY.includes('YOUR_APNS_AUTH_KEY_HERE')) {
        console.warn('APNs authentication key not configured. Live Activity push updates will not work.');
        console.warn('To enable push updates, set APNS_AUTH_KEY environment variable.');
        return null;
    }
    
    if (KEY_ID === 'YOUR_KEY_ID' || TEAM_ID === 'YOUR_TEAM_ID') {
        console.warn('APNs configuration incomplete. Please set APNS_KEY_ID and APNS_TEAM_ID environment variables.');
        return null;
    }
    
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
    { region: 'us-central1' },
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
    
    // Get the push token (but don't return if not found - we still need to check timer state)
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
                // Send completion update with dismissal date
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
                    
                    // Send completion update with a 5-minute stale date (completion shouldn't go stale)
                    const completionStaleDate = Math.floor(Date.now() / 1000) + 300;
                    const dismissalDate = Math.floor(Date.now() / 1000) + 6; // Dismiss after 6 seconds
                    
                    const payload = {
                        aps: {
                            timestamp: Math.floor(Date.now() / 1000),
                            event: 'update',
                            'content-state': completionState,
                            'stale-date': completionStaleDate,
                            'dismissal-date': dismissalDate
                        }
                    };
                    
                    const authToken = generateAPNsToken();
                    if (authToken) {
                        try {
                            const response = await axios.post(
                                `${APNS_HOST}/3/device/${pushToken}`,
                                JSON.stringify(payload),
                                {
                                    headers: {
                                        'authorization': `bearer ${authToken}`,
                                        'apns-topic': 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity',
                                        'apns-push-type': 'liveactivity',
                                        'apns-priority': '10',
                                        'apns-expiration': '0'
                                    }
                                }
                            );
                            
                            if (response.status === 200) {
                                console.log(`Successfully sent completion update for activity: ${activityId} with dismissal at ${new Date(dismissalDate * 1000).toISOString()}`);
                            }
                        } catch (error) {
                            console.error('Error sending completion notification:', error.response?.data || error.message);
                        }
                    }
                } else {
                    console.log(`Timer completed but no push token available for activity ${activityId}`);
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
        // The timer state is still being tracked server-side, we just can't send the push yet
    }
}

/**
 * Send dismissal notification to end Live Activity
 */
async function sendDismissalNotification(pushToken, activityId, delaySeconds = 2) {
    try {
        const authToken = generateAPNsToken();
        
        if (!authToken) {
            console.log(`Skipping dismissal notification for activity ${activityId} - APNs not configured`);
            return;
        }
        
        const dismissalDate = Math.floor(Date.now() / 1000) + delaySeconds;
        const payload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'end',
                'dismissal-date': dismissalDate
            }
        };
        
        const response = await axios.post(
            `${APNS_HOST}/3/device/${pushToken}`,
            JSON.stringify(payload),
            {
                headers: {
                    'authorization': `bearer ${authToken}`,
                    'apns-topic': 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity',
                    'apns-push-type': 'liveactivity',
                    'apns-priority': '10'
                }
            }
        );
        
        if (response.status === 200) {
            console.log(`Successfully sent dismissal for activity: ${activityId} (dismissal at ${new Date(dismissalDate * 1000).toISOString()})`);
        }
    } catch (error) {
        console.error('Error sending dismissal notification:', error.response?.data || error.message);
    }
}

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
        
        const response = await axios.post(
            `${APNS_HOST}/3/device/${pushToken}`,
            JSON.stringify(payload),
            {
                headers: {
                    'authorization': `bearer ${authToken}`,
                    'apns-topic': 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity',
                    'apns-push-type': 'liveactivity',
                    'apns-priority': '10',
                    'apns-expiration': '0'
                }
            }
        );
        
        if (response.status === 200) {
            console.log(`Successfully sent push update for activity: ${activityId}`);
        }
    } catch (error) {
        console.error('Error sending push notification:', error.response?.data || error.message);
        // Don't throw the error - let the timer continue tracking server-side
        // The push notification failure shouldn't stop the timer tracking
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