const fs = require('fs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config({ path: './config/.env' });

async function testAPI() {
  console.log('🔍 Testing App Store Connect API with detailed debugging\n');
  
  const config = {
    keyId: process.env.APPSTORE_KEY_ID,
    issuerId: process.env.APPSTORE_ISSUER_ID,
    bundleId: process.env.APPSTORE_BUNDLE_ID,
    keyPath: `./keys/AuthKey_${process.env.APPSTORE_KEY_ID}.p8`
  };
  
  console.log('Configuration:');
  console.log(`Key ID: ${config.keyId}`);
  console.log(`Issuer ID: ${config.issuerId}`);
  console.log(`Bundle ID: ${config.bundleId}`);
  console.log(`Key Path: ${config.keyPath}\n`);
  
  try {
    // Read private key
    const privateKey = fs.readFileSync(config.keyPath, 'utf8');
    console.log('✅ Private key loaded\n');
    
    // Generate JWT
    const now = Math.floor(Date.now() / 1000);
    const token = jwt.sign({
      iss: config.issuerId,
      iat: now,
      exp: now + 1200, // 20 minutes
      aud: 'appstoreconnect-v1'
    }, privateKey, {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: config.keyId,
        typ: 'JWT'
      }
    });
    
    console.log('✅ JWT generated');
    console.log(`Token preview: ${token.substring(0, 50)}...`);
    
    // Decode token to verify
    const decoded = jwt.decode(token, { complete: true });
    console.log('\nDecoded JWT header:', decoded.header);
    console.log('Decoded JWT payload:', decoded.payload);
    
    // Test basic API endpoint first
    console.log('\n📡 Testing basic API connection...');
    const testResponse = await axios.get('https://api.appstoreconnect.apple.com/v1/users', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      params: {
        'limit': 1
      }
    });
    
    console.log('✅ Basic API connection successful!');
    console.log(`Users endpoint returned ${testResponse.data.data.length} user(s)\n`);
    
    // Now test apps endpoint
    console.log('📱 Testing apps endpoint...');
    const appsResponse = await axios.get('https://api.appstoreconnect.apple.com/v1/apps', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`✅ Found ${appsResponse.data.data.length} total app(s)`);
    
    // List all apps
    console.log('\nAll apps in this account:');
    appsResponse.data.data.forEach(app => {
      console.log(`- ${app.attributes.name} (${app.attributes.bundleId})`);
    });
    
    // Filter for our bundle ID
    const ourApp = appsResponse.data.data.find(app => 
      app.attributes.bundleId === config.bundleId
    );
    
    if (ourApp) {
      console.log(`\n✅ Found our app: ${ourApp.attributes.name}`);
      console.log(`   App ID: ${ourApp.id}`);
      console.log(`   SKU: ${ourApp.attributes.sku}`);
    } else {
      console.log(`\n⚠️  No app found with bundle ID: ${config.bundleId}`);
      console.log('   Please verify the bundle ID is correct');
    }
    
  } catch (error) {
    console.log('\n❌ Error:', error.message);
    if (error.response) {
      console.log(`Status: ${error.response.status}`);
      console.log('Response:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

testAPI();