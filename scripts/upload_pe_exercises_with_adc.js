#!/usr/bin/env node
/**
 * Upload PE Exercises to Firebase using Application Default Credentials
 * Uses gcloud auth instead of service account key
 */

import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load the enhanced PE database
const peDatabasePath = path.join(__dirname, 'extracted_data', 'pe_methods_database_enhanced.json');
const peDatabase = JSON.parse(readFileSync(peDatabasePath, 'utf8'));

// Initialize Firebase Admin SDK with Application Default Credentials
function initializeFirebase() {
    console.log('🔐 Initializing Firebase with Application Default Credentials...\n');
    console.log('Make sure you have run:');
    console.log('  gcloud auth application-default login');
    console.log('  gcloud config set project growth-training-app\n');

    try {
        // Initialize with ADC - no service account key needed
        admin.initializeApp({
            projectId: 'growth-training-app'
        });

        console.log('✅ Firebase initialized with ADC\n');
        return admin.firestore();
    } catch (error) {
        console.error('❌ Failed to initialize Firebase:', error.message);
        console.log('\n📋 To fix this:');
        console.log('1. Install gcloud: brew install --cask google-cloud-sdk');
        console.log('2. Login: gcloud auth application-default login');
        console.log('3. Set project: gcloud config set project growth-training-app');
        process.exit(1);
    }
}

