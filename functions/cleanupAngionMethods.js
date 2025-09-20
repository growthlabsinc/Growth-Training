/**
 * Firebase Function to clean up Angion methods from Firestore
 * Removes deprecated Angion and SABRE methods from the database
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

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

/**
 * Main cleanup function - can be triggered via HTTP or scheduled
 */
exports.cleanupAngionMethods = functions.https.onRequest(async (req, res) => {
    try {
        console.log('Starting Angion method cleanup...');

        const results = {
            methodsDeleted: 0,
            routinesUpdated: 0,
            sessionsUpdated: 0,
            errors: []
        };

        // Step 1: Remove methods from growthMethods collection
        console.log('Step 1: Removing methods from growthMethods collection...');
        const methodsRef = db.collection('growthMethods');

        for (const methodId of METHODS_TO_REMOVE) {
            try {
                const methodDoc = await methodsRef.doc(methodId).get();
                if (methodDoc.exists) {
                    await methodsRef.doc(methodId).delete();
                    results.methodsDeleted++;
                    console.log(`Deleted method: ${methodId}`);
                }
            } catch (error) {
                console.error(`Error deleting method ${methodId}:`, error);
                results.errors.push(`Failed to delete method: ${methodId}`);
            }
        }

        // Step 2: Update user routines to remove Angion method references
        console.log('Step 2: Updating user routines...');
        const routinesRef = db.collection('routines');
        const routinesSnapshot = await routinesRef.get();

        const batch = db.batch();
        let batchCount = 0;

        for (const doc of routinesSnapshot.docs) {
            const routine = doc.data();
            let updated = false;

            if (routine.schedule && Array.isArray(routine.schedule)) {
                const updatedSchedule = routine.schedule.map(day => {
                    if (day.methodIds && Array.isArray(day.methodIds)) {
                        const filteredMethods = day.methodIds.filter(
                            id => !METHODS_TO_REMOVE.includes(id)
                        );

                        if (filteredMethods.length !== day.methodIds.length) {
                            updated = true;
                            return { ...day, methodIds: filteredMethods };
                        }
                    }
                    return day;
                });

                if (updated) {
                    batch.update(doc.ref, {
                        schedule: updatedSchedule,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    batchCount++;
                    results.routinesUpdated++;

                    // Commit batch if it reaches 500 operations
                    if (batchCount >= 500) {
                        await batch.commit();
                        batchCount = 0;
                    }
                }
            }
        }

        // Commit remaining batch operations
        if (batchCount > 0) {
            await batch.commit();
        }

        // Step 3: Flag orphaned session logs
        console.log('Step 3: Flagging orphaned session logs...');
        const sessionsRef = db.collection('sessionLogs');
        const sessionsSnapshot = await sessionsRef.get();

        const sessionBatch = db.batch();
        let sessionBatchCount = 0;

        for (const doc of sessionsSnapshot.docs) {
            const session = doc.data();

            if (session.methodId && METHODS_TO_REMOVE.includes(session.methodId)) {
                sessionBatch.update(doc.ref, {
                    orphanedMethod: true,
                    originalMethodId: session.methodId,
                    methodId: 'unknown_method',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                sessionBatchCount++;
                results.sessionsUpdated++;

                // Commit batch if it reaches 500 operations
                if (sessionBatchCount >= 500) {
                    await sessionBatch.commit();
                    sessionBatchCount = 0;
                }
            }
        }

        // Commit remaining batch operations
        if (sessionBatchCount > 0) {
            await sessionBatch.commit();
        }

        // Step 4: Create migration log
        console.log('Step 4: Creating migration log...');
        await db.collection('migrations').add({
            type: 'angion_method_cleanup',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            results: results,
            methodsRemoved: METHODS_TO_REMOVE,
            executedBy: 'cleanupAngionMethods',
            success: results.errors.length === 0
        });

        console.log('Cleanup completed:', results);

        res.status(200).json({
            success: true,
            message: 'Angion method cleanup completed',
            results: results
        });

    } catch (error) {
        console.error('Error in cleanup function:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * Scheduled version to run cleanup automatically
 * Uncomment to enable daily cleanup at 2 AM
 */
// exports.scheduledCleanup = functions.pubsub.schedule('0 2 * * *')
//     .timeZone('America/New_York')
//     .onRun(async (context) => {
//         // Call the cleanup logic
//         console.log('Running scheduled Angion method cleanup...');
//         // Implementation would go here
//     });

/**
 * Backup function - creates backup before cleanup
 */
exports.backupBeforeCleanup = functions.https.onRequest(async (req, res) => {
    try {
        console.log('Creating backup before cleanup...');

        const backup = {
            timestamp: new Date().toISOString(),
            methods: [],
            routines: []
        };

        // Backup methods
        const methodsRef = db.collection('growthMethods');
        for (const methodId of METHODS_TO_REMOVE) {
            const doc = await methodsRef.doc(methodId).get();
            if (doc.exists) {
                backup.methods.push({
                    id: methodId,
                    data: doc.data()
                });
            }
        }

        // Store backup
        await db.collection('backups').add({
            type: 'angion_method_backup',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            data: backup
        });

        res.status(200).json({
            success: true,
            message: 'Backup created successfully',
            backedUpMethods: backup.methods.length
        });

    } catch (error) {
        console.error('Error creating backup:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});