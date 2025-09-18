/**
 * Secure Subscription Validation with Firebase Secret Manager
 * This version loads sensitive credentials from Secret Manager instead of local files
 */

const admin = require('firebase-admin');
const functions = require('firebase-functions');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

// Initialize Secret Manager client
const secretClient = new SecretManagerServiceClient();

// Cache for secrets to avoid repeated fetches
let secretsCache = null;
let secretsCacheTime = 0;
const CACHE_DURATION = 3600000; // 1 hour

/**
 * Load secrets from Firebase Secret Manager
 */
async function loadSecrets() {
  // Check cache
  if (secretsCache && Date.now() - secretsCacheTime < CACHE_DURATION) {
    return secretsCache;
  }

  try {
    const projectId = process.env.GCLOUD_PROJECT || 'growth-70a85';
    
    // Load App Store config
    const [configVersion] = await secretClient.accessSecretVersion({
      name: `projects/${projectId}/secrets/appstore-config/versions/latest`,
    });
    const configPayload = configVersion.payload.data.toString();
    const config = JSON.parse(configPayload);
    
    // Load private key
    const [keyVersion] = await secretClient.accessSecretVersion({
      name: `projects/${projectId}/secrets/appstore-private-key/versions/latest`,
    });
    const privateKey = keyVersion.payload.data.toString();
    
    secretsCache = {
      ...config,
      privateKey
    };
    secretsCacheTime = Date.now();
    
    console.log('✅ Secrets loaded from Secret Manager');
    return secretsCache;
    
  } catch (error) {
    console.error('❌ Error loading secrets:', error);
    
    // Fallback to environment variables if Secret Manager fails
    const config = functions.config().appstore;
    if (config && config.key_id) {
      console.log('⚠️  Using fallback configuration from environment');
      return {
        keyId: config.key_id,
        issuerId: config.issuer_id,
        bundleId: config.bundle_id,
        sharedSecret: config.shared_secret,
        privateKey: null // Will need to handle this differently
      };
    }
    
    throw new Error('Failed to load credentials from Secret Manager');
  }
}

/**
 * Generate JWT for App Store Connect API using secure credentials
 */
async function generateSecureJWT() {
  const secrets = await loadSecrets();
  
  if (!secrets.privateKey) {
    throw new Error('Private key not available');
  }
  
  const now = Math.floor(Date.now() / 1000);
  
  const token = jwt.sign({
    iss: secrets.issuerId,
    iat: now,
    exp: now + 1200, // 20 minutes
    aud: 'appstoreconnect-v1'
  }, secrets.privateKey, {
    algorithm: 'ES256',
    header: {
      alg: 'ES256',
      kid: secrets.keyId,
      typ: 'JWT'
    }
  });
  
  return token;
}

/**
 * Validate subscription receipt with secure credentials
 */
async function validateReceiptSecure(receiptData, isRetry = false) {
  try {
    const secrets = await loadSecrets();
    const token = await generateSecureJWT();
    
    // Determine endpoint
    const useSandbox = functions.config().appstore?.use_sandbox === 'true';
    const endpoint = useSandbox 
      ? 'https://sandbox.itunes.apple.com/verifyReceipt'
      : 'https://buy.itunes.apple.com/verifyReceipt';
    
    // Validate receipt
    const response = await axios.post(endpoint, {
      'receipt-data': receiptData,
      'password': secrets.sharedSecret,
      'exclude-old-transactions': true
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    
    return response.data;
    
  } catch (error) {
    console.error('Receipt validation error:', error);
    
    // Retry with sandbox if production fails
    if (!isRetry && error.response?.data?.status === 21007) {
      console.log('Retrying with sandbox endpoint...');
      return validateReceiptSecure(receiptData, true);
    }
    
    throw error;
  }
}

/**
 * Firebase Function: Validate Subscription Receipt (Secure Version)
 */
exports.validateSubscriptionReceiptSecure = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const { receiptData } = data;
  
  if (!receiptData) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Receipt data is required'
    );
  }
  
  try {
    // Validate receipt using secure credentials
    const validation = await validateReceiptSecure(receiptData);
    
    if (validation.status === 0) {
      // Process successful validation
      const latestReceipt = validation.latest_receipt_info?.[0];
      
      if (latestReceipt) {
        // Update user document
        await admin.firestore()
          .collection('users')
          .doc(context.auth.uid)
          .update({
            subscriptionStatus: 'active',
            lastValidated: admin.firestore.FieldValue.serverTimestamp(),
            subscriptionExpirationDate: new Date(parseInt(latestReceipt.expires_date_ms)),
            currentSubscriptionTier: mapProductIdToTier(latestReceipt.product_id),
            subscriptionProductId: latestReceipt.product_id
          });
      }
      
      return {
        success: true,
        status: validation.status,
        expirationDate: latestReceipt?.expires_date_ms
      };
    }
    
    return {
      success: false,
      status: validation.status,
      message: getStatusMessage(validation.status)
    };
    
  } catch (error) {
    console.error('Validation error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to validate receipt',
      error.message
    );
  }
});

// Helper functions remain the same
function mapProductIdToTier(productId) {
  const tierMapping = {
    'com.growthlabs.growthmethod.subscription.basic.monthly': 'basic',
    'com.growthlabs.growthmethod.subscription.basic.yearly': 'basic',
    'com.growthlabs.growthmethod.subscription.premium.monthly': 'premium',
    'com.growthlabs.growthmethod.subscription.premium.yearly': 'premium',
    'com.growthlabs.growthmethod.subscription.elite.monthly': 'elite',
    'com.growthlabs.growthmethod.subscription.elite.yearly': 'elite'
  };
  
  return tierMapping[productId] || 'none';
}

function getStatusMessage(status) {
  const messages = {
    21000: 'Bad JSON',
    21002: 'Malformed receipt data',
    21003: 'Receipt authentication failed',
    21004: 'Shared secret mismatch',
    21005: 'Receipt server unavailable',
    21006: 'Subscription expired',
    21007: 'Sandbox receipt on production',
    21008: 'Production receipt on sandbox'
  };
  
  return messages[status] || 'Unknown error';
}

module.exports = {
  validateSubscriptionReceiptSecure,
  loadSecrets
};