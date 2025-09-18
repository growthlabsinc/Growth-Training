#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Load the comprehensive update data
const allUpdates = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/all-sabre-updates.json'), 'utf8')
);

console.log('🎯 SABRE Methods Final Deployment Script');
console.log('========================================\n');
console.log('This script generates deployment commands for updating SABRE methods');
console.log('Based on Janus Bifrons video transcript (2025-07-03)\n');

// Option 1: Firebase Console JSON
console.log('📋 OPTION 1: Firebase Console (Recommended)');
console.log('==========================================\n');
console.log('1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore/data/~2FgrowthMethods');
console.log('2. For each document below, click the document ID');
console.log('3. Click "Edit document" (pencil icon)');
console.log('4. Add/Update fields as shown\n');

Object.entries(allUpdates.methods).forEach(([docId, data]) => {
  console.log(`\n📄 Document: ${docId}`);
  console.log('─'.repeat(60));
  
  // Key fields to update
  console.log('\nFields to update:');
  console.log(`title: "${data.title}"`);
  console.log(`description: "${data.description}"`);
  console.log(`hasMultipleSteps: true`);
  console.log(`creator: "Janus Bifrons"`);
  console.log(`estimatedDurationMinutes: ${Math.round((data.timerConfig?.totalDuration || 1800) / 60)}`);
  
  console.log('\nArray fields (copy entire arrays):');
  console.log('- steps (7 items)');
  console.log('- benefits (5 items)');
  if (data.equipmentNeeded) {
    console.log('- equipmentNeeded (4 items)');
  }
  
  console.log('\nObject fields:');
  console.log('- timerConfig');
  console.log('- progressionCriteria');
});

// Option 2: Copy-paste JSON blocks
console.log('\n\n📋 OPTION 2: Copy-Paste JSON Blocks');
console.log('====================================\n');

// Create formatted JSON files for easy copying
const outputDir = path.join(__dirname, 'sabre-updates/firebase-console');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

Object.entries(allUpdates.methods).forEach(([docId, data]) => {
  // Prepare clean update object
  const updateObject = {
    title: data.title,
    description: data.description,
    instructionsText: data.instructionsText,
    safetyNotes: data.safetyNotes,
    benefits: data.benefits,
    creator: data.creator,
    hasMultipleSteps: true,
    estimatedDurationMinutes: Math.round((data.timerConfig?.totalDuration || 1800) / 60),
    steps: data.steps,
    timerConfig: data.timerConfig,
    progressionCriteria: data.progressionCriteria
  };

  // Add equipment if present
  if (data.equipmentNeeded) {
    updateObject.equipmentNeeded = data.equipmentNeeded;
  }

  // Add special fields
  if (data.sabrePhilosophy) {
    updateObject.sabrePhilosophy = data.sabrePhilosophy;
  }

  // Write formatted JSON
  const jsonPath = path.join(outputDir, `${docId}_update.json`);
  fs.writeFileSync(jsonPath, JSON.stringify(updateObject, null, 2));
  
  console.log(`✅ Created: ${jsonPath}`);
});

// Option 3: Node.js script
console.log('\n\n📋 OPTION 3: Node.js Admin SDK Script');
console.log('=====================================\n');
console.log('Run this in your project:');
console.log('\n```javascript');
console.log(`const admin = require('firebase-admin');
const updates = require('./scripts/sabre-updates/all-sabre-updates.json');

// Initialize admin SDK with your credentials
admin.initializeApp();

const db = admin.firestore();

async function updateSABRE() {
  const batch = db.batch();
  
  Object.entries(updates.methods).forEach(([docId, data]) => {
    const ref = db.collection('growthMethods').doc(docId);
    batch.update(ref, {
      ...data,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
  console.log('✅ All SABRE methods updated!');
}

updateSABRE().catch(console.error);`);
console.log('```\n');

// Summary
console.log('\n📊 UPDATE SUMMARY');
console.log('=================\n');
console.log('Documents to update: 4');
console.log('- sabre_type_a: Foundation (40 min)');
console.log('- sabre_type_b: Speed Focus (40 min)');
console.log('- sabre_type_c: Rod Introduction (53 min)');
console.log('- sabre_type_d: Maximum Intensity (47 min)\n');

console.log('Key updates per document:');
console.log('- 7 detailed steps with timings');
console.log('- Timer configuration with intervals');
console.log('- Progression criteria');
console.log('- Enhanced descriptions from video');
console.log('- Safety notes and equipment lists\n');

console.log('✨ Ready for deployment!');
console.log('\nJSON files created in: scripts/sabre-updates/firebase-console/');
console.log('Source data: scripts/sabre-updates/all-sabre-updates.json');