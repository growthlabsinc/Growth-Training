const https = require('https');

// Data from your timer
const pushToken = '801003ba001eb0f19f11bce3b057d0d69dc1c959c7eeb16a3156008452e4d781cac311e2c279c4dae7b05fb921a9bd5cd2b6f6c959d1e1b459159070e7dab6762c18fc75c05405d21551c1666ca2a29b';
const activityId = '9FFAEB73-FEFC-4CB7-BE64-F57BCB9D9477';

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

console.log('Calling collectAPNsDiagnostics...');
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
    if (res.statusCode === 200) {
      console.log('\nDiagnostic sent successfully!');
      console.log('Check Firebase logs with:');
      console.log('firebase functions:log --only collectAPNsDiagnostics --lines 200');
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(data);
req.end();