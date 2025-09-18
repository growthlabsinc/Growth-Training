/**
 * Test both API keys to see which one works
 */

const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const axios = require('axios');

const ISSUER_ID = '87056e63-dddd-4e67-989e-e0e4950b84e5';
const BUNDLE_ID = 'com.growth';

async function testKey(keyId, keyPath) {
  console.log(`\nTesting Key ID: ${keyId}`);
  console.log('=' .repeat(40));
  
  try {
    // Read private key
    const privateKey = fs.readFileSync(keyPath, 'utf8');
    
    // Generate JWT
    const token = jwt.sign({}, privateKey, {
      algorithm: 'ES256',
      expiresIn: '20m',
      issuer: ISSUER_ID,
      header: {
        alg: 'ES256',
        kid: keyId,
        typ: 'JWT'
      }
    });
    
    console.log('✅ JWT generated successfully');
    
    // Test API connection
    const response = await axios.get('https://api.appstoreconnect.apple.com/v1/apps', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      params: {
        'filter[bundleId]': BUNDLE_ID
      }
    });
    
    console.log('✅ API connection successful!');
    console.log(`   Found ${response.data.data.length} app(s)`);
    return true;
    
  } catch (error) {
    console.log('❌ API connection failed');
    if (error.response?.status === 401) {
      console.log('   Error: Authentication failed (401)');
      if (error.response.data?.errors?.[0]?.detail) {
        console.log(`   Detail: ${error.response.data.errors[0].detail}`);
      }
    } else {
      console.log(`   Error: ${error.message}`);
    }
    return false;
  }
}

async function findCorrectIssuerID() {
  console.log('\n🔍 Checking for correct Issuer ID in App Store Connect...');
  console.log('Please verify the Issuer ID from:');
  console.log('App Store Connect > Users and Access > Integrations > App Store Connect API');
  console.log(`\nCurrently configured: ${ISSUER_ID}`);
}

async function main() {
  console.log('🔐 Testing App Store Connect API Keys');
  
  // Test both keys
  const key1Success = await testKey('66LQV834DU', './AuthKey_66LQV834DU.p8');
  const key2Success = await testKey('3G84L8G52R', './AuthKey_3G84L8G52R.p8');
  
  console.log('\n📊 Summary:');
  console.log(`Key 66LQV834DU: ${key1Success ? '✅ Working' : '❌ Failed'}`);
  console.log(`Key 3G84L8G52R: ${key2Success ? '✅ Working' : '❌ Failed'}`);
  
  if (!key1Success && !key2Success) {
    console.log('\n⚠️  Both keys failed. Possible issues:');
    console.log('1. Incorrect Issuer ID (most likely)');
    console.log('2. Keys do not have In-App Purchase permission');
    console.log('3. Keys have been revoked');
    
    await findCorrectIssuerID();
  } else {
    const workingKey = key1Success ? '66LQV834DU' : '3G84L8G52R';
    console.log(`\n✅ Use Key ID: ${workingKey}`);
    console.log('\nUpdate Firebase configuration:');
    console.log(`firebase functions:config:set appstore.key_id="${workingKey}"`);
  }
}

main().catch(console.error);