#!/usr/bin/env node

/**
 * Cleanup Duplicate PE Exercises from Firestore
 *
 * This script removes old/duplicate exercise entries that were created
 * during development iterations. Only the current stage-corrected versions
 * should remain.
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/cleanup-duplicate-exercises.js
 */

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Exercise IDs to DELETE (old/duplicate versions)
const EXERCISES_TO_DELETE = [
  // Old PAC version with wrong naming convention
  'pump_assisted_clamping_pac',

  // Old PAC version from before stage corrections (was incorrectly stage 1)
  'stage1_pump_assisted_clamping',

  // Add any other old stage1 versions that should now be stage 2 or 3
  // (if they still exist in Firestore from before the stage correction)
  'stage1_rapid_interval_pumping',
  'stage1_static_pumping',
  'stage1_vanilla_interval_pumping',
  'stage1_soft_clamping',
  'stage1_shopping_bag_hanger',
  'stage1_vacuum_extending',
  'stage1_shock_loading',
  'stage1_bundles_with_pumping',
  'stage1_timed_pressure_hold'
];

// Expected final exercise IDs (current correct versions)
const EXPECTED_EXERCISES = [
  // Stage 1 (Beginner - 6 exercises)
  'stage1_basic_manual_stretch',
  'stage1_modified_jelq',
  'stage1_timed_squash',
  'stage1_milking_eq',
  'stage1_all_day_stretcher',
  'stage1_heat_application',

  // Stage 2 (Intermediate - 7 exercises)
  'stage2_timed_pressure_hold',
  'stage2_static_pumping',
  'stage2_vanilla_interval_pumping',
  'stage2_shopping_bag_hanger',
  'stage2_vacuum_extending',
  'stage2_shock_loading',

  // Stage 3 (Advanced - 4 exercises)
  'stage3_rapid_interval_pumping',
  'stage3_soft_clamping',
  'stage3_pump_assisted_clamping',
  'stage3_bundles_with_pumping'
];

async function cleanupDuplicates() {
  console.log('🧹 Starting Exercise Cleanup\n');

  // First, check what exists
  console.log('📋 Checking current exercises in Firestore...');
  const snapshot = await db.collection('growth_exercises').get();
  const existingIds = [];
  snapshot.forEach(doc => {
    existingIds.push(doc.id);
  });

  console.log(`Found ${existingIds.length} total exercises\n`);

  // Find exercises to delete that actually exist
  const toDelete = EXERCISES_TO_DELETE.filter(id => existingIds.includes(id));

  if (toDelete.length === 0) {
    console.log('✅ No duplicates found to clean up!');
    return;
  }

  console.log(`⚠️  Found ${toDelete.length} duplicate/old exercises to remove:\n`);

  // Show what will be deleted
  for (const id of toDelete) {
    const doc = await db.collection('growth_exercises').doc(id).get();
    const data = doc.data();
    console.log(`  🗑️  ${id}`);
    console.log(`      Title: ${data?.title}`);
    console.log(`      Stage: ${data?.stage}`);
    console.log('');
  }

  // Delete duplicates
  console.log('Deleting duplicates...');
  const batch = db.batch();
  toDelete.forEach(id => {
    const docRef = db.collection('growth_exercises').doc(id);
    batch.delete(docRef);
  });

  await batch.commit();
  console.log(`✅ Deleted ${toDelete.length} duplicate exercises\n`);

  // Verify final state
  console.log('📊 Verifying final exercise library...');
  const finalSnapshot = await db.collection('growth_exercises').get();
  const finalIds = [];
  const finalByStage = { 1: [], 2: [], 3: [] };

  finalSnapshot.forEach(doc => {
    finalIds.push(doc.id);
    const stage = doc.data().stage;
    if (finalByStage[stage]) {
      finalByStage[stage].push(doc.id);
    }
  });

  console.log(`\nFinal count: ${finalIds.length} exercises`);
  console.log(`  Stage 1: ${finalByStage[1].length} exercises`);
  console.log(`  Stage 2: ${finalByStage[2].length} exercises`);
  console.log(`  Stage 3: ${finalByStage[3].length} exercises`);

  // Check for any missing expected exercises
  const missing = EXPECTED_EXERCISES.filter(id => !finalIds.includes(id));
  if (missing.length > 0) {
    console.log(`\n⚠️  WARNING: ${missing.length} expected exercises are missing:`);
    missing.forEach(id => console.log(`  - ${id}`));
  }

  // Check for any unexpected exercises
  const unexpected = finalIds.filter(id => !EXPECTED_EXERCISES.includes(id));
  if (unexpected.length > 0) {
    console.log(`\n⚠️  WARNING: ${unexpected.length} unexpected exercises found:`);
    unexpected.forEach(id => console.log(`  - ${id}`));
  }

  if (missing.length === 0 && unexpected.length === 0) {
    console.log('\n✅ Exercise library is clean and complete!');
    console.log('   All 16 expected exercises present, no duplicates.');
  }
}

cleanupDuplicates().catch(err => {
  console.error('❌ Cleanup failed:', err);
  process.exit(1);
});
