/**
 * Enhanced Subscription Validation with Proper Sandbox/Production Handling
 * Follows Apple's recommended approach for receipt validation
 * https://developer.apple.com/documentation/storekit/validating-receipts-with-the-app-store
 */

const admin = require('firebase-admin');
const functions = require('firebase-functions');
const axios = require('axios');

// Apple's receipt validation endpoints
const ENDPOINTS = {
  PRODUCTION: 'https://buy.itunes.apple.com/verifyReceipt',
  SANDBOX: 'https://sandbox.itunes.apple.com/verifyReceipt'
};

// Receipt status codes from Apple
const STATUS_CODES = {
  SUCCESS: 0,
  INVALID_JSON: 21000,
  INVALID_RECEIPT_DATA: 21002,
  AUTHENTICATION_FAILED: 21003,
  SHARED_SECRET_MISMATCH: 21004,
  SERVER_UNAVAILABLE: 21005,
  SUBSCRIPTION_EXPIRED: 21006,
  SANDBOX_RECEIPT_ON_PRODUCTION: 21007,
  PRODUCTION_RECEIPT_ON_SANDBOX: 21008,
  UNAUTHORIZED: 21010
};

/**
 * Get shared secret for receipt validation
 */
async function getSharedSecret() {
  // Try to get from Secret Manager first
  try {
    const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
    const client = new SecretManagerServiceClient();
    const projectId = process.env.GCLOUD_PROJECT || 'growth-70a85';
    
    const [version] = await client.accessSecretVersion({
      name: `projects/${projectId}/secrets/appstore-shared-secret/versions/latest`,
    });
    
    return version.payload.data.toString();
  } catch (error) {
    console.log('Using fallback shared secret from config');
    // Fallback to Firebase config
    const config = functions.config().appstore;
    if (config && config.shared_secret) {
      return config.shared_secret;
    }
    throw new Error('Shared secret not configured');
  }
}

/**
 * Validate receipt with Apple's servers
 * Implements the recommended flow: try production first, then sandbox if needed
 */
async function validateReceiptWithApple(receiptData, sharedSecret) {
  console.log('Starting receipt validation...');
  
  const requestBody = {
    'receipt-data': receiptData,
    'password': sharedSecret,
    'exclude-old-transactions': true
  };
  
  try {
    // Step 1: Always try production endpoint first (Apple's recommendation)
    console.log('Attempting validation with production endpoint...');
    const productionResponse = await axios.post(ENDPOINTS.PRODUCTION, requestBody, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000
    });
    
    // Check if we got a sandbox receipt error
    if (productionResponse.data.status === STATUS_CODES.SANDBOX_RECEIPT_ON_PRODUCTION) {
      console.log('Sandbox receipt detected, retrying with sandbox endpoint...');
      
      // Step 2: Retry with sandbox endpoint
      const sandboxResponse = await axios.post(ENDPOINTS.SANDBOX, requestBody, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 15000
      });
      
      console.log('Sandbox validation response status:', sandboxResponse.data.status);
      return {
        ...sandboxResponse.data,
        environment: 'sandbox',
        retriedWithSandbox: true
      };
    }
    
    console.log('Production validation response status:', productionResponse.data.status);
    return {
      ...productionResponse.data,
      environment: 'production',
      retriedWithSandbox: false
    };
    
  } catch (error) {
    console.error('Network error during validation:', error.message);
    
    // If network error, try sandbox as fallback (for App Review testing)
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      console.log('Network error, attempting sandbox as fallback...');
      
      try {
        const sandboxResponse = await axios.post(ENDPOINTS.SANDBOX, requestBody, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000
        });
        
        return {
          ...sandboxResponse.data,
          environment: 'sandbox',
          retriedWithSandbox: true,
          networkFallback: true
        };
      } catch (sandboxError) {
        console.error('Sandbox fallback also failed:', sandboxError.message);
        throw sandboxError;
      }
    }
    
    throw error;
  }
}

/**
 * Parse and validate the receipt response
 */
function parseReceiptResponse(validation) {
  if (validation.status !== STATUS_CODES.SUCCESS) {
    return {
      isValid: false,
      status: validation.status,
      message: getStatusMessage(validation.status),
      environment: validation.environment
    };
  }
  
  // Get the latest receipt info
  const latestReceipt = validation.latest_receipt_info?.[0];
  
  if (!latestReceipt) {
    return {
      isValid: false,
      status: 'NO_ACTIVE_SUBSCRIPTION',
      message: 'No active subscription found',
      environment: validation.environment
    };
  }
  
  // Check if subscription is still valid
  const expirationTime = parseInt(latestReceipt.expires_date_ms);
  const now = Date.now();
  const isExpired = expirationTime < now;
  
  return {
    isValid: !isExpired,
    status: validation.status,
    environment: validation.environment,
    retriedWithSandbox: validation.retriedWithSandbox,
    subscription: {
      productId: latestReceipt.product_id,
      transactionId: latestReceipt.transaction_id,
      originalTransactionId: latestReceipt.original_transaction_id,
      purchaseDate: new Date(parseInt(latestReceipt.purchase_date_ms)),
      expirationDate: new Date(expirationTime),
      isTrialPeriod: latestReceipt.is_trial_period === 'true',
      isInIntroOfferPeriod: latestReceipt.is_in_intro_offer_period === 'true',
      webOrderLineItemId: latestReceipt.web_order_line_item_id
    },
    latestReceipt: validation.latest_receipt,
    pendingRenewalInfo: validation.pending_renewal_info
  };
}

/**
 * Main Firebase Function for receipt validation
 */
