/**
 * Firebase Cloud Functions for Live Activity Push Updates
 */

const functionsV2 = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

// Initialize admin if not already initialized
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
} catch (error) {
  console.error('Error initializing admin:', error);
}

// APNs configuration
// Note: Apple uses the same hostname for both production and development
// The environment is determined by the app's provisioning profile and push token
const APNS_HOST = 'api.push.apple.com';
const APNS_PORT = 443;
const APNS_PATH_PREFIX = '/3/device/';

// APNs configuration will be loaded at runtime
let apnsKey;
let apnsKeyId;
let apnsTeamId;
let apnsTopic;
let apnsConfigLoaded = false;

/**
 * Load APNs configuration from environment variables
 */
async function loadAPNsConfig() {
  if (apnsConfigLoaded) return;
  
  try {
    // These are the known values from Firebase config
    apnsKeyId = '3G84L8G52R';
    apnsTeamId = '62T6J77P6R';
    
    // Default to production topic, but can be overridden by environment
    apnsTopic = process.env.APNS_TOPIC || 'com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity';
    
    // Try to get the auth key from environment or config
    if (process.env.APNS_AUTH_KEY) {
      apnsKey = process.env.APNS_AUTH_KEY;
      console.log('Loaded APNs key from environment');
    } else {
      // Load from Firebase config (already set)
      const functions = require('firebase-functions');
      const config = functions.config();
      if (config.apns && config.apns.auth_key) {
        apnsKey = config.apns.auth_key;
        console.log('Loaded APNs key from Firebase config');
      }
    }
    
    if (!apnsKey) {
      throw new Error('APNs auth key not found');
    }
    
    // Clean up the auth key
    if (apnsKey.startsWith('"') && apnsKey.endsWith('"')) {
      apnsKey = apnsKey.slice(1, -1);
    }
    
    console.log('✅ Successfully loaded APNs configuration');
    console.log('- Key ID:', apnsKeyId);
    console.log('- Team ID:', apnsTeamId);
    console.log('- Topic:', apnsTopic);
    apnsConfigLoaded = true;
  } catch (error) {
    console.error('❌ Failed to load APNs configuration:', error.message);
    throw error;
  }
}

/**
 * Generate JWT token for APNs authentication
 */
async function generateAPNsToken() {
  await loadAPNsConfig();
  
  if (!apnsKey || !apnsKeyId || !apnsTeamId) {
    throw new Error('APNs not configured properly');
  }
  
  try {
    const token = jwt.sign(
      {
        iss: apnsTeamId,
        iat: Math.floor(Date.now() / 1000)
      },
      apnsKey,
      {
        algorithm: 'ES256',
        keyid: apnsKeyId
      }
    );
    return token;
  } catch (error) {
    console.error('Failed to generate APNs JWT token:', error);
    throw new Error(`Failed to generate APNs token: ${error.message}`);
  }
}

/**
 * Send push update to Live Activity
 */
async function sendLiveActivityUpdate(pushToken, activityId, contentState, dismissalDate = null, topicOverride = null) {
  const payload = {
    'aps': {
      'timestamp': Math.floor(Date.now() / 1000),
      'event': 'update',
      'content-state': contentState,
      'alert': {
        'title': contentState.methodName,
        'body': contentState.isPaused ? 'Timer Paused' : 'Timer Running'
      }
    }
  };

  if (dismissalDate) {
    payload.aps['dismissal-date'] = Math.floor(dismissalDate.getTime() / 1000);
  }

  const payloadString = JSON.stringify(payload);
  const token = await generateAPNsToken();

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
      'authorization': `bearer ${token}`,
      'apns-topic': topicOverride || apnsTopic,
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
      if (statusCode === 200) {
        console.log(`✅ Live Activity update sent successfully for activity ${activityId}`);
        resolve({ success: true, response: responseBody });
      } else {
        const errorInfo = {
          statusCode,
          response: responseBody,
          headers: responseHeaders
        };
        
        // Log specific error types
        if (statusCode === 400) {
          console.error('❌ Bad request - invalid payload or headers', errorInfo);
          if (responseBody.includes('BadDeviceToken')) {
            console.error('  💡 This usually means:');
            console.error('     - Token is from dev/sandbox but using production APNs');
            console.error('     - Token has expired or been invalidated');
            console.error('     - Topic doesn\'t match the app bundle ID');
            console.error('  📱 Topic used:', topicOverride || apnsTopic);
            console.error('  🔑 Token (first 20 chars):', pushToken.substring(0, 20) + '...');
          }
        } else if (statusCode === 403) {
          console.error('❌ Forbidden - invalid token or certificate', errorInfo);
        } else if (statusCode === 404) {
          console.error('❌ Device token not found or invalid', errorInfo);
        } else if (statusCode === 410) {
          console.error('❌ Device token is no longer active', errorInfo);
        }
        
        console.error(`❌ APNs error: ${statusCode} - ${responseBody}`);
        reject(new Error(`APNs error: ${statusCode} - ${responseBody}`));
      }
    });

    req.on('error', (error) => {
      console.error('Request error:', error);
      client.close();
      reject(error);
    });

    // Send the payload
    req.write(payloadString);
    req.end();
  });
}

