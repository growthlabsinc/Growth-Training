/**
 * Firebase Function: App Store Server Notifications Webhook
 * Handles real-time subscription status updates from Apple
 */

const { onRequest } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { appStoreSharedSecret } = require('./config/appStoreConfig');
const EnhancedLogger = require('../utils/enhancedLogger');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * App Store Server Notification Types
 * https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
 */
const NOTIFICATION_TYPES = {
  SUBSCRIBED: 'SUBSCRIBED',
  DID_CHANGE_RENEWAL_PREF: 'DID_CHANGE_RENEWAL_PREF',
  DID_CHANGE_RENEWAL_STATUS: 'DID_CHANGE_RENEWAL_STATUS',
  DID_FAIL_TO_RENEW: 'DID_FAIL_TO_RENEW',
  DID_RENEW: 'DID_RENEW',
  EXPIRED: 'EXPIRED',
  GRACE_PERIOD_EXPIRED: 'GRACE_PERIOD_EXPIRED',
  OFFER_REDEEMED: 'OFFER_REDEEMED',
  PRICE_INCREASE_CONSENT: 'PRICE_INCREASE_CONSENT',
  REFUND: 'REFUND',
  REVOKE: 'REVOKE'
};

/**
 * Subscription status mapping from App Store notifications
 */
const SUBSCRIPTION_STATUS = {
  ACTIVE: 'active',
  EXPIRED: 'expired',
  GRACE_PERIOD: 'grace_period',
  BILLING_RETRY: 'billing_retry',
  REVOKED: 'revoked'
};

/**
 * App Store Server Notifications webhook handler
 * HTTP endpoint for receiving real-time subscription updates from Apple
 */
exports.handleAppStoreNotification = onRequest(
  {
    region: 'us-central1',
    cors: false, // Webhook doesn't need CORS
    maxInstances: 10,
    secrets: [appStoreSharedSecret] // Include secret for signature validation
  },
  async (request, response) => {
    const enhancedLogger = new EnhancedLogger('handleAppStoreNotification');
    const requestId = enhancedLogger.generateRequestId();
    
    enhancedLogger.info('🪝 === APP STORE WEBHOOK REQUEST ===', {
      requestId,
      method: request.method,
      headers: request.headers,
      ip: request.ip
    });
    
    try {
      // Verify HTTP method
      if (request.method !== 'POST') {
        enhancedLogger.warn('Invalid HTTP method for webhook', { 
          method: request.method,
          requestId 
        });
        enhancedLogger.endRequest(false, { error: 'Method not allowed' });
        return response.status(405).send('Method Not Allowed');
      }

      // Verify content type
      if (!request.headers['content-type'] || !request.headers['content-type'].includes('application/json')) {
        enhancedLogger.warn('Invalid content type for webhook', { 
          contentType: request.headers['content-type'],
          requestId 
        });
        enhancedLogger.endRequest(false, { error: 'Invalid content type' });
        return response.status(400).send('Invalid Content-Type');
      }

      // Verify Apple signature
      const signature = request.headers['x-apple-cert-url'];
      const appleSignature = request.headers['x-apple-signature'];
      
      if (!signature || !appleSignature) {
        enhancedLogger.error('Missing Apple signature headers', { requestId });
        enhancedLogger.endRequest(false, { error: 'Missing signature headers' });
        return response.status(401).send('Missing signature headers');
      }

      // Validate signature (simplified - production should download and verify cert)
      const isValidSignature = await validateAppleSignature(
        JSON.stringify(request.body),
        signature,
        appleSignature
      );

      if (!isValidSignature) {
        enhancedLogger.error('Invalid Apple signature', { signature, appleSignature, requestId });
        enhancedLogger.endRequest(false, { error: 'Invalid signature' });
        return response.status(401).send('Invalid signature');
      }

      // Process notification payload
      const notification = request.body;
      enhancedLogger.info('Received App Store notification', {
        notificationType: notification.notification_type,
        transactionId: notification.latest_receipt_info?.[0]?.transaction_id,
        productId: notification.latest_receipt_info?.[0]?.product_id,
        requestId
      });

      // Process notification based on type
      await processNotification(notification, enhancedLogger);

      // Acknowledge receipt
      enhancedLogger.info('✅ App Store notification processed successfully', { requestId });
      enhancedLogger.endRequest(true, { status: 'processed' });
      response.status(200).send('OK');

    } catch (error) {
      enhancedLogger.error('App Store notification processing error', {
        error: error.message,
        stack: error.stack,
        requestId
      });

      // Log failed webhook for retry analysis
      await logFailedWebhook(request.body, error.message);

      enhancedLogger.endRequest(false, { error: error.message });
      // Return 500 to trigger Apple's retry mechanism
      response.status(500).send('Internal Server Error');
    }
  }
);

