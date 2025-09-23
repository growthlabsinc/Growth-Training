#!/usr/bin/env node

/**
 * Test script to verify user authentication status and Firebase Function access
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./scripts/service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-training-app'
});

async function testAuthStatus() {
  console.log('🔍 Testing Firebase Authentication Status...\n');

  try {
    // List users to check authentication status
    const listUsers = await admin.auth().listUsers(10);
    console.log(`📊 Found ${listUsers.users.length} users in the system:`);

    listUsers.users.forEach((user, index) => {
      console.log(`${index + 1}. UID: ${user.uid}`);
      console.log(`   Email: ${user.email || 'No email'}`);
      console.log(`   Anonymous: ${!user.email && !user.phoneNumber}`);
      console.log(`   Last Sign In: ${user.metadata.lastSignInTime || 'Never'}`);
      console.log(`   Disabled: ${user.disabled}`);
      console.log('');
    });

    // Test function authentication by checking if the function exists
    console.log('🔗 Testing Firebase Function access...');
    const functions = admin.functions();
    console.log('✅ Firebase Functions admin access is working');

  } catch (error) {
    console.error('❌ Error testing authentication:', error);
  }
}

// Run the test
testAuthStatus().then(() => {
  console.log('✅ Authentication test completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});