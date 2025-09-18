const jwt = require('jsonwebtoken');
const https = require('https');

// Test JWT generation with the actual APNs key
async function testAPNsJWT() {
    // These values are from the .env file
    const keyId = '55LZB28UY2';
    const teamId = '62T6J77P6R';
    
    // Read the actual auth key from environment or file
    // In production, this comes from Firebase secrets
    const authKey = process.env.APNS_AUTH_KEY || `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgSbO7m5EqdlUkkXBX
qBgDqwz8H9UkPJb6LaE6lTFUahCgCgYIKoZIzj0DAQehRANCAASDyoEYVrzeUAnU
Z5Tv/4a/4poNKQ77/QvdVqY9dfuLcRi3hOL9Y3tVjMWQULDjPKN/ZUk6zavtzuy0
VZJUFzi+
-----END PRIVATE KEY-----`;

    try {
        console.log('Testing APNs JWT generation...');
        console.log('Key ID:', keyId);
        console.log('Team ID:', teamId);
        console.log('Auth Key length:', authKey.length);
        
        const token = jwt.sign({}, authKey, {
            algorithm: 'ES256',
            header: {
                alg: 'ES256',
                kid: keyId
            },
            issuer: teamId,
            expiresIn: '1h'
        });
        
        console.log('\n✅ JWT generated successfully!');
        console.log('Token length:', token.length);
        console.log('Token preview:', token.substring(0, 50) + '...');
        
        // Decode the token to verify structure
        const decoded = jwt.decode(token, { complete: true });
        console.log('\nDecoded header:', decoded.header);
        console.log('Decoded payload:', decoded.payload);
        
        return token;
    } catch (error) {
        console.error('❌ Error generating JWT:', error);
        throw error;
    }
}

// Test APNs connection
async function testAPNsConnection(token, pushToken) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.development.push.apple.com',
            port: 443,
            path: `/3/device/${pushToken}`,
            method: 'POST',
            headers: {
                'authorization': `bearer ${token}`,
                'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
                'apns-push-type': 'liveactivity',
                'apns-priority': '10',
                'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
                'content-type': 'application/json'
            }
        };
        
        const testPayload = {
            aps: {
                timestamp: Math.floor(Date.now() / 1000),
                event: 'update',
                'content-state': {
                    startedAt: new Date().toISOString(),
                    pausedAt: new Date().toISOString(),
                    duration: 300,
                    methodName: 'Test Method',
                    sessionType: 'countdown'
                },
                alert: {
                    title: 'Test Update',
                    body: 'Testing APNs connection'
                }
            }
        };
        
        console.log('\nTesting APNs connection...');
        console.log('Host:', options.hostname);
        console.log('Path:', options.path);
        console.log('Topic:', options.headers['apns-topic']);
        
        const req = https.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                console.log('\nAPNs Response:');
                console.log('Status:', res.statusCode);
                console.log('Headers:', res.headers);
                console.log('Body:', data);
                
                if (res.statusCode === 200) {
                    console.log('✅ APNs connection successful!');
                    resolve({ success: true, response: data });
                } else {
                    console.log('❌ APNs returned error');
                    resolve({ success: false, statusCode: res.statusCode, response: data });
                }
            });
        });
        
        req.on('error', (error) => {
            console.error('❌ Connection error:', error);
            reject(error);
        });
        
        req.write(JSON.stringify(testPayload));
        req.end();
    });
}

// Main test function
async function runTests() {
    try {
        // Test JWT generation
        const token = await testAPNsJWT();
        
        // Test with a dummy token (will fail but shows connection works)
        const dummyToken = 'dummy_push_token_for_testing';
        console.log('\n\nTesting APNs connection with dummy token...');
        await testAPNsConnection(token, dummyToken);
        
    } catch (error) {
        console.error('\n\nTest failed:', error);
    }
}

// Run the tests
runTests();