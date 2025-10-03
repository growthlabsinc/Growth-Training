/**
 * App Store Connect API Client Service
 * Handles authentication and API calls to App Store Connect APIs
 */

const jwt = require('jsonwebtoken');
const axios = require('axios');
const fs = require('fs');

class AppStoreConnectClient {
  constructor() {
    // Configuration from environment variables
    this.keyId = process.env.APP_STORE_CONNECT_KEY_ID;
    this.issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
    this.privateKeyPath = process.env.APP_STORE_CONNECT_PRIVATE_KEY_PATH;
    this.baseURL = 'https://api.appstoreconnect.apple.com/v1';
    
    // Rate limiting configuration
    this.requestCount = 0;
    this.requestWindow = 60000; // 1 minute
    this.maxRequestsPerMinute = 200; // Conservative limit
    this.lastReset = Date.now();
    
    // Initialize token
    this.token = null;
    this.tokenExpiry = null;
  }

  /**
   * Generate JWT token for App Store Connect API authentication
   * @returns {string} JWT token
   */
  generateToken() {
    try {
      if (!this.keyId || !this.issuerId || !this.privateKeyPath) {
        throw new Error('Missing required App Store Connect API credentials');
      }

      // Check if current token is still valid (with 5-minute buffer)
      if (this.token && this.tokenExpiry && Date.now() < this.tokenExpiry - 300000) {
        return this.token;
      }

      // Read private key
      const privateKey = fs.readFileSync(this.privateKeyPath, 'utf8');
      
      const now = Math.round(Date.now() / 1000);
      const payload = {
        iss: this.issuerId,
        exp: now + 1200, // 20 minutes (max allowed by Apple)
        aud: 'appstoreconnect-v1',
        sub: this.keyId
      };

      this.token = jwt.sign(payload, privateKey, {
        algorithm: 'ES256',
        header: {
          alg: 'ES256',
          kid: this.keyId,
          typ: 'JWT'
        }
      });

      this.tokenExpiry = (now + 1200) * 1000; // Convert to milliseconds
      return this.token;
    } catch (error) {
      console.error('Error generating App Store Connect token:', error);
      throw new Error(`Token generation failed: ${error.message}`);
    }
  }

  /**
   * Check and enforce rate limiting
   * @throws {Error} If rate limit exceeded
   */
  checkRateLimit() {
    const now = Date.now();
    
    // Reset counter if window expired
    if (now - this.lastReset > this.requestWindow) {
      this.requestCount = 0;
      this.lastReset = now;
    }
    
    if (this.requestCount >= this.maxRequestsPerMinute) {
      const waitTime = this.requestWindow - (now - this.lastReset);
      throw new Error(`Rate limit exceeded. Wait ${Math.ceil(waitTime / 1000)} seconds`);
    }
    
    this.requestCount++;
  }

  /**
   * Make authenticated request to App Store Connect API
   * @param {string} endpoint - API endpoint path
   * @param {string} method - HTTP method (GET, POST, etc.)
   * @param {Object} data - Request data for POST/PUT requests
   * @returns {Promise<Object>} API response data
   */
  async makeRequest(endpoint, method = 'GET', data = null) {
    try {
      this.checkRateLimit();
      
      const token = this.generateToken();
      const config = {
        method,
        url: `${this.baseURL}${endpoint}`,
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000 // 30 second timeout
      };

      if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
        config.data = data;
      }

      const response = await axios(config);
      return response.data;
    } catch (error) {
      console.error(`App Store Connect API error:`, {
        endpoint,
        method,
        status: error.response?.status,
        message: error.response?.data || error.message
      });

      if (error.response?.status === 429) {
        throw new Error('Rate limit exceeded by App Store Connect API');
      }
      
      if (error.response?.status === 401) {
        throw new Error('Authentication failed with App Store Connect API');
      }
      
      throw new Error(`App Store Connect API request failed: ${error.message}`);
    }
  }

  /**
   * Get subscription product information
   * @param {string} productId - App Store product ID
   * @returns {Promise<Object>} Product information
   */
  async getSubscriptionProduct(productId) {
    return this.makeRequest(`/subscriptions?filter[productId]=${productId}`);
  }

  /**
   * Validate subscription receipt with App Store
   * @param {string} receiptData - Base64 encoded receipt data
   * @param {boolean} sandbox - Whether to use sandbox environment
   * @returns {Promise<Object>} Receipt validation response
   */
  async validateReceipt(receiptData, sandbox = false) {
    const url = sandbox 
      ? 'https://sandbox.itunes.apple.com/verifyReceipt'
      : 'https://buy.itunes.apple.com/verifyReceipt';

    try {
      const response = await axios.post(url, {
        'receipt-data': receiptData,
        'password': process.env.APP_STORE_SHARED_SECRET,
        'exclude-old-transactions': true
      }, {
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json'
        }
      });

      return response.data;
    } catch (error) {
      console.error('Receipt validation error:', error);
      throw new Error(`Receipt validation failed: ${error.message}`);
    }
  }

  /**
   * Get current rate limit status
   * @returns {Object} Rate limit information
   */
  getRateLimitStatus() {
    const now = Date.now();
    const windowRemaining = this.requestWindow - (now - this.lastReset);
    
    return {
      requestsUsed: this.requestCount,
      requestsRemaining: this.maxRequestsPerMinute - this.requestCount,
      windowResetIn: Math.max(0, windowRemaining),
      rateLimitActive: this.requestCount >= this.maxRequestsPerMinute
    };
  }
}

module.exports = AppStoreConnectClient;