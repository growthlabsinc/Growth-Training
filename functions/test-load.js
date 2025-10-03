// Test script to identify module loading issues
console.log('Starting test...');

try {
  console.log('Loading firebase-functions/v2/https...');
  const { onCall } = require('firebase-functions/v2/https');
  console.log('✅ firebase-functions/v2/https loaded');

  console.log('Loading firebase-admin...');
  const admin = require('firebase-admin');
  console.log('✅ firebase-admin loaded');

  console.log('Initializing admin...');
  if (!admin.apps.length) {
    admin.initializeApp();
    console.log('✅ Admin initialized');
  } else {
    console.log('✅ Admin already initialized');
  }

  console.log('Loading index.js exports...');
  const functions = require('./index.js');
  console.log('✅ index.js loaded');
  console.log('Exported functions:', Object.keys(functions));

} catch (error) {
  console.error('❌ Error:', error.message);
  console.error(error.stack);
}

console.log('Test complete');
process.exit(0);