const https = require('https');

// New push token from user
const pushToken = '80f39278755ba830562586791782c4b89b763d3d0f5e3585b17f3ebfccc0723661d89b955662a38958ce82866432764c7a23e8e5e2eed9f6d033e60cfdeef6d089ed7c399a0b2eec5ac47b7117936b98';
const activityId = 'NEW-TEST-' + Date.now();

// Firebase function URL (callable function format)
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

console.log('Calling collectAPNsDiagnostics with new token...');
console.log('Activity ID:', activityId);
console.log('Push Token:', pushToken.substring(0, 20) + '...');

const req = https.request(functionUrl, options, (res) => {
  console.log(`Status Code: ${res.statusCode}`);
  
  let responseData = '';
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', responseData);
    try {
      const parsed = JSON.parse(responseData);
      if (parsed.result && parsed.result.diagnostics) {
        console.log('\n=== DIAGNOSTIC RESULTS ===');
        console.log('Status Code:', parsed.result.diagnostics.statusCode);
        console.log('APNs Response:', parsed.result.diagnostics.responseBody);
        console.log('Request Duration:', parsed.result.diagnostics.requestDuration);
        console.log('APNs Topic:', parsed.result.diagnostics.requestHeaders['apns-topic']);
        console.log('Key ID:', parsed.result.diagnostics.keyId);
        console.log('Team ID:', parsed.result.diagnostics.teamId);
        if (parsed.result.diagnostics.errorInterpretation) {
          console.log('\nError Interpretation:', parsed.result.diagnostics.errorInterpretation);
        }
        console.log('========================\n');
      }
    } catch (e) {
      // Response already logged
    }
    console.log('\nCheck full logs with:');
    console.log('firebase functions:log --only collectAPNsDiagnostics --lines 200');
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(data);
req.end();