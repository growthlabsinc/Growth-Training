import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
try {
  // Try service account first, then fall back to application default credentials
  let credential;
  try {
    const serviceAccountPath = path.join(__dirname, 'service-account.json');
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    credential = admin.credential.cert(serviceAccount);
    console.log('Using service account credentials');
  } catch (serviceError) {
    credential = admin.credential.applicationDefault();
    console.log('Using application default credentials');
  }

  admin.initializeApp({
    credential: credential,
    projectId: 'growth-70a85'
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  process.exit(1);
}

// Get Firestore database reference
const db = admin.firestore();

const testFirestorePermissions = async () => {
  console.log('=== Firestore Permissions Test ===\n');
  
  try {
    // 1. Test basic collection access
    console.log('1. Testing collection access...');
    
    // Test listing collections (admin only)
    const collections = await db.listCollections();
    console.log(`   Found ${collections.length} collections:`);
    collections.forEach(collection => {
      console.log(`     - ${collection.id}`);
    });
    
    const hasEducationalResources = collections.some(c => c.id === 'educationalResources');
    console.log(`   educationalResources collection exists: ${hasEducationalResources}\n`);
    
    // 2. Test reading educationalResources as unauthenticated user would
    console.log('2. Testing unauthenticated read access...');
    
    try {
      const snapshot = await db.collection('educationalResources').limit(1).get();
      console.log(`   ✅ Can read educationalResources collection (${snapshot.size} docs returned)`);
      
      if (snapshot.size > 0) {
        const doc = snapshot.docs[0];
        console.log(`   Sample document ID: ${doc.id}`);
        console.log(`   Sample document fields: ${Object.keys(doc.data()).join(', ')}`);
      }
    } catch (error) {
      console.log(`   ❌ Cannot read educationalResources collection: ${error.message}`);
      console.log(`   This could explain why iOS app shows no resources!`);
    }
    
    // 3. Check Firestore Security Rules
    console.log('\n3. Checking Firestore security rules...');
    
    try {
      // Try to get the rules (requires admin access)
      const rulesFile = path.resolve(__dirname, '../firestore.rules');
      if (fs.existsSync(rulesFile)) {
        const rules = fs.readFileSync(rulesFile, 'utf8');
        console.log('   Current Firestore rules:');
        console.log('   ---');
        console.log(rules);
        console.log('   ---');
        
        // Check if educationalResources is mentioned
        if (rules.includes('educationalResources')) {
          console.log('   ✅ educationalResources collection has specific rules');
        } else {
          console.log('   ⚠️  No specific rules for educationalResources collection');
        }
      } else {
        console.log('   firestore.rules file not found locally');
      }
    } catch (error) {
      console.log(`   Error reading rules: ${error.message}`);
    }
    
    // 4. Test specific query that iOS app uses
    console.log('\n4. Testing exact iOS query...');
    
    try {
      const iosQuery = db.collection('educationalResources').orderBy('title');
      const iosSnapshot = await iosQuery.get();
      
      console.log(`   iOS query returned ${iosSnapshot.size} documents`);
      
      if (iosSnapshot.size === 0) {
        console.log('   ❌ iOS query returns 0 documents - this explains the issue!');
        
        // Try without orderBy
        console.log('   Trying query without orderBy...');
        const simpleSnapshot = await db.collection('educationalResources').get();
        console.log(`   Simple query returned ${simpleSnapshot.size} documents`);
        
        if (simpleSnapshot.size > 0 && iosSnapshot.size === 0) {
          console.log('   ❌ The orderBy("title") is causing the issue!');
          console.log('   This could be due to missing index or security rule restrictions');
        }
      }
    } catch (error) {
      console.log(`   ❌ iOS query failed: ${error.message}`);
      console.log('   This is likely the root cause of the iOS app issue!');
    }
    
  } catch (error) {
    console.error('Error during permissions test:', error);
    throw error;
  }
};

// Main function
const main = async () => {
  try {
    await testFirestorePermissions();
    process.exit(0);
  } catch (error) {
    console.error('Permissions test failed:', error);
    process.exit(1);
  }
};

main();