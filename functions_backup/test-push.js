const https = require('https');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

async function testPushUpdate() {
  const db = admin.firestore();
  
  // Get a recent activity ID from Firestore
  const tokenSnapshot = await db.collection('liveActivityTokens').limit(1).get();
  
  if (tokenSnapshot.empty) {
    console.log('No live activity tokens found');
    return;
  }
  
  const doc = tokenSnapshot.docs[0];
  const activityId = doc.id;
  const data = doc.data();
  
  console.log('Testing with activity:', activityId);
  console.log('User ID:', data.userId);
  
  // Call the function
  const functionUrl = 'https://us-central1-growth-70a85.cloudfunctions.net/manageLiveActivityUpdates';
  
  const postData = JSON.stringify({
    data: {
      activityId: activityId,
      userId: data.userId,
      action: 'startPushUpdates'
    }
  });
  
  const options = {
    hostname: 'us-central1-growth-70a85.cloudfunctions.net',
    path: '/manageLiveActivityUpdates',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  const req = https.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
    
    res.setEncoding('utf8');
    let body = '';
    
    res.on('data', (chunk) => {
      body += chunk;
    });
    
    res.on('end', () => {
      console.log('Response body:', body);
    });
  });
  
  req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
  });
  
  req.write(postData);
  req.end();
}

testPushUpdate().catch(console.error);