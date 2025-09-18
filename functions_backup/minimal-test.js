// Minimal test to see what's blocking
console.log('Starting minimal test...');

// Test just the problem function
const { onCall } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.testFunction = onCall({ region: 'us-central1' }, async (request) => {
  return { success: true, message: 'Test function works!' };
});

console.log('Minimal test complete!');