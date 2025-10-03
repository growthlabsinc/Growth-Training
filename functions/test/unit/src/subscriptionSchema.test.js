/**
 * Unit tests for Subscription Schema and Migration Utilities
 */

const {
  subscriptionSchema,
  migrateExistingUsers,
  validateSubscriptionData,
  getSubscriptionDefaults
} = require('../../../src/subscriptionSchema');
const admin = require('firebase-admin');

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      get: jest.fn(),
      doc: jest.fn(),
      limit: jest.fn(),
      orderBy: jest.fn(),
      startAfter: jest.fn()
    })),
    batch: jest.fn(() => ({
      update: jest.fn(),
      commit: jest.fn()
    })),
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP')
    }
  }))
}));

describe('subscriptionSchema', () => {
  describe('Schema Definition', () => {
    it('should define correct user subscription fields', () => {
      expect(subscriptionSchema.userFields).toEqual({
        subscriptionTier: expect.any(String),
        subscriptionStatus: expect.any(String),
        subscriptionExpiresAt: null,
        lastSubscriptionValidation: null,
        originalTransactionId: null,
        autoRenewStatus: expect.any(Boolean),
        gracePeriodExpiresAt: null,
        isTrialPeriod: expect.any(Boolean),
        trialExpiresAt: null
      });
    });

    it('should define subscription tiers', () => {
      expect(subscriptionSchema.tiers).toEqual({
        free: 'free',
        pro: 'pro',
        ultimate: 'ultimate'
      });
    });

    it('should define subscription statuses', () => {
      expect(subscriptionSchema.statuses).toEqual({
        active: 'active',
        expired: 'expired',
        cancelled: 'cancelled',
        grace_period: 'grace_period',
        billing_retry: 'billing_retry',
        refunded: 'refunded'
      });
    });

    it('should define validation log schema', () => {
      expect(subscriptionSchema.validationLogFields).toEqual({
        userId: expect.any(String),
        timestamp: expect.any(Object),
        validationResult: expect.any(String),
        subscriptionStatus: expect.any(String),
        tier: expect.any(String),
        receiptHash: expect.any(String),
        errorDetails: null,
        environment: expect.any(String)
      });
    });
  });

  describe('getSubscriptionDefaults', () => {
    it('should return default subscription values', () => {
      const defaults = getSubscriptionDefaults();
      
      expect(defaults).toEqual({
        subscriptionTier: 'free',
        subscriptionStatus: 'expired',
        subscriptionExpiresAt: null,
        lastSubscriptionValidation: null,
        originalTransactionId: null,
        autoRenewStatus: false,
        gracePeriodExpiresAt: null,
        isTrialPeriod: false,
        trialExpiresAt: null
      });
    });

    it('should use free tier as default', () => {
      const defaults = getSubscriptionDefaults();
      expect(defaults.subscriptionTier).toBe('free');
    });
  });

  describe('validateSubscriptionData', () => {
    it('should validate correct subscription data', () => {
      const validData = {
        subscriptionTier: 'pro',
        subscriptionStatus: 'active',
        subscriptionExpiresAt: new Date(),
        autoRenewStatus: true
      };

      const result = validateSubscriptionData(validData);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject invalid tier', () => {
      const invalidData = {
        subscriptionTier: 'invalid-tier',
        subscriptionStatus: 'active'
      };

      const result = validateSubscriptionData(invalidData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid subscription tier: invalid-tier');
    });

    it('should reject invalid status', () => {
      const invalidData = {
        subscriptionTier: 'pro',
        subscriptionStatus: 'invalid-status'
      };

      const result = validateSubscriptionData(invalidData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid subscription status: invalid-status');
    });

    it('should validate date fields are Date objects', () => {
      const invalidData = {
        subscriptionTier: 'pro',
        subscriptionStatus: 'active',
        subscriptionExpiresAt: 'not-a-date'
      };

      const result = validateSubscriptionData(invalidData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('subscriptionExpiresAt must be a Date object');
    });

    it('should allow null for optional fields', () => {
      const validData = {
        subscriptionTier: 'free',
        subscriptionStatus: 'expired',
        subscriptionExpiresAt: null,
        gracePeriodExpiresAt: null,
        trialExpiresAt: null
      };

      const result = validateSubscriptionData(validData);
      expect(result.isValid).toBe(true);
    });

    it('should validate boolean fields', () => {
      const invalidData = {
        subscriptionTier: 'pro',
        subscriptionStatus: 'active',
        autoRenewStatus: 'yes', // Should be boolean
        isTrialPeriod: 1 // Should be boolean
      };

      const result = validateSubscriptionData(invalidData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('autoRenewStatus must be a boolean');
      expect(result.errors).toContain('isTrialPeriod must be a boolean');
    });
  });

  describe('migrateExistingUsers', () => {
    let mockFirestore;
    let mockBatch;
    let mockUsersCollection;

    beforeEach(() => {
      jest.clearAllMocks();
      
      mockBatch = {
        update: jest.fn(),
        commit: jest.fn().mockResolvedValue()
      };

      mockFirestore = admin.firestore();
      mockFirestore.batch.mockReturnValue(mockBatch);

      mockUsersCollection = {
        get: jest.fn(),
        limit: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        startAfter: jest.fn().mockReturnThis()
      };

      mockFirestore.collection.mockReturnValue(mockUsersCollection);
    });

    it('should migrate users without subscription fields', async () => {
      const mockUsers = [
        {
          id: 'user1',
          data: () => ({ email: 'user1@example.com' }),
          ref: { id: 'user1' }
        },
        {
          id: 'user2',
          data: () => ({ email: 'user2@example.com', subscriptionTier: 'pro' }),
          ref: { id: 'user2' }
        }
      ];

      mockUsersCollection.get.mockResolvedValueOnce({
        empty: false,
        docs: mockUsers
      }).mockResolvedValueOnce({
        empty: true,
        docs: []
      });

      const result = await migrateExistingUsers();

      expect(mockBatch.update).toHaveBeenCalledTimes(1);
      expect(mockBatch.update).toHaveBeenCalledWith(
        mockUsers[0].ref,
        expect.objectContaining({
          subscriptionTier: 'free',
          subscriptionStatus: 'expired',
          subscriptionExpiresAt: null,
          lastSubscriptionValidation: null,
          originalTransactionId: null,
          autoRenewStatus: false,
          gracePeriodExpiresAt: null,
          isTrialPeriod: false,
          trialExpiresAt: null
        })
      );

      expect(result).toEqual({
        success: true,
        migratedCount: 1,
        totalProcessed: 2
      });
    });

    it('should process users in batches', async () => {
      const createMockUser = (id) => ({
        id,
        data: () => ({ email: `user${id}@example.com` }),
        ref: { id }
      });

      // Create 150 users (more than batch size of 100)
      const batch1Users = Array.from({ length: 100 }, (_, i) => createMockUser(`user${i}`));
      const batch2Users = Array.from({ length: 50 }, (_, i) => createMockUser(`user${i + 100}`));

      mockUsersCollection.get
        .mockResolvedValueOnce({ empty: false, docs: batch1Users })
        .mockResolvedValueOnce({ empty: false, docs: batch2Users })
        .mockResolvedValueOnce({ empty: true, docs: [] });

      const result = await migrateExistingUsers();

      expect(mockBatch.commit).toHaveBeenCalledTimes(2);
      expect(result).toEqual({
        success: true,
        migratedCount: 150,
        totalProcessed: 150
      });
    });

    it('should handle migration errors', async () => {
      mockUsersCollection.get.mockRejectedValue(new Error('Database error'));

      const result = await migrateExistingUsers();

      expect(result).toEqual({
        success: false,
        error: 'Database error',
        migratedCount: 0
      });
    });

    it('should skip users with complete subscription data', async () => {
      const mockUsers = [
        {
          id: 'user1',
          data: () => ({
            email: 'user1@example.com',
            subscriptionTier: 'pro',
            subscriptionStatus: 'active',
            subscriptionExpiresAt: new Date(),
            lastSubscriptionValidation: new Date(),
            originalTransactionId: 'trans-123',
            autoRenewStatus: true,
            gracePeriodExpiresAt: null,
            isTrialPeriod: false,
            trialExpiresAt: null
          }),
          ref: { id: 'user1' }
        }
      ];

      mockUsersCollection.get.mockResolvedValueOnce({
        empty: false,
        docs: mockUsers
      }).mockResolvedValueOnce({
        empty: true,
        docs: []
      });

      const result = await migrateExistingUsers();

      expect(mockBatch.update).not.toHaveBeenCalled();
      expect(result).toEqual({
        success: true,
        migratedCount: 0,
        totalProcessed: 1
      });
    });

    it('should add missing fields to partial subscription data', async () => {
      const mockUsers = [
        {
          id: 'user1',
          data: () => ({
            email: 'user1@example.com',
            subscriptionTier: 'pro',
            subscriptionStatus: 'active'
            // Missing other subscription fields
          }),
          ref: { id: 'user1' }
        }
      ];

      mockUsersCollection.get.mockResolvedValueOnce({
        empty: false,
        docs: mockUsers
      }).mockResolvedValueOnce({
        empty: true,
        docs: []
      });

      const result = await migrateExistingUsers();

      expect(mockBatch.update).toHaveBeenCalledWith(
        mockUsers[0].ref,
        expect.objectContaining({
          subscriptionExpiresAt: null,
          lastSubscriptionValidation: null,
          originalTransactionId: null,
          autoRenewStatus: false,
          gracePeriodExpiresAt: null,
          isTrialPeriod: false,
          trialExpiresAt: null
        })
      );

      expect(mockBatch.update).not.toHaveBeenCalledWith(
        mockUsers[0].ref,
        expect.objectContaining({
          subscriptionTier: expect.anything(),
          subscriptionStatus: expect.anything()
        })
      );
    });
  });

  describe('Firestore Indexes', () => {
    it('should define required indexes', () => {
      expect(subscriptionSchema.requiredIndexes).toEqual([
        {
          collection: 'users',
          fields: [
            { field: 'subscriptionTier', order: 'ASCENDING' },
            { field: 'subscriptionExpiresAt', order: 'ASCENDING' }
          ]
        },
        {
          collection: 'users',
          fields: [
            { field: 'subscriptionStatus', order: 'ASCENDING' },
            { field: 'lastSubscriptionValidation', order: 'DESCENDING' }
          ]
        },
        {
          collection: 'users',
          fields: [
            { field: 'originalTransactionId', order: 'ASCENDING' }
          ]
        },
        {
          collection: 'subscriptionValidationLogs',
          fields: [
            { field: 'userId', order: 'ASCENDING' },
            { field: 'timestamp', order: 'DESCENDING' }
          ]
        }
      ]);
    });
  });
});