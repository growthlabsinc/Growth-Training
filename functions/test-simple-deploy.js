/**
 * Simplified test function for deployment
 */

const { onCall } = require('firebase-functions/v2/https');

exports.testSimpleAPNs = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    return {
      success: true,
      message: 'Simple test function works',
      timestamp: new Date().toISOString()
    };
  }
);