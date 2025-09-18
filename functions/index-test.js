/**
 * Minimal test deployment - no secrets, no dependencies
 */

const { onCall } = require('firebase-functions/v2/https');

// Simple test function without any secrets
exports.testDeployment = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    return {
      success: true,
      message: 'Deployment successful',
      timestamp: new Date().toISOString()
    };
  }
);