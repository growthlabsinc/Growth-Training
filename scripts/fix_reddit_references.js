#!/usr/bin/env node
/**
 * Fix Reddit References in PE Exercises
 * This script replaces Reddit URL references with actual exercise content
 */

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const { readFileSync } = fs;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load the PE database
const peDatabasePath = path.join(__dirname, 'extracted_data', 'pe_methods_database_enhanced.json');
const peDatabase = JSON.parse(readFileSync(peDatabasePath, 'utf8'));

// Initialize Firebase Admin SDK
function initializeFirebase() {
    const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

    if (!fs.existsSync(serviceAccountPath)) {
        console.error('❌ Service account key not found!');
        console.log('Please ensure service-account-key.json is in the scripts directory');
        process.exit(1);
    }

    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    return admin.firestore();
}

// Exercises that need fixing with proper content
const fixedExercises = {
    'ligament_stretching': {
        name: 'Ligament Stretching',
        description: 'Traditional stretching technique targeting the suspensory ligaments to expose more shaft length and improve erection angle.',
        instructions: `1. Warm up with hot wrap for 5 minutes
2. Achieve 20-40% erection (flaccid stretch)
3. Grip behind the glans firmly but gently
4. Pull straight out until you feel a good stretch
5. Hold for 30 seconds
6. Release and massage for 30 seconds
7. Repeat in different directions: up, down, left, right
8. Perform 3-5 stretches in each direction
9. Cool down with light massage`,
        duration: '10-15 minutes',
        warnings: [
            'Never stretch with full erection',
            'Stop if you feel sharp pain',
            'Grip should be firm but not painful'
        ]
    },
    'need_to_change_your_erection_angle': {
        name: 'Erection Angle Adjustment',
        description: 'Targeted stretching to modify erection angle through ligament conditioning.',
        instructions: `1. Start completely flaccid after warm-up
2. For lower angle: stretch upward against natural angle
3. For higher angle: stretch downward gently
4. Use OK grip behind glans
5. Apply steady tension for 30-60 seconds
6. Focus on feeling the stretch at the base
7. Perform 5-10 stretches per session
8. Combine with targeted kegels in stretched position
9. Track angle changes weekly with photos`,
        duration: '10-15 minutes',
        warnings: [
            'Changes take months to manifest',
            'Never force against natural anatomy',
            'Stop if numbness occurs'
        ]
    },
    'shopping_bag_hanger': {
        name: 'Shopping Bag Weight Hanger',
        description: 'DIY weight hanging method using common household items for length gains.',
        instructions: `1. Create hanger from cloth strip or sock
2. Wrap penis with cloth for protection
3. Attach hanger behind glans (not on glans)
4. Use shopping bag as weight holder
5. Start with 1-2 lbs maximum
6. Hang for 10-15 minutes per set
7. Never exceed 20 minutes continuously
8. Increase weight gradually over weeks
9. Always warm up before and cool down after`,
        duration: '10-20 minutes',
        equipment: [
            'Cloth strips or sock',
            'Shopping bag',
            'Small weights (water bottles work)'
        ],
        warnings: [
            'Start with minimal weight',
            'Check for circulation every 5 minutes',
            'Stop if glans becomes cold or numb'
        ]
    },
    'post_pump': {
        name: 'Post-Pump Routine',
        description: 'Essential routine to perform after pumping sessions to maintain gains and prevent fluid buildup.',
        instructions: `1. Remove from pump slowly to avoid injury
2. Immediately perform light jelqs (50-100 reps)
3. Use cock ring at base for 5-10 minutes
4. Massage to distribute any fluid buildup
5. Apply heat with warm wrap for 5 minutes
6. Perform slow squash jelqs if trained
7. Do 50 kegels while semi-erect
8. Finish with thorough massage
9. Monitor for excessive fluid retention`,
        duration: '10-15 minutes',
        equipment: [
            'Cock ring (optional)',
            'Warm wrap',
            'Massage oil'
        ],
        warnings: [
            'Don\'t wear cock ring too tight',
            'Watch for edema (fluid buildup)',
            'Skip if experiencing pain'
        ]
    },
    'tunica_shears_diamond_jelqs': {
        name: 'Diamond Jelqs (Tunica Shears)',
        description: 'Advanced jelqing variation that targets the tunica for girth gains through lateral pressure.',
        instructions: `1. Achieve 60-70% erection level
2. Form diamond shape with both hands
3. Place thumbs on top, fingers underneath
4. Position hands at mid-shaft
5. Apply pressure and rotate hands opposite directions
6. Create shearing force on tunica
7. Hold for 2-3 seconds per rep
8. Move along shaft in small increments
9. Perform 20-30 reps per session`,
        duration: '5-10 minutes',
        warnings: [
            'Advanced technique - master basic jelq first',
            'Use plenty of lubrication',
            'Stop if sharp pain occurs'
        ]
    }
};