/**
 * Update Live Activity with new content state format
 */
exports.updateLiveActivity = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, contentState, pushToken } = request.data;

    if (!activityId || !contentState) {
      throw new HttpsError('invalid-argument', 'activityId and contentState are required');
    }

    try {
      let finalPushToken = pushToken;
      let tokenData = null;
      
      if (!finalPushToken) {
        const tokenDoc = await admin.firestore()
          .collection('liveActivityTokens')
          .doc(activityId)
          .get();

        if (!tokenDoc.exists) {
          throw new HttpsError('not-found', 'Live Activity token not found');
        }

        tokenData = tokenDoc.data();
        
        if (tokenData.userId !== request.auth.uid) {
          throw new HttpsError('permission-denied', 'Not authorized to update this activity');
        }
        
        finalPushToken = tokenData.pushToken;
      }

      // Use the environment-specific topic if available
      let topicOverride = null;
      if (tokenData) {
        if (tokenData.widgetBundleId) {
          // New tokens have widgetBundleId
          topicOverride = `${tokenData.widgetBundleId}.push-type.liveactivity`;
          console.log(`📱 Using dynamic topic from token data: ${topicOverride}`);
        } else if (tokenData.environment) {
          // Fallback: construct topic from environment
          let bundleId;
          switch (tokenData.environment) {
            case 'development':
              bundleId = 'com.growth.dev';
              break;
            case 'staging':
              bundleId = 'com.growth.staging';
              break;
            case 'production':
            default:
              bundleId = 'com.growthtraining.Growth';
              break;
          }
          topicOverride = `${bundleId}.GrowthTimerWidget.push-type.liveactivity`;
          console.log(`📱 Using topic based on environment (${tokenData.environment}): ${topicOverride}`);
        }
      }

      await sendLiveActivityUpdate(finalPushToken, activityId, contentState, null, topicOverride);

      await admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .set({
          activityId,
          contentState,
          lastUpdate: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

      return { success: true, activityId };

    } catch (error) {
      console.error('Error updating Live Activity:', error);
      
      if (error.message?.includes('APNs not configured')) {
        throw new HttpsError('failed-precondition', 'APNs configuration error. Please contact support.');
      }
      
      throw new HttpsError('internal', error.message);
    }
  }
);

/**
 * Cloud Function to update Live Activity timer state
 */
exports.updateLiveActivityTimer = onCall(
  {
    cors: true,
    region: 'us-central1',
    consumeAppCheckToken: false,
    memory: '256MiB',
    timeoutSeconds: 30
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, action, endTime } = request.data;

    if (!activityId || !action) {
      throw new HttpsError('invalid-argument', 'activityId and action are required');
    }

    try {
      const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        throw new HttpsError('not-found', 'Live Activity token not found');
      }

      const tokenData = tokenDoc.data();
      
      if (tokenData.userId !== request.auth.uid) {
        throw new HttpsError('permission-denied', 'Not authorized to update this activity');
      }
      
      // Get topic override if available
      let topicOverride = null;
      if (tokenData.widgetBundleId) {
        // New tokens have widgetBundleId
        topicOverride = `${tokenData.widgetBundleId}.push-type.liveactivity`;
        console.log(`📱 Using dynamic topic: ${topicOverride}`);
      } else if (tokenData.environment) {
        // Fallback: construct topic from environment
        let bundleId;
        switch (tokenData.environment) {
          case 'development':
            bundleId = 'com.growth.dev';
            break;
          case 'staging':
            bundleId = 'com.growth.staging';
            break;
          case 'production':
          default:
            bundleId = 'com.growthtraining.Growth';
            break;
        }
        topicOverride = `${bundleId}.GrowthTimerWidget.push-type.liveactivity`;
        console.log(`📱 Using topic based on environment (${tokenData.environment}): ${topicOverride}`);
      }

      const timerDoc = await admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .get();

      let contentState = {
        startTime: new Date().toISOString(),
        endTime: endTime || new Date(Date.now() + 3600000).toISOString(),
        methodName: tokenData.methodName || 'Timer',
        sessionType: 'countdown',
        isPaused: false
      };

      if (timerDoc.exists) {
        const timerData = timerDoc.data();
        if (timerData.contentState) {
          contentState = {
            ...contentState,
            ...timerData.contentState
          };
          
          if (contentState.startTime && contentState.startTime.toDate) {
            contentState.startTime = contentState.startTime.toDate().toISOString();
          }
          if (contentState.endTime && contentState.endTime.toDate) {
            contentState.endTime = contentState.endTime.toDate().toISOString();
          }
        }
      }

      switch (action) {
        case 'pause':
          contentState.isPaused = true;
          break;
        case 'resume':
          contentState.isPaused = false;
          break;
        case 'stop':
          await sendLiveActivityUpdate(
            tokenData.pushToken,
            activityId,
            contentState,
            new Date(),
            topicOverride
          );
          
          await tokenDoc.ref.delete();
          
          return { success: true, action: 'stopped' };
        default:
          throw new HttpsError('invalid-argument', 'Invalid action');
      }

      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState,
        null,
        topicOverride
      );

      await admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .set({
          contentState,
          activityId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

      return { success: true, action, contentState };

    } catch (error) {
      console.error('Error updating Live Activity:', error);
      
      if (error.message?.includes('APNs not configured')) {
        throw new HttpsError('failed-precondition', 'APNs configuration error. Please contact support.');
      }
      
      throw new HttpsError('internal', error.message);
    }
  }
);

