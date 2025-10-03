/**
 * updateLiveActivity without any secrets
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');

exports.updateLiveActivity = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    console.log('📲 [updateLiveActivity] No-secrets version called');
    
    // Lazy load admin
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    
    try {
      if (!request.data) {
        throw new HttpsError('invalid-argument', 'No data provided in request');
      }
      
      const { pushToken, activityId, contentState, dismissalDate, topicOverride } = request.data;
      
      // Check required parameters (pushToken is optional - can be looked up)
      const missingParams = [];
      if (!activityId) missingParams.push('activityId');
      if (!contentState) missingParams.push('contentState');
      
      if (missingParams.length > 0) {
        throw new HttpsError('invalid-argument', `Missing required parameters: ${missingParams.join(', ')}`);
      }
      
      // If pushToken not provided, try to look it up
      let finalPushToken = pushToken;
      
      if (!finalPushToken) {
        console.log('🔍 Looking up pushToken for activity:', activityId);
        
        const tokenDoc = await admin.firestore()
          .collection('liveActivityTokens')
          .doc(activityId)
          .get();
        
        if (!tokenDoc.exists) {
          throw new HttpsError('not-found', `Live Activity token not found for activity: ${activityId}`);
        }
        
        const tokenData = tokenDoc.data();
        finalPushToken = tokenData.pushToken;
        
        if (!finalPushToken) {
          throw new HttpsError('failed-precondition', 'Push token not found for this activity');
        }
        
        console.log('✅ Found pushToken for activity');
      }
      
      // Load apnsHelper
      const apnsHelper = require('./apnsHelper');
      
      // Configuration (would normally come from secrets)
      const config = {
        apnsKey: process.env.APNS_AUTH_KEY || '',
        apnsKeyId: process.env.APNS_KEY_ID || '',
        apnsTeamId: process.env.APNS_TEAM_ID || '',
        apnsTopic: process.env.APNS_TOPIC || 'com.growthlabs.growthmethod',
        apnsKeyProd: process.env.APNS_AUTH_KEY_PROD || process.env.APNS_AUTH_KEY || '',
        apnsKeyIdProd: process.env.APNS_KEY_ID_PROD || process.env.APNS_KEY_ID || ''
      };
      
      // Send the update
      const result = await apnsHelper.sendLiveActivityUpdate.call(
        config,
        finalPushToken,
        activityId,
        contentState,
        dismissalDate ? new Date(dismissalDate) : null,
        topicOverride || config.apnsTopic,
        'auto'
      );
      
      if (!result.success) {
        throw new HttpsError('internal', result.error || 'Failed to send update');
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