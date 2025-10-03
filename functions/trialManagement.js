/**
 * trialManagement.js
 * Firebase Functions for 3-day trial management
 *
 * Handles server-side trial validation, usage tracking, and anti-tampering
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Helper function to check if two dates are the same day (UTC)
function isSameDay(date1, date2) {
    return date1.toISOString().split('T')[0] === date2.toISOString().split('T')[0];
}

// Helper function to get next midnight UTC
function getNextMidnightUTC() {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    tomorrow.setUTCHours(0, 0, 0, 0);
    return tomorrow.getTime() / 1000; // Return as Unix timestamp
}

// Helper function to get feature limits
function getLimit(feature) {
    const limits = {
        aiCoach: 3,
        guidedSessions: 1,
        quickTimer: 5 // minutes
    };
    return limits[feature] || 0;
}

/**
 * Record trial start for a new user
 */
exports.recordTrialStart = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { userId, deviceId, startDate } = request.data;

        if (!deviceId) {
            throw new HttpsError('invalid-argument', 'Device ID is required');
        }

        const now = admin.firestore.Timestamp.now();
        const trialData = {
            firstLaunchDate: admin.firestore.Timestamp.fromMillis(startDate * 1000),
            deviceId: deviceId,
            createdAt: now,
            environment: process.env.GCLOUD_PROJECT || 'unknown'
        };

        try {
            // Record in user document if userId exists
            if (userId) {
                await admin.firestore()
                    .collection('users')
                    .doc(userId)
                    .set({ trial: trialData }, { merge: true });
            }

            // Also record by device ID for reinstall prevention
            await admin.firestore()
                .collection('deviceTrials')
                .doc(deviceId)
                .set({
                    ...trialData,
                    userId: userId || null,
                    lastSeen: now
                });

            console.log(`✅ Trial started for device: ${deviceId}, user: ${userId || 'anonymous'}`);
            return { success: true, startDate: startDate };

        } catch (error) {
            console.error('Failed to record trial start:', error);
            throw new HttpsError('internal', 'Failed to record trial start');
        }
    }
);

/**
 * Get trial data for a user
 */
exports.getTrialData = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { userId } = request.data;

        if (!userId) {
            throw new HttpsError('invalid-argument', 'User ID is required');
        }

        try {
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(userId)
                .get();

            if (!userDoc.exists) {
                return null;
            }

            const userData = userDoc.data();
            if (!userData.trial?.firstLaunchDate) {
                return null;
            }

            return {
                firstLaunchDate: userData.trial.firstLaunchDate.toMillis() / 1000,
                deviceId: userData.trial.deviceId
            };

        } catch (error) {
            console.error('Failed to get trial data:', error);
            throw new HttpsError('internal', 'Failed to get trial data');
        }
    }
);

/**
 * Check device trial history
 */
exports.checkDeviceTrial = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { deviceId } = request.data;

        if (!deviceId) {
            throw new HttpsError('invalid-argument', 'Device ID is required');
        }

        try {
            const deviceDoc = await admin.firestore()
                .collection('deviceTrials')
                .doc(deviceId)
                .get();

            if (!deviceDoc.exists) {
                return null;
            }

            const deviceData = deviceDoc.data();

            // Update last seen
            await deviceDoc.ref.update({
                lastSeen: admin.firestore.Timestamp.now()
            });

            return {
                firstLaunchDate: deviceData.firstLaunchDate.toMillis() / 1000,
                userId: deviceData.userId
            };

        } catch (error) {
            console.error('Failed to check device trial:', error);
            throw new HttpsError('internal', 'Failed to check device trial');
        }
    }
);

/**
 * Validate and increment feature usage
 */
