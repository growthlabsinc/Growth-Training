const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const http2 = require('http2');
const jwt = require('jsonwebtoken');
const dns = require('dns');
const { promisify } = require('util');
const https = require('https');

const lookup = promisify(dns.lookup);

// Define the secrets - Force update to use latest secret versions
const apnsAuthKeySecret = defineSecret('APNS_AUTH_KEY');
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');

exports.collectAPNsDiagnostics = onCall(
  { 
    region: 'us-central1',
    secrets: [apnsAuthKeySecret, apnsKeyIdSecret, apnsTeamIdSecret],
    consumeAppCheckToken: false
  },
  async (request) => {
    const diagnostics = {
      timestamp: new Date().toISOString(),
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      bundleId: 'com.growthlabs.growthmethod',
      keyId: process.env.APNS_KEY_ID?.trim(),
      teamId: process.env.APNS_TEAM_ID?.trim(),
      secretVersions: {
        authKey: process.env.GOOGLE_CLOUD_PROJECT ? 'latest' : 'local',
        keyId: process.env.APNS_KEY_ID ? 'loaded' : 'missing'
      }
    };
    
    try {
      // Get server IP
      try {
        const serverInfo = await lookup('api.push.apple.com');
        diagnostics.apnsServerIP = serverInfo.address;
      } catch (e) {
        diagnostics.apnsServerIP = 'DNS lookup failed: ' + e.message;
      }
      
      // Get our public IP (Firebase Functions)
      try {
        const ipData = await new Promise((resolve, reject) => {
          https.get('https://api.ipify.org?format=json', (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
              try {
                resolve(JSON.parse(data));
              } catch (e) {
                reject(e);
              }
            });
          }).on('error', reject);
        });
        diagnostics.ourPublicIP = ipData.ip;
      } catch (e) {
        diagnostics.ourPublicIP = 'Could not determine public IP';
      }
      
      // Validate auth key
      const authKey = process.env.APNS_AUTH_KEY;
      if (!authKey) {
        throw new Error('APNS_AUTH_KEY not found in environment');
      }
      
      // Clean up the auth key if needed
      let cleanedKey = authKey;
      if (cleanedKey.startsWith('"') && cleanedKey.endsWith('"')) {
        cleanedKey = cleanedKey.slice(1, -1);
      }
      
      // Generate JWT
      const token = jwt.sign(
        {
          iss: process.env.APNS_TEAM_ID?.trim(),
          iat: Math.floor(Date.now() / 1000)
        },
        cleanedKey,
        {
          algorithm: 'ES256',
          header: {
            alg: 'ES256',
            kid: process.env.APNS_KEY_ID?.trim()
          }
        }
      );
      
      diagnostics.jwtToken = token.substring(0, 50) + '...';
      diagnostics.jwtTokenLength = token.length;
      
      // Test push token from request
      const { pushToken, activityId } = request.data;
      
      if (!pushToken) {
        throw new Error('Push token is required');
      }
      
      diagnostics.pushToken = pushToken;
      diagnostics.activityId = activityId || 'test-diagnostic';
      
      // Prepare test payload
      const payload = {
        aps: {
          timestamp: Math.floor(Date.now() / 1000),
          event: 'update',
          'content-state': {
            startTime: new Date().toISOString(),
            endTime: new Date(Date.now() + 3600000).toISOString(),
            methodName: 'Diagnostic Test',
            sessionType: 'countdown',
            isPaused: false
          },
          alert: {
            title: 'Diagnostic Test',
            body: 'Testing Live Activity Update'
          }
        }
      };
      
      diagnostics.payload = payload;
      diagnostics.payloadSize = JSON.stringify(payload).length;
      
      // Capture full HTTP/2 exchange
      // Use development server since we have a development/sandbox key
      const client = http2.connect('https://api.development.push.apple.com:443');
      
      const headers = {
        ':method': 'POST',
        ':path': `/3/device/${pushToken}`,
        'authorization': `bearer ${token}`,
        'apns-topic': 'com.growthlabs.growthmethod',
        'apns-push-type': 'liveactivity',
        'apns-priority': '10',
        'apns-expiration': String(Math.floor(Date.now() / 1000) + 3600),
        'content-type': 'application/json',
        'content-length': String(Buffer.byteLength(JSON.stringify(payload)))
      };
      
      diagnostics.requestHeaders = headers;
      
      return new Promise((resolve) => {
        const startTime = Date.now();
        const req = client.request(headers);
        
        let responseHeaders = {};
        let responseBody = '';
        
        req.on('response', (headers) => {
          responseHeaders = headers;
          diagnostics.responseHeaders = headers;
        });
        
        req.on('data', (chunk) => {
          responseBody += chunk;
        });
        
        req.on('end', () => {
          const endTime = Date.now();
          diagnostics.requestDuration = endTime - startTime + 'ms';
          
          client.close();
          
          diagnostics.responseBody = responseBody;
          diagnostics.statusCode = responseHeaders[':status'];
          
          // Add specific error interpretation
          if (diagnostics.statusCode === 403 && responseBody.includes('InvalidProviderToken')) {
            diagnostics.errorInterpretation = 'APNs rejected the authentication token. This typically means: ' +
              '1) The key is not valid for this app, ' +
              '2) The Team ID is incorrect, ' +
              '3) The key has been revoked, or ' +
              '4) The key does not have APNs permission enabled.';
          }
          
          // Log everything
          console.log('=== APNs DIAGNOSTIC DATA ===');
          console.log(JSON.stringify(diagnostics, null, 2));
          console.log('=== END DIAGNOSTIC DATA ===');
          
          resolve({
            success: diagnostics.statusCode === 200,
            diagnostics
          });
        });
        
        req.on('error', (error) => {
          diagnostics.error = error.message;
          diagnostics.errorCode = error.code;
          client.close();
          resolve({
            success: false,
            diagnostics
          });
        });
        
        req.write(JSON.stringify(payload));
        req.end();
      });
      
    } catch (error) {
      diagnostics.error = error.message;
      diagnostics.errorStack = error.stack;
      return {
        success: false,
        diagnostics
      };
    }
  }
);