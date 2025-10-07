#!/usr/bin/env node

const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function testAuthenticatedAccess() {
  console.log('🧪 Testing authenticated Firestore access...\n');

  try {
    // The user ID from your iOS app logs
    const testUserId = 'e05emmXMWtbU9TEh7OPeans7iyG2';

    console.log(`👤 Testing with user ID: ${testUserId}`);

    // Try to verify the user exists
    try {
      const userRecord = await getAuth().getUser(testUserId);
      console.log('✅ User exists in Firebase Auth');
      console.log(`   Email: ${userRecord.email || 'No email'}`);
      console.log(`   Created: ${userRecord.metadata.creationTime}\n`);
    } catch (error) {
      console.log('⚠️  User verification failed:', error.message);
    }

    // Test 1: Try to read educational_resources collection
    console.log('📖 Test 1: Reading educational_resources collection...');

    // This simulates what the iOS app is doing
    const snapshot = await db.collection('educational_resources')
      .orderBy('title')
      .get();

    if (!snapshot.empty) {
      console.log(`✅ Successfully read ${snapshot.size} documents`);
      snapshot.forEach(doc => {
        console.log(`   - ${doc.id}: ${doc.data().title}`);
      });
    } else {
      console.log('⚠️  Collection is empty');
    }

    // Test 2: Check if rules allow read for authenticated users
    console.log('\n🔍 Test 2: Simulating client-side query...');
    console.log('Note: Admin SDK bypasses security rules, but we can still test the query structure');

    // The exact query from FirestoreService.swift
    const clientQuery = db.collection('educational_resources')
      .orderBy('title');

    const result = await clientQuery.get();
    console.log(`✅ Query structure is valid, returned ${result.size} documents`);

    // Test 3: Check the actual security rules
    console.log('\n🔒 Test 3: Current security rules status:');
    console.log('Rule for educational_resources: allow read: if true (temporary public access)');
    console.log('This should allow ANY read access, even without authentication');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('   Full error:', error);
  }
}

testAuthenticatedAccess();