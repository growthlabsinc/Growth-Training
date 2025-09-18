const https = require('https');

// Development push token just received
const pushToken = '806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600';
const activityId = 'DEV-TEST-' + Date.now();

// Firebase function URL
const functionUrl = 'https://collectapnsdiagnostics-7lb4hvy3wa-uc.a.run.app';

const data = JSON.stringify({
  data: {
    pushToken: pushToken,
    activityId: activityId
  }
});

const options = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

console.log('🚀 Testing with development push token...');
console.log('Activity ID:', activityId);
console.log('Push Token:', pushToken.substring(0, 20) + '...');
console.log('');

const req = https.request(functionUrl, options, (res) => {
  console.log(`HTTP Status: ${res.statusCode}`);
  
  let responseData = '';
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    try {
      const parsed = JSON.parse(responseData);
      if (parsed.result && parsed.result.diagnostics) {
        const diag = parsed.result.diagnostics;
        console.log('\n=== DIAGNOSTIC RESULTS ===');
        console.log('✅ APNs Status:', diag.statusCode);
        console.log('🔑 Key ID:', diag.keyId);
        console.log('👥 Team ID:', diag.teamId);
        console.log('📦 Bundle ID:', diag.bundleId);
        console.log('🌐 APNs Server:', diag.apnsServerIP || 'Development');
        console.log('⏱️ Request Duration:', diag.requestDuration);
        
        if (diag.statusCode === 200) {
          console.log('\n✅ SUCCESS! Development environment is working correctly!');
          console.log('🎉 Your Live Activity updates should work now.');
        } else if (diag.statusCode === 400 && diag.responseBody.includes('BadDeviceToken')) {
          console.log('\n⚠️  BadDeviceToken - This might mean:');
          console.log('   - Token/server mismatch (should not happen now)');
          console.log('   - Token is expired or invalid');
        } else {
          console.log('\n❌ Error:', diag.responseBody || diag.errorInterpretation);
        }
        console.log('==========================\n');
      }
    } catch (e) {
      console.log('Full response:', responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(data);
req.end();