/**
 * Process App Store notification based on type
 * @param {Object} notification - Apple notification payload
 */
async function processNotification(notification, enhancedLogger) {
  const notificationType = notification.notification_type;
  const latestReceiptInfo = notification.latest_receipt_info?.[0];
  
  if (!latestReceiptInfo) {
    enhancedLogger.warn('Missing receipt info in notification', { notificationType });
    return;
  }

  const originalTransactionId = latestReceiptInfo.original_transaction_id;
  const productId = latestReceiptInfo.product_id;
  const expiresDateMs = latestReceiptInfo.expires_date_ms;
  const transactionId = latestReceiptInfo.transaction_id;

  // Find user by original transaction ID
  const userId = await findUserByTransactionId(originalTransactionId);
  if (!userId) {
    enhancedLogger.warn('User not found for transaction', { originalTransactionId });
    return;
  }

  enhancedLogger.info('Processing notification for user', {
    userId,
    notificationType,
    productId,
    transactionId
  });

  // Update subscription status based on notification type
  switch (notificationType) {
    case NOTIFICATION_TYPES.SUBSCRIBED:
    case NOTIFICATION_TYPES.DID_RENEW:
      await updateSubscriptionStatus(userId, {
        status: SUBSCRIPTION_STATUS.ACTIVE,
        tier: mapProductIdToTier(productId),
        expirationDate: expiresDateMs ? new Date(parseInt(expiresDateMs)) : null,
        transactionId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      break;

    case NOTIFICATION_TYPES.EXPIRED:
    case NOTIFICATION_TYPES.GRACE_PERIOD_EXPIRED:
      await updateSubscriptionStatus(userId, {
        status: SUBSCRIPTION_STATUS.EXPIRED,
        tier: 'none',
        expirationDate: expiresDateMs ? new Date(parseInt(expiresDateMs)) : null,
        transactionId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      break;

    case NOTIFICATION_TYPES.DID_FAIL_TO_RENEW:
      await updateSubscriptionStatus(userId, {
        status: SUBSCRIPTION_STATUS.BILLING_RETRY,
        // Keep existing tier during billing retry
        expirationDate: expiresDateMs ? new Date(parseInt(expiresDateMs)) : null,
        transactionId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      break;

    case NOTIFICATION_TYPES.REFUND:
    case NOTIFICATION_TYPES.REVOKE:
      await updateSubscriptionStatus(userId, {
        status: SUBSCRIPTION_STATUS.REVOKED,
        tier: 'none',
        expirationDate: expiresDateMs ? new Date(parseInt(expiresDateMs)) : null,
        transactionId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      break;

    case NOTIFICATION_TYPES.DID_CHANGE_RENEWAL_STATUS:
      // Handle auto-renewal preference changes
      const autoRenewStatus = latestReceiptInfo.auto_renew_status;
      await updateAutoRenewalStatus(userId, autoRenewStatus === '1');
      break;

    default:
      enhancedLogger.info('Unhandled notification type', { notificationType });
  }

  // Log notification for audit trail
  await logNotificationEvent(userId, notification, 'processed');
}

/**
 * Validate Apple's signature on webhook payload
 * @param {string} payload - Raw JSON payload
 * @param {string} certUrl - Apple certificate URL
 * @param {string} signature - Apple signature
 * @returns {Promise<boolean>} True if signature is valid
 */
async function validateAppleSignature(payload, certUrl, signature) {
  try {
    // In production, you should:
    // 1. Download certificate from certUrl
    // 2. Verify certificate chain
    // 3. Extract public key
    // 4. Verify signature using public key
    
    // For now, simplified validation - check URL format
    const appleUrlPattern = /^https:\/\/developer\.apple\.com\//;
    if (!appleUrlPattern.test(certUrl)) {
      logger.error('Invalid Apple certificate URL', { certUrl });
      return false;
    }

    // TODO: Implement full certificate chain verification
    // This is a critical security requirement for production
    logger.info('Signature validation - simplified check passed', { certUrl });
    return true;

  } catch (error) {
    logger.error('Signature validation error', { error: error.message });
    return false;
  }
}

/**
 * Find user by original transaction ID
 * @param {string} originalTransactionId - Apple's original transaction ID
 * @returns {Promise<string|null>} User ID or null if not found
 */
async function findUserByTransactionId(originalTransactionId) {
  try {
    const querySnapshot = await db.collection('users')
      .where('subscriptionTransactionId', '==', originalTransactionId)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      return null;
    }

    return querySnapshot.docs[0].id;
  } catch (error) {
    logger.error('Error finding user by transaction ID', {
      originalTransactionId,
      error: error.message
    });
    return null;
  }
}

/**
 * Update user subscription status
 * @param {string} userId - User ID
 * @param {Object} subscriptionData - Subscription update data
 */
async function updateSubscriptionStatus(userId, subscriptionData) {
  try {
    await db.collection('users').doc(userId).update({
      currentSubscriptionTier: subscriptionData.tier,
      subscriptionStatus: subscriptionData.status,
      subscriptionExpirationDate: subscriptionData.expirationDate,
      subscriptionTransactionId: subscriptionData.transactionId,
      lastValidated: subscriptionData.lastUpdated
    });

    logger.info('Updated user subscription status', {
      userId,
      tier: subscriptionData.tier,
      status: subscriptionData.status
    });
  } catch (error) {
    logger.error('Error updating subscription status', {
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Update auto-renewal status
 * @param {string} userId - User ID
 * @param {boolean} autoRenew - Auto-renewal enabled
 */
async function updateAutoRenewalStatus(userId, autoRenew) {
  try {
    await db.collection('users').doc(userId).update({
      subscriptionAutoRenew: autoRenew,
      lastValidated: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info('Updated auto-renewal status', { userId, autoRenew });
  } catch (error) {
    logger.error('Error updating auto-renewal status', {
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Map App Store product ID to subscription tier
 * @param {string} productId - App Store product ID
 * @returns {string} Subscription tier
 */
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

/**
 * Log notification event for audit trail
 * @param {string} userId - User ID
 * @param {Object} notification - Apple notification payload
 * @param {string} status - Processing status
 */
async function logNotificationEvent(userId, notification, status) {
  try {
    await db.collection('appStoreNotificationLogs').add({
      userId,
      notificationType: notification.notification_type,
      transactionId: notification.latest_receipt_info?.[0]?.transaction_id,
      productId: notification.latest_receipt_info?.[0]?.product_id,
      status,
      notification: notification, // Store full payload for debugging
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      environment: process.env.FIREBASE_ENV || 'development'
    });
  } catch (error) {
    logger.warn('Notification logging error', { error: error.message });
  }
}

/**
 * Log failed webhook for retry analysis
 * @param {Object} payload - Webhook payload
 * @param {string} errorMessage - Error message
 */
async function logFailedWebhook(payload, errorMessage) {
  try {
    await db.collection('failedWebhooks').add({
      type: 'app_store_notification',
      payload,
      errorMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      environment: process.env.FIREBASE_ENV || 'development'
    });
  } catch (error) {
    logger.warn('Failed webhook logging error', { error: error.message });
  }
}

module.exports = {
  handleAppStoreNotification: exports.handleAppStoreNotification,
  NOTIFICATION_TYPES,
  SUBSCRIPTION_STATUS
};