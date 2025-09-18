const https = require('https');

// Check if the function is responding
const functionUrl = 'https://us-central1-growth-70a85.cloudfunctions.net/manageLiveActivityUpdates';

const testData = JSON.stringify({
  data: {
    activityId: 'test-activity',
    userId: 'test-user',
    action: 'test'
  }
});

const options = {
  hostname: 'us-central1-growth-70a85.cloudfunctions.net',
  path: '/manageLiveActivityUpdates',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(testData)
  }
};

const req = https.request(options, (res) => {
  console.log(`Function status: ${res.statusCode}`);
  
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', body);
    
    // If we get a response (even an error), the function is deployed
    if (res.statusCode === 403 || res.statusCode === 401) {
      console.log('✅ Function is deployed and responding (authentication required)');
    } else if (res.statusCode === 400) {
      console.log('✅ Function is deployed and responding (invalid request)');
    } else if (res.statusCode === 500) {
      console.log('⚠️  Function is deployed but has internal errors');
    }
  });
});

req.on('error', (e) => {
  console.error(`❌ Function not accessible: ${e.message}`);
});

req.write(testData);
req.end();