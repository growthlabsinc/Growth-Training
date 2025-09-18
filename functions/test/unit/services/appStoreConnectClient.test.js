/**
 * Unit tests for App Store Connect Client
 */

const { appStoreConnectClient } = require('../../../src/services/appStoreConnectClient');

// Mock axios
jest.mock('axios');
const axios = require('axios');

// Mock jsonwebtoken
jest.mock('jsonwebtoken');
const jwt = require('jsonwebtoken');

// Mock Firebase Functions config
jest.mock('firebase-functions', () => ({
  config: () => ({
    appstore: {
      key_id: 'test-key-id',
      issuer_id: 'test-issuer-id',
      private_key: 'test-private-key'
    }
  })
}));

describe('appStoreConnectClient', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset the client to clear any cached tokens
    appStoreConnectClient._token = null;
    appStoreConnectClient._tokenExpiry = null;
  });

  describe('generateToken', () => {
    it('should generate a valid JWT token', () => {
      const mockToken = 'mock-jwt-token';
      jwt.sign.mockReturnValue(mockToken);

      const token = appStoreConnectClient.generateToken();

      expect(jwt.sign).toHaveBeenCalledWith(
        expect.objectContaining({
          iss: 'test-issuer-id',
          iat: expect.any(Number),
          exp: expect.any(Number),
          aud: 'appstoreconnect-v1'
        }),
        'test-private-key',
        expect.objectContaining({
          algorithm: 'ES256',
          header: {
            alg: 'ES256',
            kid: 'test-key-id',
            typ: 'JWT'
          }
        })
      );
      expect(token).toBe(mockToken);
    });

    it('should cache the token for subsequent calls', () => {
      const mockToken = 'cached-token';
      jwt.sign.mockReturnValue(mockToken);

      const token1 = appStoreConnectClient.generateToken();
      const token2 = appStoreConnectClient.generateToken();

      expect(jwt.sign).toHaveBeenCalledTimes(1);
      expect(token1).toBe(token2);
    });

    it('should regenerate token when expired', () => {
      const mockToken1 = 'token-1';
      const mockToken2 = 'token-2';
      jwt.sign.mockReturnValueOnce(mockToken1).mockReturnValueOnce(mockToken2);

      // First call
      const token1 = appStoreConnectClient.generateToken();
      
      // Manually expire the token
      appStoreConnectClient._tokenExpiry = Date.now() - 1000;
      
      // Second call should generate new token
      const token2 = appStoreConnectClient.generateToken();

      expect(jwt.sign).toHaveBeenCalledTimes(2);
      expect(token1).toBe(mockToken1);
      expect(token2).toBe(mockToken2);
    });
  });

  describe('makeRequest', () => {
    beforeEach(() => {
      jwt.sign.mockReturnValue('test-token');
    });

    it('should make successful API request', async () => {
      const mockResponse = {
        data: { test: 'data' },
        status: 200
      };
      axios.mockResolvedValue(mockResponse);

      const result = await appStoreConnectClient.makeRequest('/test-endpoint');

      expect(axios).toHaveBeenCalledWith({
        method: 'GET',
        url: 'https://api.appstoreconnect.apple.com/v1/test-endpoint',
        headers: {
          'Authorization': 'Bearer test-token',
          'Content-Type': 'application/json'
        },
        data: undefined
      });
      expect(result).toEqual(mockResponse.data);
    });

    it('should handle rate limiting with retry', async () => {
      const rateLimitError = {
        response: {
          status: 429,
          headers: {
            'retry-after': '2'
          }
        }
      };
      const mockResponse = {
        data: { test: 'data' },
        status: 200
      };

      axios.mockRejectedValueOnce(rateLimitError).mockResolvedValueOnce(mockResponse);

      const result = await appStoreConnectClient.makeRequest('/test-endpoint');

      expect(axios).toHaveBeenCalledTimes(2);
      expect(result).toEqual(mockResponse.data);
    });

    it('should throw error after max retries', async () => {
      const error = new Error('API Error');
      axios.mockRejectedValue(error);

      await expect(appStoreConnectClient.makeRequest('/test-endpoint'))
        .rejects.toThrow('API Error');

      expect(axios).toHaveBeenCalledTimes(3); // Initial + 2 retries
    });
  });

  describe('validateReceipt', () => {
    beforeEach(() => {
      jwt.sign.mockReturnValue('test-token');
    });

    it('should validate receipt successfully', async () => {
      const mockReceipt = 'base64-receipt-data';
      const mockResponse = {
        data: {
          status: 0,
          receipt: {
            bundle_id: 'com.example.app',
            in_app: []
          }
        }
      };

      axios.mockResolvedValue({ data: mockResponse });

      const result = await appStoreConnectClient.validateReceipt(mockReceipt);

      expect(axios).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'POST',
          url: expect.stringContaining('/receipts/verify')
        })
      );
      expect(result).toEqual(mockResponse);
    });

    it('should handle invalid receipt', async () => {
      const mockResponse = {
        data: {
          status: 21003,
          receipt: null
        }
      };

      axios.mockResolvedValue({ data: mockResponse });

      const result = await appStoreConnectClient.validateReceipt('invalid-receipt');

      expect(result.status).toBe(21003);
    });
  });

  describe('getSubscriptionStatus', () => {
    beforeEach(() => {
      jwt.sign.mockReturnValue('test-token');
    });

    it('should get subscription status for a transaction', async () => {
      const mockResponse = {
        data: {
          data: {
            type: 'subscriptionStatuses',
            id: 'transaction-123',
            attributes: {
              state: 'active',
              autoRenewStatus: true
            }
          }
        }
      };

      axios.mockResolvedValue({ data: mockResponse.data });

      const result = await appStoreConnectClient.getSubscriptionStatus('transaction-123');

      expect(axios).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: expect.stringContaining('/subscriptionStatuses/transaction-123')
        })
      );
      expect(result).toEqual(mockResponse.data);
    });
  });
});