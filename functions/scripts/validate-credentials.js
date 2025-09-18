/**
 * App Store Connect Credential Validation Script
 * Validates API credentials and tests basic functionality
 */

const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config({ path: path.join(__dirname, '../config/.env') });

// Configuration
const CONFIG = {
  keyId: process.env.APPSTORE_KEY_ID,
  issuerId: process.env.APPSTORE_ISSUER_ID,
  bundleId: process.env.APPSTORE_BUNDLE_ID,
  privateKeyPath: path.join(__dirname, '../keys', `AuthKey_${process.env.APPSTORE_KEY_ID}.p8`)
};

// Validation results
const results = {
  credentials: false,
  privateKey: false,
  jwtGeneration: false,
  apiConnection: false,
  subscriptionProducts: false,
  webhookConfig: false
};

/**
 * Validate environment variables
 */
function validateCredentials() {
  console.log('🔍 Validating credentials...\n');
  
  const required = ['APPSTORE_KEY_ID', 'APPSTORE_ISSUER_ID', 'APPSTORE_BUNDLE_ID'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.log('❌ Missing required environment variables:');
    missing.forEach(key => console.log(`   - ${key}`));
    return false;
  }
  
  console.log('✅ All required credentials found');
  console.log(`   Key ID: ${CONFIG.keyId}`);
  console.log(`   Issuer ID: ${CONFIG.issuerId}`);
  console.log(`   Bundle ID: ${CONFIG.bundleId}`);
  
  results.credentials = true;
  return true;
}

/**
 * Validate private key file
 */
function validatePrivateKey() {
  console.log('\n🔑 Validating private key...\n');
  
  if (!fs.existsSync(CONFIG.privateKeyPath)) {
    console.log(`❌ Private key not found at: ${CONFIG.privateKeyPath}`);
    console.log('   Please ensure the .p8 file is in the correct location');
    return false;
  }
  
  try {
    const privateKey = fs.readFileSync(CONFIG.privateKeyPath, 'utf8');
    if (!privateKey.includes('BEGIN PRIVATE KEY')) {
      console.log('❌ Invalid private key format');
      return false;
    }
    
    console.log('✅ Private key file found and valid');
    results.privateKey = true;
    return true;
  } catch (error) {
    console.log(`❌ Error reading private key: ${error.message}`);
    return false;
  }
}

/**
 * Generate JWT token for App Store Connect API
 */
function generateJWT() {
  console.log('\n🎫 Generating JWT token...\n');
  
  try {
    const privateKey = fs.readFileSync(CONFIG.privateKeyPath, 'utf8');
    
    const now = Math.floor(Date.now() / 1000);
    const token = jwt.sign({
      iss: CONFIG.issuerId,
      iat: now,
      exp: now + 1200, // 20 minutes
      aud: 'appstoreconnect-v1'
    }, privateKey, {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: CONFIG.keyId,
        typ: 'JWT'
      }
    });
    
    console.log('✅ JWT token generated successfully');
    console.log(`   Token length: ${token.length} characters`);
    
    results.jwtGeneration = true;
    return token;
  } catch (error) {
    console.log(`❌ Error generating JWT: ${error.message}`);
    return null;
  }
}

/**
 * Test App Store Connect API connection
 */
async function testAPIConnection(token) {
  console.log('\n🌐 Testing App Store Connect API...\n');
  
  try {
    const response = await axios.get('https://api.appstoreconnect.apple.com/v1/apps', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      params: {
        'filter[bundleId]': CONFIG.bundleId
      }
    });
    
    console.log('✅ API connection successful');
    console.log(`   Found ${response.data.data.length} app(s) with bundle ID: ${CONFIG.bundleId}`);
    
    results.apiConnection = true;
    return true;
  } catch (error) {
    console.log('❌ API connection failed');
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Error: ${JSON.stringify(error.response.data.errors, null, 2)}`);
    } else {
      console.log(`   Error: ${error.message}`);
    }
    return false;
  }
}

/**
 * Validate subscription products
 */
async function validateSubscriptionProducts(token) {
  console.log('\n📦 Validating subscription products...\n');
  
  const expectedProducts = [
    'com.growth.subscription.basic.monthly',
    'com.growth.subscription.basic.yearly',
    'com.growth.subscription.premium.monthly',
    'com.growth.subscription.premium.yearly',
    'com.growth.subscription.elite.monthly',
    'com.growth.subscription.elite.yearly'
  ];
  
  // Note: This is a placeholder - actual implementation would query App Store Connect
  // for in-app purchases associated with the app
  console.log('⚠️  Subscription product validation requires manual verification');
  console.log('   Expected products:');
  expectedProducts.forEach(product => console.log(`   - ${product}`));
  console.log('\n   Please verify these products exist in App Store Connect');
  
  return true;
}

/**
 * Validate webhook configuration
 */
function validateWebhookConfig() {
  console.log('\n🔔 Validating webhook configuration...\n');
  
  const webhookUrl = 'https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification';
  const sandboxUrl = 'https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox';
  
  console.log('📋 Webhook URLs configured:');
  console.log(`   Production: ${webhookUrl}`);
  console.log(`   Sandbox: ${sandboxUrl}`);
  console.log('\n⚠️  Please configure these URLs in App Store Connect:');
  console.log('   1. Go to App Store Connect > Users and Access > Integrations');
  console.log('   2. Configure App Store Server Notifications');
  console.log('   3. Set the production and sandbox URLs');
  console.log('   4. Enable all notification types');
  
  if (process.env.APPSTORE_SHARED_SECRET) {
    console.log('\n✅ Shared secret found for webhook signature verification');
    results.webhookConfig = true;
  } else {
    console.log('\n❌ Missing APPSTORE_SHARED_SECRET for webhook verification');
  }
  
  return true;
}

/**
 * Main validation flow
 */
async function main() {
  console.log('🏁 App Store Connect Credential Validation');
  console.log('==========================================\n');
  
  // Step 1: Validate credentials
  if (!validateCredentials()) {
    console.log('\n❌ Validation failed: Missing credentials');
    process.exit(1);
  }
  
  // Step 2: Validate private key
  if (!validatePrivateKey()) {
    console.log('\n❌ Validation failed: Invalid private key');
    process.exit(1);
  }
  
  // Step 3: Generate JWT
  const token = generateJWT();
  if (!token) {
    console.log('\n❌ Validation failed: Could not generate JWT');
    process.exit(1);
  }
  
  // Step 4: Test API connection
  await testAPIConnection(token);
  
  // Step 5: Validate subscription products
  await validateSubscriptionProducts(token);
  
  // Step 6: Validate webhook configuration
  validateWebhookConfig();
  
  // Summary
  console.log('\n📊 Validation Summary');
  console.log('====================');
  Object.entries(results).forEach(([key, value]) => {
    const status = value ? '✅' : '❌';
    const label = key.replace(/([A-Z])/g, ' $1').trim();
    console.log(`${status} ${label.charAt(0).toUpperCase() + label.slice(1)}`);
  });
  
  const successCount = Object.values(results).filter(v => v).length;
  const totalCount = Object.keys(results).length;
  
  console.log(`\n🎯 Overall: ${successCount}/${totalCount} checks passed`);
  
  if (successCount === totalCount) {
    console.log('\n✅ All validations passed! Ready for production.');
  } else {
    console.log('\n⚠️  Some validations need attention. Please review above.');
  }
}

// Run validation
main().catch(error => {
  console.error('\n❌ Unexpected error:', error.message);
  process.exit(1);
});