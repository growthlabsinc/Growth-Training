const http2 = require('http2');
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Direct test with the DQ46FN4PQU key
const APNS_AUTH_KEY = fs.readFileSync('/Users/tradeflowj/Downloads/AuthKey_DQ46FN4PQU.p8', 'utf8');
const KEY_ID = 'DQ46FN4PQU';
const TEAM_ID = '62T6J77P6R';
const BUNDLE_ID = 'com.growthlabs.growthmethod';

// Development push token just received
const pushToken = '806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600';
const activityId = 'DEV-DIRECT-TEST-' + Date.now();

// Generate JWT
const token = jwt.sign(
  {
    iss: TEAM_ID,
    iat: Math.floor(Date.now() / 1000)
  },
  APNS_AUTH_KEY,
  {
    algorithm: 'ES256',
    header: {
      alg: 'ES256',
      kid: KEY_ID
    }
  }
);

console.log('🔑 Using Key ID:', KEY_ID);
console.log('👥 Team ID:', TEAM_ID);
console.log('📦 Bundle ID:', BUNDLE_ID);
console.log('🔐 JWT Token (first 20 chars):', token.substring(0, 20) + '...');

// Prepare test payload
const payload = {
  aps: {
    timestamp: Math.floor(Date.now() / 1000),
    event: 'update',
    'content-state': {
      startTime: new Date().toISOString(),
      endTime: new Date(Date.now() + 3600000).toISOString(),
      methodName: 'Direct Test',
      sessionType: 'countdown',
      isPaused: false,
      elapsedTimeAtLastUpdate: 0,
      remainingTimeAtLastUpdate: 3600
    },
    alert: {
      title: 'Direct Test',
      body: 'Testing Live Activity Update'
    }
  }
};

const payloadString = JSON.stringify(payload);

// Test with production server to compare errors
console.log('\n🚀 Testing with PRODUCTION server (api.push.apple.com) first...\n');

const client = http2.connect('https://api.push.apple.com:443');

const headers = {
  ':method': 'POST',
  ':path': `/3/device/${pushToken}`,
  'authorization': `bearer ${token}`,
  'apns-topic': BUNDLE_ID,
  'apns-push-type': 'liveactivity',
  'apns-priority': '10',
  'apns-expiration': String(Math.floor(Date.now() / 1000) + 3600),
  'content-type': 'application/json',
  'content-length': String(Buffer.byteLength(payloadString))
};

console.log('📤 Request Headers:', JSON.stringify(headers, null, 2));

const req = client.request(headers);

let responseHeaders = {};
let responseBody = '';

req.on('response', (headers) => {
  responseHeaders = headers;
  console.log('\n📥 Response Headers:', headers);
});

req.on('data', (chunk) => {
  responseBody += chunk;
});

req.on('end', () => {
  client.close();
  
  const statusCode = responseHeaders[':status'];
  console.log('\n=== RESULTS ===');
  console.log('✅ Status Code:', statusCode);
  console.log('📄 Response Body:', responseBody || '(empty)');
  
  if (statusCode === 200) {
    console.log('\n🎉 SUCCESS! Development APNs is working correctly!');
    console.log('Your Live Activity should have updated.');
  } else if (statusCode === 400 && responseBody.includes('BadDeviceToken')) {
    console.log('\n⚠️  BadDeviceToken - This might mean:');
    console.log('   - The token is from a production build');
    console.log('   - The token is expired or invalid');
    console.log('   - Try rebuilding the app in Debug mode');
  } else if (statusCode === 403) {
    console.log('\n❌ Authentication Failed - Check the key configuration');
  } else if (statusCode === 410) {
    console.log('\n❌ Token expired or Live Activity no longer exists');
  } else {
    console.log('\n❌ Unexpected error');
  }
});

req.on('error', (error) => {
  console.error('Request error:', error);
  client.close();
});

req.write(payloadString);
req.end();