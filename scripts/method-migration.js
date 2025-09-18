#!/usr/bin/env node
/**
 * Migration Script: Re-Define and Re-Classify Core Growth Methods (Epic 13, Story 13.1)
 *
 * This script updates the `growthMethods` collection in Firestore to include the new
 * `classification` field, ensures each method matches the definitive list from the
 * documentation, and removes outdated methods.
 *
 * Usage:
 *   1. Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account json file.
 *   2. Run `node scripts/method-migration.js --dry-run` to preview changes.
 *   3. Run `node scripts/method-migration.js` to execute.
 */

/* eslint-disable no-console */

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import * as fs from 'fs';
import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';

// ----------------- CONFIGURATION -----------------

// Definitive methods list (could be loaded from JSON or YAML instead)
const definitiveMethods = [
  {
    id: 'angion_method_1_0',
    title: 'Angion Method 1.0',
    classification: 'Beginner',
    stage: 1,
    methodDescription:
      'Angion Method 1.0 focuses on manipulating the venous side of the Bulbo-Dorsal Circuit. Users apply alternating thumb strokes along the dorsal vein cluster to increase venous return and stimulate vascular growth. It is intended for men who can achieve an erection unaided but cannot yet palpate a strong arterial pulse.',
    instructionsText:
      '1. Obtain an erection.\n2. Apply a silicone-based lubricant along the dorsal center line.\n3. Place both thumbs on the dorsal side just below the glans.\n4. Depress the vein cluster and drag the first thumb toward the base.\n5. As the first thumb reaches mid-shaft, start the same motion with the other thumb, creating an alternating rhythm.\n6. Start slowly, then gradually increase speed; aim for 30-minute sessions.\n7. Graduate when you can maintain a full 30-minute session with a palpable dorsal artery pulse.',
    equipmentNeeded: ['Silicone or water-based lubricant'],
    estimatedDurationMinutes: 30,
    progressionCriteriaText:
      'Graduate when you can maintain a 30-minute AM 1.0 session and easily palpate a pulse in both dorsal arteries.'
  },
  {
    id: 'angion_method_2_0',
    title: 'Angion Method 2.0',
    classification: 'Foundation',
    stage: 2,
    methodDescription:
      'Angion Method 2.0 shifts focus to the arterial side of the Bulbo-Dorsal Circuit. Using a two-hand technique (one at the base, one at the glans), users rhythmically push blood into the glans to increase arterial flow and shear stress.',
    instructionsText:
      '1. Obtain an erection.\n2. Grip the lower shaft with thumb + first two digits.\n3. Grip the glans with the other hand.\n4. Lightly squeeze the shaft hand to push blood into the glans, then release.\n5. Immediately squeeze the glans and feel blood rush back through dorsal veins.\n6. Repeat in rapid succession, building a rhythmic pump.\n7. Avoid excessive kegels to prevent pelvic-floor overtraining.\n8. Session length: up to 30 minutes.\n9. Graduate when you can perform Vascion technique for at least 5 minutes.',
    equipmentNeeded: ['Lubricant (optional)'],
    estimatedDurationMinutes: 30,
    progressionCriteriaText:
      'Ready to progress when arterial pulse is strong and Corpora Spongiosum no longer flattens during sessions.'
  },
  {
    id: 'angion_method_2_5',
    title: 'Angion Method 2.5 (JELQ 2.0)',
    classification: 'Intermediate',
    stage: 3,
    methodDescription:
      'Jelq 2.0 is an intermediary stage for trainees whose Corpora Spongiosum collapses during Vascion attempts. The partial-grip jelq targets the ventral tissue to further develop arterial capacity before Vascion.',
    instructionsText:
      '1. Obtain an erection and lubricate the shaft.\n2. Rotate hand so thumb points downward; use first two digits to depress the Corpora Spongiosum.\n3. Allow dorsal shaft to rest lightly against palm.\n4. Pull hand from base toward glans, concentrating pressure on ventral side.\n5. Start with slow strokes, then increase speed as vascular networks dilate.\n6. Session length: 20-30 minutes.\n7. Test Vascion occasionally; once you can sustain 5 minutes of Vascion, move on.',
    equipmentNeeded: ['Lubricant'],
    estimatedDurationMinutes: 30,
    progressionCriteriaText:
      'Graduate when you can sustain 5 minutes of Vascion without Corpora Spongiosum collapse.'
  },
  {
    id: 'vascion',
    title: 'Angion Method 3.0 - Vascion',
    classification: 'Expert',
    stage: 4,
    methodDescription:
      'Vascion represents the peak manual Angion technique, driving supra-physiological engorgement through alternating middle-finger strokes along the lubricated Corpora Spongiosum while lying on the back. Short-lived priapism and extreme expansion are common.',
    instructionsText:
      '1. Lie on your back and lubricate the full length of the Corpora Spongiosum.\n2. Extend middle fingers of both hands.\n3. Depress the ventral ridge and stroke upward in an alternating pattern, keeping a swift cadence.\n4. Aim for session duration up to 30 minutes.\n5. Expect occasional flat CS when first starting; this subsides with adaptation.',
    equipmentNeeded: ['Lubricant'],
    estimatedDurationMinutes: 30,
    progressionCriteriaText:
      'Graduate when you can complete consistent 30-minute Vascion sessions; proceed to Angio-Wheel if desired.'
  },
  {
    id: 'angio_wheel',
    title: 'Angio-Wheel',
    classification: 'Master',
    stage: 5,
    methodDescription:
      'The Angio-Wheel device enables unmatched localized vascular stress, exceeding what manual methods can achieve. Intended only for advanced users with extensive Vascion experience.',
    instructionsText:
      '1. Mount the Angio-Wheel device as per manufacturer instructions.\n2. Perform controlled rolling passes along the Corpora Spongiosum, maintaining steady pressure.\n3. Limit sessions to 20-30 minutes; monitor for edema.\n4. Use a 1-on-1-off schedule for recovery.\n5. Discontinue if pain or abnormal discoloration occurs.',
    equipmentNeeded: ['Angio-Wheel device', 'Lubricant'],
    estimatedDurationMinutes: 30,
    progressionCriteriaText:
      'Mastery entails maintaining vascular health and comfort while using the Angio-Wheel for full 30-minute sessions.'
  },
  {
    id: 'angio_pumping',
    title: 'Angio Pumping',
    classification: 'Prerequisite',
    stage: 0,
    methodDescription:
      'Angio Pumping employs fluctuating vacuum pressure combined with an ACE bandage wrap to promote vascular health for individuals unable to achieve an erection unassisted.',
    instructionsText:
      '1. Apply a light ACE bandage wrap\n2. Use a quick-release vacuum pump to cycle pressure (5–10 seconds on, 5–10 seconds off)\n3. Begin with 5-minute sessions and gradually work up to 10 minutes, aiming for 30 minutes over time.',
    equipmentNeeded: ['Quick-release vacuum pump', 'ACE bandage', 'Lubricant'],
    estimatedDurationMinutes: 10,
    progressionCriteriaText:
      'Graduate when you can maintain an erection for ≥15 minutes without devices or vaso-active substances.'
  },
];

