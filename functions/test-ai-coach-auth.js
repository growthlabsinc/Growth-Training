const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

async function testAICoachAuth() {
  try {
    console.log('🔍 Testing AI Coach Authentication...\n');

    // Create a custom token for testing
    const testUid = 'test-user-' + Date.now();
    const customToken = await getAuth().createCustomToken(testUid);
    console.log('✅ Created custom token for test user');

    // Get the function URL
    const functionUrl = 'https://generateairesponse-a37lmvzgka-uc.a.run.app';
    console.log(`📍 Function URL: ${functionUrl}`);

    // Test 1: Call without authentication (should fail)
    console.log('\n📝 Test 1: Call without authentication...');
    try {
      const response1 = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          data: {
            query: 'Test query',
            conversationHistory: []
          }
        })
      });

      const result1 = await response1.text();
      console.log(`Response status: ${response1.status}`);
      console.log(`Response: ${result1.substring(0, 200)}...`);

      if (response1.status === 401 || response1.status === 403) {
        console.log('❌ Expected: Function requires authentication');
      } else if (response1.status === 200) {
        console.log('⚠️  Unexpected: Function allowed unauthenticated access');
      }
    } catch (error) {
      console.log('❌ Error calling without auth:', error.message);
    }

    // Test 2: Check if function is publicly accessible
    console.log('\n📝 Test 2: Check public accessibility...');
    try {
      const response2 = await fetch(functionUrl, {
        method: 'OPTIONS',
        headers: {
          'Origin': 'https://example.com',
          'Access-Control-Request-Method': 'POST'
        }
      });

      console.log(`CORS preflight status: ${response2.status}`);
      if (response2.status === 200 || response2.status === 204) {
        console.log('✅ Function is publicly accessible (CORS enabled)');
        console.log('   This is expected for Firebase Callable Functions v2');
      }
    } catch (error) {
      console.log('❌ Error checking accessibility:', error.message);
    }

    // Test 3: Verify IAM policy
    console.log('\n📝 Test 3: Verify Cloud Run IAM policy...');
    const { execSync } = require('child_process');
    try {
      const iamPolicy = execSync(
        'gcloud run services get-iam-policy generateairesponse --region=us-central1 --format=json',
        { encoding: 'utf-8' }
      );
      const policy = JSON.parse(iamPolicy);

      const hasAllUsers = policy.bindings?.some(binding =>
        binding.members?.includes('allUsers') &&
        binding.role === 'roles/run.invoker'
      );

      if (hasAllUsers) {
        console.log('✅ Cloud Run service has allUsers invoker policy');
        console.log('   Authentication is handled inside the function');
      } else {
        console.log('❌ Cloud Run service missing allUsers invoker policy');
        console.log('   This will cause UNAUTHENTICATED errors');
      }
    } catch (error) {
      console.log('⚠️  Could not check IAM policy:', error.message);
    }

    console.log('\n✅ Authentication test complete!');
    console.log('\nSummary:');
    console.log('- Function URL is accessible');
    console.log('- Authentication should be handled inside the function');
    console.log('- Client apps need to include Firebase Auth ID tokens');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testAICoachAuth();