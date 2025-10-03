/**
 * Unit tests for App Store Server Notifications Webhook Handler
 */

const { handleAppStoreNotification } = require('../../../src/appStoreNotifications');
const admin = require('firebase-admin');
const crypto = require('crypto');

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        set: jest.fn(),
        update: jest.fn()
      })),
      add: jest.fn(),
      where: jest.fn(() => ({
        limit: jest.fn(() => ({
          get: jest.fn()
        }))
      }))
    })),
    batch: jest.fn(() => ({
      update: jest.fn(),
      commit: jest.fn()
    }))
  }))
}));

// Mock Firebase Functions
jest.mock('firebase-functions', () => ({
  https: {
    onRequest: (handler) => handler,
    HttpsError: class HttpsError extends Error {
      constructor(code, message) {
        super(message);
        this.code = code;
      }
    }
  },
  config: () => ({
    appstore: {
      webhook_secret: 'test-webhook-secret'
    }
  })
}));

describe('handleAppStoreNotification', () => {
  let mockRequest;
  let mockResponse;
  let mockFirestore;
  let mockUserDoc;
  let mockUserQuery;

  beforeEach(() => {
    jest.clearAllMocks();

    mockRequest = {
      body: {},
      headers: {}
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      send: jest.fn().mockReturnThis()
    };

    mockUserDoc = {
      exists: true,
      id: 'test-user-id',
      data: () => ({
        email: 'test@example.com',
        subscriptionTier: 'pro'
      }),
      ref: {
        update: jest.fn().mockResolvedValue()
      }
    };

    mockUserQuery = {
      empty: false,
      docs: [mockUserDoc]
    };

    mockFirestore = admin.firestore();
    mockFirestore.collection.mockImplementation((collection) => {
      if (collection === 'users') {
        return {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue(mockUserQuery),
          doc: () => ({
            update: jest.fn().mockResolvedValue()
          })
        };
      } else if (collection === 'appStoreNotifications') {
        return {
          add: jest.fn().mockResolvedValue()
        };
      }
    });
  });

  describe('Signature Validation', () => {
    it('should reject request without signature header', async () => {
      mockRequest.body = { notificationType: 'SUBSCRIBED' };

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Missing signature header'
      });
    });

    it('should reject request with invalid signature', async () => {
      mockRequest.body = { notificationType: 'SUBSCRIBED' };
      mockRequest.headers['x-apple-signature'] = 'invalid-signature';

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Invalid signature'
      });
    });

    it('should accept request with valid signature', async () => {
      const notificationData = {
        notificationType: 'SUBSCRIBED',
        subtype: 'INITIAL_BUY',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          expiresDate: Date.now() + 86400000
        }
      };

      mockRequest.body = notificationData;
      
      // Generate valid signature
      const secret = 'test-webhook-secret';
      const payload = JSON.stringify(notificationData);
      const signature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('base64');
      
      mockRequest.headers['x-apple-signature'] = signature;

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
    });
  });

  describe('Notification Processing', () => {
    beforeEach(() => {
      // Setup valid signature for all tests
      const secret = 'test-webhook-secret';
      mockRequest.headers['x-apple-signature'] = 'valid-for-tests';
      
      // Mock signature validation to pass
      jest.spyOn(crypto, 'createHmac').mockReturnValue({
        update: jest.fn().mockReturnThis(),
        digest: jest.fn().mockReturnValue('valid-for-tests')
      });
    });

    it('should handle SUBSCRIBED notification', async () => {
      mockRequest.body = {
        notificationType: 'SUBSCRIBED',
        subtype: 'INITIAL_BUY',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_ultimate_yearly',
          expiresDate: Date.now() + 86400000,
          bundleId: 'com.growthlabs.growthmethod',
          environment: 'Production'
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockFirestore.collection('users').where).toHaveBeenCalledWith(
        'originalTransactionId',
        '==',
        'transaction-123'
      );
    });

    it('should handle DID_RENEW notification', async () => {
      mockRequest.body = {
        notificationType: 'DID_RENEW',
        subtype: 'BILLING_RECOVERY',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          expiresDate: Date.now() + 2592000000, // 30 days
          autoRenewStatus: true
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const userUpdate = mockFirestore.collection('users').doc().update;
      expect(userUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          subscriptionTier: 'pro',
          subscriptionExpiresAt: expect.any(Object),
          subscriptionStatus: 'active',
          autoRenewStatus: true
        })
      );
    });

    it('should handle DID_FAIL_TO_RENEW notification', async () => {
      mockRequest.body = {
        notificationType: 'DID_FAIL_TO_RENEW',
        subtype: 'GRACE_PERIOD',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          expiresDate: Date.now() - 86400000, // Expired
          gracePeriodExpiresDate: Date.now() + 86400000
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const userUpdate = mockFirestore.collection('users').doc().update;
      expect(userUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          subscriptionStatus: 'grace_period',
          gracePeriodExpiresAt: expect.any(Object)
        })
      );
    });

    it('should handle EXPIRED notification', async () => {
      mockRequest.body = {
        notificationType: 'EXPIRED',
        subtype: 'VOLUNTARY',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          expiresDate: Date.now() - 86400000
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const userUpdate = mockFirestore.collection('users').doc().update;
      expect(userUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          subscriptionTier: 'free',
          subscriptionStatus: 'expired',
          subscriptionExpiresAt: null,
          autoRenewStatus: false
        })
      );
    });

    it('should handle REFUND notification', async () => {
      mockRequest.body = {
        notificationType: 'REFUND',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          refundDate: Date.now()
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const userUpdate = mockFirestore.collection('users').doc().update;
      expect(userUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          subscriptionTier: 'free',
          subscriptionStatus: 'refunded',
          subscriptionExpiresAt: null,
          refundedAt: expect.any(Object)
        })
      );
    });

    it('should log all notifications', async () => {
      mockRequest.body = {
        notificationType: 'SUBSCRIBED',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly'
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const notificationLog = mockFirestore.collection('appStoreNotifications').add;
      expect(notificationLog).toHaveBeenCalledWith(
        expect.objectContaining({
          notificationType: 'SUBSCRIBED',
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly',
          timestamp: expect.any(Object),
          processed: true
        })
      );
    });

    it('should handle user not found', async () => {
      mockUserQuery.empty = true;
      mockUserQuery.docs = [];

      mockRequest.body = {
        notificationType: 'DID_RENEW',
        data: {
          originalTransactionId: 'unknown-transaction',
          productId: 'growth_pro_monthly'
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      const notificationLog = mockFirestore.collection('appStoreNotifications').add;
      expect(notificationLog).toHaveBeenCalledWith(
        expect.objectContaining({
          processed: false,
          error: 'User not found'
        })
      );
    });

    it('should handle grace period expiration', async () => {
      mockRequest.body = {
        notificationType: 'GRACE_PERIOD_EXPIRED',
        data: {
          originalTransactionId: 'transaction-123',
          productId: 'growth_pro_monthly'
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      const userUpdate = mockFirestore.collection('users').doc().update;
      expect(userUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          subscriptionTier: 'free',
          subscriptionStatus: 'expired',
          gracePeriodExpiresAt: null
        })
      );
    });

    it('should map product IDs to subscription tiers correctly', async () => {
      const productTests = [
        { productId: 'growth_pro_monthly', expectedTier: 'pro' },
        { productId: 'growth_pro_yearly', expectedTier: 'pro' },
        { productId: 'growth_ultimate_monthly', expectedTier: 'ultimate' },
        { productId: 'growth_ultimate_yearly', expectedTier: 'ultimate' }
      ];

      for (const test of productTests) {
        jest.clearAllMocks();
        
        mockRequest.body = {
          notificationType: 'SUBSCRIBED',
          data: {
            originalTransactionId: 'transaction-123',
            productId: test.productId,
            expiresDate: Date.now() + 86400000
          }
        };

        await handleAppStoreNotification(mockRequest, mockResponse);

        const userUpdate = mockFirestore.collection('users').doc().update;
        expect(userUpdate).toHaveBeenCalledWith(
          expect.objectContaining({
            subscriptionTier: test.expectedTier
          })
        );
      }
    });
  });

  describe('Error Handling', () => {
    beforeEach(() => {
      // Setup valid signature
      jest.spyOn(crypto, 'createHmac').mockReturnValue({
        update: jest.fn().mockReturnThis(),
        digest: jest.fn().mockReturnValue('valid-for-tests')
      });
      mockRequest.headers['x-apple-signature'] = 'valid-for-tests';
    });

    it('should handle database errors gracefully', async () => {
      mockFirestore.collection('users').where().limit().get.mockRejectedValue(
        new Error('Database error')
      );

      mockRequest.body = {
        notificationType: 'SUBSCRIBED',
        data: {
          originalTransactionId: 'transaction-123'
        }
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Internal server error'
      });
    });

    it('should handle missing notification data', async () => {
      mockRequest.body = {
        notificationType: 'SUBSCRIBED'
        // Missing data field
      };

      await handleAppStoreNotification(mockRequest, mockResponse);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Invalid notification data'
      });
    });
  });
});