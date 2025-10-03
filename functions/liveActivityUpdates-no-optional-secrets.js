/**
 * Firebase Cloud Functions for Live Activity Push Updates
 * Version without optional secrets - using only required secrets
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');

// Define only the required secrets
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');
const apnsTopicSecret = defineSecret('APNS_TOPIC');

// All initialization happens inside functions to avoid deployment timeouts
let initialized = false;
let modules = {};
let config = {};

async function initialize() {
  if (initialized) return;
  
  try {
    console.log('🔧 [Initialize] Starting initialization...');
    
    console.log('🔧 [Initialize] Loading modules...');
    modules.admin = require('firebase-admin');
    modules.http2 = require('http2');
    modules.jwt = require('jsonwebtoken');
    console.log('✅ [Initialize] Modules loaded.');
    
    console.log('🔧 [Initialize] Initializing Firebase Admin...');
    if (!modules.admin.apps.length) {
      modules.admin.initializeApp();
      console.log('✅ [Initialize] Firebase Admin SDK initialized');
    } else {
      console.log('ℹ️ [Initialize] Firebase Admin SDK already initialized');
    }
    
    // APNs configuration constants
    config.APNS_HOST_PROD = 'api.push.apple.com';  // Production server
    config.APNS_HOST_DEV = 'api.development.push.apple.com';  // Development server
    config.APNS_PORT = 443;
    config.APNS_PATH_PREFIX = '/3/device/';
    
    // Load environment variables from secrets (trim whitespace)
    config.apnsKey = (process.env.APNS_AUTH_KEY || apnsAuthKeySecret.value() || '').trim();
    config.apnsKeyId = (process.env.APNS_KEY_ID || apnsKeyIdSecret.value() || '').trim();
    config.apnsTeamId = (process.env.APNS_TEAM_ID || apnsTeamIdSecret.value() || '').trim();
    config.apnsTopic = (process.env.APNS_TOPIC || apnsTopicSecret.value() || '').trim();
    
    // Check for production secrets (use same as dev if not set)
    // Note: Production secrets are loaded from environment but might not be available during initialization
    // They will be loaded when the function is executed with proper secret access
    config.apnsKeyProd = (process.env.APNS_AUTH_KEY_PROD || '').trim();
    config.apnsKeyIdProd = (process.env.APNS_KEY_ID_PROD || '').trim();
    
    // If production secrets are not loaded yet, they'll be same as dev
    if (!config.apnsKeyProd) config.apnsKeyProd = config.apnsKey;
    if (!config.apnsKeyIdProd) config.apnsKeyIdProd = config.apnsKeyId;
    
    // Log configuration (without exposing sensitive data)
    console.log('📋 [Initialize] Configuration loaded:', {
      hasAuthKey: !!config.apnsKey,
      keyId: config.apnsKeyId,
      keyIdProd: config.apnsKeyIdProd,
      teamId: config.apnsTeamId,
      topic: config.apnsTopic,
      hasProductionKey: config.apnsKeyProd !== config.apnsKey,
      hasProductionKeyId: config.apnsKeyIdProd !== config.apnsKeyId
    });
    
    initialized = true;
    console.log('✅ [Initialize] Initialization complete.');
  } catch (error) {
    console.error('❌ [Initialize] Initialization error:', error);
    throw error;
  }
}

// Helper functions for APNs
const apnsHelper = require('./apnsHelper');

/**
 * Cloud function to handle Live Activity updates from timer state changes
 */
