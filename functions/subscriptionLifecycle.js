/**
 * Firebase Cloud Functions for subscription lifecycle management
 * Handles enabling/disabling shared routines based on subscription status
 */

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

/**
 * Handle subscription status changes
 */
exports.handleSubscriptionStatusChange = onDocumentUpdated(
    {
        document: 'users/{userId}',
        region: 'us-central1',
        maxInstances: 100
    },
    async (event) => {
        const userId = event.params.userId;
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        // Check if subscription status changed
        const hadPremium = beforeData.isPremium || beforeData.entitlements?.premium === true;
        const hasPremium = afterData.isPremium || afterData.entitlements?.premium === true;

        if (hadPremium === hasPremium) {
            return null; // No change
        }

        console.log(`Subscription changed for ${userId}: ${hadPremium} -> ${hasPremium}`);

        try {
            if (hasPremium && !hadPremium) {
                await enableUserSharedRoutines(userId);
            } else if (!hasPremium && hadPremium) {
                await disableUserSharedRoutines(userId);
            }
        } catch (error) {
            console.error(`Error updating routines for ${userId}:`, error);
            throw error;
        }

        return null;
    }
);

/**
 * Daily check to ensure routine statuses are correct
 */
exports.dailyRoutineStatusCheck = onSchedule(
    {
        schedule: 'every 24 hours',
        timeZone: 'UTC',
        region: 'us-central1',
        maxInstances: 1
    },
    async (event) => {
        console.log('Starting daily routine status check');
        const db = admin.firestore();

        try {
            const usersSnapshot = await db.collection('users').get();
            let processedCount = 0;
            let updatedCount = 0;

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
                                updatedCount++;
                            } else if (!hasPremium && routine.isEnabled) {
                                await disableUserSharedRoutines(userId);
                                updatedCount++;
                            }
                            processedCount++;
                        }
                    } catch (error) {
                        console.error(`Error processing user ${userDoc.id}:`, error);
                    }
                }));
            }

            console.log(`Daily check completed: ${processedCount} processed, ${updatedCount} updated`);

            // Log summary
            await db.collection('audit_logs').add({
                action: 'daily_routine_check',
                processedCount,
                updatedCount,
                totalUsers: userDocs.length,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

        } catch (error) {
            console.error('Error in daily check:', error);
            throw error;
        }
    }
);

// Helper functions

async function disableUserSharedRoutines(userId) {
    const db = admin.firestore();
    const snapshot = await db.collection('routines')
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines for user ${userId}`);
        return;
    }

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
    console.log(`Disabled ${count} routines for user ${userId}`);

    await db.collection('audit_logs').add({
        action: 'routines_disabled',
        userId,
        routineCount: count,
        reason: 'subscription_expired',
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}

async function enableUserSharedRoutines(userId) {
    const db = admin.firestore();
    const snapshot = await db.collection('routines')
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines for user ${userId}`);
        return;
    }

    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
        const data = doc.data();
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
        console.log(`Re-enabled ${count} routines for user ${userId}`);

        await db.collection('audit_logs').add({
            action: 'routines_enabled',
            userId,
            routineCount: count,
            reason: 'subscription_renewed',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    } else {
        console.log(`No disabled routines to re-enable for user ${userId}`);
    }
}

/**
 * Log offer code redemption for marketing attribution (Story 9.3)
 * Tracks which offer codes drive subscriptions for influencer ROI tracking
 */
exports.logOfferCodeRedemption = onCall(
    {
        region: 'us-central1',
        maxInstances: 100
    },
    async (request) => {
        // Verify authentication
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }

        const { offerCodeRef, timestamp, platform, subscriptionProductId } = request.data;
        const userId = request.auth.uid;

        console.log(`📊 Logging offer code redemption: ${offerCodeRef} for user ${userId}`);

        try {
            const db = admin.firestore();

            // Store in Firestore collection
            await db.collection('offer_code_redemptions')
                .doc(userId)
                .collection('redemptions')
                .doc(timestamp.toString())
                .set({
                    offerCodeRef,
                    userId,
                    timestamp,
                    platform,
                    subscriptionProductId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

            console.log(`✅ Offer code redemption logged to Firestore`);

            // Log analytics event (server-side confirmation)
            // Note: Firebase Admin SDK doesn't have direct analytics logging
            // This would typically be done via Firebase Analytics REST API or client-side
            // For now, we rely on client-side analytics tracking

            return { success: true };
        } catch (error) {
            console.error(`Error logging offer code redemption: ${error}`);
            throw new HttpsError('internal', 'Failed to log offer code redemption');
        }
    }
);