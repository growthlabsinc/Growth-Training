/**
 * Simplified Live Activity Updates without optional production secrets
 */

const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

// Define only the required secrets
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');
const apnsTopicSecret = defineSecret('APNS_TOPIC');

// Simple test function
exports.testAPNsConnection = onCall(
  {
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret, apnsTopicSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    console.log('🧪 testAPNsConnection called');
    
    // Check if secrets are loaded
    const config = {
      hasAuthKey: !!process.env.APNS_AUTH_KEY,
      keyId: process.env.APNS_KEY_ID,
      teamId: process.env.APNS_TEAM_ID,
      topic: process.env.APNS_TOPIC
    };
    
    console.log('Config check:', config);
    
    return {
      success: true,
      message: 'APNs test function deployed successfully',
      config: config,
      timestamp: new Date().toISOString()
    };
  }
);