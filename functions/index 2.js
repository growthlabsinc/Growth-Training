/**
 * Minimal Firebase Functions for testing deployment
 */

const { onCall } = require('firebase-functions/v2/https');

// Simple test function
exports.testDeploy = onCall(
  { 
    cors: true,
    region: 'us-central1'
  },
  async (request) => {
    return { 
      message: 'Firebase Functions are working!',
      timestamp: new Date().toISOString(),
      data: request.data
    };
  }
);