/**
 * Trigger Live Activity updates when timer state changes in Firestore
 */
exports.onTimerStateChange = onDocumentWritten(
  'activeTimers/{userId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const afterData = snapshot.after.exists ? snapshot.after.data() : null;
    const beforeData = snapshot.before.exists ? snapshot.before.data() : null;

    if (!afterData || !afterData.activityId) {
      console.log('No afterData or activityId found');
      return;
    }
    
    if (beforeData && afterData.lastPushUpdate && 
        beforeData.lastPushUpdate !== afterData.lastPushUpdate &&
        beforeData.contentState?.isPaused === afterData.contentState?.isPaused) {
      console.log('Processing push update trigger');
    } else {
      if (beforeData && 
          beforeData.contentState?.isPaused === afterData.contentState?.isPaused &&
          beforeData.contentState?.endTime?.isEqual?.(afterData.contentState?.endTime)) {
        console.log('No state change detected, skipping update');
        return;
      }
    }

    const userId = event.params.userId;
    const activityId = afterData.activityId;

    try {
      const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        console.log('No Live Activity token found for activity:', activityId);
        return;
      }

      const tokenData = tokenDoc.data();
      
      // Get topic override if available
      let topicOverride = null;
      if (tokenData.widgetBundleId) {
        topicOverride = `${tokenData.widgetBundleId}.push-type.liveactivity`;
      }
      
      let contentState = afterData.contentState || {};
      
      if (contentState.startTime && contentState.startTime.toDate) {
        contentState.startTime = contentState.startTime.toDate().toISOString();
      }
      if (contentState.endTime && contentState.endTime.toDate) {
        contentState.endTime = contentState.endTime.toDate().toISOString();
      }
      
      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState,
        null,
        topicOverride
      );

      console.log('Successfully updated Live Activity:', activityId);

    } catch (error) {
      console.error('Error in onTimerStateChange:', error);
    }
  }
);

/**
 * Start a new Live Activity via push-to-start
 */
exports.startLiveActivity = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { userId, attributes, contentState } = request.data;

    if (!userId || !attributes || !contentState) {
      throw new HttpsError('invalid-argument', 'userId, attributes, and contentState are required');
    }

    if (userId !== request.auth.uid) {
      throw new HttpsError('permission-denied', 'Cannot start activity for another user');
    }

    try {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User not found');
      }

      const userData = userDoc.data();
      const pushToStartToken = userData.liveActivityPushToStartToken;

      if (!pushToStartToken) {
        throw new HttpsError('failed-precondition', 'Push-to-start not available for this user');
      }

      const payload = {
        'aps': {
          'timestamp': Math.floor(Date.now() / 1000),
          'event': 'start',
          'attributes-type': 'TimerActivityAttributes',
          'attributes': attributes,
          'content-state': contentState,
          'alert': {
            'title': contentState.methodName,
            'body': 'Timer started remotely'
          }
        }
      };

      const payloadString = JSON.stringify(payload);
      const token = await generateAPNsToken();

      const options = {
        hostname: APNS_HOST,
        port: APNS_PORT,
        path: `${APNS_PATH_PREFIX}${pushToStartToken}`,
        method: 'POST',
        headers: {
          'authorization': `bearer ${token}`,
          'apns-topic': apnsTopic,
          'apns-push-type': 'liveactivity',
          'apns-priority': '10',
          'content-type': 'application/json',
          'content-length': Buffer.byteLength(payloadString)
        }
      };

      const result = await new Promise((resolve, reject) => {
        // Create HTTP/2 client
        const client = http2.connect(`https://${APNS_HOST}:${APNS_PORT}`);
        
        client.on('error', (err) => {
          console.error('HTTP/2 client error:', err);
          reject(err);
        });

        // Create request
        const req = client.request({
          ':method': 'POST',
          ':path': `${APNS_PATH_PREFIX}${pushToStartToken}`,
          'authorization': `bearer ${token}`,
          'apns-topic': apnsTopic,
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
            console.log('✅ Push-to-start sent successfully');
            resolve({ success: true });
          } else {
            console.error(`❌ Push-to-start failed: ${statusCode} - ${responseBody}`);
            reject(new Error(`APNs error: ${statusCode}`));
          }
        });

        req.on('error', (error) => {
          console.error('Request error:', error);
          client.close();
          reject(error);
        });

        // Send the payload
        req.write(payloadString);
        req.end();
      });

      return result;

    } catch (error) {
      console.error('Error starting Live Activity:', error);
      throw new HttpsError('internal', error.message);
    }
  }
);