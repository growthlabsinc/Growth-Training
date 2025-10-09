#!/usr/bin/env node

/**
 * Manual script to manage routine status based on subscription
 *
 * Usage:
 * node manage-subscription-routines.js disable <userId>  - Disable routines when subscription expires
 * node manage-subscription-routines.js enable <userId>   - Enable routines when subscription renewed
 * node manage-subscription-routines.js check             - Check all users and update statuses
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'growth-training-app'
});

const db = admin.firestore();

/**
 * Disable all shared routines for a user
 */
async function disableUserSharedRoutines(userId) {
    console.log(`🔴 Disabling shared routines for user ${userId}...`);

    const routinesRef = db.collection('routines');
    const snapshot = await routinesRef
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines found for user ${userId}`);
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
    console.log(`✅ Disabled ${count} shared routines for user ${userId}`);

    // Log the action
    await db.collection('audit_logs').add({
        action: 'routines_disabled_manual',
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
    console.log(`🟢 Enabling shared routines for user ${userId}...`);

    const routinesRef = db.collection('routines');
    const snapshot = await routinesRef
        .where('createdBy', '==', userId)
        .where('shareWithCommunity', '==', true)
        .get();

    if (snapshot.empty) {
        console.log(`No shared routines found for user ${userId}`);
        return;
    }

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
        console.log(`✅ Re-enabled ${count} shared routines for user ${userId}`);

        // Log the action
        await db.collection('audit_logs').add({
            action: 'routines_enabled_manual',
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
 * Check all users and update routine statuses
 */
async function checkAllUsers() {
    console.log('🔍 Checking all users for subscription status...\n');

    const usersSnapshot = await db.collection('users').get();
    let processedCount = 0;
    let updatedCount = 0;

    for (const userDoc of usersSnapshot.docs) {
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
                console.log(`📗 User ${userId} has premium, enabling routines...`);
                await enableUserSharedRoutines(userId);
                updatedCount++;
            } else if (!hasPremium && routine.isEnabled) {
                console.log(`📕 User ${userId} lost premium, disabling routines...`);
                await disableUserSharedRoutines(userId);
                updatedCount++;
            } else {
                console.log(`✓ User ${userId} status is correct (Premium: ${hasPremium}, Enabled: ${routine.isEnabled})`);
            }

            processedCount++;
        }
    }

    console.log(`\n✅ Check completed. Processed: ${processedCount} users with shared routines, Updated: ${updatedCount}`);

    // Log summary
    await db.collection('audit_logs').add({
        action: 'manual_routine_check_completed',
        processedCount: processedCount,
        updatedCount: updatedCount,
        totalUsers: usersSnapshot.size,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}

// Main execution
const command = process.argv[2];
const userId = process.argv[3];

async function main() {
    try {
        switch (command) {
            case 'disable':
                if (!userId) {
                    console.error('❌ Please provide a user ID');
                    process.exit(1);
                }
                await disableUserSharedRoutines(userId);
                break;

            case 'enable':
                if (!userId) {
                    console.error('❌ Please provide a user ID');
                    process.exit(1);
                }
                await enableUserSharedRoutines(userId);
                break;

            case 'check':
                await checkAllUsers();
                break;

            default:
                console.log('Usage:');
                console.log('  node manage-subscription-routines.js disable <userId>');
                console.log('  node manage-subscription-routines.js enable <userId>');
                console.log('  node manage-subscription-routines.js check');
                process.exit(1);
        }

        console.log('\n✅ Done!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

main();