// Convert PE exercise to Firestore document format
function convertToFirestoreDoc(exercise) {
    // Map exercise format to GrowthMethod Firebase schema
    const stage = exercise.difficulty === 'Beginner' ? 1 :
                  exercise.difficulty === 'Intermediate' ? 2 : 3;

    // Clean up instructions - remove escape characters
    let instructions = exercise.instructions || '';
    instructions = instructions.replace(/\\n/g, '\n').replace(/\\"/g, '"');

    // Ensure equipment is an array
    const equipment = Array.isArray(exercise.equipment) ?
                     exercise.equipment :
                     exercise.equipment ? [exercise.equipment] : [];

    // Parse duration to get minutes
    let durationMinutes = 15; // default
    if (exercise.duration) {
        const match = exercise.duration.match(/(\d+)/);
        if (match) {
            durationMinutes = parseInt(match[1]);
        }
    }

    // Build the Firestore document
    const doc = {
        // Required fields from GrowthMethod model
        stage: stage,
        classification: exercise.difficulty || 'Beginner',
        title: exercise.name || exercise.title,
        description: exercise.description || '',
        methodDescription: exercise.description || '',
        instructionsText: instructions,
        instructions_text: instructions, // Both formats for compatibility

        // Optional fields
        visualPlaceholderUrl: null,
        visual_placeholder_url: null,
        equipmentNeeded: equipment,
        equipment_needed: equipment,
        estimatedDurationMinutes: durationMinutes,
        estimated_duration_minutes: durationMinutes,
        categories: [exercise.category, exercise.difficulty],
        isFeatured: false,
        is_featured: false,

        // Safety and warnings
        safetyNotes: exercise.warnings && exercise.warnings.length > 0 ?
                    exercise.warnings.join('. ') :
                    'Always monitor for discomfort',
        safety_notes: exercise.warnings && exercise.warnings.length > 0 ?
                     exercise.warnings.join('. ') :
                     'Always monitor for discomfort',

        // Benefits
        benefits: exercise.benefits || [],

        // Prerequisites
        prerequisites: exercise.prerequisites || [],

        // PE specific fields
        communityRating: exercise.community_rating || 0,
        community_rating: exercise.community_rating || 0,
        sourceType: exercise.source_type || 'manual',
        source_type: exercise.source_type || 'manual',
        sourceUrl: exercise.source_url || '',
        source_url: exercise.source_url || '',

        // Timestamps
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        extractedDate: exercise.extracted_date || new Date().toISOString(),

        // Migration metadata
        migratedFromPE: true,
        originalId: exercise.id
    };

    // Add timer configuration for certain exercises
    if (exercise.id === 'kegels' || exercise.id === 'reverse_kegels') {
        doc.timerConfig = {
            recommendedDurationSeconds: 5,
            recommended_duration_seconds: 5,
            isCountdown: false,
            is_countdown: false,
            hasIntervals: true,
            has_intervals: true,
            intervals: [
                {
                    name: exercise.id === 'kegels' ? 'Contract' : 'Push',
                    durationSeconds: 5,
                    duration_seconds: 5
                },
                {
                    name: 'Relax',
                    durationSeconds: 5,
                    duration_seconds: 5
                }
            ]
        };
    }

    return doc;
}

// Main upload function
async function uploadExercises() {
    console.log('🚀 Starting PE exercises upload to Firebase...\n');

    const db = initializeFirebase();
    const collection = db.collection('growth_methods');
    const batch = db.batch();

    // First, backup existing methods
    console.log('📦 Backing up existing methods...');
    const existingSnapshot = await collection.get();
    const backup = [];

    existingSnapshot.forEach(doc => {
        backup.push({
            id: doc.id,
            data: doc.data()
        });
    });

    // Save backup
    if (backup.length > 0) {
        const backupDoc = db.collection('migration_backups').doc(`pe_upload_backup_${Date.now()}`);
        await backupDoc.set({
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            count: backup.length,
            data: backup,
            type: 'pe_exercises_upload'
        });
        console.log(`✅ Backed up ${backup.length} existing methods\n`);
    }

    // Process each exercise
    console.log('📤 Uploading PE exercises...\n');
    const exercises = peDatabase.exercises;
    let successCount = 0;
    let errorCount = 0;

    for (const exercise of exercises) {
        try {
            const docId = exercise.id.toLowerCase().replace(/[^a-z0-9_]/g, '_');
            const docData = convertToFirestoreDoc(exercise);

            // Use set with merge to preserve any existing data
            const docRef = collection.doc(docId);
            batch.set(docRef, docData, { merge: true });

            console.log(`✅ ${exercise.name} (${exercise.category})`);
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

    // Upload summary statistics
    const summaryDoc = db.collection('migration_reports').doc(`pe_upload_${Date.now()}`);
    await summaryDoc.set({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        totalExercises: exercises.length,
        successCount: successCount,
        errorCount: errorCount,
        categories: peDatabase.metadata.categories,
        difficulties: peDatabase.metadata.difficulties,
        type: 'pe_exercises_upload'
    });

    // Print summary
    console.log('='.repeat(50));
    console.log('📊 UPLOAD SUMMARY');
    console.log('='.repeat(50));
    console.log(`Total exercises: ${exercises.length}`);
    console.log(`Successfully uploaded: ${successCount}`);
    console.log(`Failed: ${errorCount}`);
    console.log('\nCategory distribution:');
    Object.entries(peDatabase.metadata.categories).forEach(([cat, count]) => {
        console.log(`  ${cat}: ${count}`);
    });
    console.log('\nDifficulty distribution:');
    Object.entries(peDatabase.metadata.difficulties).forEach(([diff, count]) => {
        console.log(`  ${diff}: ${count}`);
    });
    console.log('\n✅ PE exercises uploaded to Firebase successfully!');
}

// Function to verify upload
async function verifyUpload() {
    console.log('\n🔍 Verifying upload...');
    const db = initializeFirebase();
    const collection = db.collection('growth_methods');

    // Query for migrated exercises
    const migratedDocs = await collection.where('migratedFromPE', '==', true).get();
    console.log(`Found ${migratedDocs.size} PE exercises in Firebase`);

    // Check categories
    const categories = {};
    migratedDocs.forEach(doc => {
        const data = doc.data();
        const cat = data.categories ? data.categories[0] : 'Unknown';
        categories[cat] = (categories[cat] || 0) + 1;
    });

    console.log('\nCategories in Firebase:');
    Object.entries(categories).forEach(([cat, count]) => {
        console.log(`  ${cat}: ${count}`);
    });
}

// Function to delete PE exercises (for cleanup if needed)
async function deleteExercises() {
    console.log('\n🗑️ Deleting PE exercises from Firebase...');
    const db = initializeFirebase();
    const collection = db.collection('growth_methods');
    const batch = db.batch();

    // Query for migrated exercises
    const migratedDocs = await collection.where('migratedFromPE', '==', true).get();

    migratedDocs.forEach(doc => {
        batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ Deleted ${migratedDocs.size} PE exercises`);
}

// Parse command line arguments
const command = process.argv[2];

switch (command) {
    case 'upload':
        uploadExercises()
            .then(() => process.exit(0))
            .catch(error => {
                console.error('Upload failed:', error);
                process.exit(1);
            });
        break;

    case 'verify':
        verifyUpload()
            .then(() => process.exit(0))
            .catch(error => {
                console.error('Verification failed:', error);
                process.exit(1);
            });
        break;

    case 'delete':
        deleteExercises()
            .then(() => process.exit(0))
            .catch(error => {
                console.error('Deletion failed:', error);
                process.exit(1);
            });
        break;

    default:
        console.log('PE Exercises Firebase Upload Tool (Using ADC)');
        console.log('==============================================');
        console.log('\n⚠️  This version uses Application Default Credentials');
        console.log('\nSetup required:');
        console.log('  1. Install gcloud: brew install --cask google-cloud-sdk');
        console.log('  2. Login: gcloud auth application-default login');
        console.log('  3. Set project: gcloud config set project growth-training-app');
        console.log('\nUsage: node upload_pe_exercises_with_adc.js <command>');
        console.log('\nCommands:');
        console.log('  upload  - Upload all PE exercises to Firebase');
        console.log('  verify  - Verify exercises were uploaded');
        console.log('  delete  - Delete all PE exercises from Firebase');
        console.log('\nExample:');
        console.log('  node upload_pe_exercises_with_adc.js upload');
}