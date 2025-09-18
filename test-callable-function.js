const https = require('https');

// Development push token
const pushToken = '806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600';
const activityId = 'DEV-TEST-' + Date.now();

// Prepare the callable function request
const requestData = {
  data: {
    pushToken: pushToken,
    activityId: activityId
  }
};

const options = {
  hostname: 'us-central1-growth-70a85.cloudfunctions.net',
  path: '/collectAPNsDiagnostics',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(JSON.stringify(requestData))
  }
};

console.log('🚀 Testing callable function...');
console.log('Activity ID:', activityId);
console.log('Push Token:', pushToken.substring(0, 20) + '...');
console.log('');

const req = https.request(options, (res) => {
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
        console.log('📄 Response:', diag.responseBody);
        
        if (diag.statusCode === 200) {
          console.log('\n✅ SUCCESS! Development environment is working correctly!');
          console.log('🎉 Your Live Activity updates should work now.');
        } else if (diag.statusCode === 400 && diag.responseBody && diag.responseBody.includes('BadDeviceToken')) {
          console.log('\n⚠️  BadDeviceToken - This might mean:');
          console.log('   - Token/server mismatch');
          console.log('   - Token is expired or invalid');
        } else if (diag.statusCode === 403) {
          console.log('\n❌ InvalidProviderToken - Authentication issue');
          console.log('   Error interpretation:', diag.errorInterpretation);
        } else {
          console.log('\n❌ Error:', diag.responseBody || diag.errorInterpretation);
        }
        console.log('==========================\n');
      } else {
        console.log('Full response:', responseData);
      }
    } catch (e) {
      console.log('Failed to parse response:', e.message);
      console.log('Raw response:', responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(JSON.stringify(requestData));
req.end();