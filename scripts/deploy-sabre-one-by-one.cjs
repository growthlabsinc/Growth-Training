#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Service account
const serviceAccount = JSON.parse(fs.readFileSync(
  '/Users/tradeflowj/Desktop/Dev/growth-fresh/growth-70a85-firebase-adminsdk-fbsvc-a9a1390b26.json', 
  'utf8'
));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85'
});

const db = admin.firestore();

// Load just Type A data first
const typeAData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/firebase-console/sabre_type_a_update.json'), 'utf8')
);

async function updateTypeA() {
  console.log('Updating SABRE Type A...');
  
  try {
    await db.collection('growthMethods').doc('sabre_type_a').update({
      ...typeAData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Type A updated successfully!');
    
    // Verify
    const doc = await db.collection('growthMethods').doc('sabre_type_a').get();
    const data = doc.data();
    console.log(`Verification: ${data.steps ? data.steps.length : 0} steps, hasMultipleSteps: ${data.hasMultipleSteps}`);
    
  } catch (error) {
    console.error('Error:', error.message);
  }
  
  process.exit(0);
}

updateTypeA();