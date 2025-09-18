const axios = require('axios');

async function testAPNsConnection() {
  try {
    console.log('Testing APNs connection...');
    
    // Get the Firebase ID token
    const idToken = process.env.FIREBASE_TEST_TOKEN || '';
    
    const response = await axios.post(
      'https://us-central1-growth-70a85.cloudfunctions.net/testAPNsConnection',
      {},
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken ? `Bearer ${idToken}` : undefined
        }
      }
    );
    
    console.log('Response:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testAPNsConnection();