const admin = require('firebase-admin');
const https = require('https');

// Initialize admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

async function runDiagnostic() {
  try {
    const db = admin.firestore();
    
    // Get the most recent Live Activity token
    const activityId = '55D2E17F-D280-474F-8DFB-C55611A10120';
    console.log(`Fetching token for activity: ${activityId}`);
    
    const doc = await db.collection('liveActivityTokens').doc(activityId).get();
    
    if (!doc.exists) {
      console.error('No token found for this activity');
      return;
    }
    
    const data = doc.data();
    console.log('Found token data:');
    console.log('- Push Token:', data.pushToken);
    console.log('- Activity ID:', data.activityId);
    console.log('- User ID:', data.userId);
    console.log('- Bundle ID:', data.bundleId);
    console.log('- Environment:', data.environment);
    
    // Call the diagnostic function via HTTP
    const functionUrl = 'https://collectapnsdiagnostics-i7nqvdntua-uc.a.run.app';
    
    // Get an auth token
    const auth = admin.auth();
    const customToken = await auth.createCustomToken(data.userId);
    
    console.log('\nCalling diagnostic function...');
    
    const requestData = {
      data: {
        pushToken: data.pushToken,
        activityId: data.activityId
      }
    };
    
    // Make the request
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customToken}`
      }
    };
    
    const req = https.request(functionUrl, options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        console.log('\nDiagnostic Response:');
        try {
          const result = JSON.parse(responseData);
          console.log(JSON.stringify(result, null, 2));
        } catch (e) {
          console.log(responseData);
        }
      });
    });
    
    req.on('error', (error) => {
      console.error('Request error:', error);
    });
    
    req.write(JSON.stringify(requestData));
    req.end();
    
  } catch (error) {
    console.error('Error:', error);
  }
}

// Run the diagnostic
runDiagnostic();