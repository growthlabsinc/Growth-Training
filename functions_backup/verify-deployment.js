const https = require('https');

console.log('Checking deployed function status...\n');

// Test data that will trigger the function
const testData = JSON.stringify({
  data: {
    activityId: 'test-' + Date.now(),
    userId: 'test-user',
    action: 'startPushUpdates'
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
  console.log(`Function Response Status: ${res.statusCode}`);
  
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  
  res.on('end', () => {
    console.log('Response Body:', body);
    
    // Parse the response
    try {
      const response = JSON.parse(body);
      
      if (response.error) {
        console.log('\n❌ Function returned an error:', response.error.message);
        
        // Check if it's the authentication error (expected)
        if (response.error.status === 'UNAUTHENTICATED') {
          console.log('✅ This is expected - function requires authentication');
          console.log('✅ Function is deployed and responding correctly');
        } else if (response.error.status === 'INTERNAL') {
          console.log('⚠️  Internal error - check function logs for details');
        }
      }
    } catch (e) {
      console.log('Could not parse response as JSON');
    }
    
    console.log('\n📋 Next Steps:');
    console.log('1. Check function logs: firebase functions:log --only manageLiveActivityUpdates');
    console.log('2. Look for "Parse Error: Expected HTTP/" - if present, old code is still deployed');
    console.log('3. Look for "Successfully sent push update" - if present, new code is working');
  });
});

req.on('error', (e) => {
  console.error(`❌ Error calling function: ${e.message}`);
});

req.write(testData);
req.end();