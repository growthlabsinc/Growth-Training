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

// Load remaining types
const typeBData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/firebase-console/sabre_type_b_update.json'), 'utf8')
);
const typeCData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/firebase-console/sabre_type_c_update.json'), 'utf8')
);
const typeDData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/firebase-console/sabre_type_d_update.json'), 'utf8')
);

async function updateRemaining() {
  console.log('Updating remaining SABRE types...\n');
  
  const updates = [
    { id: 'sabre_type_b', data: typeBData, name: 'Type B' },
    { id: 'sabre_type_c', data: typeCData, name: 'Type C' },
    { id: 'sabre_type_d', data: typeDData, name: 'Type D' }
  ];
  
  for (const update of updates) {
    try {
      console.log(`Updating ${update.name}...`);
      
      await db.collection('growthMethods').doc(update.id).update({
        ...update.data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Verify
      const doc = await db.collection('growthMethods').doc(update.id).get();
      const data = doc.data();
      console.log(`✅ ${update.name} updated! Steps: ${data.steps ? data.steps.length : 0}, Duration: ${data.estimatedDurationMinutes} min\n`);
      
    } catch (error) {
      console.error(`❌ Error updating ${update.name}:`, error.message);
    }
  }
  
  console.log('🎉 All SABRE methods deployment complete!');
  
  // Final summary
  console.log('\n📊 Final Verification:');
  for (const docId of ['sabre_type_a', 'sabre_type_b', 'sabre_type_c', 'sabre_type_d']) {
    const doc = await db.collection('growthMethods').doc(docId).get();
    const data = doc.data();
    console.log(`${docId}: ${data.steps?.length || 0} steps, ${data.hasMultipleSteps ? '✓' : '✗'} multiStep`);
  }
  
  process.exit(0);
}

updateRemaining();