exports.validateSubscriptionReceipt = functions
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to validate receipts'
      );
    }
    
    const { receiptData, forceRefresh } = data;
    
    if (!receiptData) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Receipt data is required'
      );
    }
    
    try {
      // Log for debugging (especially during App Review)
      console.log(`Receipt validation requested by user: ${context.auth.uid}`);
      console.log(`Force refresh: ${forceRefresh}`);
      
      // Get shared secret
      const sharedSecret = await getSharedSecret();
      
      // Validate with Apple
      const validation = await validateReceiptWithApple(receiptData, sharedSecret);
      
      // Parse the response
      const result = parseReceiptResponse(validation);
      
      // Log the result for debugging
      console.log('Validation result:', {
        isValid: result.isValid,
        status: result.status,
        environment: result.environment,
        retriedWithSandbox: result.retriedWithSandbox
      });
      
      // Update Firestore if validation successful
      if (result.isValid && result.subscription) {
        const tier = mapProductIdToTier(result.subscription.productId);
        
        await admin.firestore()
          .collection('users')
          .doc(context.auth.uid)
          .update({
            subscriptionStatus: 'active',
            subscriptionTier: tier,
            subscriptionProductId: result.subscription.productId,
            subscriptionExpirationDate: result.subscription.expirationDate,
            subscriptionEnvironment: result.environment,
            lastValidated: admin.firestore.FieldValue.serverTimestamp(),
            subscriptionMetadata: {
              transactionId: result.subscription.transactionId,
              originalTransactionId: result.subscription.originalTransactionId,
              isTrialPeriod: result.subscription.isTrialPeriod,
              webOrderLineItemId: result.subscription.webOrderLineItemId
            }
          });
        
        // Store latest receipt for future validations
        if (result.latestReceipt) {
          await admin.firestore()
            .collection('subscriptions')
            .doc(context.auth.uid)
            .set({
              latestReceipt: result.latestReceipt,
              environment: result.environment,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }
      }
      
      return {
        isValid: result.isValid,
        tier: result.isValid ? mapProductIdToTier(result.subscription?.productId) : 'none',
        expirationDate: result.subscription?.expirationDate?.toISOString(),
        environment: result.environment,
        timestamp: new Date().toISOString(),
        retriedWithSandbox: result.retriedWithSandbox,
        message: result.message || 'Validation successful'
      };
      
    } catch (error) {
      console.error('Receipt validation error:', error);
      
      // Provide helpful error messages for debugging
      let errorMessage = 'Failed to validate receipt';
      let errorCode = 'internal';
      
      if (error.response?.status === 503) {
        errorMessage = 'Apple servers are temporarily unavailable. Please try again later.';
        errorCode = 'unavailable';
      } else if (error.code === 'ECONNREFUSED') {
        errorMessage = 'Cannot connect to Apple servers. Please check your internet connection.';
        errorCode = 'unavailable';
      } else if (error.message.includes('secret')) {
        errorMessage = 'Server configuration error. Please contact support.';
        errorCode = 'internal';
      }
      
      throw new functions.https.HttpsError(
        errorCode,
        errorMessage,
        { originalError: error.message }
      );
    }
  });

/**
 * Map product ID to subscription tier
 */
function mapProductIdToTier(productId) {
  if (!productId) return 'none';
  
  const tierMapping = {
    // Basic tier
    'com.growthlabs.growthmethod.subscription.basic.monthly': 'basic',
    'com.growthlabs.growthmethod.subscription.basic.yearly': 'basic',
    'com.growthlabs.growthmethod.subscription.basic.annual': 'basic',
    
    // Premium tier
    'com.growthlabs.growthmethod.subscription.premium.monthly': 'premium',
    'com.growthlabs.growthmethod.subscription.premium.yearly': 'premium',
    'com.growthlabs.growthmethod.subscription.premium.annual': 'premium',
    
    // Elite tier
    'com.growthlabs.growthmethod.subscription.elite.monthly': 'elite',
    'com.growthlabs.growthmethod.subscription.elite.yearly': 'elite',
    'com.growthlabs.growthmethod.subscription.elite.annual': 'elite',
    
    // Legacy product IDs (for backward compatibility)
    'com.growthlabs.growthmethod.premium.monthly': 'premium',
    'com.growthlabs.growthmethod.premium.yearly': 'premium'
  };
  
  return tierMapping[productId] || 'none';
}

/**
 * Get human-readable message for status code
 */
function getStatusMessage(status) {
  const messages = {
    [STATUS_CODES.SUCCESS]: 'Valid receipt',
    [STATUS_CODES.INVALID_JSON]: 'The receipt data is not properly formatted',
    [STATUS_CODES.INVALID_RECEIPT_DATA]: 'The receipt data is malformed',
    [STATUS_CODES.AUTHENTICATION_FAILED]: 'Receipt authentication failed',
    [STATUS_CODES.SHARED_SECRET_MISMATCH]: 'Invalid app shared secret',
    [STATUS_CODES.SERVER_UNAVAILABLE]: 'Apple servers are temporarily unavailable',
    [STATUS_CODES.SUBSCRIPTION_EXPIRED]: 'Subscription has expired',
    [STATUS_CODES.SANDBOX_RECEIPT_ON_PRODUCTION]: 'Test receipt submitted to production',
    [STATUS_CODES.PRODUCTION_RECEIPT_ON_SANDBOX]: 'Production receipt submitted to test environment',
    [STATUS_CODES.UNAUTHORIZED]: 'Receipt validation not authorized'
  };
  
  return messages[status] || `Unknown status code: ${status}`;
}

module.exports = {
  validateSubscriptionReceipt: exports.validateSubscriptionReceipt,
  validateReceiptWithApple,
  parseReceiptResponse,
  mapProductIdToTier
};