/**
 * App Store Connect Configuration
 * Maps environment variables for App Store Connect API
 * 
 * Note: functions.config() is deprecated in Firebase Functions v2
 * Use environment variables or Secret Manager instead
 */

const { defineSecret } = require('firebase-functions/params');

// Define secrets for sensitive values
const appStoreKeyId = defineSecret('APP_STORE_CONNECT_KEY_ID');
const appStoreIssuerId = defineSecret('APP_STORE_CONNECT_ISSUER_ID');
const appStoreSharedSecret = defineSecret('APP_STORE_SHARED_SECRET');

// Initialize App Store Connect environment variables
function initializeAppStoreConfig() {
  try {
    // Check for environment variables first (for local development)
    // In production, these will be populated from Secret Manager
    const hasKeyId = process.env.APP_STORE_CONNECT_KEY_ID || false;
    const hasIssuerId = process.env.APP_STORE_CONNECT_ISSUER_ID || false;
    const hasSharedSecret = process.env.APP_STORE_SHARED_SECRET || false;
    
    console.log('App Store Connect configuration status:');
    console.log(`- Key ID: ${hasKeyId ? '✓ (env)' : '⏳ (will load from secrets)'}`);
    console.log(`- Issuer ID: ${hasIssuerId ? '✓ (env)' : '⏳ (will load from secrets)'}`);
    console.log(`- Shared Secret: ${hasSharedSecret ? '✓ (env)' : '⏳ (will load from secrets)'}`);
    
    // Note: Secret values can only be accessed within function execution context
    // They cannot be accessed during module initialization
  } catch (error) {
    console.error('Error checking App Store config:', error);
  }
}

// Initialize on module load
initializeAppStoreConfig();

// Export secrets for use in functions
module.exports = {
  initializeAppStoreConfig,
  appStoreKeyId,
  appStoreIssuerId,
  appStoreSharedSecret
};