const https = require('https');
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Load the APNs key
const apnsKeyPath = '/Users/tradeflowj/Downloads/AuthKey_66LQV834DU.p8';
const apnsKey = fs.readFileSync(apnsKeyPath, 'utf8');

// Configuration - exactly as in Firebase
const config = {
  apnsKeyId: '66LQV834DU',
  apnsTeamId: '62T6J77P6R',
  apnsTopic: 'com.growthlabs.growthmethod.push-type.liveactivity'
};

// Generate JWT token
function generateAPNsToken() {
  try {
    const token = jwt.sign(
      {
        iss: config.apnsTeamId,
        iat: Math.floor(Date.now() / 1000)
      },
      apnsKey,
      {
        algorithm: 'ES256',
        header: {
          alg: 'ES256',
          kid: config.apnsKeyId
        }
      }
    );
    
    console.log('✅ JWT token generated successfully');
    return token;
  } catch (error) {
    console.error('❌ Failed to generate JWT token:', error.message);
    throw error;
  }
}

// Test APNs connection with a dummy push token
async function testAPNsConnection() {
  const token = generateAPNsToken();
  const apnsHost = 'api.development.push.apple.com';  // Using development server for dev key
  
  // Create a dummy push token for testing
  const pushToken = 'dummy_token_for_testing_403_error';
  
  const payload = {
    aps: {
      timestamp: Math.floor(Date.now() / 1000),
      event: 'update',
      'content-state': {
        startTime: new Date().toISOString(),
        endTime: new Date(Date.now() + 60000).toISOString(),
        isPaused: false,
        isCompleted: false,
        methodName: 'Test Method'
      }
    }
  };
  
  const payloadData = JSON.stringify(payload);
  
  const options = {
    hostname: apnsHost,
    port: 443,
    path: `/3/device/${pushToken}`,
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'apns-topic': config.apnsTopic,
      'apns-push-type': 'liveactivity',
      'apns-priority': '10',
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payloadData)
    }
  };
  
  console.log('\n📱 Testing APNs connection...');
  console.log('Host:', apnsHost);
  console.log('Topic:', config.apnsTopic);
  console.log('Team ID:', config.apnsTeamId);
  console.log('Key ID:', config.apnsKeyId);
  console.log('Token (first 50 chars):', token.substring(0, 50) + '...');
  
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('\n📊 Response:');
        console.log('Status Code:', res.statusCode);
        console.log('Headers:', res.headers);
        console.log('Body:', data);
        
        if (res.statusCode === 403) {
          console.log('\n❌ 403 Forbidden - This confirms the InvalidProviderToken error');
          console.log('Possible causes:');
          console.log('1. The APNs authentication key might be revoked');
          console.log('2. Wrong Team ID or Key ID');
          console.log('3. Key doesn\'t have permission for this app');
          console.log('4. Bundle ID mismatch');
        }
        
        resolve({ statusCode: res.statusCode, body: data, headers: res.headers });
      });
    });
    
    req.on('error', (error) => {
      console.error('Request error:', error);
      reject(error);
    });
    
    req.write(payloadData);
    req.end();
  });
}

// Run the test
testAPNsConnection().catch(console.error);