exports.validateAndIncrementUsage = onCall(
    { region: 'us-central1',
      consumeAppCheckToken: true
    },
    async (request) => {
        const userId = request.auth?.uid;
        const { feature, timestamp } = request.data;

        if (!userId) {
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }

        if (!feature) {
            throw new HttpsError('invalid-argument', 'Feature is required');
        }

        try {
            const userDoc = await admin.firestore().collection('users').doc(userId).get();
            const userData = userDoc.data() || {};

            // Check if user has premium
            if (userData.hasPremium || userData.hasLifetime) {
                return { allowed: true, isPremium: true };
            }

            // Validate trial status
            const trialStart = userData.trial?.firstLaunchDate?.toDate();
            if (!trialStart) {
                return { allowed: false, reason: 'no_trial' };
            }

            const now = admin.firestore.Timestamp.now().toDate();
            const daysSinceStart = Math.floor((now - trialStart) / (24 * 60 * 60 * 1000));

            // Check if trial expired (3 days)
            if (daysSinceStart >= 3) {
                // After trial, only quick timer under 5 min is allowed
                if (feature === 'quickTimer') {
                    return { allowed: true, postTrial: true };
                }
                return { allowed: false, reason: 'trial_expired', daysExpired: daysSinceStart - 3 };
            }

            // Check daily usage limits during trial
            const usageKey = `dailyUsage.${feature}`;
            const lastResetKey = `dailyUsage.lastReset`;

            const lastReset = userData.dailyUsage?.lastReset?.toDate() || new Date(0);
            const isNewDay = !isSameDay(lastReset, now);

            if (isNewDay) {
                // Reset counters for new day
                const resetData = {
                    [usageKey]: 1,
                    [lastResetKey]: admin.firestore.Timestamp.now(),
                    'dailyUsage.aiCoach': feature === 'aiCoach' ? 1 : 0,
                    'dailyUsage.guidedSessions': feature === 'guidedSessions' ? 1 : 0
                };

                await userDoc.ref.update(resetData);

                return {
                    allowed: true,
                    usage: 1,
                    limit: getLimit(feature),
                    resetTime: getNextMidnightUTC()
                };
            }

            const currentUsage = userData.dailyUsage?.[feature] || 0;
            const limit = getLimit(feature);

            // Check if limit reached
            if (currentUsage >= limit) {
                return {
                    allowed: false,
                    reason: 'daily_limit_reached',
                    usage: currentUsage,
                    limit: limit,
                    resetTime: getNextMidnightUTC()
                };
            }

            // Increment usage
            await userDoc.ref.update({
                [usageKey]: admin.firestore.FieldValue.increment(1)
            });

            return {
                allowed: true,
                usage: currentUsage + 1,
                limit: limit,
                resetTime: getNextMidnightUTC()
            };

        } catch (error) {
            console.error('Failed to validate usage:', error);
            throw new HttpsError('internal', 'Failed to validate usage');
        }
    }
);

/**
 * Get server time for sync
 */
exports.getServerTime = onCall(
    { region: 'us-central1' },
    async (request) => {
        return {
            timestamp: Date.now() / 1000,
            timezone: 'UTC'
        };
    }
);

/**
 * Record daily usage reset
 */
exports.recordDailyReset = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { userId, resetTime, nextReset } = request.data;

        if (!userId) {
            // Anonymous user - no server tracking needed
            return { success: true };
        }

        try {
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .update({
                    'dailyUsage.lastReset': admin.firestore.Timestamp.fromMillis(resetTime * 1000),
                    'dailyUsage.nextReset': admin.firestore.Timestamp.fromMillis(nextReset * 1000),
                    'dailyUsage.aiCoach': 0,
                    'dailyUsage.guidedSessions': 0
                });

            console.log(`✅ Daily reset recorded for user: ${userId}`);
            return { success: true };

        } catch (error) {
            console.error('Failed to record daily reset:', error);
            // Don't throw error - not critical
            return { success: false };
        }
    }
);

/**
 * Update usage statistics
 */
