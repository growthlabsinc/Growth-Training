/**
 * Unit tests for Subscription Validation Firebase Function
 */

const { validateSubscriptionReceipt } = require('../../../src/subscriptionValidation');
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        set: jest.fn(),
        update: jest.fn()
      })),
      add: jest.fn()
    }))
  })),
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn()
  }))
}));

// Mock Firebase Functions
jest.mock('firebase-functions', () => ({
  https: {
    onCall: (handler) => handler,
    HttpsError: class HttpsError extends Error {
      constructor(code, message, details) {
        super(message);
        this.code = code;
        this.details = details;
      }
    }
  },
  config: () => ({
    appstore: {
      environment: 'sandbox'
    }
  })
}));

// Mock App Store Connect Client
jest.mock('../../../src/services/appStoreConnectClient', () => ({
  appStoreConnectClient: {
    validateReceipt: jest.fn()
  }
}));

const { appStoreConnectClient } = require('../../../src/services/appStoreConnectClient');

describe('validateSubscriptionReceipt', () => {
  let mockContext;
  let mockFirestore;
  let mockUserDoc;
  let mockValidationLogDoc;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockContext = {
      auth: {
        uid: 'test-user-id',
        token: {
          email: 'test@example.com'
        }
      }
    };

    mockUserDoc = {
      exists: true,
      data: () => ({
        email: 'test@example.com',
        subscriptionTier: 'free'
      }),
      ref: {
        update: jest.fn()
      }
    };

    mockValidationLogDoc = {
      add: jest.fn()
    };

    mockFirestore = admin.firestore();
    mockFirestore.collection.mockImplementation((collection) => {
      if (collection === 'users') {
        return {
          doc: () => ({
            get: jest.fn().mockResolvedValue(mockUserDoc),
            update: jest.fn().mockResolvedValue()
          })
        };
      } else if (collection === 'subscriptionValidationLogs') {
        return mockValidationLogDoc;
      }
    });
  });

  it('should validate a valid subscription receipt', async () => {
    const mockReceipt = 'valid-receipt-data';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.growthlabs.growthmethod',
        in_app: [{
          product_id: 'growth_pro_monthly',
          expires_date_ms: String(Date.now() + 86400000), // 1 day from now
          is_trial_period: 'false',
          is_in_intro_offer_period: 'false'
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    const result = await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(appStoreConnectClient.validateReceipt).toHaveBeenCalledWith(mockReceipt);
    expect(result).toEqual({
      success: true,
      subscription: {
        status: 'active',
        tier: 'pro',
        expiresAt: expect.any(String),
        isTrialPeriod: false,
        autoRenewStatus: true
      }
    });
  });

  it('should handle missing authentication', async () => {
    await expect(
      validateSubscriptionReceipt({ receiptData: 'test' }, { auth: null })
    ).rejects.toThrow('User must be authenticated');
  });

  it('should handle missing receipt data', async () => {
    await expect(
      validateSubscriptionReceipt({}, mockContext)
    ).rejects.toThrow('Receipt data is required');
  });

  it('should handle invalid receipt from Apple', async () => {
    const mockReceipt = 'invalid-receipt';
    const mockValidationResponse = {
      status: 21003, // Authentication error
      receipt: null
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    const result = await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(result).toEqual({
      success: false,
      error: 'Invalid receipt',
      errorCode: 21003
    });
  });

  it('should handle expired subscription', async () => {
    const mockReceipt = 'expired-receipt';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.growthlabs.growthmethod',
        in_app: [{
          product_id: 'growth_pro_monthly',
          expires_date_ms: String(Date.now() - 86400000), // 1 day ago
          is_trial_period: 'false'
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    const result = await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(result.subscription.status).toBe('expired');
  });

  it('should detect trial period', async () => {
    const mockReceipt = 'trial-receipt';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.growthlabs.growthmethod',
        in_app: [{
          product_id: 'growth_pro_monthly',
          expires_date_ms: String(Date.now() + 86400000),
          is_trial_period: 'true'
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    const result = await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(result.subscription.isTrialPeriod).toBe(true);
  });

  it('should update user subscription in Firestore', async () => {
    const mockReceipt = 'valid-receipt-data';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.growthlabs.growthmethod',
        in_app: [{
          product_id: 'growth_ultimate_yearly',
          expires_date_ms: String(Date.now() + 86400000)
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    const userUpdateCall = mockFirestore.collection('users').doc().update;
    expect(userUpdateCall).toHaveBeenCalledWith(
      expect.objectContaining({
        subscriptionTier: 'ultimate',
        subscriptionExpiresAt: expect.any(Object),
        lastSubscriptionValidation: expect.any(Object)
      })
    );
  });

  it('should log validation attempt', async () => {
    const mockReceipt = 'valid-receipt-data';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.growthlabs.growthmethod',
        in_app: [{
          product_id: 'growth_pro_monthly',
          expires_date_ms: String(Date.now() + 86400000)
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(mockValidationLogDoc.add).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'test-user-id',
        validationResult: 'success',
        subscriptionStatus: 'active',
        tier: 'pro',
        timestamp: expect.any(Object)
      })
    );
  });

  it('should handle network errors gracefully', async () => {
    appStoreConnectClient.validateReceipt.mockRejectedValue(new Error('Network error'));

    const result = await validateSubscriptionReceipt(
      { receiptData: 'test-receipt' },
      mockContext
    );

    expect(result).toEqual({
      success: false,
      error: 'Failed to validate receipt',
      details: 'Network error'
    });
  });

  it('should validate bundle ID matches app', async () => {
    const mockReceipt = 'wrong-bundle-receipt';
    const mockValidationResponse = {
      status: 0,
      receipt: {
        bundle_id: 'com.wrong.bundle',
        in_app: [{
          product_id: 'some_product',
          expires_date_ms: String(Date.now() + 86400000)
        }]
      }
    };

    appStoreConnectClient.validateReceipt.mockResolvedValue(mockValidationResponse);

    const result = await validateSubscriptionReceipt(
      { receiptData: mockReceipt },
      mockContext
    );

    expect(result).toEqual({
      success: false,
      error: 'Invalid bundle ID'
    });
  });
});