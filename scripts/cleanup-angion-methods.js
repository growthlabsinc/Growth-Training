#!/usr/bin/env node

/**
 * Local script to clean up Angion methods from Firestore
 * Run with: node scripts/cleanup-angion-methods.js [--dry-run] [--backup]
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const createBackup = args.includes('--backup');

// Initialize Firebase Admin with service account
const serviceAccount = require(path.join(__dirname, '../functions/service-account-key.json'));

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Methods to remove
const METHODS_TO_REMOVE = [
    'am1_0', 'am2_0', 'am3_0',
    'angion_method_1_0', 'angion_method_2_5',
    'angion_method_3_0', 'vascion',
    'sabre_type_a', 'sabre_type_b',
    'sabre_type_c', 'sabre_type_d'
];

// Valid replacement methods
const VALID_METHODS = [
    's2s_stretch',
    's2s_advanced',
    'bfr_cyclic_bending',
    'bfr_glans_pulsing',
    'angio_pumping'
];

async function createBackupFile() {
    console.log('📦 Creating backup...');

    const backup = {
        timestamp: new Date().toISOString(),
        methods: [],
        routines: [],
        sessions: []
    };

    // Backup methods
    for (const methodId of METHODS_TO_REMOVE) {
        const doc = await db.collection('growthMethods').doc(methodId).get();
        if (doc.exists) {
            backup.methods.push({
                id: methodId,
                data: doc.data()
            });
        }
    }

    // Backup affected routines
    const routinesSnapshot = await db.collection('routines').get();
    for (const doc of routinesSnapshot.docs) {
        const routine = doc.data();
        if (routine.schedule && Array.isArray(routine.schedule)) {
            const hasAngionMethods = routine.schedule.some(day =>
                day.methodIds && day.methodIds.some(id => METHODS_TO_REMOVE.includes(id))
            );

            if (hasAngionMethods) {
                backup.routines.push({
                    id: doc.id,
                    data: routine
                });
            }
        }
    }

    // Save backup to file
    const backupPath = path.join(__dirname, `../backups/angion-backup-${Date.now()}.json`);

    // Create backups directory if it doesn't exist
    const backupsDir = path.join(__dirname, '../backups');
    if (!fs.existsSync(backupsDir)) {
        fs.mkdirSync(backupsDir);
    }

    fs.writeFileSync(backupPath, JSON.stringify(backup, null, 2));
    console.log(`✅ Backup saved to: ${backupPath}`);
    console.log(`   - Methods backed up: ${backup.methods.length}`);
    console.log(`   - Routines backed up: ${backup.routines.length}`);

    return backupPath;
}

async function cleanupMethods() {
    const results = {
        methodsDeleted: 0,
        routinesUpdated: 0,
        sessionsUpdated: 0,
        errors: []
    };

    console.log(isDryRun ? '🧪 DRY RUN MODE - No changes will be made' : '🚀 Starting cleanup...');

    // Step 1: Remove methods from growthMethods collection
    console.log('\n📌 Step 1: Checking growthMethods collection...');

    for (const methodId of METHODS_TO_REMOVE) {
        try {
            const methodDoc = await db.collection('growthMethods').doc(methodId).get();
            if (methodDoc.exists) {
                console.log(`   Found method: ${methodId}`);
                if (!isDryRun) {
                    await db.collection('growthMethods').doc(methodId).delete();
                    console.log(`   ✅ Deleted: ${methodId}`);
                } else {
                    console.log(`   [DRY RUN] Would delete: ${methodId}`);
                }
                results.methodsDeleted++;
            }
        } catch (error) {
            console.error(`   ❌ Error with method ${methodId}:`, error.message);
            results.errors.push(`Failed to delete method: ${methodId}`);
        }
    }

    // Step 2: Update user routines
    console.log('\n📌 Step 2: Updating user routines...');
    const routinesSnapshot = await db.collection('routines').get();

    for (const doc of routinesSnapshot.docs) {
        const routine = doc.data();
        let updated = false;
        let removedMethods = [];

        if (routine.schedule && Array.isArray(routine.schedule)) {
            const updatedSchedule = routine.schedule.map(day => {
                if (day.methodIds && Array.isArray(day.methodIds)) {
                    const originalLength = day.methodIds.length;
                    const filteredMethods = day.methodIds.filter(id => {
                        const shouldKeep = !METHODS_TO_REMOVE.includes(id);
                        if (!shouldKeep) {
                            removedMethods.push(id);
                        }
                        return shouldKeep;
                    });

                    if (filteredMethods.length !== originalLength) {
                        updated = true;
                        return { ...day, methodIds: filteredMethods };
                    }
                }
                return day;
            });

            if (updated) {
                console.log(`   Routine ${doc.id}: removing ${removedMethods.join(', ')}`);
                if (!isDryRun) {
                    await doc.ref.update({
                        schedule: updatedSchedule,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log(`   ✅ Updated routine: ${doc.id}`);
                } else {
                    console.log(`   [DRY RUN] Would update routine: ${doc.id}`);
                }
                results.routinesUpdated++;
            }
        }
    }

    // Step 3: Flag orphaned session logs
    console.log('\n📌 Step 3: Checking session logs...');
    const sessionsSnapshot = await db.collection('sessionLogs').get();

    for (const doc of sessionsSnapshot.docs) {
        const session = doc.data();

        if (session.methodId && METHODS_TO_REMOVE.includes(session.methodId)) {
            console.log(`   Session ${doc.id}: orphaned method ${session.methodId}`);
            if (!isDryRun) {
                await doc.ref.update({
                    orphanedMethod: true,
                    originalMethodId: session.methodId,
                    methodId: 'unknown_method',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                console.log(`   ✅ Flagged session: ${doc.id}`);
            } else {
                console.log(`   [DRY RUN] Would flag session: ${doc.id}`);
            }
            results.sessionsUpdated++;
        }
    }

    // Step 4: Create migration log
    if (!isDryRun) {
        console.log('\n📌 Step 4: Creating migration log...');
        await db.collection('migrations').add({
            type: 'angion_method_cleanup',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            results: results,
            methodsRemoved: METHODS_TO_REMOVE,
            executedBy: 'local_cleanup_script',
            success: results.errors.length === 0
        });
    }

    return results;
}

async function main() {
    try {
        console.log('🧹 Angion Method Cleanup Script');
        console.log('================================\n');

        // Create backup if requested
        if (createBackup) {
            await createBackupFile();
            console.log('');
        }

        // Run cleanup
        const results = await cleanupMethods();

        // Print summary
        console.log('\n📊 Cleanup Summary:');
        console.log('==================');
        console.log(`Methods deleted: ${results.methodsDeleted}`);
        console.log(`Routines updated: ${results.routinesUpdated}`);
        console.log(`Sessions flagged: ${results.sessionsUpdated}`);

        if (results.errors.length > 0) {
            console.log(`\n⚠️ Errors encountered: ${results.errors.length}`);
            results.errors.forEach(error => console.log(`   - ${error}`));
        }

        if (isDryRun) {
            console.log('\n💡 This was a DRY RUN. To execute changes, run without --dry-run flag.');
        } else {
            console.log('\n✅ Cleanup completed successfully!');
        }

    } catch (error) {
        console.error('\n❌ Fatal error:', error);
        process.exit(1);
    } finally {
        // Terminate the admin app
        await admin.app().delete();
    }
}

// Run the script
main();