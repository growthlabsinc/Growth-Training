/**
 * Firebase Function: Subscription Receipt Validation
 * Validates App Store subscription receipts and manages subscription status
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const AppStoreConnectClient = require('./services/appStoreConnectClient');
const { appStoreKeyId, appStoreIssuerId, appStoreSharedSecret } = require('./config/appStoreConfig');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cache configuration for subscription validation
 */
const CACHE_CONFIG = {
  VALID_DURATION: 24 * 60 * 60 * 1000, // 24 hours
  INVALID_DURATION: 60 * 60 * 1000,    // 1 hour
  PENDING_DURATION: 5 * 60 * 1000      // 5 minutes
};

/**
 * Subscription tiers enumeration
 */
const SUBSCRIPTION_TIERS = {
  NONE: 'none',
  BASIC: 'basic',
  PREMIUM: 'premium',
  ELITE: 'elite'
};

/**
 * Standardized response format for subscription validation
 */
class SubscriptionValidationResponse {
  constructor(isValid, tier, expirationDate, transactionId, error = null) {
    this.isValid = isValid;
    this.tier = tier;
    this.expirationDate = expirationDate;
    this.transactionId = transactionId;
    this.error = error;
    this.timestamp = new Date().toISOString();
  }

  static success(tier, expirationDate, transactionId) {
    return new SubscriptionValidationResponse(true, tier, expirationDate, transactionId);
  }

  static failure(error, tier = SUBSCRIPTION_TIERS.NONE) {
    return new SubscriptionValidationResponse(false, tier, null, null, error);
  }
}

/**
 * Validate subscription receipt with caching
 * HTTP Callable Function
 */
exports.validateSubscriptionReceipt = onCall(
  {
    region: 'us-central1',
    maxInstances: 100,
    secrets: [appStoreKeyId, appStoreIssuerId, appStoreSharedSecret]
  },
  async (request) => {
  try {
    // Authenticate user
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { receiptData, forceRefresh = false } = request.data;
    const userId = request.auth.uid;

    if (!receiptData) {
      throw new HttpsError('invalid-argument', 'receiptData is required');
    }

    logger.info('Subscription validation request', {
      userId,
      forceRefresh,
      timestamp: new Date().toISOString()
    });

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      const cachedResult = await getCachedValidation(userId);
      if (cachedResult) {
        logger.info('Returning cached subscription validation', { userId });
        return cachedResult;
      }
    }

    // Validate receipt with App Store
    const client = new AppStoreConnectClient();
    const sandbox = process.env.FIREBASE_ENV !== 'production';
    
    const validation = await client.validateReceipt(receiptData, sandbox);
    
    if (validation.status !== 0) {
      const error = getReceiptValidationError(validation.status);
      const response = SubscriptionValidationResponse.failure(error);
      await cacheValidationResult(userId, response, CACHE_CONFIG.INVALID_DURATION);
      return response;
    }

    // Process latest subscription info
    const subscriptionInfo = extractSubscriptionInfo(validation);
    const response = SubscriptionValidationResponse.success(
      subscriptionInfo.tier,
      subscriptionInfo.expirationDate,
      subscriptionInfo.transactionId
    );

    // Update user subscription status in Firestore
    await updateUserSubscription(userId, subscriptionInfo);
    
    // Cache successful validation
    await cacheValidationResult(userId, response, CACHE_CONFIG.VALID_DURATION);
    
    // Log validation success
    await logValidationEvent(userId, response, 'success');

    logger.info('Subscription validation successful', {
      userId,
      tier: subscriptionInfo.tier,
      expirationDate: subscriptionInfo.expirationDate
    });

    return response;

  } catch (error) {
    logger.error('Subscription validation error', {
      error: error.message,
      userId: request.auth?.uid,
      stack: error.stack
    });

    // Log validation failure
    if (request.auth?.uid) {
      await logValidationEvent(request.auth.uid, null, 'error', error.message);
    }

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError('internal', 'Subscription validation failed');
  }
  }
);

/**
 * Get cached validation result
 * @param {string} userId - User ID
 * @returns {Promise<Object|null>} Cached validation result or null
 */
async function getCachedValidation(userId) {
  try {
    const cacheDoc = await db.collection('subscriptionCache').doc(userId).get();
    
    if (!cacheDoc.exists) {
      return null;
    }

    const cached = cacheDoc.data();
    const now = Date.now();
    
    if (cached.expiresAt && now < cached.expiresAt) {
      return cached.result;
    }

    // Cache expired, delete it
    await cacheDoc.ref.delete();
    return null;
    
  } catch (error) {
    logger.warn('Cache retrieval error', { userId, error: error.message });
    return null;
  }
}

