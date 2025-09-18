const https = require('https');

// Production push token just received
const pushToken = '80f90507f183d907049c5f94f9c00c59663ca7881889adc2d378aa9d00e0fefd3ebdb851e4c535b64d8269de749af0da639b064be428b4d7809b9d5ace3ddc48db4670376f54b45cd85f061f24b43a1f';
const activityId = 'PROD-TEST-' + Date.now();

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

console.log('🚀 Testing with production push token...');
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
        console.log('📱 Environment:', diag.statusCode === 200 ? 'Production' : 'Check response');
        console.log('🔑 Key ID:', diag.keyId);
        console.log('👥 Team ID:', diag.teamId);
        console.log('📦 Bundle ID:', diag.bundleId);
        console.log('⏱️ Request Duration:', diag.requestDuration);
        console.log('📨 APNs Response:', diag.responseBody || 'Success');
        
        if (diag.statusCode === 200) {
          console.log('\n✅ SUCCESS! Live Activities are now working!');
          console.log('🎉 Your timer updates should work properly now.');
        } else {
          console.log('\n❌ Error:', diag.errorInterpretation || diag.responseBody);
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