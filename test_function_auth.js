#!/usr/bin/env node

/**
 * Test Firebase Function authentication by calling functions directly
 */

const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFunctions, httpsCallable } = require('firebase/functions');

// Firebase config from GoogleService-Info.plist
const firebaseConfig = {
  apiKey: "AIzaSyAjE0ojXLB6hnme7BmOPCvsRapujs-1DkQ",
  authDomain: "growth-training-app.firebaseapp.com",
  projectId: "growth-training-app",
  storageBucket: "growth-training-app.firebasestorage.app",
  messagingSenderId: "997901246801",
  appId: "1:997901246801:ios:4d1e1e8e8e8e8e8e8e8e8e"
};

async function testFunctionAuth() {
  console.log('🔍 Testing Firebase Function Authentication...\n');

  try {
    // Initialize Firebase
    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);
    const functions = getFunctions(app, 'us-central1');

    console.log('📧 Attempting to sign in...');

    // Try to sign in with a test user (you'll need to replace with actual credentials)
    // For this test, we'll just check if we can call the function without auth
    console.log('⚠️  Testing function call without authentication first...');

    // Test the testDeployment function (should not require auth)
    try {
      const testFunction = httpsCallable(functions, 'testDeployment');
      const result = await testFunction();
      console.log('✅ testDeployment function works:', result.data);
    } catch (error) {
      console.log('❌ testDeployment function failed:', error.message);
    }

    // Now test an authenticated function
    console.log('\n🔐 Testing authenticated function...');
    try {
      const aiFunction = httpsCallable(functions, 'generateAIResponse');
      const result = await aiFunction({ query: "Hello" });
      console.log('✅ generateAIResponse function works:', result.data);
    } catch (error) {
      console.log('❌ generateAIResponse function failed:', error.message);
      console.log('Error code:', error.code);
      console.log('Error details:', error.details);
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testFunctionAuth().then(() => {
  console.log('\n✅ Function authentication test completed');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});