exports.onTimerStateChange = onDocumentWritten(
  {
    document: 'users/{userId}/timerState/current',
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret]
  },
  async (event) => {
    await initialize();
    console.log('🔥 [onTimerStateChange] Timer state change detected for path:', event.params);
    
    try {
      const userId = event.params.userId;
      const afterData = event.data?.after?.data();
      const beforeData = event.data?.before?.data();
      
      // Only process if we have after data (not a deletion)
      if (!afterData) {
        console.log('⚠️ [onTimerStateChange] No after data, skipping (document deleted)');
        return null;
      }
      
      // Check if this is a meaningful change
      if (beforeData && 
          beforeData.isActive === afterData.isActive && 
          beforeData.isPaused === afterData.isPaused &&
          beforeData.isCompleted === afterData.isCompleted) {
        console.log('ℹ️ [onTimerStateChange] No meaningful state change, skipping update');
        return null;
      }
      
      // Extract the necessary fields
      const timerData = {
        isActive: afterData.isActive || false,
        isPaused: afterData.isPaused || false,
        isCompleted: afterData.isCompleted || false,
        startTime: afterData.startTime,
        pauseTime: afterData.pauseTime,
        totalDuration: afterData.totalDuration,
        elapsedTime: afterData.elapsedTime || 0,
        pushToken: afterData.pushToken,
        activityId: afterData.activityId,
        bundleId: afterData.bundleId,
        lastUpdated: afterData.lastUpdated
      };
      
      console.log('📊 [onTimerStateChange] Processing timer update:', {
        userId,
        isActive: timerData.isActive,
        isPaused: timerData.isPaused,
        isCompleted: timerData.isCompleted,
        hasPushToken: !!timerData.pushToken,
        hasActivityId: !!timerData.activityId,
        bundleId: timerData.bundleId
      });
      
      // Skip if no push token or activity ID
      if (!timerData.pushToken || !timerData.activityId) {
        console.log('⚠️ [onTimerStateChange] Missing push token or activity ID, skipping');
        return null;
      }
      
      // Prepare the content state for the Live Activity
      const contentState = {
        isActive: timerData.isActive,
        isPaused: timerData.isPaused,
        isCompleted: timerData.isCompleted,
        startTime: timerData.startTime,
        pauseTime: timerData.pauseTime,
        totalDuration: timerData.totalDuration,
        elapsedTime: timerData.elapsedTime,
        lastUpdated: new Date().toISOString()
      };
      
      // Set dismissal date for completed timers
      let dismissalDate = null;
      if (timerData.isCompleted || (!timerData.isActive && !timerData.isPaused)) {
        dismissalDate = new Date(Date.now() + 30 * 1000); // Dismiss after 30 seconds
        console.log('⏰ [onTimerStateChange] Setting dismissal date for inactive timer:', dismissalDate.toISOString());
      }
      
      // Send the update to APNs
      console.log('📤 [onTimerStateChange] Sending Live Activity update...');
      const result = await apnsHelper.sendLiveActivityUpdate.call(
        config,
        timerData.pushToken,
        timerData.activityId,
        contentState,
        dismissalDate,
        timerData.bundleId || config.apnsTopic,
        'auto'  // Let the helper determine the best environment
      );
      
      if (result.success) {
        console.log('✅ [onTimerStateChange] Successfully sent Live Activity update');
        
        // Update the last push update time
        await modules.admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('timerState')
          .doc('current')
          .update({
            lastPushUpdate: modules.admin.firestore.FieldValue.serverTimestamp()
          });
      } else {
        console.error('❌ [onTimerStateChange] Failed to send update:', result.error);
      }
      
      return result;
      
    } catch (error) {
      console.error('❌ [onTimerStateChange] Error processing timer state change:', error);
      throw error;
    }
  }
);

/**
 * Callable function to update Live Activity from the app
 */
