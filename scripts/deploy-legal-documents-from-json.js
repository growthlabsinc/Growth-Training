// Script to deploy legal documents from JSON file to Firestore
// Run with: node scripts/deploy-legal-documents-from-json.js

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Initialize Firebase Admin
const app = initializeApp({
  projectId: 'growth-70a85'
});

const db = getFirestore();

// Read legal documents from JSON file
const legalDocumentsPath = join(__dirname, 'legal-documents.json');
const legalDocumentsData = JSON.parse(readFileSync(legalDocumentsPath, 'utf8'));

// Add documents to Firestore
async function deployLegalDocuments() {
  console.log('Deploying legal documents from JSON to Firestore...\n');
  
  for (const [docId, docData] of Object.entries(legalDocumentsData)) {
    try {
      // Convert ISO date string to Firestore timestamp
      const lastUpdated = new Date(docData.lastUpdated);
      
      const documentData = {
        title: docData.title,
        version: docData.version,
        lastUpdated: FieldValue.serverTimestamp(), // Use server timestamp
        content: docData.content
      };
      
      await db.collection('legalDocuments').doc(docId).set(documentData);
      console.log(`✓ Deployed ${docData.title} (v${docData.version})`);
    } catch (error) {
      console.error(`✗ Error deploying ${docData.title}:`, error.message);
    }
  }
  
  console.log('\n✅ All legal documents have been deployed to Firestore!');
  console.log('\nYou can verify them at:');
  console.log('https://console.firebase.google.com/project/growth-70a85/firestore/data/~2FlegalDocuments');
  
  process.exit(0);
}

deployLegalDocuments().catch(error => {
  console.error('Failed to deploy documents:', error);
  process.exit(1);
});