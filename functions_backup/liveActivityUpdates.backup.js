/**
 * Firebase Cloud Functions for Live Activity Push Updates
 */

const functionsV2 = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const https = require('https');
const jwt = require('jsonwebtoken');

// Note: APNs configuration is loaded from Firebase config or environment variables
// No need to define parameters here since we're using v1 config system

// Initialize admin if not already initialized
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
} catch (error) {
  console.error('Error initializing admin:', error);
}

// APNs configuration
const APNS_HOST = 'api.push.apple.com';
const APNS_PORT = 443;
const APNS_PATH_PREFIX = '/3/device/';

// Removed Google Secret Manager - using Firebase config instead

// Load APNs configuration
// NOTE: APNs configuration is required for push updates to work
// Set these environment variables in Firebase Functions:
// - APNS_KEY_ID: Your APNs authentication key ID
// - APNS_TEAM_ID: Your Apple Developer Team ID
// - APNS_AUTH_KEY: Your APNs authentication key (p8 file contents)
// - APNS_TOPIC: com.growthtraining.Growth.GrowthTimerWidget.push-type.liveactivity
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
    // First try environment variables (for local development with .env)
    if (process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID && process.env.APNS_TOPIC && process.env.APNS_AUTH_KEY) {
      apnsKeyId = process.env.APNS_KEY_ID;
      apnsTeamId = process.env.APNS_TEAM_ID;
      apnsTopic = process.env.APNS_TOPIC;
      apnsKey = process.env.APNS_AUTH_KEY;
      console.log('Loaded APNs config from environment variables (.env)');
    } else {
      // For deployed functions, use Firebase v1 config
      console.log('Loading from Firebase config...');
      const functionsV1 = require('firebase-functions');
      let config = {};
      
      try {
        config = functionsV1.config();
      } catch (configError) {
        // In v2 functions, config() might not work, but the values are exposed as env vars
        console.log('Direct config() failed, checking process.env for Firebase config...');
        
        // Firebase exposes config as FIREBASE_CONFIG_* env vars
        if (process.env.FIREBASE_CONFIG) {
          const firebaseConfig = JSON.parse(process.env.FIREBASE_CONFIG);
          console.log('Found FIREBASE_CONFIG:', Object.keys(firebaseConfig));
        }
        
        // Try uppercase env vars (Firebase sometimes does this)
        apnsKeyId = process.env.FIREBASE_CONFIG_APNS_KEY_ID || process.env.apns_key_id;
        apnsTeamId = process.env.FIREBASE_CONFIG_APNS_TEAM_ID || process.env.apns_team_id;
        apnsTopic = process.env.FIREBASE_CONFIG_APNS_TOPIC || process.env.apns_topic;
        apnsKey = process.env.FIREBASE_CONFIG_APNS_AUTH_KEY || process.env.apns_auth_key;
      }
      
      // If config loaded successfully, use it
      if (config && config.apns) {
        apnsKeyId = config.apns.key_id || apnsKeyId;
        apnsTeamId = config.apns.team_id || apnsTeamId;
        apnsTopic = config.apns.topic || apnsTopic;
        apnsKey = config.apns.auth_key || apnsKey;
        console.log('Loaded APNs config from Firebase v1 config');
      }
    }
    
    // Log what we found
    console.log('APNs config check:');
    console.log('- Key ID:', apnsKeyId);
    console.log('- Team ID:', apnsTeamId);
    console.log('- Topic:', apnsTopic);
    console.log('- Auth Key present:', !!apnsKey);
    console.log('- Auth Key length:', apnsKey ? apnsKey.length : 0);
    
    // Validate configuration
    if (!apnsKeyId || !apnsTeamId || !apnsTopic || !apnsKey) {
      throw new Error('Missing required APNs configuration');
    }
    
    // Clean up the auth key - remove quotes and fix newlines
    if (apnsKey.startsWith('"') && apnsKey.endsWith('"')) {
      apnsKey = apnsKey.slice(1, -1);
    }
    
    // Replace escaped newlines with actual newlines
    if (apnsKey.includes('\\n')) {
      apnsKey = apnsKey.replace(/\\n/g, '\n');
    }
    
    // Validate the key format
    if (!apnsKey.includes('BEGIN PRIVATE KEY') || !apnsKey.includes('END PRIVATE KEY')) {
      throw new Error('Invalid APNs auth key format');
    }
    
    console.log('✅ Successfully loaded APNs configuration');
    apnsConfigLoaded = true;
  } catch (error) {
    console.error('❌ Failed to load APNs configuration:', error.message);
    throw error; // Re-throw to handle in calling function
  }
}

