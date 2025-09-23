#!/usr/bin/env node
/**
 * Verify Fixed PE Exercises in Firebase
 */

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const { readFileSync } = fs;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
function initializeFirebase() {
    const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

    if (!fs.existsSync(serviceAccountPath)) {
        console.error('❌ Service account key not found!');
        process.exit(1);
    }

    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    return admin.firestore();
}

// Exercises to verify
const exercisesToCheck = [
    'ligament_stretching',
    'need_to_change_your_erection_angle',
    'shopping_bag_hanger',
    'post_pump',
    'tunica_shears_diamond_jelqs'
];

async function verifyExercises() {
    console.log('🔍 Verifying fixed exercises in Firebase...\n');

    const db = initializeFirebase();
    const collection = db.collection('growth_exercises');

    for (const exerciseId of exercisesToCheck) {
        const docId = exerciseId.toLowerCase().replace(/[^a-z0-9_]/g, '_');

        try {
            const doc = await collection.doc(docId).get();

            if (doc.exists) {
                const data = doc.data();
                console.log(`\n📋 ${data.title || exerciseId}`);
                console.log('='.repeat(50));

                // Check for Reddit references
                const hasReddit = (text) => text && (
                    text.includes('reddit.com') ||
                    text.includes('r/') ||
                    text.includes('.jpg') ||
                    text.includes('.png') ||
                    text.includes('http')
                );

                // Check description
                if (hasReddit(data.description)) {
                    console.log(`  ❌ Description still has Reddit references`);
                } else {
                    console.log(`  ✅ Description: ${data.description.substring(0, 60)}...`);
                }

                // Check instructions
                if (hasReddit(data.instructionsText)) {
                    console.log(`  ❌ Instructions still have Reddit references`);
                } else {
                    const firstLine = data.instructionsText.split('\n')[0];
                    console.log(`  ✅ Instructions start: ${firstLine}`);
                }

                // Check other fields
                console.log(`  ✅ Duration: ${data.estimatedDurationMinutes} minutes`);
                console.log(`  ✅ Equipment: ${data.equipmentNeeded.length > 0 ? data.equipmentNeeded.join(', ') : 'None'}`);
                console.log(`  ✅ Has safety notes: ${data.safetyNotes ? 'Yes' : 'No'}`);

            } else {
                console.log(`❌ Document ${docId} not found`);
            }
        } catch (error) {
            console.error(`❌ Error checking ${exerciseId}: ${error.message}`);
        }
    }

    console.log('\n' + '='.repeat(50));
    console.log('✅ Verification complete!');
}

// Run verification
verifyExercises()
    .then(() => process.exit(0))
    .catch(error => {
        console.error('Verification failed:', error);
        process.exit(1);
    });