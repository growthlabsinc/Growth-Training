const admin = require('firebase-admin');

// Initialize without service account key - uses Application Default Credentials
admin.initializeApp({
  projectId: 'growth-training-app'
});

console.log('🚀 Testing Firebase Admin SDK with Application Default Credentials...\n');

// Test Firestore access
async function testFirestore() {
  try {
    const db = admin.firestore();

    // Try to read from a collection
    console.log('📖 Testing Firestore read access...');
    const snapshot = await db.collection('app_config').limit(1).get();
    console.log('✅ Firestore read successful! Documents found:', snapshot.size);

    // Try to write to a test collection
    console.log('\n✏️ Testing Firestore write access...');
    const testDoc = await db.collection('test_auth').add({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      message: 'Auth test successful',
      testedBy: 'Application Default Credentials',
      testedAt: new Date().toISOString()
    });
    console.log('✅ Firestore write successful! Document ID:', testDoc.id);

    // Clean up test document
    await testDoc.delete();
    console.log('🧹 Test document cleaned up');

  } catch (error) {
    console.error('❌ Firestore error:', error.message);
    if (error.code === 7) {
      console.log('\n💡 Hint: Make sure you ran:');
      console.log('   gcloud auth application-default login');
      console.log('   gcloud auth application-default set-quota-project growth-training-app');
    }
  }
}

// Test Authentication access
async function testAuth() {
  try {
    console.log('\n🔐 Testing Firebase Auth access...');
    const auth = admin.auth();

    // List users (limit 1) to test auth access
    const listResult = await auth.listUsers(1);
    console.log('✅ Auth access successful! Users in system:', listResult.users.length);

  } catch (error) {
    console.error('❌ Auth error:', error.message);
  }
}

// Run tests
async function runTests() {
  await testFirestore();
  await testAuth();

  console.log('\n✨ All tests complete!');
  console.log('\nYou can now use Firebase Admin SDK in your functions without a service account key.');
  console.log('Just initialize with: admin.initializeApp({ projectId: "growth-training-app" })');

  process.exit(0);
}

runTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});