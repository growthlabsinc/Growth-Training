#!/usr/bin/env node

/**
 * Script to validate APNs JWT token structure and diagnose InvalidProviderToken issues
 */

const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '../functions/.env') });

console.log('🔍 APNs JWT Token Validation Script\n');

// Configuration from environment
const config = {
  apnsKeyId: process.env.APNS_KEY_ID,
  apnsTeamId: process.env.APNS_TEAM_ID,
  apnsTopic: process.env.APNS_TOPIC,
  apnsKey: process.env.APNS_AUTH_KEY
};

console.log('📋 Current Configuration:');
console.log(`- Key ID: ${config.apnsKeyId}`);
console.log(`- Team ID: ${config.apnsTeamId}`);
console.log(`- Topic: ${config.apnsTopic}`);
console.log(`- Key present: ${!!config.apnsKey}`);
console.log('');

// Validate configuration
if (!config.apnsKey || !config.apnsKeyId || !config.apnsTeamId) {
  console.error('❌ Missing required configuration. Check your .env file.');
  process.exit(1);
}

// Clean up the auth key if needed
if (config.apnsKey.startsWith('"') && config.apnsKey.endsWith('"')) {
  config.apnsKey = config.apnsKey.slice(1, -1);
}

// Generate JWT token
try {
  const token = jwt.sign(
    {
      iss: config.apnsTeamId,
      iat: Math.floor(Date.now() / 1000)
    },
    config.apnsKey,
    {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: config.apnsKeyId
      }
    }
  );
  
  console.log('✅ JWT token generated successfully');
  console.log(`Token (first 50 chars): ${token.substring(0, 50)}...`);
  console.log('');
  
  // Decode and validate token structure
  const decoded = jwt.decode(token, { complete: true });
  
  console.log('🔐 Token Structure:');
  console.log('Header:', JSON.stringify(decoded.header, null, 2));
  console.log('Payload:', JSON.stringify(decoded.payload, null, 2));
  console.log('');
  
  // Validate token components
  console.log('✔️ Validation Checks:');
  
  // Check algorithm
  if (decoded.header.alg === 'ES256') {
    console.log('✅ Algorithm: ES256 (correct)');
  } else {
    console.log(`❌ Algorithm: ${decoded.header.alg} (should be ES256)`);
  }
  
  // Check kid
  if (decoded.header.kid === config.apnsKeyId) {
    console.log(`✅ Key ID (kid): ${decoded.header.kid} (matches configuration)`);
  } else {
    console.log(`❌ Key ID (kid): ${decoded.header.kid} (expected ${config.apnsKeyId})`);
  }
  
  // Check issuer
  if (decoded.payload.iss === config.apnsTeamId) {
    console.log(`✅ Issuer (iss): ${decoded.payload.iss} (matches Team ID)`);
  } else {
    console.log(`❌ Issuer (iss): ${decoded.payload.iss} (expected ${config.apnsTeamId})`);
  }
  
  // Check timestamp
  const issuedAt = decoded.payload.iat;
  const now = Math.floor(Date.now() / 1000);
  const age = now - issuedAt;
  
  if (age < 3600) {
    console.log(`✅ Issued at (iat): ${new Date(issuedAt * 1000).toISOString()} (${age}s ago)`);
  } else {
    console.log(`❌ Issued at (iat): ${new Date(issuedAt * 1000).toISOString()} (${age}s ago - too old!)`);
  }
  
  // Check for invalid characters in token
  const invalidChars = ['+', '=', '-'].filter(char => token.includes(char));
  if (invalidChars.length === 0) {
    console.log('✅ Token encoding: No invalid characters found');
  } else {
    console.log(`❌ Token encoding: Contains invalid characters: ${invalidChars.join(', ')}`);
  }
  
  console.log('');
  console.log('📝 Summary:');
  console.log('- Current Key ID: 378FZMBP8L (Development Key)');
  console.log('- Expected endpoint: api.development.push.apple.com');
  console.log('- Bundle ID: com.growthlabs.growthmethod');
  console.log('- Live Activity topic: com.growthlabs.growthmethod.push-type.liveactivity');
  
} catch (error) {
  console.error('❌ Failed to generate JWT token:', error.message);
  console.error('Stack trace:', error.stack);
  
  // Additional debugging for common issues
  if (error.message.includes('secretOrPrivateKey')) {
    console.error('\n⚠️  Key format issue detected. Make sure the private key:');
    console.error('- Includes -----BEGIN PRIVATE KEY----- and -----END PRIVATE KEY-----');
    console.error('- Has no extra whitespace or line breaks');
    console.error('- Is in valid PEM format');
  }
}

console.log('\n🔍 Next Steps:');
console.log('1. Verify in Apple Developer Portal that key 378FZMBP8L:');
console.log('   - Is active (not revoked)');
console.log('   - Has APNs service enabled');
console.log('   - Is associated with Team ID 62T6J77P6R');
console.log('2. Check that your app is built with development provisioning profile');
console.log('3. Ensure aps-environment entitlement is set to "development"');