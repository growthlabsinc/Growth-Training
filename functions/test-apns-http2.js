const http2 = require('http2');
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Test APNs connection with HTTP/2
async function testAPNsHttp2() {
    // APNs configuration
    const keyId = '55LZB28UY2';
    const teamId = '62T6J77P6R';
    const authKeyPath = './AuthKey_55LZB28UY2.p8';
    const pushToken = '803424c9589c28467e1d82a5eaaf5c1b7c5c4ba2c3b3bb9f7c892a666c090e26'; // Most recent token
    
    try {
        // Read auth key
        const authKey = fs.readFileSync(authKeyPath, 'utf8');
        console.log('✅ Auth key loaded successfully');
        
        // Generate JWT
        const token = jwt.sign({}, authKey, {
            algorithm: 'ES256',
            header: {
                alg: 'ES256',
                kid: keyId
            },
            issuer: teamId,
            expiresIn: '1h'
        });
        console.log('✅ JWT generated successfully');
        console.log('Token length:', token.length);
        
        // Create test payload
        const testPayload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'update',
                'content-state': {
                    startedAt: new Date().toISOString(),
                    pausedAt: new Date().toISOString(), // Paused state
                    duration: 300,
                    methodName: 'Test Method',
                    sessionType: 'countdown',
                    isPaused: true,
                    updateSource: 'test-script'
                },
                'stale-date': Math.floor(Date.now() / 1000) + 3600,
                'relevance-score': 100,
                alert: {
                    title: 'Test Update',
                    body: 'Testing pause state from script'
                }
            }
        };
        
        const payloadString = JSON.stringify(testPayload);
        console.log('\nPayload:', JSON.stringify(testPayload, null, 2));
        console.log('Payload size:', payloadString.length, 'bytes');
        
        // Connect to APNs
        console.log('\n🔌 Connecting to APNs development server...');
        const client = http2.connect('https://api.development.push.apple.com:443');
        
        client.on('error', (err) => {
            console.error('❌ HTTP/2 client error:', err);
        });
        
        // Send request
        const req = client.request({
            ':method': 'POST',
            ':path': `/3/device/${pushToken}`,
            'authorization': `bearer ${token}`,
            'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
            'apns-push-type': 'liveactivity',
            'apns-priority': '10',
            'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
            'content-type': 'application/json',
            'content-length': Buffer.byteLength(payloadString)
        });
        
        console.log('\n📤 Sending push notification...');
        console.log('Push token:', pushToken.substring(0, 20) + '...');
        console.log('Topic:', 'com.growthlabs.growthmethod.push-type.liveactivity');
        
        let responseBody = '';
        let responseHeaders = {};
        
        req.on('response', (headers) => {
            responseHeaders = headers;
            console.log('\n📥 Response headers:', headers);
        });
        
        req.on('data', (chunk) => {
            responseBody += chunk;
        });
        
        req.on('end', () => {
            client.close();
            
            const statusCode = responseHeaders[':status'];
            console.log('\n📊 Response Status:', statusCode);
            
            if (responseBody) {
                console.log('Response Body:', responseBody);
            }
            
            if (statusCode === 200) {
                console.log('\n✅ SUCCESS! Live Activity update sent successfully!');
                console.log('The Live Activity should now show as paused.');
            } else {
                console.log('\n❌ FAILED! Status:', statusCode);
                
                // Decode specific errors
                if (responseBody.includes('BadDeviceToken')) {
                    console.log('🚨 BadDeviceToken - The push token is invalid or expired');
                } else if (responseBody.includes('InvalidProviderToken')) {
                    console.log('🚨 InvalidProviderToken - JWT authentication failed');
                } else if (statusCode === 410) {
                    console.log('🚨 410 Gone - The push token is no longer valid');
                } else if (responseBody.includes('TopicDisallowed')) {
                    console.log('🚨 TopicDisallowed - The topic is not allowed for this app');
                }
            }
        });
        
        req.on('error', (error) => {
            console.error('❌ Request error:', error);
            client.close();
        });
        
        req.write(payloadString);
        req.end();
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run the test
console.log('🚀 APNs HTTP/2 Test Starting...\n');
testAPNsHttp2();