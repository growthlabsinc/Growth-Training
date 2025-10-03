/**
 * Subscription Database Schema Design and Migration
 * Defines Firestore collections and field structures for subscription management
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * User collection schema extension for subscriptions
 */
const USER_SUBSCRIPTION_FIELDS = {
  // Current subscription information
  currentSubscriptionTier: 'none', // 'none' | 'basic' | 'premium' | 'elite'
  subscriptionStatus: 'inactive', // 'active' | 'expired' | 'grace_period' | 'billing_retry' | 'revoked' | 'inactive'
  subscriptionExpirationDate: null, // Timestamp or null
  subscriptionTransactionId: null, // Apple's original transaction ID
  subscriptionAutoRenew: false, // Boolean
  
  // Subscription history and metadata
  subscriptionStartDate: null, // When subscription first started
  subscriptionPlan: null, // 'monthly' | 'yearly'
  lastValidated: null, // Last time subscription was validated
  subscriptionRegion: null, // App Store region for pricing
  
  // Trial and promotional information
  hasUsedFreeTrial: false, // Boolean
  promoCodesUsed: [], // Array of promo code IDs
  
  // Billing and payment
  lastPaymentDate: null, // Last successful payment timestamp
  paymentFailureCount: 0, // Number of consecutive payment failures
  gracePeriodEnd: null, // Grace period expiration date
  
  // Feature access (derived from subscription tier)
  hasAdvancedFeatures: false, // Computed based on tier
  hasCoachingAccess: false, // Computed based on tier
  hasPremiumContent: false, // Computed based on tier
  
  // Audit fields
  createdAt: null, // Account creation date
  updatedAt: null // Last profile update
};

/**
 * Subscription validation logs collection schema
 */
const SUBSCRIPTION_VALIDATION_LOG_SCHEMA = {
  userId: '', // Reference to user
  result: {}, // Validation result object
  status: '', // 'success' | 'error' | 'cache_hit'
  errorMessage: null, // Error message if status is 'error'
  timestamp: null, // Server timestamp
  environment: '', // 'development' | 'staging' | 'production'
  validationType: '', // 'manual' | 'automatic' | 'webhook'
  responseTime: 0, // Validation response time in milliseconds
  cacheUsed: false // Whether cached result was used
};

/**
 * App Store notification logs collection schema
 */
const APP_STORE_NOTIFICATION_LOG_SCHEMA = {
  userId: '', // Reference to user (if found)
  notificationType: '', // Apple notification type
  transactionId: '', // Apple transaction ID
  productId: '', // App Store product ID
  status: '', // 'processed' | 'failed' | 'ignored'
  notification: {}, // Full Apple notification payload
  timestamp: null, // Server timestamp
  environment: '', // Firebase environment
  processingTime: 0, // Processing time in milliseconds
  errorMessage: null // Error message if processing failed
};

/**
 * Subscription cache collection schema
 */
const SUBSCRIPTION_CACHE_SCHEMA = {
  result: {}, // Cached validation result
  expiresAt: 0, // Cache expiration timestamp
  createdAt: null, // Server timestamp when cached
  validationType: '', // Type of validation that was cached
  hitCount: 0 // Number of times this cache entry was used
};

/**
 * Failed webhooks collection schema
 */
const FAILED_WEBHOOK_SCHEMA = {
  type: '', // 'app_store_notification'
  payload: {}, // Original webhook payload
  errorMessage: '', // Error that caused failure
  timestamp: null, // Server timestamp
  environment: '', // Firebase environment
  retryCount: 0, // Number of retry attempts
  lastRetryAt: null, // Last retry timestamp
  resolved: false // Whether the issue was resolved
};

/**
 * Subscription product configuration schema
 */
