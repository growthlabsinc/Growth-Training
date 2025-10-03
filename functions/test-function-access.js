const https = require('https');

async function testFunctionAccess() {
  console.log('🔍 Testing Firebase Functions Accessibility...\n');

  const functions = [
    { name: 'generateAIResponse', url: 'https://generateairesponse-a37lmvzgka-uc.a.run.app' },
    { name: 'registerPushToStartToken', url: 'https://registerpushtostarttoken-a37lmvzgka-uc.a.run.app' },
    { name: 'registerLiveActivityPushToken', url: 'https://registerliveactivitypushtoken-a37lmvzgka-uc.a.run.app' },
    { name: 'updateLiveActivity', url: 'https://updateliveactivity-a37lmvzgka-uc.a.run.app' }
  ];

  for (const func of functions) {
    console.log(`\n📝 Testing ${func.name}...`);
    console.log(`   URL: ${func.url}`);

    try {
      // Test OPTIONS request (CORS preflight)
      const optionsResponse = await fetch(func.url, {
        method: 'OPTIONS',
        headers: {
          'Origin': 'https://example.com',
          'Access-Control-Request-Method': 'POST'
        }
      });

      console.log(`   CORS preflight status: ${optionsResponse.status}`);

      // Test POST request without auth
      const postResponse = await fetch(func.url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ data: {} })
      });

      console.log(`   POST request status: ${postResponse.status}`);

      if (postResponse.status === 200) {
        console.log(`   ✅ Function is accessible (auth handled internally)`);
      } else if (postResponse.status === 401 || postResponse.status === 403) {
        console.log(`   ⚠️  Function returned ${postResponse.status} - may need allUsers IAM policy`);
      } else {
        console.log(`   ℹ️  Status: ${postResponse.status}`);
      }

    } catch (error) {
      console.log(`   ❌ Error: ${error.message}`);
    }
  }

  console.log('\n\n📊 Checking IAM policies for all functions...\n');

  // Check IAM policies using gcloud
  const { execSync } = require('child_process');

  for (const func of functions) {
    const serviceName = func.name.toLowerCase();
    console.log(`\n${func.name}:`);

    try {
      const iamPolicy = execSync(
        `gcloud run services get-iam-policy ${serviceName} --region=us-central1 --format=json 2>/dev/null`,
        { encoding: 'utf-8' }
      );
      const policy = JSON.parse(iamPolicy);

      const hasAllUsers = policy.bindings?.some(binding =>
        binding.members?.includes('allUsers') &&
        binding.role === 'roles/run.invoker'
      );

      if (hasAllUsers) {
        console.log('  ✅ Has allUsers invoker policy');
      } else {
        console.log('  ❌ Missing allUsers invoker policy');
        console.log('  Available bindings:', JSON.stringify(policy.bindings, null, 2));
      }
    } catch (error) {
      console.log(`  ⚠️  Could not check: ${error.message.split('\n')[0]}`);
    }
  }

  console.log('\n✅ Test complete!');
}

testFunctionAccess();