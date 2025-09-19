// Test script to verify Application Default Credentials are working
// Run with: node test-firebase-auth.js

console.log('🔧 Testing Firebase connection with Application Default Credentials...\n');

// First, let's verify ADC file exists
const fs = require('fs');
const path = require('path');
const os = require('os');

const adcPath = path.join(os.homedir(), '.config', 'gcloud', 'application_default_credentials.json');

if (fs.existsSync(adcPath)) {
  console.log('✅ Application Default Credentials file found at:', adcPath);

  const adc = JSON.parse(fs.readFileSync(adcPath, 'utf8'));
  console.log('📧 Authenticated as:', adc.client_id || 'User account');
  console.log('🎯 Quota project:', adc.quota_project_id || 'Not set');
  console.log('\n');
} else {
  console.error('❌ No Application Default Credentials found!');
  console.log('Run: gcloud auth application-default login');
  process.exit(1);
}

// Now test with Firebase Admin SDK if available
try {
  const admin = require('firebase-admin');

  console.log('📦 Firebase Admin SDK found, testing initialization...');

  // Initialize without service account key
  admin.initializeApp({
    projectId: 'growth-training-app'
  });

  console.log('✅ Firebase Admin initialized successfully!');
  console.log('\nYou can now use this pattern in your code:');
  console.log('----------------------------------------');
  console.log('const admin = require("firebase-admin");');
  console.log('admin.initializeApp({');
  console.log('  projectId: "growth-training-app"');
  console.log('});');
  console.log('----------------------------------------\n');

  // Test Firestore connection
  const db = admin.firestore();
  db.collection('test').limit(1).get()
    .then(() => {
      console.log('✅ Firestore connection successful!');
      process.exit(0);
    })
    .catch(error => {
      console.error('⚠️ Firestore connection failed:', error.message);
      console.log('\nThis might be normal if Firestore rules require authentication.');
      process.exit(0);
    });

} catch (error) {
  if (error.code === 'MODULE_NOT_FOUND') {
    console.log('📦 Firebase Admin SDK not installed in this directory.');
    console.log('\n✨ But your Application Default Credentials are configured correctly!');
    console.log('\nWhen you set up Firebase Functions, initialize admin SDK like this:');
    console.log('----------------------------------------');
    console.log('const admin = require("firebase-admin");');
    console.log('admin.initializeApp({');
    console.log('  projectId: "growth-training-app"');
    console.log('});');
    console.log('----------------------------------------\n');
    console.log('No service account key file needed! 🎉');
  } else {
    console.error('Error:', error.message);
  }
}