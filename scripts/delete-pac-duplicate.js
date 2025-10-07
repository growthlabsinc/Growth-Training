#!/usr/bin/env node

/**
 * Delete duplicate PAC exercise
 *
 * Removes the old PAC exercise (pump_assisted_clamping_pac - 25min version)
 * Keeps the correct PAC (stage3_pump_assisted_clamping - 20min version)
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/delete-pac-duplicate.js
 */

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// PAC exercises to DELETE
const EXERCISES_TO_DELETE = [
  'pump_assisted_clamping_pac',  // Old 25min version
  'stage1_pump_assisted_clamping' // Also delete the stage1 version if it exists
];

// PAC exercise to KEEP
const EXERCISE_TO_KEEP = 'stage3_pump_assisted_clamping'; // 20min version

async function deletePACDuplicate() {
  console.log('🗑️  Deleting PAC Duplicate\n');

  // First verify the exercise we want to keep exists
  const keepDoc = await db.collection('growth_exercises').doc(EXERCISE_TO_KEEP).get();
  if (!keepDoc.exists) {
    console.error(`❌ Error: Exercise to keep (${EXERCISE_TO_KEEP}) does not exist!`);
    process.exit(1);
  }

  const keepData = keepDoc.data();
  console.log('✅ Verified exercise to KEEP:');
  console.log(`   ID: ${EXERCISE_TO_KEEP}`);
  console.log(`   Title: ${keepData.title}`);
  console.log(`   Stage: ${keepData.stage}`);
  console.log(`   Duration: ${keepData.estimatedDurationMinutes} min\n`);

  // Check which duplicates exist
  const toDelete = [];
  for (const id of EXERCISES_TO_DELETE) {
    const doc = await db.collection('growth_exercises').doc(id).get();
    if (doc.exists) {
      toDelete.push({ id, data: doc.data() });
    }
  }

  if (toDelete.length === 0) {
    console.log('✅ No duplicates found to delete!');
    return;
  }

  console.log(`Found ${toDelete.length} duplicate(s) to DELETE:\n`);
  toDelete.forEach(({ id, data }) => {
    console.log(`🗑️  ${id}`);
    console.log(`   Title: ${data.title}`);
    console.log(`   Stage: ${data.stage}`);
    console.log(`   Duration: ${data.estimatedDurationMinutes} min\n`);
  });

  // Delete duplicates
  const batch = db.batch();
  toDelete.forEach(({ id }) => {
    const docRef = db.collection('growth_exercises').doc(id);
    batch.delete(docRef);
  });

  await batch.commit();
  console.log(`✅ Deleted ${toDelete.length} duplicate PAC exercise(s)\n`);

  // Verify final state - check all PAC exercises
  console.log('📊 Verifying final PAC exercises...');
  const finalSnapshot = await db.collection('growth_exercises').get();
  const pacExercises = [];

  finalSnapshot.forEach(doc => {
    const data = doc.data();
    const title = data.title || '';
    if (title.toLowerCase().includes('pump') && title.toLowerCase().includes('clamp')) {
      pacExercises.push({
        id: doc.id,
        title: data.title,
        stage: data.stage,
        duration: data.estimatedDurationMinutes
      });
    }
  });

  console.log(`\nFinal PAC exercise count: ${pacExercises.length}\n`);
  pacExercises.forEach(ex => {
    console.log(`✅ ${ex.id}`);
    console.log(`   Title: ${ex.title}`);
    console.log(`   Stage: ${ex.stage}`);
    console.log(`   Duration: ${ex.duration} min\n`);
  });

  if (pacExercises.length === 1 && pacExercises[0].id === EXERCISE_TO_KEEP) {
    console.log('✅ SUCCESS! Only the correct PAC exercise remains.');
  } else if (pacExercises.length > 1) {
    console.log('⚠️  WARNING: Multiple PAC exercises still exist!');
  } else {
    console.log('❌ ERROR: No PAC exercises found!');
  }
}

deletePACDuplicate().catch(err => {
  console.error('❌ Deletion failed:', err);
  process.exit(1);
});
