#!/usr/bin/env node

/**
 * Direct Firestore import using Firebase Admin SDK
 * This script attempts multiple authentication methods
 */

import admin from 'firebase-admin';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PROJECT_ID = 'growth-70a85';
const COLLECTION_NAME = 'ai_coach_knowledge';

async function initializeFirebase() {
  console.log('🔧 Initializing Firebase Admin SDK...\n');
  
  try {
    // Try different initialization methods
    
    // Method 1: Use GOOGLE_APPLICATION_CREDENTIALS if set
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('Using service account from GOOGLE_APPLICATION_CREDENTIALS');
      const serviceAccount = JSON.parse(
        await fs.readFile(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8')
      );
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: PROJECT_ID
      });
      return true;
    }
    
    // Method 2: Try Application Default Credentials
    console.log('Attempting to use Application Default Credentials...');
    admin.initializeApp({
      projectId: PROJECT_ID
    });
    
    // Test the connection
    const db = admin.firestore();
    await db.collection('_test_').doc('test').set({ test: true });
    await db.collection('_test_').doc('test').delete();
    console.log('✅ Successfully connected to Firestore\n');
    return true;
    
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    
    // If all methods fail, try one more approach
    console.log('\n🔄 Attempting alternative initialization...');
    try {
      // Initialize without credentials (works in some environments)
      if (!admin.apps.length) {
        admin.initializeApp({
          projectId: PROJECT_ID,
          databaseURL: `https://${PROJECT_ID}.firebaseio.com`
        });
      }
      return true;
    } catch (altError) {
      return false;
    }
  }
}

async function importKnowledgeBase() {
  console.log('📚 Firestore Knowledge Base Import');
  console.log('==================================\n');
  
  // Initialize Firebase
  const initialized = await initializeFirebase();
  if (!initialized) {
    console.error('\n❌ Could not initialize Firebase Admin SDK');
    console.log('\n📋 Manual Import Instructions:');
    console.log('1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore');
    console.log('2. Create collection "ai_coach_knowledge"');
    console.log('3. Use the import feature with: ai_coach_knowledge_export.json\n');
    process.exit(1);
  }
  
  const db = admin.firestore();
  
  try {
    // Load the export file
    const exportPath = path.join(__dirname, 'ai_coach_knowledge_export.json');
    const exportData = JSON.parse(await fs.readFile(exportPath, 'utf8'));
    
    console.log(`📄 Loaded ${Object.keys(exportData).length} documents from export file\n`);
    
    // Clear existing collection
    console.log('🗑️  Clearing existing collection...');
    const collectionRef = db.collection(COLLECTION_NAME);
    const existing = await collectionRef.get();
    
    if (!existing.empty) {
      const batch = db.batch();
      existing.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`   Deleted ${existing.size} existing documents\n`);
    }
    
    // Import documents
    console.log('📥 Importing documents...\n');
    const batch = db.batch();
    let count = 0;
    
    for (const [docId, docData] of Object.entries(exportData)) {
      const docRef = collectionRef.doc(docId);
      
      // Convert date strings to timestamps
      const data = {
        ...docData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      batch.set(docRef, data);
      count++;
      console.log(`   ✅ Prepared: ${docData.title}`);
      
      // Firestore has a limit of 500 operations per batch
      if (count % 500 === 0) {
        await batch.commit();
        console.log(`\n   📤 Committed batch of ${count} documents\n`);
      }
    }
    
    // Commit final batch
    await batch.commit();
    console.log(`\n✅ Successfully imported ${count} documents!\n`);
    
    // Verify import
    console.log('🔍 Verifying import...\n');
    
    // Test query 1: Search for AM1
    const am1Query = await collectionRef
      .where('keywords', 'array-contains', 'am1')
      .limit(1)
      .get();
    
    if (!am1Query.empty) {
      console.log('✅ Test 1 passed: Found AM1 content');
    } else {
      console.log('❌ Test 1 failed: AM1 content not found');
    }
    
    // Test query 2: Search for SABRE
    const sabreQuery = await collectionRef
      .where('keywords', 'array-contains', 'sabre')
      .limit(1)
      .get();
    
    if (!sabreQuery.empty) {
      console.log('✅ Test 2 passed: Found SABRE content');
    } else {
      console.log('❌ Test 2 failed: SABRE content not found');
    }
    
    // Get total count
    const allDocs = await collectionRef.get();
    console.log(`\n📊 Total documents in knowledge base: ${allDocs.size}\n`);
    
    console.log('🎉 Knowledge Base Import Complete!');
    console.log('==================================\n');
    console.log('The AI Coach now has access to:');
    console.log('• AM1, AM2, Vascion (AM3) techniques');
    console.log('• SABRE techniques and safety information');
    console.log('• Common abbreviations and terminology');
    console.log('• Progression timelines');
    console.log('• Hand techniques breakdown');
    console.log('• And much more!\n');
    console.log('📱 Test it by asking the AI Coach:');
    console.log('• "What is AM1?"');
    console.log('• "How do I perform Angion Method 1.0?"');
    console.log('• "What does CS mean?"');
    console.log('• "Explain SABRE techniques"\n');
    
    // Deploy functions reminder
    console.log('⚠️  Don\'t forget to deploy the updated functions:');
    console.log('   firebase deploy --only functions:generateAIResponse\n');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Import failed:', error);
    console.error('\nError details:', error.message);
    
    if (error.code === 'permission-denied') {
      console.log('\n⚠️  Permission denied. This usually means:');
      console.log('1. You need proper authentication');
      console.log('2. Your account needs Firestore write permissions');
      console.log('3. Security rules might be blocking writes\n');
    }
    
    process.exit(1);
  }
}

// Run the import
importKnowledgeBase().catch(error => {
  console.error('Unexpected error:', error);
  process.exit(1);
});