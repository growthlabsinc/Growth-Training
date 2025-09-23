#!/usr/bin/env node
/**
 * Update PE Exercises in Firebase with Complete Document Structure
 * This script updates the existing PE exercises to match the proper Firestore document structure
 */

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const { readFileSync } = fs;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load the enhanced PE database
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

// Convert PE exercise to complete Firestore document structure
function convertToCompleteFirestoreDoc(exercise) {
    // Determine stage based on difficulty
    const stage = exercise.difficulty === 'Beginner' ? 1 :
                  exercise.difficulty === 'Intermediate' ? 2 : 3;

    // Clean up instructions
    let instructions = exercise.instructions || '';
    instructions = instructions.replace(/\\n/g, '\n').replace(/\\"/g, '"');

    // Ensure equipment is an array
    const equipment = Array.isArray(exercise.equipment) ?
                     exercise.equipment :
                     exercise.equipment ? [exercise.equipment] : [];

    // Parse duration
    let durationMinutes = 15;
    if (exercise.duration) {
        const match = exercise.duration.match(/(\d+)/);
        if (match) {
            durationMinutes = parseInt(match[1]);
        }
    }

    // Create benefits array
    const benefits = exercise.benefits || [];
    if (benefits.length === 0) {
        // Generate benefits based on category
        switch(exercise.category) {
            case 'Length':
                benefits.push('Increased length potential');
                benefits.push('Improved ligament flexibility');
                benefits.push('Enhanced tissue expansion');
                break;
            case 'Girth':
                benefits.push('Increased girth development');
                benefits.push('Improved vascular expansion');
                benefits.push('Enhanced tissue density');
                break;
            case 'EQ':
                benefits.push('Better erection quality');
                benefits.push('Improved blood flow');
                benefits.push('Enhanced vascular health');
                break;
            case 'Stamina':
                benefits.push('Increased sexual stamina');
                benefits.push('Better control');
                benefits.push('Enhanced endurance');
                break;
        }
    }

    // Create categories array
    const categories = [exercise.category];
    if (exercise.difficulty) {
        categories.push(exercise.difficulty);
    }
    categories.push('PE Training');

    // Create steps array from instructions
    const steps = [];
    const instructionLines = instructions.split(/\d+\.\s+/).filter(line => line.trim());

    instructionLines.forEach((instruction, index) => {
        if (instruction.trim()) {
            steps.push({
                stepNumber: index + 1,
                title: `Step ${index + 1}`,
                description: instruction.trim(),
                duration: 60, // Default 1 minute per step
                tips: [],
                warnings: []
            });
        }
    });

    // If no steps were created, create a single step with all instructions
    if (steps.length === 0 && instructions.trim()) {
        steps.push({
            stepNumber: 1,
            title: exercise.name || 'Main Exercise',
            description: instructions,
            duration: durationMinutes * 60, // Convert to seconds
            tips: exercise.tips || [],
            warnings: exercise.warnings || []
        });
    }

    // Create progression criteria
    const progressionCriteria = {
        minimumSessions: stage === 1 ? 10 : stage === 2 ? 20 : 30,
        consistencyDays: stage === 1 ? 7 : stage === 2 ? 14 : 21,
        keyIndicators: [
            'Comfortable with current intensity',
            'No pain or discomfort',
            'Consistent technique mastery'
        ],
        readinessMarkers: []
    };

    // Add readiness markers based on category
    switch(exercise.category) {
        case 'Length':
            progressionCriteria.readinessMarkers = [
                'Improved flexibility',
                'Less resistance during stretches',
                'Visible length improvements'
            ];
            break;
        case 'Girth':
            progressionCriteria.readinessMarkers = [
                'Better expansion during exercises',
                'Improved vascular visibility',
                'Noticeable girth improvements'
            ];
            break;
        case 'EQ':
            progressionCriteria.readinessMarkers = [
                'Stronger erections',
                'Better blood flow',
                'Improved stamina'
            ];
            break;
    }

    // Create timer configuration
    const timerConfig = {
        totalDuration: durationMinutes * 60,
        hasRest: true,
        restBetweenSets: 60,
        intervals: []
    };

    // Add intervals based on exercise type
    if (exercise.id === 'kegels' || exercise.id === 'reverse_kegels') {
        timerConfig.intervals = [
            {
                name: exercise.id === 'kegels' ? 'Contract' : 'Push',
                duration: 5,
                type: 'work'
            },
            {
                name: 'Relax',
                duration: 5,
                type: 'rest'
            }
        ];
    } else if (steps.length > 0) {
        // Create intervals from steps
        steps.forEach(step => {
            timerConfig.intervals.push({
                name: step.title,
                duration: step.duration,
                type: 'work'
            });
        });
    } else {
        // Default single interval
        timerConfig.intervals = [{
            name: 'Main Exercise',
            duration: durationMinutes * 60,
            type: 'work'
        }];
    }

    // Build the complete document
    const doc = {
        // Core fields
        id: exercise.id.toLowerCase().replace(/[^a-z0-9_]/g, '_'),
        title: exercise.name || exercise.title,
        description: exercise.description || `${exercise.category} exercise for PE training`,
        classification: exercise.difficulty || 'Beginner',
        stage: stage,

        // Instructions and steps
        instructionsText: instructions || 'Follow the step-by-step guide below.',
        steps: steps,

        // Benefits and categories
        benefits: benefits,
        categories: categories,

        // Equipment and duration
        equipmentNeeded: equipment,
        estimatedDurationMinutes: durationMinutes,

        // Safety
        safetyNotes: exercise.warnings && exercise.warnings.length > 0 ?
                    exercise.warnings.join('. ') + '.' :
                    'Always monitor for discomfort. Stop if pain occurs.',

        // Progression
        progressionCriteria: progressionCriteria,

        // Related methods (to be filled based on category)
        relatedMethods: [],

        // Timer configuration
        timerConfig: timerConfig,

        // Metadata
        isFeatured: exercise.community_rating > 100,
        communityRating: exercise.community_rating || 0,
        sourceType: exercise.source_type || 'reddit',
        sourceUrl: exercise.source_url || '',

        // Timestamps
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        extractedDate: exercise.extracted_date || new Date().toISOString(),

        // Migration flag
        migratedFromPE: true,
        version: 2 // Version 2 with complete structure
    };

    // Add related methods based on category
    const allExercises = peDatabase.exercises;
    const sameCategory = allExercises
        .filter(ex => ex.category === exercise.category && ex.id !== exercise.id)
        .slice(0, 3)
        .map(ex => ex.id.toLowerCase().replace(/[^a-z0-9_]/g, '_'));

    doc.relatedMethods = sameCategory;

    return doc;
}

// Rename existing collection and create new one
async function migrateCollection() {
    console.log('🚀 Starting PE exercises structure update...\n');

    const db = initializeFirebase();

    // First, delete old collection documents
    console.log('📦 Cleaning up old growth_methods collection...');
    const oldCollection = db.collection('growth_methods');
    const oldSnapshot = await oldCollection.where('migratedFromPE', '==', true).get();

    const deleteBatch = db.batch();
    oldSnapshot.forEach(doc => {
        deleteBatch.delete(doc.ref);
    });

    if (oldSnapshot.size > 0) {
        await deleteBatch.commit();
        console.log(`✅ Deleted ${oldSnapshot.size} old PE exercises from growth_methods\n`);
    }

    // Now create new collection with proper structure
    const newCollection = db.collection('growth_exercises');
    const batch = db.batch();

    // Process each exercise
    console.log('📤 Uploading PE exercises with complete structure...\n');
    const exercises = peDatabase.exercises;
    let successCount = 0;
    let errorCount = 0;

    for (const exercise of exercises) {
        try {
            const docId = exercise.id.toLowerCase().replace(/[^a-z0-9_]/g, '_');
            const docData = convertToCompleteFirestoreDoc(exercise);

            // Create document in new collection
            const docRef = newCollection.doc(docId);
            batch.set(docRef, docData);

            console.log(`✅ ${exercise.name} (${exercise.category}) - ${docData.steps.length} steps`);
            successCount++;
        } catch (error) {
            console.error(`❌ Failed to process ${exercise.name}: ${error.message}`);
            errorCount++;
        }
    }

    // Commit the batch
    console.log('\n💾 Committing batch upload...');
    try {
        await batch.commit();
        console.log('✅ Batch committed successfully!\n');
    } catch (error) {
        console.error('❌ Batch commit failed:', error);
        return;
    }

    // Create summary document
    const summaryDoc = db.collection('migration_reports').doc(`pe_structure_update_${Date.now()}`);
    await summaryDoc.set({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        totalExercises: exercises.length,
        successCount: successCount,
        errorCount: errorCount,
        collectionName: 'growth_exercises',
        documentVersion: 2,
        categories: peDatabase.metadata.categories,
        difficulties: peDatabase.metadata.difficulties,
        type: 'pe_exercises_structure_update'
    });

    // Print summary
    console.log('='.repeat(50));
    console.log('📊 UPDATE SUMMARY');
    console.log('='.repeat(50));
    console.log(`Collection: growth_exercises`);
    console.log(`Total exercises: ${exercises.length}`);
    console.log(`Successfully uploaded: ${successCount}`);
    console.log(`Failed: ${errorCount}`);
    console.log('\nCategory distribution:');
    Object.entries(peDatabase.metadata.categories).forEach(([cat, count]) => {
        console.log(`  ${cat}: ${count}`);
    });
    console.log('\n✅ PE exercises uploaded with complete structure!');
    console.log('📍 New collection: growth_exercises');
}

// Verify the new structure
async function verifyStructure() {
    console.log('\n🔍 Verifying new document structure...');
    const db = initializeFirebase();
    const collection = db.collection('growth_exercises');

    // Get one document to verify structure
    const snapshot = await collection.limit(1).get();

    if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        const data = doc.data();

        console.log('\n📋 Document Structure Check:');
        console.log(`  ✅ ID: ${doc.id}`);
        console.log(`  ✅ Title: ${data.title}`);
        console.log(`  ✅ Steps: ${data.steps ? data.steps.length : 0} steps`);
        console.log(`  ✅ Benefits: ${data.benefits ? data.benefits.length : 0} benefits`);
        console.log(`  ✅ Timer Config: ${data.timerConfig ? 'Present' : 'Missing'}`);
        console.log(`  ✅ Progression Criteria: ${data.progressionCriteria ? 'Present' : 'Missing'}`);
        console.log(`  ✅ Categories: ${data.categories ? data.categories.join(', ') : 'None'}`);

        // Check all required fields
        const requiredFields = [
            'id', 'title', 'description', 'classification', 'stage',
            'instructionsText', 'steps', 'benefits', 'categories',
            'equipmentNeeded', 'estimatedDurationMinutes', 'safetyNotes',
            'progressionCriteria', 'timerConfig', 'isFeatured'
        ];

        console.log('\n🔍 Required Fields Check:');
        requiredFields.forEach(field => {
            const present = data[field] !== undefined;
            console.log(`  ${present ? '✅' : '❌'} ${field}`);
        });
    } else {
        console.log('❌ No documents found in growth_exercises collection');
    }
}

// Parse command line arguments
const command = process.argv[2];

switch (command) {
    case 'migrate':
        migrateCollection()
            .then(() => verifyStructure())
            .then(() => process.exit(0))
            .catch(error => {
                console.error('Migration failed:', error);
                process.exit(1);
            });
        break;

    case 'verify':
        verifyStructure()
            .then(() => process.exit(0))
            .catch(error => {
                console.error('Verification failed:', error);
                process.exit(1);
            });
        break;

    default:
        console.log('PE Exercises Structure Update Tool');
        console.log('====================================');
        console.log('\nUsage: node update_pe_exercises_structure.js <command>');
        console.log('\nCommands:');
        console.log('  migrate  - Migrate and update all PE exercises to new structure');
        console.log('  verify   - Verify the document structure');
        console.log('\nExample:');
        console.log('  node update_pe_exercises_structure.js migrate');
}