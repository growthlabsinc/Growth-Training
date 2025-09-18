/**
 * Test script for dual-key APNs configuration
 * 
 * This script tests the updated APNs implementation that supports
 * both development and production keys with automatic retry logic.
 */

const http2 = require('http2');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Test configuration
const config = {
  // Development credentials (current key)
  apnsKeyId: process.env.APNS_KEY_ID || '55LZB28UY2',
  apnsKey: process.env.APNS_AUTH_KEY,
  
  // Production credentials (optional, falls back to dev if not set)
  apnsKeyIdProd: process.env.APNS_KEY_ID_PROD || process.env.APNS_KEY_ID || '55LZB28UY2',
  apnsKeyProd: process.env.APNS_AUTH_KEY_PROD || process.env.APNS_AUTH_KEY,
  
  // Common settings
  apnsTeamId: process.env.APNS_TEAM_ID || '62T6J77P6R',
  apnsTopic: process.env.APNS_TOPIC || 'com.growthlabs.growthmethod',
  
  // Test push token (replace with actual token from your app)
  testPushToken: process.argv[2] || '806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600'
};

// Generate JWT token
function generateAPNsToken(useProduction = false) {
  const keyId = useProduction ? config.apnsKeyIdProd : config.apnsKeyId;
  const authKey = useProduction ? config.apnsKeyProd : config.apnsKey;
  
  if (!authKey) {
    throw new Error(`No ${useProduction ? 'production' : 'development'} auth key found`);
  }
  
  const token = jwt.sign(
    {
      iss: config.apnsTeamId,
      iat: Math.floor(Date.now() / 1000)
    },
    authKey,
    {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: keyId
      }
    }
  );
  
  console.log(`✅ Generated ${useProduction ? 'PRODUCTION' : 'DEVELOPMENT'} JWT token`);
  console.log(`   Key ID: ${keyId}`);
  console.log(`   Token preview: ${token.substring(0, 40)}...`);
  
  return token;
}

// Test APNs connection
async function testAPNsConnection(environment, token) {
  const host = environment === 'production' ? 'api.push.apple.com' : 'api.development.push.apple.com';
  
  return new Promise((resolve, reject) => {
    console.log(`\n🔧 Testing ${environment.toUpperCase()} environment...`);
    console.log(`   Host: ${host}`);
    
    const client = http2.connect(`https://${host}:443`);
    
    client.on('error', (err) => {
      console.error(`❌ ${environment} connection error:`, err.message);
      reject(err);
    });

    // Test payload
    const payload = JSON.stringify({
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': {
          startTime: new Date().toISOString(),
          endTime: new Date(Date.now() + 3600000).toISOString(),
          methodName: 'Test Timer',
          sessionType: 'countdown',
          isPaused: false
        }
      }
    });

    const req = client.request({
      ':method': 'POST',
      ':path': `/3/device/${config.testPushToken}`,
      'authorization': `bearer ${token}`,
      'apns-topic': config.apnsTopic,
      'apns-push-type': 'liveactivity',
      'apns-priority': '10',
      'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
      'content-type': 'application/json',
      'content-length': Buffer.byteLength(payload)
    });

    let responseBody = '';
    let responseHeaders = {};

    req.on('response', (headers) => {
      responseHeaders = headers;
      console.log(`📥 Response Status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      responseBody += chunk;
    });

    req.on('end', () => {
      client.close();
      
      const statusCode = responseHeaders[':status'];
      const result = {
        environment,
        statusCode,
        response: responseBody,
        success: statusCode === 200
      };
      
      if (statusCode === 200) {
        console.log(`✅ ${environment} - Success!`);
      } else if (statusCode === 400 && responseBody.includes('BadDeviceToken')) {
        console.log(`⚠️  ${environment} - BadDeviceToken (token/server mismatch)`);
      } else if (statusCode === 403) {
        console.log(`❌ ${environment} - 403 Forbidden (invalid authentication)`);
        console.log(`   Response: ${responseBody}`);
      } else if (statusCode === 410) {
        console.log(`❌ ${environment} - 410 Gone (token no longer valid)`);
      } else {
        console.log(`❌ ${environment} - Error ${statusCode}: ${responseBody}`);
      }
      
      resolve(result);
    });

    req.on('error', (error) => {
      console.error(`❌ ${environment} request error:`, error.message);
      client.close();
      reject(error);
    });

    req.write(payload);
    req.end();
  });
}

// Main test function
async function runTests() {
  console.log('🚀 Testing Dual-Key APNs Configuration');
  console.log('=====================================\n');
  
  console.log('📋 Configuration:');
  console.log(`   Team ID: ${config.apnsTeamId}`);
  console.log(`   Topic: ${config.apnsTopic}`);
  console.log(`   Dev Key ID: ${config.apnsKeyId}`);
  console.log(`   Prod Key ID: ${config.apnsKeyIdProd}`);
  console.log(`   Has Dev Key: ${!!config.apnsKey}`);
  console.log(`   Has Prod Key: ${!!config.apnsKeyProd}`);
  console.log(`   Keys are different: ${config.apnsKey !== config.apnsKeyProd}`);
  
  const results = [];
  
  // Test development environment
  try {
    const devToken = generateAPNsToken(false);
    const devResult = await testAPNsConnection('development', devToken);
    results.push(devResult);
  } catch (error) {
    console.error('❌ Development test failed:', error.message);
    results.push({ environment: 'development', error: error.message });
  }
  
  // Test production environment
  try {
    const prodToken = generateAPNsToken(true);
    const prodResult = await testAPNsConnection('production', prodToken);
    results.push(prodResult);
  } catch (error) {
    console.error('❌ Production test failed:', error.message);
    results.push({ environment: 'production', error: error.message });
  }
  
  // Summary
  console.log('\n📊 Test Summary:');
  console.log('================');
  
  for (const result of results) {
    if (result.success) {
      console.log(`✅ ${result.environment}: SUCCESS`);
    } else if (result.statusCode === 400 && result.response?.includes('BadDeviceToken')) {
      console.log(`⚠️  ${result.environment}: Token/Server mismatch (expected with dev token)`);
    } else {
      console.log(`❌ ${result.environment}: FAILED - ${result.statusCode || result.error}`);
    }
  }
  
  console.log('\n💡 Recommendations:');
  if (results.some(r => r.statusCode === 403)) {
    console.log('- Contact Apple Developer Support about the 403 InvalidProviderToken error');
    console.log('- Verify the key has APNs capability enabled in Apple Developer Portal');
    console.log('- Check if the key belongs to the correct Team ID');
  }
  
  if (results.every(r => !r.success)) {
    console.log('- Both environments failed - check APNs key configuration');
  } else if (results.some(r => r.success)) {
    console.log('- At least one environment works - the implementation supports automatic retry');
  }
}

// Check for auth key
if (!config.apnsKey) {
  console.error('❌ Error: APNS_AUTH_KEY not found in environment');
  console.error('Please ensure Firebase secrets are configured or .env file exists');
  process.exit(1);
}

// Run the tests
runTests().catch(console.error);