/**
 * Generate JWT token for APNs authentication
 */
async function generateAPNsToken() {
  await loadAPNsConfig();
  
  // Check if APNs is properly configured
  if (!apnsConfigLoaded) {
    throw new Error('APNs configuration not loaded. Please check environment variables.');
  }
  
  if (!apnsKey || !apnsKeyId || !apnsTeamId) {
    throw new Error('APNs authentication key not configured. Please set APNS_AUTH_KEY, APNS_KEY_ID, and APNS_TEAM_ID environment variables.');
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
async function sendLiveActivityUpdate(pushToken, activityId, contentState, dismissalDate = null) {
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

  const options = {
    hostname: APNS_HOST,
    port: APNS_PORT,
    path: `${APNS_PATH_PREFIX}${pushToken}`,
    method: 'POST',
    headers: {
      'authorization': `bearer ${token}`,
      'apns-topic': apnsTopic,
      'apns-push-type': 'liveactivity',
      'apns-priority': '10',
      'apns-expiration': Math.floor(Date.now() / 1000) + 3600, // Expire after 1 hour
      'content-type': 'application/json',
      'content-length': Buffer.byteLength(payloadString)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseBody = '';
      
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log(`✅ Live Activity update sent successfully for activity ${activityId}`);
          resolve({ success: true, response: responseBody });
        } else {
          const errorInfo = {
            statusCode: res.statusCode,
            response: responseBody,
            headers: res.headers
          };
          
          // Log specific error types
          if (res.statusCode === 400) {
            console.error('❌ Bad request - invalid payload or headers', errorInfo);
          } else if (res.statusCode === 403) {
            console.error('❌ Forbidden - invalid token or certificate', errorInfo);
          } else if (res.statusCode === 404) {
            console.error('❌ Device token not found or invalid', errorInfo);
          } else if (res.statusCode === 410) {
            console.error('❌ Device token is no longer active', errorInfo);
          } else if (res.statusCode === 413) {
            console.error('❌ Payload too large', errorInfo);
          } else if (res.statusCode === 429) {
            console.error('❌ Too many requests', errorInfo);
          } else if (res.statusCode === 500) {
            console.error('❌ Internal server error at APNs', errorInfo);
          } else if (res.statusCode === 503) {
            console.error('❌ APNs service unavailable', errorInfo);
          }
          
          reject(new Error(`APNs error: ${res.statusCode} - ${responseBody}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(payloadString);
    req.end();
  });
}

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
    // Require authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, action, endTime } = request.data;

    if (!activityId || !action) {
      throw new HttpsError('invalid-argument', 'activityId and action are required');
    }

    try {
      // Get the Live Activity token from Firestore
      const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        throw new HttpsError('not-found', 'Live Activity token not found');
      }

      const tokenData = tokenDoc.data();
      
      // Verify the user owns this activity
      if (tokenData.userId !== request.auth.uid) {
        throw new HttpsError('permission-denied', 'Not authorized to update this activity');
      }

      // Get current timer state from Firestore (you might store this separately)
      const timerDoc = await admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .get();

      let contentState = {
        startTime: new Date().toISOString(),
        endTime: endTime || new Date(Date.now() + 3600000).toISOString(), // Default 1 hour
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
          
          // Convert Firestore timestamps to ISO strings
          if (contentState.startTime && contentState.startTime.toDate) {
            contentState.startTime = contentState.startTime.toDate().toISOString();
          }
          if (contentState.endTime && contentState.endTime.toDate) {
            contentState.endTime = contentState.endTime.toDate().toISOString();
          }
        }
      }

      // Update content state based on action
      switch (action) {
        case 'pause':
          contentState.isPaused = true;
          break;
        case 'resume':
          contentState.isPaused = false;
          break;
        case 'stop':
          // End the activity
          await sendLiveActivityUpdate(
            tokenData.pushToken,
            activityId,
            contentState,
            new Date() // Dismissal date is now
          );
          
          // Clean up the token
          await tokenDoc.ref.delete();
          
          return { success: true, action: 'stopped' };
        default:
          throw new HttpsError('invalid-argument', 'Invalid action');
      }

      // Send the update
      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState
      );

      // Update timer state in Firestore
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
      
      // Provide more specific error messages
      if (error.message?.includes('APNs authentication key not configured')) {
        throw new HttpsError('failed-precondition', 'APNs not configured. Please contact support.');
      } else if (error.message?.includes('APNs configuration incomplete')) {
        throw new HttpsError('failed-precondition', 'APNs configuration incomplete. Please contact support.');
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

    // Skip if no actual change or no activity ID
    if (!afterData || !afterData.activityId) {
      console.log('No afterData or activityId found');
      return;
    }
    
    // Skip if this is just a push update trigger
    if (beforeData && afterData.lastPushUpdate && 
        beforeData.lastPushUpdate !== afterData.lastPushUpdate &&
        beforeData.contentState?.isPaused === afterData.contentState?.isPaused) {
      console.log('Processing push update trigger');
      // Continue to send the update even if state hasn't changed
    } else {
      // Check if there was an actual state change
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
      // Get the Live Activity token
      const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        console.log('No Live Activity token found for activity:', activityId);
        return;
      }

      const tokenData = tokenDoc.data();
      
      // Prepare content state for push notification
      let contentState = afterData.contentState || {};
      
      // Convert Firestore timestamps to ISO strings
      if (contentState.startTime && contentState.startTime.toDate) {
        contentState.startTime = contentState.startTime.toDate().toISOString();
      }
      if (contentState.endTime && contentState.endTime.toDate) {
        contentState.endTime = contentState.endTime.toDate().toISOString();
      }
      
      // Send the update
      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState
      );

      console.log('Successfully updated Live Activity:', activityId);

    } catch (error) {
      console.error('Error in onTimerStateChange:', error);
      
      // Log specific error types for debugging
      if (error.message?.includes('APNs authentication key not configured')) {
        console.error('⚠️ APNs not configured. Please run setup-apns-v2.sh to configure APNs credentials.');
      } else if (error.message?.includes('APNs configuration incomplete')) {
        console.error('⚠️ APNs configuration incomplete. Please check APNS_KEY_ID and APNS_TEAM_ID environment variables.');
      }
    }
  }
);

/**
 * Update Live Activity with new content state format
 * This function is called by the iOS app to send push updates
 */
exports.updateLiveActivity = onCall(
  { region: 'us-central1' },
  async (request) => {
    // Require authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, contentState, pushToken } = request.data;

    if (!activityId || !contentState) {
      throw new HttpsError('invalid-argument', 'activityId and contentState are required');
    }

    try {
      let finalPushToken = pushToken;
      
      // If no push token provided, get it from Firestore
      if (!finalPushToken) {
        const tokenDoc = await admin.firestore()
          .collection('liveActivityTokens')
          .doc(activityId)
          .get();

        if (!tokenDoc.exists) {
          throw new HttpsError('not-found', 'Live Activity token not found');
        }

        const tokenData = tokenDoc.data();
        
        // Verify the user owns this activity
        if (tokenData.userId !== request.auth.uid) {
          throw new HttpsError('permission-denied', 'Not authorized to update this activity');
        }
        
        finalPushToken = tokenData.pushToken;
      }

      // Send the push update
      await sendLiveActivityUpdate(finalPushToken, activityId, contentState);

      // Store the latest state in Firestore for reference
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
      
      if (error.message?.includes('APNs authentication key not configured')) {
        throw new HttpsError('failed-precondition', 'APNs not configured. Please contact support.');
      }
      
      throw new HttpsError('internal', error.message);
    }
  }
);

/**
 * Start a new Live Activity via push-to-start
 * Requires iOS 17.2+
 */
exports.startLiveActivity = onCall(
  { region: 'us-central1' },
  async (request) => {
    // Require authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { userId, attributes, contentState } = request.data;

    if (!userId || !attributes || !contentState) {
      throw new HttpsError('invalid-argument', 'userId, attributes, and contentState are required');
    }

    // Verify the user is starting their own activity
    if (userId !== request.auth.uid) {
      throw new HttpsError('permission-denied', 'Cannot start activity for another user');
    }

    try {
      // Get user's push-to-start token from Firestore
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

      // Create the push-to-start payload
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
        const req = https.request(options, (res) => {
          let responseBody = '';
          
          res.on('data', (chunk) => {
            responseBody += chunk;
          });
          
          res.on('end', () => {
            if (res.statusCode === 200) {
              console.log('✅ Push-to-start sent successfully');
              resolve({ success: true });
            } else {
              console.error(`❌ Push-to-start failed: ${res.statusCode} - ${responseBody}`);
              reject(new Error(`APNs error: ${res.statusCode}`));
            }
          });
        });

        req.on('error', (error) => {
          console.error('Network error:', error);
          reject(error);
        });

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