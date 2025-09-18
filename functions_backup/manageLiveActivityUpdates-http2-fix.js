// This is the critical HTTP/2 fix for the sendPushNotification function
// Replace the axios-based implementation with this http2 version

const http2 = require('http2');

/**
 * Send push notification to update Live Activity using HTTP/2
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
            const client = http2.connect(`https://api.push.apple.com:443`);
            
            client.on('error', (err) => {
                console.error('HTTP/2 client error:', err);
                resolve({ success: false, error: err.message });
            });

            // Create request
            const req = client.request({
                ':method': 'POST',
                ':path': `/3/device/${pushToken}`,
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