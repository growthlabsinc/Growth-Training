#!/usr/bin/env node

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function testFirestoreAccess() {
  console.log('🧪 Testing Firestore access to educational_resources collection...\n');

  try {
    // Test 1: Direct read
    console.log('📖 Test 1: Direct document read...');
    const snapshot = await db.collection('educational_resources').limit(1).get();

    if (!snapshot.empty) {
      console.log('✅ Successfully read from educational_resources');
      console.log(`   Found ${snapshot.size} document(s)`);
      const doc = snapshot.docs[0];
      console.log(`   Document ID: ${doc.id}`);
      console.log(`   Title: ${doc.data().title}\n`);
    } else {
      console.log('⚠️  Collection is empty\n');
    }

    // Test 2: Count documents
    console.log('📊 Test 2: Counting documents...');
    const allDocs = await db.collection('educational_resources').get();
    console.log(`✅ Total documents in collection: ${allDocs.size}\n`);

    // Test 3: List all document IDs and titles
    console.log('📋 Test 3: Listing all documents:');
    allDocs.forEach(doc => {
      console.log(`   - ${doc.id}: ${doc.data().title}`);
    });

    // Test 4: Check collection metadata
    console.log('\n🔍 Test 4: Collection verification:');
    console.log(`   Collection path: educational_resources`);
    console.log(`   Project ID: growth-training-app`);
    console.log(`   Database: (default)`);

  } catch (error) {
    console.error('❌ Error accessing Firestore:', error.message);
    console.error('   Error code:', error.code);
    console.error('   Full error:', error);
  }
}

testFirestoreAccess();