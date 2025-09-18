/**
 * Script to set Cloud Function to allow public access
 * This uses the Google Cloud IAM API to add allUsers as an invoker
 */

const https = require('https');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

async function getAccessToken() {
  try {
    // Try to get access token using gcloud (if available)
    const { stdout } = await execPromise('gcloud auth print-access-token 2>/dev/null');
    return stdout.trim();
  } catch (error) {
    console.error('Cannot get access token. Please ensure gcloud is installed and authenticated.');
    return null;
  }
}

async function setFunctionPublic() {
  const projectId = 'growth-70a85';
  const functionName = 'generateAIResponse';
  const region = 'us-central1';
  
  console.log('Setting Cloud Function to allow public access...');
  console.log(`Project: ${projectId}`);
  console.log(`Function: ${functionName}`);
  console.log(`Region: ${region}`);
  console.log('');
  
  // First, let's provide the manual instructions
  console.log('=== Manual Instructions ===');
  console.log('Since gcloud CLI is not available, please follow these steps:');
  console.log('');
  console.log('1. Go to the Google Cloud Console:');
  console.log(`   https://console.cloud.google.com/functions/details/${region}/${functionName}?project=${projectId}`);
  console.log('');
  console.log('2. Click on the "Permissions" tab');
  console.log('');
  console.log('3. Click "ADD PRINCIPAL" or "GRANT ACCESS"');
  console.log('');
  console.log('4. In the "New principals" field, enter: allUsers');
  console.log('');
  console.log('5. In the "Select a role" dropdown, choose:');
  console.log('   Cloud Functions > Cloud Functions Invoker');
  console.log('');
  console.log('6. Click "Save"');
  console.log('');
  console.log('7. A warning will appear about making the function public. Click "Allow Public Access"');
  console.log('');
  console.log('=== Alternative: Using Firebase CLI ===');
  console.log('');
  console.log('You can also try running this command if you have gcloud installed:');
  console.log('');
  console.log(`gcloud functions add-iam-policy-binding ${functionName} \\`);
  console.log(`  --member="allUsers" \\`);
  console.log(`  --role="roles/cloudfunctions.invoker" \\`);
  console.log(`  --region=${region} \\`);
  console.log(`  --project=${projectId}`);
  console.log('');
  console.log('=== Testing the Function ===');
  console.log('');
  console.log('After setting permissions, test with:');
  console.log('');
  console.log(`curl -X POST https://${region}-${projectId}.cloudfunctions.net/${functionName} \\`);
  console.log('  -H "Content-Type: application/json" \\');
  console.log('  -d \'{"data":{"query":"Hello"}}\'');
  console.log('');
}

// Run the script
setFunctionPublic().catch(console.error);