/**
 * Cache validation result
 * @param {string} userId - User ID
 * @param {Object} result - Validation result to cache
 * @param {number} duration - Cache duration in milliseconds
 */
async function cacheValidationResult(userId, result, duration) {
  try {
    await db.collection('subscriptionCache').doc(userId).set({
      result,
      expiresAt: Date.now() + duration,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    logger.warn('Cache storage error', { userId, error: error.message });
  }
}

/**
 * Extract subscription information from receipt validation
 * @param {Object} validation - App Store validation response
 * @returns {Object} Subscription information
 */
function extractSubscriptionInfo(validation) {
  const receipt = validation.receipt;
  const latestReceiptInfo = validation.latest_receipt_info || [];
  
  // Find the most recent active subscription
  const activeSubscriptions = latestReceiptInfo
    .filter(transaction => {
      const expiresDate = new Date(parseInt(transaction.expires_date_ms));
      return expiresDate > new Date();
    })
    .sort((a, b) => parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms));

  if (activeSubscriptions.length === 0) {
    return {
      tier: SUBSCRIPTION_TIERS.NONE,
      expirationDate: null,
      transactionId: null
    };
  }

  const activeSubscription = activeSubscriptions[0];
  const productId = activeSubscription.product_id;
  
  return {
    tier: mapProductIdToTier(productId),
    expirationDate: new Date(parseInt(activeSubscription.expires_date_ms)),
    transactionId: activeSubscription.transaction_id
  };
}

/**
 * Map App Store product ID to subscription tier
 * @param {string} productId - App Store product ID
 * @returns {string} Subscription tier
 */
function mapProductIdToTier(productId) {
  const tierMapping = {
    'com.growthlabs.growthmethod.subscription.basic.monthly': SUBSCRIPTION_TIERS.BASIC,
    'com.growthlabs.growthmethod.subscription.basic.yearly': SUBSCRIPTION_TIERS.BASIC,
    'com.growthlabs.growthmethod.subscription.premium.monthly': SUBSCRIPTION_TIERS.PREMIUM,
    'com.growthlabs.growthmethod.subscription.premium.yearly': SUBSCRIPTION_TIERS.PREMIUM,
    'com.growthlabs.growthmethod.subscription.elite.monthly': SUBSCRIPTION_TIERS.ELITE,
    'com.growthlabs.growthmethod.subscription.elite.yearly': SUBSCRIPTION_TIERS.ELITE
  };

  return tierMapping[productId] || SUBSCRIPTION_TIERS.NONE;
}

/**
 * Update user subscription status in Firestore
 * @param {string} userId - User ID
 * @param {Object} subscriptionInfo - Subscription information
 */
async function updateUserSubscription(userId, subscriptionInfo) {
  try {
    await db.collection('users').doc(userId).update({
      currentSubscriptionTier: subscriptionInfo.tier,
      subscriptionExpirationDate: subscriptionInfo.expirationDate,
      lastValidated: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    logger.error('User subscription update error', {
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Log validation event for audit trail
 * @param {string} userId - User ID
 * @param {Object} result - Validation result
 * @param {string} status - Event status (success, error, etc.)
 * @param {string} errorMessage - Error message if applicable
 */
async function logValidationEvent(userId, result, status, errorMessage = null) {
  try {
    await db.collection('subscriptionValidationLogs').add({
      userId,
      result,
      status,
      errorMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      environment: process.env.FIREBASE_ENV || 'development'
    });
  } catch (error) {
    logger.warn('Validation logging error', { error: error.message });
  }
}

/**
 * Get human-readable error message for receipt validation status codes
 * @param {number} status - Apple receipt validation status code
 * @returns {string} Error message
 */
function getReceiptValidationError(status) {
  const statusMessages = {
    21000: 'The App Store could not read the JSON object you provided.',
    21002: 'The data in the receipt-data property was malformed or missing.',
    21003: 'The receipt could not be authenticated.',
    21004: 'The shared secret you provided does not match the shared secret on file.',
    21005: 'The receipt server is not currently available.',
    21006: 'This receipt is valid but the subscription has expired.',
    21007: 'This receipt is from the sandbox environment, but it was sent to the production environment.',
    21008: 'This receipt is from the production environment, but it was sent to the sandbox environment.',
    21010: 'This receipt could not be authorized.'
  };

  return statusMessages[status] || `Unknown receipt validation error: ${status}`;
}

module.exports = {
  validateSubscriptionReceipt: exports.validateSubscriptionReceipt,
  SubscriptionValidationResponse,
  SUBSCRIPTION_TIERS,
  CACHE_CONFIG
};