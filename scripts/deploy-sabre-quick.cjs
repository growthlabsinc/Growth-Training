#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Service account path
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  '/Users/tradeflowj/Desktop/Dev/growth-fresh/growth-70a85-firebase-adminsdk-fbsvc-a9a1390b26.json';

// Initialize Firebase Admin
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Load update data
const allUpdates = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/all-sabre-updates.json'), 'utf8')
);

async function deployQuick() {
  console.log('🚀 Quick SABRE Deployment');
  console.log('========================\n');

  try {
    // Update each document individually
    for (const [docId, data] of Object.entries(allUpdates.methods)) {
      console.log(`Updating ${docId}...`);
      
      await db.collection('growthMethods').doc(docId).update({
        ...data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ ${docId} updated successfully`);
    }

    console.log('\n✨ All SABRE methods updated!');
    
    // Quick verification
    console.log('\n🔍 Verifying updates:');
    for (const docId of Object.keys(allUpdates.methods)) {
      const doc = await db.collection('growthMethods').doc(docId).get();
      const data = doc.data();
      console.log(`${docId}: ${data.steps ? data.steps.length : 0} steps`);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
  
  process.exit(0);
}

// Run immediately
deployQuick();