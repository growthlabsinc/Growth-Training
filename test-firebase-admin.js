const admin = require('firebase-admin');
const serviceAccount = require('./growth-70a85-firebase-adminsdk-s2g2d-4cd96e9e82.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85'
});

const functions = admin.functions();

// Development push token
const pushToken = '806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600';
const activityId = 'DEV-TEST-' + Date.now();

async function testDiagnostics() {
  try {
    console.log('🚀 Testing with Firebase Admin SDK...');
    console.log('Activity ID:', activityId);
    console.log('Push Token:', pushToken.substring(0, 20) + '...');
    console.log('');
    
    // Call the function
    const collectAPNsDiagnostics = functions.httpsCallable('collectAPNsDiagnostics');
    const result = await collectAPNsDiagnostics({
      pushToken: pushToken,
      activityId: activityId
    });
    
    if (result.data && result.data.diagnostics) {
      const diag = result.data.diagnostics;
      console.log('\n=== DIAGNOSTIC RESULTS ===');
      console.log('✅ APNs Status:', diag.statusCode);
      console.log('🔑 Key ID:', diag.keyId);
      console.log('👥 Team ID:', diag.teamId);
      console.log('📦 Bundle ID:', diag.bundleId);
      console.log('🌐 APNs Server:', diag.apnsServerIP || 'Development');
      console.log('⏱️ Request Duration:', diag.requestDuration);
      console.log('📄 Response:', diag.responseBody);
      
      if (diag.statusCode === 200) {
        console.log('\n✅ SUCCESS! Development environment is working correctly!');
        console.log('🎉 Your Live Activity updates should work now.');
      } else if (diag.statusCode === 400 && diag.responseBody && diag.responseBody.includes('BadDeviceToken')) {
        console.log('\n⚠️  BadDeviceToken - This might mean:');
        console.log('   - Token/server mismatch');
        console.log('   - Token is expired or invalid');
      } else if (diag.statusCode === 403) {
        console.log('\n❌ InvalidProviderToken - Authentication issue');
        console.log('   Error interpretation:', diag.errorInterpretation);
      } else {
        console.log('\n❌ Error:', diag.responseBody || diag.errorInterpretation);
      }
      console.log('==========================\n');
    } else {
      console.log('Unexpected response:', result);
    }
  } catch (error) {
    console.error('Error calling function:', error.message);
    if (error.details) {
      console.error('Details:', error.details);
    }
  }
  
  process.exit(0);
}

testDiagnostics();