exports.updateLiveActivity = onCall(
  {
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    await initialize();
    console.log('📲 [updateLiveActivity] Manual update requested');
    
    try {
      // Check if request.data exists
      if (!request.data) {
        console.error('❌ [updateLiveActivity] No data provided in request');
        throw new HttpsError('invalid-argument', 'No data provided in request');
      }
      
      const { pushToken, activityId, contentState, dismissalDate, topicOverride } = request.data;
      
      // Log what was received for debugging
      console.log('📋 [updateLiveActivity] Received data:', {
        hasPushToken: !!pushToken,
        hasActivityId: !!activityId,
        hasContentState: !!contentState,
        hasDismissalDate: !!dismissalDate,
        hasTopicOverride: !!topicOverride,
        requestData: JSON.stringify(request.data)
      });
      
      // Check required parameters (pushToken is optional - can be looked up)
      const missingParams = [];
      if (!activityId) missingParams.push('activityId');
      if (!contentState) missingParams.push('contentState');
      
      if (missingParams.length > 0) {
        console.error('❌ [updateLiveActivity] Missing required parameters:', missingParams.join(', '));
        throw new HttpsError('invalid-argument', `Missing required parameters: ${missingParams.join(', ')}`);
      }
      
      // Validate contentState structure
      if (typeof contentState !== 'object') {
        console.error('❌ [updateLiveActivity] contentState must be an object');
        throw new HttpsError('invalid-argument', 'contentState must be an object');
      }
      
      // Log contentState for debugging
      console.log('📊 [updateLiveActivity] ContentState:', JSON.stringify(contentState));
      
      // Validate date fields in contentState
      console.log('🔍 [updateLiveActivity] Validating date fields...');
      const dateFields = ['startTime', 'endTime', 'lastUpdateTime', 'lastKnownGoodUpdate', 'expectedEndTime'];
      const invalidDates = [];
      
      for (const field of dateFields) {
        if (contentState[field]) {
          const dateStr = contentState[field];
          const date = new Date(dateStr);
          const timestamp = date.getTime() / 1000; // Convert to seconds
          
          console.log(`  - ${field}: ${dateStr} -> Unix: ${timestamp}`);
          
          // Check if date is from 1994 or otherwise invalid
          if (timestamp < 1000000000) { // Before September 2001
            invalidDates.push({
              field,
              value: dateStr,
              timestamp,
              error: 'Date is from 1994 or earlier'
            });
          }
        }
      }
      
      if (invalidDates.length > 0) {
        console.error('❌ [updateLiveActivity] Invalid dates detected:', invalidDates);
        // Don't throw error, just log for now to debug
      }
      
      // If pushToken not provided, try to look it up from liveActivityTokens collection
      let finalPushToken = pushToken;
      let tokenData = null;
      let finalTopicOverride = topicOverride;
      
      if (!finalPushToken) {
        console.log('🔍 [updateLiveActivity] No pushToken provided, looking up from activityId:', activityId);
        
        const tokenDoc = await modules.admin.firestore()
          .collection('liveActivityTokens')
          .doc(activityId)
          .get();
        
        if (!tokenDoc.exists) {
          console.error('❌ [updateLiveActivity] Activity not found in liveActivityTokens:', activityId);
          throw new HttpsError('not-found', `Live Activity token not found for activity: ${activityId}`);
        }
        
        tokenData = tokenDoc.data();
        finalPushToken = tokenData.pushToken;
        
        if (!finalPushToken) {
          console.error('❌ [updateLiveActivity] No pushToken stored for activity:', activityId);
          throw new HttpsError('failed-precondition', 'Push token not found for this activity');
        }
        
        console.log('✅ [updateLiveActivity] Found pushToken for activity');
        
        // Use the stored bundle ID for topic if available
        if (tokenData.bundleId && !finalTopicOverride) {
          finalTopicOverride = tokenData.bundleId;
          console.log('📱 [updateLiveActivity] Using bundleId from token data:', finalTopicOverride);
        }
      }
      
      // Send the update
      const result = await apnsHelper.sendLiveActivityUpdate.call(
        config,
        finalPushToken,
        activityId,
        contentState,
        dismissalDate ? new Date(dismissalDate) : null,
        finalTopicOverride || config.apnsTopic,
        'auto'
      );
      
      if (!result.success) {
        console.error('❌ [updateLiveActivity] Failed:', result.error);
        throw new HttpsError('internal', result.error || 'Failed to send update');
      }
      
      console.log('✅ [updateLiveActivity] Update sent successfully');
      
      // Store the timer state in activeTimers collection if we have auth
      if (request.auth?.uid) {
        try {
          await modules.admin.firestore()
            .collection('activeTimers')
            .doc(request.auth.uid)
            .set({
              activityId,
              contentState,
              lastUpdate: modules.admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
          console.log('💾 [updateLiveActivity] Stored timer state for user:', request.auth.uid);
        } catch (error) {
          console.error('⚠️ [updateLiveActivity] Failed to store timer state:', error.message);
          // Don't fail the request just because we couldn't store the state
        }
      }
      
      return result;
      
    } catch (error) {
      console.error('❌ [updateLiveActivity] Error:', error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', error.message || 'Internal error');
    }
  }
);

/**
 * Callable function to update Live Activity timer
 */
exports.updateLiveActivityTimer = onCall(
  {
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    await initialize();
    console.log('⏱️ [updateLiveActivityTimer] Timer update requested');
    
    try {
      // Check if request.data exists
      if (!request.data) {
        console.error('❌ [updateLiveActivityTimer] No data provided in request');
        throw new HttpsError('invalid-argument', 'No data provided in request');
      }
      
      const { userId } = request.data;
      
      console.log('📋 [updateLiveActivityTimer] Received data:', {
        hasUserId: !!userId,
        requestData: JSON.stringify(request.data)
      });
      
      if (!userId) {
        console.error('❌ [updateLiveActivityTimer] Missing userId');
        throw new HttpsError('invalid-argument', 'User ID is required');
      }
      
      // Get the current timer state
      const timerDoc = await modules.admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('timerState')
        .doc('current')
        .get();
      
      if (!timerDoc.exists) {
        throw new HttpsError('not-found', 'Timer state not found');
      }
      
      const timerData = timerDoc.data();
      
      if (!timerData.pushToken || !timerData.activityId) {
        throw new HttpsError('failed-precondition', 'Push token or activity ID not set');
      }
      
      // Prepare the content state
      const contentState = {
        isActive: timerData.isActive || false,
        isPaused: timerData.isPaused || false,
        isCompleted: timerData.isCompleted || false,
        startTime: timerData.startTime,
        pauseTime: timerData.pauseTime,
        totalDuration: timerData.totalDuration,
        elapsedTime: timerData.elapsedTime || 0,
        lastUpdated: new Date().toISOString()
      };
      
      // Set dismissal date for completed timers
      let dismissalDate = null;
      if (timerData.isCompleted || (!timerData.isActive && !timerData.isPaused)) {
        dismissalDate = new Date(Date.now() + 30 * 1000);
      }
      
      // Send the update
      const result = await apnsHelper.sendLiveActivityUpdate.call(
        config,
        timerData.pushToken,
        timerData.activityId,
        contentState,
        dismissalDate,
        timerData.bundleId || config.apnsTopic,
        'auto'
      );
      
      if (!result.success) {
        throw new HttpsError('internal', result.error || 'Failed to send update');
      }
      
      // Update the last push update time
      await timerDoc.ref.update({
        lastPushUpdate: modules.admin.firestore.FieldValue.serverTimestamp()
      });
      
      return result;
      
    } catch (error) {
      console.error('❌ [updateLiveActivityTimer] Error:', error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', error.message || 'Internal error');
    }
  }
);

/**
 * Test function to verify APNs connection
 */
exports.testAPNsConnection = onCall(
  {
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    await initialize();
    console.log('🧪 [testAPNsConnection] Test requested');
    
    try {
      // Check if we have production keys configured
      const hasProductionKeys = config.apnsKeyProd !== config.apnsKey || 
                               config.apnsKeyIdProd !== config.apnsKeyId;
      
      return {
        success: true,
        message: 'APNs configuration loaded successfully',
        config: {
          keyId: config.apnsKeyId,
          teamId: config.apnsTeamId,
          topic: config.apnsTopic,
          hasProductionKeys: hasProductionKeys,
          productionKeyId: hasProductionKeys ? config.apnsKeyIdProd : 'Same as development'
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ [testAPNsConnection] Test failed:', error);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
);