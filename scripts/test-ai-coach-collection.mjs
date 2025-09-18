#!/usr/bin/env node

import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, collection, getDocs, query, where, limit } from 'firebase/firestore';
import * as readline from 'readline';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAKJqgUv4Galjb4iKmm88P8dPMGlMJB7GA",
  authDomain: "growth-70a85.firebaseapp.com",
  projectId: "growth-70a85",
  storageBucket: "growth-70a85.firebasestorage.app",
  messagingSenderId: "732875330330",
  appId: "1:732875330330:ios:ba965c87a36c4d3ee2b3a6"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function testCollection() {
  try {
    console.log('AI Coach Knowledge Base Test');
    console.log('============================\n');
    
    // Get user credentials
    console.log('Please enter your Firebase credentials:');
    const email = await question('Email: ');
    const password = await question('Password: ');
    
    console.log('\nAuthenticating...');
    await signInWithEmailAndPassword(auth, email, password);
    console.log('✅ Authenticated successfully\n');
    
    // Test 1: Check if collection exists and has documents
    console.log('Test 1: Checking collection existence...');
    const knowledgeRef = collection(db, 'ai_coach_knowledge');
    const allDocs = await getDocs(knowledgeRef);
    console.log(`✅ Collection exists with ${allDocs.size} documents\n`);
    
    // Test 2: List first few documents
    console.log('Test 2: Sample documents:');
    let count = 0;
    allDocs.forEach(doc => {
      if (count < 3) {
        const data = doc.data();
        console.log(`\n📄 Document ID: ${doc.id}`);
        console.log(`   Title: ${data.title}`);
        console.log(`   Type: ${data.type}`);
        console.log(`   Keywords: ${data.keywords ? data.keywords.slice(0, 5).join(', ') + '...' : 'none'}`);
        count++;
      }
    });
    
    // Test 3: Test keyword search for "am1"
    console.log('\n\nTest 3: Searching for "am1" in keywords...');
    const am1Terms = ['am1', 'am 1', 'angion method 1', 'angion 1'];
    const am1Query = query(knowledgeRef, where('keywords', 'array-contains-any', am1Terms), limit(5));
    const am1Results = await getDocs(am1Query);
    console.log(`Found ${am1Results.size} documents matching AM1 keywords`);
    
    am1Results.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${data.title}`);
    });
    
    // Test 4: Check document structure
    console.log('\n\nTest 4: Checking document structure...');
    if (allDocs.size > 0) {
      const firstDoc = allDocs.docs[0];
      const data = firstDoc.data();
      console.log('Sample document fields:');
      Object.keys(data).forEach(key => {
        const value = data[key];
        const preview = typeof value === 'string' ? value.substring(0, 50) + '...' : 
                       Array.isArray(value) ? `Array(${value.length})` : 
                       typeof value;
        console.log(`  - ${key}: ${preview}`);
      });
    }
    
    // Test 5: Search in content
    console.log('\n\nTest 5: Checking content search capability...');
    let foundAM1 = false;
    allDocs.forEach(doc => {
      const data = doc.data();
      const content = (data.content || '').toLowerCase();
      const searchable = (data.searchableContent || '').toLowerCase();
      if (content.includes('am1') || content.includes('angion method 1') || 
          searchable.includes('am1') || searchable.includes('angion method 1')) {
        if (!foundAM1) {
          console.log('✅ Found AM1 content in documents');
          console.log(`  Example: ${data.title}`);
          foundAM1 = true;
        }
      }
    });
    
    if (!foundAM1) {
      console.log('⚠️  No AM1 content found in document text');
    }
    
    console.log('\n✅ All tests completed!');
    
    rl.close();
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error:', error);
    rl.close();
    process.exit(1);
  }
}

// Run the test
testCollection();