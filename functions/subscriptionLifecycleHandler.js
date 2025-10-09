/**
 * Firebase Cloud Function to handle subscription lifecycle events
 * Manages community routine status based on subscription state
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Handle subscription status changes
 * Triggered when user subscription status changes in Firestore
 */
exports.handleSubscriptionStatusChange = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const userId = context.params.userId;
        const before = change.before.data();
        const after = change.after.data();

        // Check if subscription status changed
        const beforePremium = before.isPremium || false;
        const afterPremium = after.isPremium || false;

        // Also check entitlements
        const beforeEntitlements = before.entitlements || {};
        const afterEntitlements = after.entitlements || {};

        const hadPremium = beforePremium || beforeEntitlements.premium === true;
        const hasPremium = afterPremium || afterEntitlements.premium === true;

        if (hadPremium === hasPremium) {
            // No change in premium status
            return null;
        }

        console.log(`Subscription status changed for user ${userId}: ${hadPremium} -> ${hasPremium}`);

        try {
            if (hasPremium && !hadPremium) {
                // Subscription renewed/activated - enable routines
                await enableUserSharedRoutines(userId);
            } else if (!hasPremium && hadPremium) {
                // Subscription expired/cancelled - disable routines
                await disableUserSharedRoutines(userId);
            }
        } catch (error) {
            console.error(`Error updating routine status for user ${userId}:`, error);
            throw error;
        }

        return null;
    });

/**
 * Disable all shared routines for a user
 */
async function disableUserSharedRoutines(userId) {
    const routinesRef = db.collection('routines');

    // Query for all routines shared by this user
    const snapshot = await routinesRef
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines found for user ${userId}`);
        return;
    }

    // Batch update to disable all routines
    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
        batch.update(doc.ref, {
            isEnabled: false,
            disabledAt: admin.firestore.FieldValue.serverTimestamp(),
            disabledReason: 'subscription_expired'
        });
        count++;
    });

    await batch.commit();
    console.log(`Disabled ${count} shared routines for user ${userId}`);

    // Log the action for auditing
    await db.collection('audit_logs').add({
        action: 'routines_disabled',
        userId: userId,
        routineCount: count,
        reason: 'subscription_expired',
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}

/**
 * Enable all shared routines for a user
 */
async function enableUserSharedRoutines(userId) {
    const routinesRef = db.collection('routines');

    // Query for all routines shared by this user
    const snapshot = await routinesRef
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines found for user ${userId}`);
        return;
    }

    // Batch update to enable all routines
    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
        const data = doc.data();
        // Only re-enable if it was disabled due to subscription
        if (!data.isEnabled && data.disabledReason === 'subscription_expired') {
            batch.update(doc.ref, {
                isEnabled: true,
                enabledAt: admin.firestore.FieldValue.serverTimestamp(),
                disabledReason: admin.firestore.FieldValue.delete(),
                disabledAt: admin.firestore.FieldValue.delete()
            });
            count++;
        }
    });

    if (count > 0) {
        await batch.commit();
        console.log(`Re-enabled ${count} shared routines for user ${userId}`);

        // Log the action for auditing
        await db.collection('audit_logs').add({
            action: 'routines_enabled',
            userId: userId,
            routineCount: count,
            reason: 'subscription_renewed',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    } else {
        console.log(`No disabled routines to re-enable for user ${userId}`);
    }
}

/**
 * Scheduled function to check and update routine statuses daily
 * Ensures consistency in case of any missed events
 */
exports.dailyRoutineStatusCheck = functions.pubsub
    .schedule('every 24 hours')
    .timeZone('UTC')
    .onRun(async (context) => {
        console.log('Starting daily routine status check');

        try {
            // Get all users
            const usersSnapshot = await db.collection('users').get();
            let processedCount = 0;
            let errorCount = 0;

            // Process in batches to avoid overwhelming the system
            const batchSize = 10;
            const userDocs = usersSnapshot.docs;

            for (let i = 0; i < userDocs.length; i += batchSize) {
                const batch = userDocs.slice(i, i + batchSize);

                await Promise.all(batch.map(async (userDoc) => {
                    try {
                        const userData = userDoc.data();
                        const userId = userDoc.id;
                        const hasPremium = userData.isPremium || userData.entitlements?.premium === true;

                        // Check if user has shared routines
                        const routinesSnapshot = await db.collection('routines')
                            .where('createdBy', '==', userId)
                            .where('shareWithCommunity', '==', true)
                            .limit(1)
                            .get();

                        if (!routinesSnapshot.empty) {
                            const routine = routinesSnapshot.docs[0].data();

                            // Check if status needs updating
                            if (hasPremium && !routine.isEnabled && routine.disabledReason === 'subscription_expired') {
                                await enableUserSharedRoutines(userId);
                                processedCount++;
                            } else if (!hasPremium && routine.isEnabled) {
                                await disableUserSharedRoutines(userId);
                                processedCount++;
                            }
                        }
                    } catch (error) {
                        console.error(`Error processing user ${userDoc.id}:`, error);
                        errorCount++;
                    }
                }));
            }

            console.log(`Daily routine status check completed. Processed: ${processedCount}, Errors: ${errorCount}`);

            // Log summary
            await db.collection('audit_logs').add({
                action: 'daily_routine_check_completed',
                processedCount: processedCount,
                errorCount: errorCount,
                totalUsers: userDocs.length,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

        } catch (error) {
            console.error('Error in daily routine status check:', error);
            throw error;
        }

        return null;
    });

module.exports = {
    handleSubscriptionStatusChange: exports.handleSubscriptionStatusChange,
    dailyRoutineStatusCheck: exports.dailyRoutineStatusCheck
};