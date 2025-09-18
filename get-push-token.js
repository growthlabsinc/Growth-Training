const admin = require('firebase-admin');
const serviceAccount = require('./functions/growth-70a85-firebase-adminsdk-1uzmo-ce0b3f36f2.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://growth-70a85.firebaseio.com'
});

const db = admin.firestore();

async function getPushToken() {
  try {
    const activityId = '55D2E17F-D280-474F-8DFB-C55611A10120';
    console.log('Fetching token for activity:', activityId);
    
    const doc = await db.collection('liveActivityTokens').doc(activityId).get();
    
    if (!doc.exists) {
      console.log('No token found for this activity');
      
      // Try to get any recent token
      const snapshot = await db.collection('liveActivityTokens')
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();
      
      if (!snapshot.empty) {
        const latestDoc = snapshot.docs[0];
        const data = latestDoc.data();
        console.log('\nFound most recent token:');
        console.log('Activity ID:', latestDoc.id);
        console.log('Push Token:', data.pushToken);
        console.log('Environment:', data.environment);
        console.log('Bundle ID:', data.bundleId);
      } else {
        console.log('No Live Activity tokens found at all');
      }
    } else {
      const data = doc.data();
      console.log('\nFound token data:');
      console.log('Push Token:', data.pushToken);
      console.log('Activity ID:', data.activityId);
      console.log('User ID:', data.userId);
      console.log('Bundle ID:', data.bundleId);
      console.log('Environment:', data.environment);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

getPushToken();