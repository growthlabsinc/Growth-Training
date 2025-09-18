/**
 * Integration tests for subscription validation with Firebase Emulator
 */

const admin = require('firebase-admin');
const { validateSubscriptionReceipt } = require('../../functions/src/subscriptionValidation');
const { handleAppStoreNotification } = require('../../functions/src/appStoreNotifications');

// Initialize Firebase Admin for testing
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

// Test configuration
const TEST_USER_ID = 'test-user-123';
const TEST_RECEIPT = 'base64-encoded-receipt-data';
const TEST_BUNDLE_ID = 'com.growth.dev';

describe('Subscription Validation Integration Tests', () => {
  let db;
  
  beforeAll(async () => {
    // Initialize admin with emulator settings
    admin.initializeApp({
      projectId: 'test-project'
    });
    
    db = admin.firestore();
  });
  
  beforeEach(async () => {
    // Clear test data
    const batch = db.batch();
    const collections = ['users', 'subscriptionValidationLogs', 'subscriptionCache'];
    
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
    }
    
    await batch.commit();
    
    // Create test user
    await db.collection('users').doc(TEST_USER_ID).set({
      email: 'test@example.com',
      currentSubscriptionTier: 'none',
      subscriptionStatus: 'inactive',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  
  afterAll(async () => {
    await admin.app().delete();
  });
  
  describe('validateSubscriptionReceipt', () => {
    it('should validate a valid receipt and update user subscription', async () => {
      // Mock auth context
      const context = {
        auth: {
          uid: TEST_USER_ID
        }
      };
      
      // Mock valid receipt data
      const data = {
        receipt: TEST_RECEIPT,
        bundleId: TEST_BUNDLE_ID
      };
      
      // Note: In real test, would need to mock App Store Connect API response
      const result = await validateSubscriptionReceipt(data, context);
      
      // Verify result
      expect(result.success).toBe(true);
      expect(result.data).toHaveProperty('tier');
      expect(result.data).toHaveProperty('expiresAt');
      
      // Verify user was updated
      const user = await db.collection('users').doc(TEST_USER_ID).get();
      const userData = user.data();
      expect(userData.currentSubscriptionTier).not.toBe('none');
      expect(userData.subscriptionStatus).toBe('active');
      
      // Verify validation log was created
      const logs = await db.collection('subscriptionValidationLogs')
        .where('userId', '==', TEST_USER_ID)
        .get();
      expect(logs.size).toBe(1);
    });
    
    it('should handle invalid receipt gracefully', async () => {
      const context = {
        auth: {
          uid: TEST_USER_ID
        }
      };
      
      const data = {
        receipt: 'invalid-receipt',
        bundleId: TEST_BUNDLE_ID
      };
      
      const result = await validateSubscriptionReceipt(data, context);
      
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
      
      // User should remain unchanged
      const user = await db.collection('users').doc(TEST_USER_ID).get();
      const userData = user.data();
      expect(userData.currentSubscriptionTier).toBe('none');
      expect(userData.subscriptionStatus).toBe('inactive');
    });
    
    it('should use cached validation if available', async () => {
      const context = {
        auth: {
          uid: TEST_USER_ID
        }
      };
      
      const data = {
        receipt: TEST_RECEIPT,
        bundleId: TEST_BUNDLE_ID
      };
      
      // Create cache entry
      const cacheKey = `${TEST_USER_ID}_${TEST_RECEIPT.substring(0, 20)}`;
      await db.collection('subscriptionCache').doc(cacheKey).set({
        result: {
          tier: 'premium',
          status: 'active',
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
        },
        expiresAt: Date.now() + 3600000, // 1 hour cache
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        validationType: 'manual',
        hitCount: 0
      });
      
      const result = await validateSubscriptionReceipt(data, context);
      
      expect(result.success).toBe(true);
      expect(result.cached).toBe(true);
      
      // Verify cache hit count increased
      const cache = await db.collection('subscriptionCache').doc(cacheKey).get();
      expect(cache.data().hitCount).toBe(1);
    });
  });
  
  describe('handleAppStoreNotification', () => {
    it('should process subscription renewal notification', async () => {
      const req = {
        body: {
          signedPayload: 'signed-jwt-payload'
        }
      };
      
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      
      // Note: Would need to create valid JWT for real test
      await handleAppStoreNotification(req, res);
      
      expect(res.status).toHaveBeenCalledWith(200);
      
      // Verify notification log was created
      const logs = await db.collection('appStoreNotificationLogs').get();
      expect(logs.size).toBeGreaterThan(0);
    });
    
    it('should handle invalid webhook signature', async () => {
      const req = {
        body: {
          signedPayload: 'invalid-signature'
        }
      };
      
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      
      await handleAppStoreNotification(req, res);
      
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Invalid webhook signature'
      });
    });
  });
  
  describe('End-to-end subscription flow', () => {
    it('should handle complete subscription lifecycle', async () => {
      // 1. Initial receipt validation
      const context = {
        auth: {
          uid: TEST_USER_ID
        }
      };
      
      const receiptData = {
        receipt: TEST_RECEIPT,
        bundleId: TEST_BUNDLE_ID
      };
      
      const validationResult = await validateSubscriptionReceipt(receiptData, context);
      expect(validationResult.success).toBe(true);
      
      // 2. Simulate renewal webhook
      const renewalNotification = {
        body: {
          signedPayload: 'renewal-notification-jwt'
        }
      };
      
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      
      await handleAppStoreNotification(renewalNotification, res);
      
      // 3. Verify user subscription is updated
      const user = await db.collection('users').doc(TEST_USER_ID).get();
      const userData = user.data();
      expect(userData.subscriptionStatus).toBe('active');
      
      // 4. Verify audit trail
      const validationLogs = await db.collection('subscriptionValidationLogs')
        .where('userId', '==', TEST_USER_ID)
        .orderBy('timestamp', 'desc')
        .get();
      
      expect(validationLogs.size).toBeGreaterThan(0);
      
      const notificationLogs = await db.collection('appStoreNotificationLogs')
        .orderBy('timestamp', 'desc')
        .get();
      
      expect(notificationLogs.size).toBeGreaterThan(0);
    });
  });
});

module.exports = {
  // Export test utilities for other tests
  TEST_USER_ID,
  TEST_RECEIPT,
  TEST_BUNDLE_ID
};