#!/usr/bin/env node

/**
 * Remove All Jelq Content from Firestore
 *
 * This script removes all jelq-related content from:
 * 1. growth_exercises collection - Any exercise with "jelq" in the name or content
 * 2. ai_coach_knowledge collection - Any knowledge base entries about jelqing
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/remove-jelq-content.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

/**
 * Remove jelq exercises from growth_exercises collection
 */
async function removeJelqExercises() {
  console.log('\n📋 Searching for jelq exercises in growth_exercises collection...\n');

  try {
    const exercisesRef = db.collection('growth_exercises');
    const snapshot = await exercisesRef.get();

    if (snapshot.empty) {
      console.log('No exercises found in collection.');
      return;
    }

    const jelqExercises = [];

    // Search for jelq-related exercises
    snapshot.forEach(doc => {
      const data = doc.data();
      const searchText = JSON.stringify(data).toLowerCase();

      if (searchText.includes('jelq')) {
        jelqExercises.push({
          id: doc.id,
          title: data.title || 'Unknown',
          hasJelqInId: doc.id.toLowerCase().includes('jelq'),
          hasJelqInTitle: (data.title || '').toLowerCase().includes('jelq'),
          hasJelqInDescription: (data.description || '').toLowerCase().includes('jelq'),
          hasJelqInInstructions: (data.instructionsText || '').toLowerCase().includes('jelq')
        });
      }
    });

    if (jelqExercises.length === 0) {
      console.log('✅ No jelq exercises found in growth_exercises collection.');
      return;
    }

    console.log(`❗ Found ${jelqExercises.length} jelq-related exercise(s):\n`);
    jelqExercises.forEach(ex => {
      console.log(`  - ${ex.id}: "${ex.title}"`);
      if (ex.hasJelqInId) console.log('    → "jelq" found in document ID');
      if (ex.hasJelqInTitle) console.log('    → "jelq" found in title');
      if (ex.hasJelqInDescription) console.log('    → "jelq" found in description');
      if (ex.hasJelqInInstructions) console.log('    → "jelq" found in instructions');
      console.log('');
    });

    // Remove each jelq exercise
    console.log('🗑️  Removing jelq exercises...\n');
    const batch = db.batch();

    for (const exercise of jelqExercises) {
      const docRef = exercisesRef.doc(exercise.id);
      batch.delete(docRef);
      console.log(`  ✓ Marked for deletion: ${exercise.id}`);
    }

    // Commit the batch delete
    await batch.commit();
    console.log(`\n✅ Successfully removed ${jelqExercises.length} jelq exercise(s) from growth_exercises collection.`);

  } catch (error) {
    console.error('❌ Error removing jelq exercises:', error);
    throw error;
  }
}

/**
 * Remove jelq content from ai_coach_knowledge collection
 */
async function removeJelqKnowledge() {
  console.log('\n📚 Searching for jelq content in ai_coach_knowledge collection...\n');

  try {
    const knowledgeRef = db.collection('ai_coach_knowledge');
    const snapshot = await knowledgeRef.get();

    if (snapshot.empty) {
      console.log('No knowledge entries found in collection.');
      return;
    }

    const jelqKnowledge = [];

    // Search for jelq-related knowledge
    snapshot.forEach(doc => {
      const data = doc.data();
      const searchText = JSON.stringify(data).toLowerCase();

      if (searchText.includes('jelq')) {
        jelqKnowledge.push({
          id: doc.id,
          title: data.title || 'Unknown',
          category: data.category || 'Unknown'
        });
      }
    });

    if (jelqKnowledge.length === 0) {
      console.log('✅ No jelq content found in ai_coach_knowledge collection.');
      return;
    }

    console.log(`❗ Found ${jelqKnowledge.length} jelq-related knowledge entry/entries:\n`);
    jelqKnowledge.forEach(kb => {
      console.log(`  - ${kb.id}: "${kb.title}" (Category: ${kb.category})`);
    });

    // Remove each jelq knowledge entry
    console.log('\n🗑️  Removing jelq knowledge entries...\n');
    const batch = db.batch();

    for (const kb of jelqKnowledge) {
      const docRef = knowledgeRef.doc(kb.id);
      batch.delete(docRef);
      console.log(`  ✓ Marked for deletion: ${kb.id}`);
    }

    // Commit the batch delete
    await batch.commit();
    console.log(`\n✅ Successfully removed ${jelqKnowledge.length} jelq knowledge entry/entries from ai_coach_knowledge collection.`);

  } catch (error) {
    console.error('❌ Error removing jelq knowledge:', error);
    throw error;
  }
}

/**
 * Check routines for references to jelq exercises
 */
async function checkRoutinesForJelqReferences() {
  console.log('\n🔍 Checking routines for jelq exercise references...\n');

  try {
    const routinesRef = db.collection('routines');
    const snapshot = await routinesRef.get();

    if (snapshot.empty) {
      console.log('No routines found in collection.');
      return;
    }

    const routinesWithJelqRefs = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      const searchText = JSON.stringify(data).toLowerCase();

      if (searchText.includes('jelq')) {
        // Look for jelq method IDs in the schedule
        const jelqMethodIds = [];

        if (data.schedule && Array.isArray(data.schedule)) {
          data.schedule.forEach(day => {
            if (day.methods && Array.isArray(day.methods)) {
              day.methods.forEach(method => {
                if (method.methodId && method.methodId.toLowerCase().includes('jelq')) {
                  jelqMethodIds.push(method.methodId);
                }
              });
            }
          });
        }

        if (jelqMethodIds.length > 0) {
          routinesWithJelqRefs.push({
            id: doc.id,
            name: data.name || 'Unknown',
            jelqMethodIds: [...new Set(jelqMethodIds)] // Remove duplicates
          });
        }
      }
    });

    if (routinesWithJelqRefs.length === 0) {
      console.log('✅ No routines found with jelq exercise references.');
      return;
    }

    console.log(`⚠️  Found ${routinesWithJelqRefs.length} routine(s) with jelq exercise references:\n`);
    routinesWithJelqRefs.forEach(routine => {
      console.log(`  - ${routine.id}: "${routine.name}"`);
      console.log(`    Referenced jelq methods: ${routine.jelqMethodIds.join(', ')}`);
      console.log('');
    });

    console.log('💡 These routines reference jelq exercises that will be removed.');
    console.log('   Consider updating these routines to use alternative exercises.\n');

  } catch (error) {
    console.error('❌ Error checking routines:', error);
    throw error;
  }
}

/**
 * Main function to remove all jelq content
 */
async function main() {
  console.log('🚀 Starting Jelq Content Removal\n');
  console.log('This will remove all jelq-related content from Firestore.\n');

  try {
    // Remove from growth_exercises collection
    await removeJelqExercises();

    // Remove from ai_coach_knowledge collection
    await removeJelqKnowledge();

    // Check routines for references
    await checkRoutinesForJelqReferences();

    console.log('\n✅ Jelq content removal complete!\n');
    console.log('Next steps:');
    console.log('  1. Verify removal in Firebase Console');
    console.log('  2. Update any routines that referenced jelq exercises');
    console.log('  3. Test the app to ensure no broken references');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Failed to remove jelq content:', error);
    process.exit(1);
  }
}

// Run the removal script
main();