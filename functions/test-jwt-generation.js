const jwt = require('jsonwebtoken');
const fs = require('fs');

// Load the development APNs key
const apnsKeyPath = '/Users/tradeflowj/Downloads/AuthKey_378FZMBP8L.p8';
const apnsKey = fs.readFileSync(apnsKeyPath, 'utf8');

// Configuration with development key
const config = {
  apnsKeyId: '378FZMBP8L',
  apnsTeamId: '62T6J77P6R'
};

// Generate JWT token
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
  
  console.log('✅ JWT token generated successfully with DEVELOPMENT key');
  console.log('Key ID:', config.apnsKeyId);
  console.log('Team ID:', config.apnsTeamId);
  console.log('Token (first 50 chars):', token.substring(0, 50) + '...');
  console.log('Full token length:', token.length);
  
  // Decode the token to verify its contents
  const decoded = jwt.decode(token, { complete: true });
  console.log('\nDecoded header:', JSON.stringify(decoded.header, null, 2));
  console.log('Decoded payload:', JSON.stringify(decoded.payload, null, 2));
  
  console.log('\n⚠️  IMPORTANT: This is a DEVELOPMENT key');
  console.log('Make sure your app is built with development provisioning profile');
  
} catch (error) {
  console.error('❌ Failed to generate JWT token:', error.message);
  console.error('Error details:', error);
}