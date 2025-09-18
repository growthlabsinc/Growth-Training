console.log('1. Starting test...');

console.log('2. Testing firebase-admin...');
const admin = require('firebase-admin');
console.log('   ✓ firebase-admin loaded');

console.log('3. Testing firebase-functions...');
const functions = require('firebase-functions');
console.log('   ✓ firebase-functions loaded');

console.log('4. Testing firebase-functions v2...');
const { onCall } = require('firebase-functions/v2/https');
console.log('   ✓ firebase-functions v2 loaded');

console.log('5. Initializing admin...');
if (!admin.apps.length) {
  admin.initializeApp();
}
console.log('   ✓ admin initialized');

console.log('6. Testing vertexAIProxy...');
try {
  const vertexAIProxy = require('./vertexAiProxy');
  console.log('   ✓ vertexAIProxy loaded');
} catch (e) {
  console.log('   ✗ vertexAIProxy failed:', e.message);
}

console.log('7. Testing fallbackKnowledge...');
try {
  const { getFallbackResponse } = require('./fallbackKnowledge');
  console.log('   ✓ fallbackKnowledge loaded');
} catch (e) {
  console.log('   ✗ fallbackKnowledge failed:', e.message);
}

console.log('8. All tests complete!');