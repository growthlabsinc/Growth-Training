/**
 * Test script for checkUsernameAvailability function
 * Run with: node test-username-check.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function testUsernameCheck(username) {
  console.log(`\n🔍 Testing username: "${username}"`);
  console.log('-----------------------------------');

  try {
    const lowercaseUsername = username.trim().toLowerCase();

    // Step 1: Format validation
    if (lowercaseUsername.length < 3 || lowercaseUsername.length > 20) {
      console.log('❌ FAIL: Username must be 3-20 characters');
      console.log(`   Length: ${lowercaseUsername.length}`);
      return;
    }

    const validFormat = /^[a-z0-9_]+$/.test(lowercaseUsername);
    if (!validFormat) {
      console.log('❌ FAIL: Username contains invalid characters');
      console.log('   Only lowercase letters, numbers, and underscores allowed');
      return;
    }

    console.log('✅ Format validation passed');

    // Step 2: Check users collection
    console.log('\n📊 Checking users collection...');
    const usersSnapshot = await db.collection('users')
      .where('username', '==', lowercaseUsername)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      console.log('❌ Username is already taken (found in users collection)');
      const existingUser = usersSnapshot.docs[0].data();
      console.log(`   Used by: ${existingUser.email || 'unknown'}`);
      return;
    }
    console.log('✅ Not found in users collection');

    // Step 3: Check usernames collection
    console.log('\n📊 Checking usernames collection...');
    const usernamesDoc = await db.collection('usernames').doc(lowercaseUsername).get();

    if (usernamesDoc.exists) {
      const data = usernamesDoc.data();
      if (data.reserved || data.blocked) {
        console.log('❌ Username is reserved or blocked');
        console.log(`   Reason: ${data.reason || 'N/A'}`);
        return;
      }
      console.log('⚠️  Username document exists but not marked as reserved/blocked');
    } else {
      console.log('✅ Not found in usernames collection');
    }

    // Final result
    console.log('\n✅ SUCCESS: Username is available!');

  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    console.error('Error details:', error);
  }
}

async function main() {
  console.log('🧪 Testing Username Availability Function');
  console.log('=========================================\n');

  // Test cases
  const testCases = [
    'testuser123',    // Should be available
    'admin',          // Might be reserved
    'test_user',      // Should be available
    'ab',             // Too short
    'this_is_way_too_long_username', // Too long
    'test@user',      // Invalid characters
  ];

  for (const username of testCases) {
    await testUsernameCheck(username);
  }

  console.log('\n=========================================');
  console.log('✅ All tests complete!\n');
}

// Run tests
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
