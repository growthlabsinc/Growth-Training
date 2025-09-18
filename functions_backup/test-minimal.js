console.log('Starting minimal test...');

// Test each module individually
try {
  console.log('Loading firebase-admin...');
  const admin = require('firebase-admin');
  console.log('✓ firebase-admin loaded');
} catch (e) {
  console.error('✗ firebase-admin failed:', e);
}

try {
  console.log('Loading firebase-functions...');
  const functions = require('firebase-functions');
  console.log('✓ firebase-functions loaded');
} catch (e) {
  console.error('✗ firebase-functions failed:', e);
}

try {
  console.log('Loading firebase-functions/v2/https...');
  const { onCall } = require('firebase-functions/v2/https');
  console.log('✓ firebase-functions/v2/https loaded');
} catch (e) {
  console.error('✗ firebase-functions/v2/https failed:', e);
}

try {
  console.log('Loading http2...');
  const http2 = require('http2');
  console.log('✓ http2 loaded');
} catch (e) {
  console.error('✗ http2 failed:', e);
}

try {
  console.log('Loading jsonwebtoken...');
  const jwt = require('jsonwebtoken');
  console.log('✓ jsonwebtoken loaded');
} catch (e) {
  console.error('✗ jsonwebtoken failed:', e);
}

console.log('\nAll tests complete!');