const SUBSCRIPTION_PRODUCT_SCHEMA = {
  productId: '', // App Store product ID (e.g., 'com.growth.subscription.basic.monthly')
  tier: '', // 'basic' | 'premium' | 'elite'
  plan: '', // 'monthly' | 'yearly'
  priceUSD: 0, // Price in USD cents
  displayName: '', // Human-readable name
  description: '', // Product description
  features: [], // Array of included features
  active: true, // Whether product is available for purchase
  createdAt: null, // Server timestamp
  updatedAt: null // Last update timestamp
};

/**
 * Create initial subscription product configurations
 */
async function createSubscriptionProducts() {
  const products = [
    {
      productId: 'com.growth.subscription.basic.monthly',
      tier: 'basic',
      plan: 'monthly',
      priceUSD: 499, // $4.99
      displayName: 'Basic Monthly',
      description: 'Access to basic growth methods and progress tracking',
      features: ['basic_methods', 'progress_tracking', 'community_access'],
      active: true
    },
    {
      productId: 'com.growth.subscription.basic.yearly',
      tier: 'basic',
      plan: 'yearly',
      priceUSD: 4999, // $49.99 (2 months free)
      displayName: 'Basic Yearly',
      description: 'Access to basic growth methods and progress tracking (yearly)',
      features: ['basic_methods', 'progress_tracking', 'community_access'],
      active: true
    },
    {
      productId: 'com.growth.subscription.premium.monthly',
      tier: 'premium',
      plan: 'monthly',
      priceUSD: 999, // $9.99
      displayName: 'Premium Monthly',
      description: 'Access to all growth methods plus AI coaching',
      features: ['all_methods', 'ai_coaching', 'progress_tracking', 'community_access', 'advanced_analytics'],
      active: true
    },
    {
      productId: 'com.growth.subscription.premium.yearly',
      tier: 'premium',
      plan: 'yearly',
      priceUSD: 9999, // $99.99 (2 months free)
      displayName: 'Premium Yearly',
      description: 'Access to all growth methods plus AI coaching (yearly)',
      features: ['all_methods', 'ai_coaching', 'progress_tracking', 'community_access', 'advanced_analytics'],
      active: true
    },
    {
      productId: 'com.growth.subscription.elite.monthly',
      tier: 'elite',
      plan: 'monthly',
      priceUSD: 1999, // $19.99
      displayName: 'Elite Monthly',
      description: 'Premium features plus personalized coaching and priority support',
      features: ['all_methods', 'ai_coaching', 'personal_coaching', 'priority_support', 'progress_tracking', 'community_access', 'advanced_analytics', 'exclusive_content'],
      active: true
    },
    {
      productId: 'com.growth.subscription.elite.yearly',
      tier: 'elite',
      plan: 'yearly',
      priceUSD: 19999, // $199.99 (2 months free)
      displayName: 'Elite Yearly',
      description: 'Premium features plus personalized coaching and priority support (yearly)',
      features: ['all_methods', 'ai_coaching', 'personal_coaching', 'priority_support', 'progress_tracking', 'community_access', 'advanced_analytics', 'exclusive_content'],
      active: true
    }
  ];

  const batch = db.batch();
  
  for (const product of products) {
    const docRef = db.collection('subscriptionProducts').doc(product.productId);
    batch.set(docRef, {
      ...product,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  await batch.commit();
  console.log('Subscription products created successfully');
}

/**
 * Create Firestore indexes for subscription queries
 */
async function createSubscriptionIndexes() {
  // Note: Firestore indexes must be created through Firebase console or CLI
  // This function documents the required indexes
  
  const requiredIndexes = [
    {
      collection: 'users',
      fields: [
        { field: 'currentSubscriptionTier', order: 'ASCENDING' },
        { field: 'subscriptionStatus', order: 'ASCENDING' },
        { field: 'subscriptionExpirationDate', order: 'ASCENDING' }
      ]
    },
    {
      collection: 'users',
      fields: [
        { field: 'subscriptionTransactionId', order: 'ASCENDING' }
      ]
    },
    {
      collection: 'subscriptionValidationLogs',
      fields: [
        { field: 'userId', order: 'ASCENDING' },
        { field: 'timestamp', order: 'DESCENDING' }
      ]
    },
    {
      collection: 'appStoreNotificationLogs',
      fields: [
        { field: 'userId', order: 'ASCENDING' },
        { field: 'timestamp', order: 'DESCENDING' }
      ]
    },
    {
      collection: 'subscriptionCache',
      fields: [
        { field: 'expiresAt', order: 'ASCENDING' }
      ]
    }
  ];

  console.log('Required Firestore indexes:', JSON.stringify(requiredIndexes, null, 2));
  console.log('Create these indexes using: firebase deploy --only firestore:indexes');
  
  return requiredIndexes;
}

/**
 * Migrate existing users to include subscription fields
 */
async function migrateUsersForSubscriptions() {
  try {
    console.log('Starting user subscription migration...');
    
    const usersRef = db.collection('users');
    const batchSize = 100;
    let lastDoc = null;
    let totalMigrated = 0;

    while (true) {
      let query = usersRef.limit(batchSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      
      if (snapshot.empty) {
        break;
      }

      const batch = db.batch();
      
      for (const doc of snapshot.docs) {
        const userData = doc.data();
        
        // Only migrate if subscription fields don't exist
        if (!userData.hasOwnProperty('currentSubscriptionTier')) {
          batch.update(doc.ref, {
            currentSubscriptionTier: 'none',
            subscriptionStatus: 'inactive',
            subscriptionExpirationDate: null,
            subscriptionTransactionId: null,
            subscriptionAutoRenew: false,
            subscriptionStartDate: null,
            subscriptionPlan: null,
            lastValidated: null,
            subscriptionRegion: null,
            hasUsedFreeTrial: false,
            promoCodesUsed: [],
            lastPaymentDate: null,
            paymentFailureCount: 0,
            gracePeriodEnd: null,
            hasAdvancedFeatures: false,
            hasCoachingAccess: false,
            hasPremiumContent: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      await batch.commit();
      totalMigrated += snapshot.size;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      
      console.log(`Migrated ${totalMigrated} users...`);
    }

    console.log(`User subscription migration completed. Total users migrated: ${totalMigrated}`);
    return totalMigrated;
    
  } catch (error) {
    console.error('User migration error:', error);
    throw error;
  }
}

/**
 * Validate subscription data integrity
 */
async function validateSubscriptionData() {
  try {
    const issues = [];
    
    // Check for users with invalid subscription tiers
    const invalidTierQuery = await db.collection('users')
      .where('currentSubscriptionTier', 'not-in', ['none', 'basic', 'premium', 'elite'])
      .get();
    
    if (!invalidTierQuery.empty) {
      issues.push(`Found ${invalidTierQuery.size} users with invalid subscription tiers`);
    }

    // Check for expired subscriptions that are still marked as active
    const now = new Date();
    const expiredActiveQuery = await db.collection('users')
      .where('subscriptionStatus', '==', 'active')
      .where('subscriptionExpirationDate', '<', now)
      .get();
    
    if (!expiredActiveQuery.empty) {
      issues.push(`Found ${expiredActiveQuery.size} users with expired but active subscriptions`);
    }

    return {
      isValid: issues.length === 0,
      issues
    };
    
  } catch (error) {
    console.error('Subscription data validation error:', error);
    throw error;
  }
}

module.exports = {
  USER_SUBSCRIPTION_FIELDS,
  SUBSCRIPTION_VALIDATION_LOG_SCHEMA,
  APP_STORE_NOTIFICATION_LOG_SCHEMA,
  SUBSCRIPTION_CACHE_SCHEMA,
  FAILED_WEBHOOK_SCHEMA,
  SUBSCRIPTION_PRODUCT_SCHEMA,
  createSubscriptionProducts,
  createSubscriptionIndexes,
  migrateUsersForSubscriptions,
  validateSubscriptionData
};