#!/usr/bin/env node

/**
 * Script to remove all single-step methods from Firebase except ADS
 * This will query the growth_exercises collection and delete methods with only one step
 */

import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import readline from 'readline';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Firebase Admin with the service account
const serviceAccountPath = join(__dirname, '../functions/service-account-key.json');
const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://growth-training-app.firebaseio.com`
});

const db = admin.firestore();

async function removeSingleStepMethods() {
    console.log('🔍 Fetching all methods from growth_exercises collection...\n');

    try {
        const snapshot = await db.collection('growth_exercises').get();

        if (snapshot.empty) {
            console.log('❌ No methods found in growth_exercises collection');
            return;
        }

        console.log(`📊 Found ${snapshot.size} total methods\n`);

        const methodsToDelete = [];
        const methodsToKeep = [];

        // Analyze each method
        snapshot.forEach(doc => {
            const data = doc.data();
            const methodId = doc.id;
            const methodTitle = data.title || 'Untitled';

            // Check if method has steps array
            const steps = data.steps || [];
            const stepCount = steps.length;

            // Also check if it has old-style instructions that might indicate multiple steps
            const instructionsText = data.instructionsText || '';
            const hasMultilineInstructions = instructionsText.includes('\n') && instructionsText.trim().split('\n').length > 2;

            // Determine if this is effectively a single-step method
            const isSingleStep = stepCount <= 1 && !hasMultilineInstructions;

            // Check if this is ADS (keep regardless of steps)
            const isADS = methodId.toLowerCase() === 'ads' ||
                         methodTitle.toLowerCase().includes('ads') ||
                         methodTitle.toLowerCase().includes('all day') ||
                         methodTitle.toLowerCase().includes('all-day');

            if (isSingleStep && !isADS) {
                methodsToDelete.push({
                    id: methodId,
                    title: methodTitle,
                    stepCount: stepCount
                });
            } else {
                methodsToKeep.push({
                    id: methodId,
                    title: methodTitle,
                    stepCount: stepCount,
                    reason: isADS ? 'ADS method' : `Has ${stepCount} steps`
                });
            }
        });

        // Display methods to keep
        console.log('✅ Methods to KEEP:');
        console.log('─'.repeat(50));
        methodsToKeep.forEach(method => {
            console.log(`  • ${method.title} (${method.id})`);
            console.log(`    Reason: ${method.reason}`);
        });

        console.log('\n');

        // Display methods to delete
        console.log('🗑️  Methods to DELETE (single-step):');
        console.log('─'.repeat(50));
        if (methodsToDelete.length === 0) {
            console.log('  None - all methods either have multiple steps or are ADS');
        } else {
            methodsToDelete.forEach(method => {
                console.log(`  • ${method.title} (${method.id})`);
            });
        }

        console.log('\n');
        console.log(`Summary: ${methodsToDelete.length} methods will be deleted, ${methodsToKeep.length} will be kept`);

        if (methodsToDelete.length > 0) {
            // Ask for confirmation
            console.log('\n⚠️  WARNING: This action cannot be undone!');
            console.log('Do you want to proceed with deletion? Type "DELETE" to confirm:');

            // Set up stdin for user input
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });

            rl.question('> ', async (answer) => {
                if (answer === 'DELETE') {
                    console.log('\n🔥 Deleting single-step methods...\n');

                    // Perform deletion
                    const batch = db.batch();
                    let batchCount = 0;

                    for (const method of methodsToDelete) {
                        const docRef = db.collection('growth_exercises').doc(method.id);
                        batch.delete(docRef);
                        batchCount++;

                        // Firestore batch limit is 500
                        if (batchCount === 500) {
                            await batch.commit();
                            batch = db.batch();
                            batchCount = 0;
                        }
                    }

                    // Commit remaining operations
                    if (batchCount > 0) {
                        await batch.commit();
                    }

                    console.log(`✅ Successfully deleted ${methodsToDelete.length} single-step methods`);
                    console.log(`✅ Kept ${methodsToKeep.length} methods (including ADS and multi-step methods)`);
                } else {
                    console.log('\n❌ Deletion cancelled. No methods were removed.');
                }

                rl.close();
                process.exit(0);
            });
        } else {
            console.log('\n✅ No single-step methods to delete. All methods are either multi-step or ADS.');
            process.exit(0);
        }

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

// Add a dry run option
async function analyzeMethods() {
    console.log('🔍 Analyzing methods (DRY RUN - no deletions)...\n');

    try {
        const snapshot = await db.collection('growth_exercises').get();

        if (snapshot.empty) {
            console.log('❌ No methods found in growth_exercises collection');
            return;
        }

        console.log(`📊 Found ${snapshot.size} total methods\n`);

        const singleStepMethods = [];
        const multiStepMethods = [];
        const adsMethods = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            const methodId = doc.id;
            const methodTitle = data.title || 'Untitled';
            const steps = data.steps || [];
            const stepCount = steps.length;

            // Check if this is ADS
            const isADS = methodId.toLowerCase() === 'ads' ||
                         methodTitle.toLowerCase().includes('ads') ||
                         methodTitle.toLowerCase().includes('all day') ||
                         methodTitle.toLowerCase().includes('all-day');

            if (isADS) {
                adsMethods.push({ id: methodId, title: methodTitle, stepCount });
            } else if (stepCount <= 1) {
                singleStepMethods.push({ id: methodId, title: methodTitle, stepCount });
            } else {
                multiStepMethods.push({ id: methodId, title: methodTitle, stepCount });
            }
        });

        console.log('📈 Analysis Results:');
        console.log('═'.repeat(50));
        console.log(`Total methods: ${snapshot.size}`);
        console.log(`Multi-step methods: ${multiStepMethods.length}`);
        console.log(`Single-step methods: ${singleStepMethods.length}`);
        console.log(`ADS methods: ${adsMethods.length}`);
        console.log('═'.repeat(50));

        if (adsMethods.length > 0) {
            console.log('\n🎯 ADS Methods (will be kept):');
            adsMethods.forEach(m => console.log(`  • ${m.title} (${m.stepCount} steps)`));
        }

        if (singleStepMethods.length > 0) {
            console.log('\n📝 Single-Step Methods (would be deleted):');
            singleStepMethods.forEach(m => console.log(`  • ${m.title}`));
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

// Check command line arguments
const args = process.argv.slice(2);
if (args.includes('--analyze') || args.includes('-a')) {
    analyzeMethods();
} else {
    console.log('Single-Step Method Removal Tool');
    console.log('================================\n');
    console.log('This will remove all methods with only 1 step, except ADS methods.\n');
    console.log('Options:');
    console.log('  --analyze, -a    Analyze methods without deleting (dry run)');
    console.log('  (no args)        Proceed with deletion (will ask for confirmation)\n');

    if (args.length === 0) {
        removeSingleStepMethods();
    }
}