#!/usr/bin/env node
/**
 * Test APNs connection and JWT generation
 */

const http2 = require('http2');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// Load the APNs key
const keyPath = '/Users/tradeflowj/Downloads/AuthKey_66LQV834DU.p8';
const apnsKey = fs.readFileSync(keyPath, 'utf8');

// APNs configuration
const KEY_ID = '66LQV834DU';
const TEAM_ID = '62T6J77P6R';
const BUNDLE_ID = 'com.growthlabs.growthmethod';
const TOPIC = `${BUNDLE_ID}.GrowthTimerWidget.push-type.liveactivity`;

console.log('🔧 APNs Configuration:');
console.log('  - Key ID:', KEY_ID);
console.log('  - Team ID:', TEAM_ID);
console.log('  - Bundle ID:', BUNDLE_ID);
console.log('  - Topic:', TOPIC);

// Generate JWT token
function generateAPNsToken() {
    try {
        const token = jwt.sign(
            {
                iss: TEAM_ID,
                iat: Math.floor(Date.now() / 1000)
            },
            apnsKey,
            {
                algorithm: 'ES256',
                header: {
                    alg: 'ES256',
                    kid: KEY_ID
                }
            }
        );
        
        console.log('\n✅ Successfully generated JWT token');
        console.log('Token (first 50 chars):', token.substring(0, 50) + '...');
        return token;
    } catch (error) {
        console.error('\n❌ Failed to generate JWT token:', error.message);
        console.error('Error details:', error);
        return null;
    }
}

// Test connection to APNs
async function testAPNsConnection() {
    const token = generateAPNsToken();
    if (!token) {
        console.error('Cannot test connection without valid token');
        return;
    }
    
    console.log('\n🔄 Testing connection to APNs production server...');
    
    // Test production endpoint
    const client = http2.connect('https://api.push.apple.com:443');
    
    client.on('error', (err) => {
        console.error('❌ HTTP/2 client error:', err);
    });
    
    client.on('connect', () => {
        console.log('✅ Successfully connected to APNs production server');
        client.close();
    });
    
    // Also test dev endpoint
    console.log('\n🔄 Testing connection to APNs development server...');
    const devClient = http2.connect('https://api.development.push.apple.com:443');
    
    devClient.on('error', (err) => {
        console.error('❌ HTTP/2 dev client error:', err);
    });
    
    devClient.on('connect', () => {
        console.log('✅ Successfully connected to APNs development server');
        devClient.close();
    });
}

// Run tests
console.log('🚀 Starting APNs connection test...\n');
testAPNsConnection();