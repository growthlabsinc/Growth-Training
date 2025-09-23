#!/usr/bin/env node

/**
 * Test Firebase authentication and function call permissions
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./scripts/service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-training-app'
});

async function testAuth() {
  console.log('🔍 Testing Firebase Authentication and Function Access...\n');

  try {
    // Check recent function logs for authentication errors
    console.log('📊 Checking recent function invocations...');

    // List recent users
    const listUsers = await admin.auth().listUsers(5);
    console.log(`👥 Recent users (${listUsers.users.length}):`);

    listUsers.users.forEach((user, index) => {
      console.log(`${index + 1}. UID: ${user.uid}`);
      console.log(`   Email: ${user.email || 'No email'}`);
      console.log(`   Last Sign In: ${user.metadata.lastSignInTime || 'Never'}`);
      console.log(`   Created: ${user.metadata.creationTime}`);
      console.log(`   Disabled: ${user.disabled}`);
      console.log('');
    });

    // Check if any user tokens are still valid
    if (listUsers.users.length > 0) {
      const testUser = listUsers.users[0];
      console.log(`🔑 Testing token for user: ${testUser.uid}`);

      try {
        // Create a custom token for testing
        const customToken = await admin.auth().createCustomToken(testUser.uid);
        console.log(`✅ Custom token created successfully (length: ${customToken.length})`);
      } catch (error) {
        console.error(`❌ Failed to create custom token: ${error.message}`);
      }
    }

    // Test Firestore access
    console.log('📄 Testing Firestore access...');
    const db = admin.firestore();
    const testDoc = await db.collection('test').doc('auth-test').set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      test: 'Firebase admin auth working'
    });
    console.log('✅ Firestore write successful');

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

testAuth().then(() => {
  console.log('✅ Authentication test completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});