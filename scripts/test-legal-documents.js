// Test script to check if legal documents exist in Firestore
// Run with: node scripts/test-legal-documents.js

import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc } from 'firebase/firestore';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBP4SlK2K_CWYPXCPRj1FLjW_PF8BFgLLY",
  authDomain: "growth-70a85.firebaseapp.com",
  projectId: "growth-70a85",
  storageBucket: "growth-70a85.firebasestorage.app",
  messagingSenderId: "39532219396",
  appId: "1:39532219396:ios:57e5b967c949e1b9f42d48"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function checkLegalDocuments() {
  console.log('Checking for legal documents in Firestore...\n');
  
  const documentIds = ['privacy_policy', 'terms_of_use', 'disclaimer'];
  
  for (const docId of documentIds) {
    try {
      const docRef = doc(db, 'legalDocuments', docId);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        const data = docSnap.data();
        console.log(`✓ Found ${docId}:`);
        console.log(`  - Title: ${data.title}`);
        console.log(`  - Version: ${data.version}`);
        console.log(`  - Content length: ${data.content?.length || 0} characters\n`);
      } else {
        console.log(`✗ Missing ${docId}\n`);
      }
    } catch (error) {
      console.error(`✗ Error checking ${docId}:`, error.message, '\n');
    }
  }
  
  console.log('\nIf documents are missing, add them via Firebase Console:');
  console.log('https://console.firebase.google.com/project/growth-70a85/firestore/data');
}

checkLegalDocuments();