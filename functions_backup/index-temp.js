/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Import the fixed manageLiveActivityUpdates function
const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates');

// Export the Live Activity management function
exports.manageLiveActivityUpdates = manageLiveActivityUpdates;

// Simple test function to verify deployment
exports.testFunction = onCall({
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false
}, async (request) => {
  return { 
    success: true, 
    message: 'Functions are working!',
    timestamp: new Date().toISOString()
  };
});

console.log('Functions index.js loaded successfully');