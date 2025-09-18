// Test script to verify APNs configuration
const functions = require('firebase-functions');

console.log('Testing APNs configuration...');

try {
  const config = functions.config();
  console.log('Firebase config loaded successfully');
  
  if (config.apns) {
    console.log('APNs configuration found:');
    console.log('- Team ID:', config.apns.team_id);
    console.log('- Key ID:', config.apns.key_id);
    console.log('- Topic:', config.apns.topic);
    console.log('- Auth Key present:', !!config.apns.auth_key);
    console.log('- Auth Key length:', config.apns.auth_key ? config.apns.auth_key.length : 0);
  } else {
    console.log('No APNs configuration found in Firebase config');
  }
} catch (error) {
  console.error('Error loading config:', error.message);
}

// Also check environment variables
console.log('\nEnvironment variables:');
console.log('- APNS_TEAM_ID:', process.env.APNS_TEAM_ID || 'not set');
console.log('- APNS_KEY_ID:', process.env.APNS_KEY_ID || 'not set');
console.log('- APNS_TOPIC:', process.env.APNS_TOPIC || 'not set');
console.log('- APNS_AUTH_KEY present:', !!process.env.APNS_AUTH_KEY);