// Ensure every method has at least a placeholder description/instructions
for (const m of definitiveMethods) {
  if (!m.methodDescription) {
    m.methodDescription = `${m.title} – full description coming soon.`;
  }
  if (!m.instructionsText) {
    m.instructionsText = 'Detailed instructions will be added soon.';
  }
}

// -------------------------------------------------

const argv = yargs(hideBin(process.argv))
  .option('dry-run', {
    alias: 'd',
    type: 'boolean',
    description: 'Preview changes without writing to Firestore',
  })
  .help()
  .argv;

// Initialize Firebase Admin
initializeApp({});
const db = getFirestore();

async function runMigration() {
  console.log('\nStarting Growth Methods migration...');
  const collectionRef = db.collection('growthMethods');

  // Fetch existing methods (skip when dry-run to avoid requiring credentials)
  let existingIds = [];
  if (!argv['dry-run']) {
    const snapshot = await collectionRef.get();
    existingIds = snapshot.docs.map((doc) => doc.id);
  }

  // Upsert definitive methods
  for (const method of definitiveMethods) {
    const docRef = collectionRef.doc(method.id);
    if (argv['dry-run']) {
      console.log(`[DRY-RUN] Upserting ${method.id} with classification=${method.classification}`);
    } else {
      const payload = {
        classification: method.classification,
        stage: method.stage,
        title: method.title,
        updatedAt: new Date(),
      };

      // Include rich fields if present
      if (method.methodDescription) payload.description = method.methodDescription;
      if (method.instructionsText) payload.instructionsText = method.instructionsText;
      if (method.equipmentNeeded) payload.equipmentNeeded = method.equipmentNeeded;
      if (method.estimatedDurationMinutes) payload.estimatedDurationMinutes = method.estimatedDurationMinutes;
      if (method.progressionCriteriaText) payload.progressionCriteriaText = method.progressionCriteriaText;

      await docRef.set(payload, { merge: true });
      console.log(`Upserted ${method.id}`);
    }
  }

  if (!argv['dry-run']) {
    // Remove outdated methods only when not dry-run
    const definitiveIds = definitiveMethods.map((m) => m.id);
    const obsoleteIds = existingIds.filter((id) => !definitiveIds.includes(id));
    for (const id of obsoleteIds) {
      await collectionRef.doc(id).delete();
      console.log(`Deleted obsolete method ${id}`);
    }
  }

  console.log('\nMigration complete.');
}

runMigration().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
}); 