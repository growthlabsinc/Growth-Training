/**
 * Minimal Firebase Functions to test deployment
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Simple test function
exports.testFunction = onCall({
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false
}, async (request) => {
  return { 
    success: true, 
    message: 'Test function works!',
    timestamp: new Date().toISOString()
  };
});

console.log('Minimal index.js loaded successfully');