exports.updateUsageStats = onCall(
    { region: 'us-central1' },
    async (request) => {
        const { userId, aiCoachUsage, guidedSessionUsage, timestamp } = request.data;

        if (!userId) {
            return { success: true }; // Anonymous user
        }

        try {
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .update({
                    'dailyUsage.aiCoach': aiCoachUsage,
                    'dailyUsage.guidedSessions': guidedSessionUsage,
                    'dailyUsage.lastUpdate': admin.firestore.Timestamp.fromMillis(timestamp * 1000)
                });

            return { success: true };

        } catch (error) {
            console.error('Failed to update usage stats:', error);
            return { success: false };
        }
    }
);

/**
 * Admin function to extend trial (for customer support)
 */
exports.extendTrial = onCall(
    { region: 'us-central1' },
    async (request) => {
        const adminUid = request.auth?.uid;
        const { userId, additionalDays, reason } = request.data;

        // Check if caller is admin (you'll need to implement this check)
        // For now, we'll check if the user has a custom claim
        if (!request.auth?.token?.admin) {
            throw new HttpsError('permission-denied', 'Only admins can extend trials');
        }

        if (!userId || !additionalDays) {
            throw new HttpsError('invalid-argument', 'User ID and additional days are required');
        }

        try {
            const userDoc = await admin.firestore().collection('users').doc(userId).get();

            if (!userDoc.exists) {
                throw new HttpsError('not-found', 'User not found');
            }

            const userData = userDoc.data();
            const currentFirstLaunch = userData.trial?.firstLaunchDate?.toDate();

            if (!currentFirstLaunch) {
                throw new HttpsError('failed-precondition', 'User has no trial to extend');
            }

            // Calculate new first launch date (push it back)
            const newFirstLaunch = new Date(currentFirstLaunch);
            newFirstLaunch.setDate(newFirstLaunch.getDate() - additionalDays);

            await userDoc.ref.update({
                'trial.firstLaunchDate': admin.firestore.Timestamp.fromDate(newFirstLaunch),
                'trial.extended': true,
                'trial.extensionReason': reason || 'Customer support',
                'trial.extendedBy': adminUid,
                'trial.extendedAt': admin.firestore.Timestamp.now()
            });

            console.log(`✅ Trial extended for user ${userId} by ${additionalDays} days`);
            return {
                success: true,
                newExpirationDate: new Date(newFirstLaunch.getTime() + (3 * 24 * 60 * 60 * 1000))
            };

        } catch (error) {
            console.error('Failed to extend trial:', error);
            throw new HttpsError('internal', 'Failed to extend trial');
        }
    }
);

/**
 * Get trial analytics (for monitoring)
 */
exports.getTrialAnalytics = onCall(
    { region: 'us-central1' },
    async (request) => {
        // Check if caller is admin
        if (!request.auth?.token?.admin) {
            throw new HttpsError('permission-denied', 'Only admins can view analytics');
        }

        try {
            const now = new Date();
            const threeDaysAgo = new Date(now.getTime() - (3 * 24 * 60 * 60 * 1000));

            // Get trial statistics
            const activeTrials = await admin.firestore()
                .collection('users')
                .where('trial.firstLaunchDate', '>', admin.firestore.Timestamp.fromDate(threeDaysAgo))
                .count()
                .get();

            const expiredTrials = await admin.firestore()
                .collection('users')
                .where('trial.firstLaunchDate', '<=', admin.firestore.Timestamp.fromDate(threeDaysAgo))
                .where('hasPremium', '==', false)
                .count()
                .get();

            const conversions = await admin.firestore()
                .collection('users')
                .where('trial.firstLaunchDate', '<=', admin.firestore.Timestamp.fromDate(threeDaysAgo))
                .where('hasPremium', '==', true)
                .count()
                .get();

            return {
                activeTrials: activeTrials.data().count,
                expiredTrials: expiredTrials.data().count,
                conversions: conversions.data().count,
                conversionRate: conversions.data().count / (expiredTrials.data().count + conversions.data().count) || 0
            };

        } catch (error) {
            console.error('Failed to get trial analytics:', error);
            throw new HttpsError('internal', 'Failed to get analytics');
        }
    }
);