// Function to check if content has Reddit references
function hasRedditReference(text) {
    if (!text) return false;
    return text.includes('reddit.com') ||
           text.includes('r/') ||
           text.includes('.jpg') ||
           text.includes('.png') ||
           text.includes('http') ||
           text.match(/^\d+\.\s*\[/); // Matches patterns like "2. [Growth Signs]"
}

// Function to fix an exercise
function fixExercise(exercise) {
    const fixed = fixedExercises[exercise.id];

    if (fixed) {
        console.log(`✅ Fixing ${exercise.id} with proper content`);
        return {
            ...exercise,
            name: fixed.name,
            description: fixed.description,
            instructions: fixed.instructions,
            duration: fixed.duration || exercise.duration,
            equipment: fixed.equipment || exercise.equipment,
            warnings: fixed.warnings || exercise.warnings
        };
    }

    // For exercises not in our fixed list, clean up any URL fragments
    let cleanedExercise = { ...exercise };

    // Clean description
    if (hasRedditReference(exercise.description)) {
        console.log(`⚠️ Cleaning description for ${exercise.id}`);
        cleanedExercise.description = exercise.description
            .replace(/https?:\/\/[^\s]+/g, '')
            .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
            .replace(/^\d+\.\s*/, '')
            .trim();

        if (cleanedExercise.description.length < 20) {
            cleanedExercise.description = `${exercise.category} exercise for PE training`;
        }
    }

    // Clean instructions
    if (hasRedditReference(exercise.instructions)) {
        console.log(`⚠️ Cleaning instructions for ${exercise.id}`);
        // If instructions are just a URL or image reference, provide generic instructions
        if (exercise.instructions.includes('.jpg') || exercise.instructions.includes('.png')) {
            cleanedExercise.instructions = `1. Warm up properly before starting
2. Follow proper form and technique
3. Start with lighter intensity
4. Gradually increase over time
5. Monitor for any discomfort
6. Cool down after exercise`;
        } else {
            cleanedExercise.instructions = exercise.instructions
                .replace(/https?:\/\/[^\s]+/g, '')
                .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
                .trim();
        }
    }

    return cleanedExercise;
}

// Main function to update Firebase
async function updateExercisesInFirebase() {
    console.log('🚀 Starting Reddit reference fixes...\n');

    const db = initializeFirebase();
    const collection = db.collection('growth_exercises');

    let fixedCount = 0;
    let errorCount = 0;

    for (const exercise of peDatabase.exercises) {
        // Check if this exercise needs fixing
        if (hasRedditReference(exercise.description) ||
            hasRedditReference(exercise.instructions) ||
            fixedExercises[exercise.id]) {

            try {
                const fixedExercise = fixExercise(exercise);
                const docId = exercise.id.toLowerCase().replace(/[^a-z0-9_]/g, '_');

                // Update in Firebase
                await collection.doc(docId).update({
                    title: fixedExercise.name,
                    description: fixedExercise.description,
                    instructionsText: fixedExercise.instructions,
                    estimatedDurationMinutes: parseInt(fixedExercise.duration) || 15,
                    equipmentNeeded: fixedExercise.equipment || [],
                    safetyNotes: fixedExercise.warnings ? fixedExercise.warnings.join('. ') + '.' : 'Always monitor for discomfort.',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                console.log(`✅ Updated: ${fixedExercise.name}`);
                fixedCount++;
            } catch (error) {
                console.error(`❌ Error updating ${exercise.name}: ${error.message}`);
                errorCount++;
            }
        }
    }

    console.log('\n=================');
    console.log('📊 Update Summary');
    console.log('=================');
    console.log(`Fixed: ${fixedCount} exercises`);
    console.log(`Errors: ${errorCount}`);
    console.log('\n✅ Reddit references have been replaced with proper content!');
}

// Run the update
updateExercisesInFirebase()
    .then(() => process.exit(0))
    .catch(error => {
        console.error('Failed:', error);
        process.exit(1);
    });