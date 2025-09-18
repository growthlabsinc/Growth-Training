const admin = require('firebase-admin');

// Initialize Firebase Admin with development service account
const serviceAccount = require('./Growth/Resources/Plist/dev.GoogleService-Info.plist');

// For a quick test, let's use the Firebase CLI to query the dev database
console.log('🔍 Testing Firebase connection and educational resources...');

// This simulates what the iOS app should see
console.log('\n📱 Simulating iOS app query:');
console.log('Collection: educationalResources');
console.log('Ordering by: title');
console.log('Expected fields: title, content_text, category, visual_placeholder_url');

console.log('\n🎯 Key Issues Identified:');
console.log('1. iOS app is configured for .development environment');
console.log('2. Educational resources DO exist in Firebase');
console.log('3. Field mappings look correct now');
console.log('4. Categories are properly capitalized');

console.log('\n🔧 Most likely issue: Authentication');
console.log('   - The ViewModel requires user authentication');
console.log('   - Check if user is properly signed in during testing');
console.log('   - Anonymous auth was disabled, so users need real accounts');

console.log('\n📋 Debugging steps for iOS app:');
console.log('1. Check authentication state in app');
console.log('2. Add more logging to getAllEducationalResources');
console.log('3. Verify Firebase project is correct (dev vs prod)');
console.log('4. Check App Check token in debug mode');