/**
 * Firebase Cloud Functions for Live Activity Push Updates
 * Dual-key version with proper optional secret handling
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');

// Define required secrets
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');
const apnsTopicSecret = defineSecret('APNS_TOPIC');

// Define optional production secrets
const apnsAuthKeyProdSecret = defineSecret('APNS_AUTH_KEY_PROD');
const apnsKeyIdProdSecret = defineSecret('APNS_KEY_ID_PROD');

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
    
    // Check for production secrets
    try {
      const prodKey = process.env.APNS_AUTH_KEY_PROD || apnsAuthKeyProdSecret.value() || '';
      const prodKeyId = process.env.APNS_KEY_ID_PROD || apnsKeyIdProdSecret.value() || '';
      
      config.apnsKeyProd = prodKey.trim() || config.apnsKey;
      config.apnsKeyIdProd = prodKeyId.trim() || config.apnsKeyId;
    } catch (error) {
      // Production secrets might not be available
      console.log('ℹ️ [Initialize] Production secrets not available, using dev keys for both environments');
      config.apnsKeyProd = config.apnsKey;
      config.apnsKeyIdProd = config.apnsKeyId;
    }
    
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
 * Test function to verify APNs configuration
 */
exports.testAPNsConnection = onCall(
  {
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret, apnsAuthKeyProdSecret, apnsKeyIdProdSecret],
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

/**
 * Cloud function to handle Live Activity updates from timer state changes
 */
exports.onTimerStateChange = onDocumentWritten(
  {
    document: 'users/{userId}/timerState/current',
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret, apnsAuthKeyProdSecret, apnsKeyIdProdSecret]
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
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret, apnsAuthKeyProdSecret, apnsKeyIdProdSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    await initialize();
    console.log('📲 [updateLiveActivity] Manual update requested');
    
    try {
      const { pushToken, activityId, contentState, dismissalDate, topicOverride } = request.data;
      
      if (!pushToken || !activityId || !contentState) {
        console.error('❌ [updateLiveActivity] Missing required parameters');
        throw new HttpsError('invalid-argument', 'Missing required parameters');
      }
      
      // Send the update
      const result = await apnsHelper.sendLiveActivityUpdate.call(
        config,
        pushToken,
        activityId,
        contentState,
        dismissalDate ? new Date(dismissalDate) : null,
        topicOverride || config.apnsTopic,
        'auto'
      );
      
      if (!result.success) {
        console.error('❌ [updateLiveActivity] Failed:', result.error);
        throw new HttpsError('internal', result.error || 'Failed to send update');
      }
      
      console.log('✅ [updateLiveActivity] Update sent successfully');
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
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret, apnsAuthKeyProdSecret, apnsKeyIdProdSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    await initialize();
    console.log('⏱️ [updateLiveActivityTimer] Timer update requested');
    
    try {
      const { userId } = request.data;
      
      if (!userId) {
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