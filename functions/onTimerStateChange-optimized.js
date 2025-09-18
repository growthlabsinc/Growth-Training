const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

/**
 * Optimized Firestore trigger for timer state changes
 * Only notifies Live Activity when state actually changes (pause/resume/stop)
 * Based on the article's approach - no periodic updates needed
 */
exports.onTimerStateChange = onDocumentWritten(
    {
        document: 'activeTimers/{userId}',
        region: 'us-central1'
    },
    async (event) => {
        const change = event.data;
        const userId = event.params.userId;
        
        // Get before and after data
        const beforeData = change.before.exists ? change.before.data() : null;
        const afterData = change.after.exists ? change.after.data() : null;
        
        // Determine what changed
        const isNewTimer = !beforeData && afterData;
        const isTimerDeleted = beforeData && !afterData;
        const isStateChange = beforeData && afterData && (
            beforeData.contentState?.isPaused !== afterData.contentState?.isPaused ||
            beforeData.action !== afterData.action
        );
        
        console.log(`⏱️ Timer state change for user ${userId}:`, {
            isNewTimer,
            isTimerDeleted,
            isStateChange,
            action: afterData?.action,
            isPaused: afterData?.contentState?.isPaused
        });
        
        // Only proceed if there's an actual state change
        if (!isNewTimer && !isTimerDeleted && !isStateChange) {
            console.log('✅ No significant state change, skipping Live Activity update');
            return null;
        }
        
        // Get the activity ID from the timer data
        const activityId = afterData?.activityId || beforeData?.activityId;
        
        if (!activityId) {
            console.log('⚠️ No activityId found, skipping Live Activity update');
            return null;
        }
        
        // Initialize admin if needed
        if (!admin.apps.length) {
            admin.initializeApp();
        }
        
        try {
            // Check if we have a push token for this activity
            const tokenDoc = await admin.firestore()
                .collection('liveActivityTokens')
                .doc(activityId)
                .get();
            
            if (!tokenDoc.exists) {
                console.log(`⚠️ No push token found for activity ${activityId}`);
                return null;
            }
            
            // Call the optimized state change notification
            const { notifyLiveActivityStateChange } = require('./manageLiveActivityUpdates-optimized');
            
            await notifyLiveActivityStateChange({
                data: { activityId, userId },
                auth: { uid: userId }
            });
            
            console.log(`✅ Live Activity notified of state change for ${activityId}`);
            
            // If timer is stopped/completed, clean up the token
            if (isTimerDeleted || afterData?.action === 'stop') {
                await admin.firestore()
                    .collection('liveActivityTokens')
                    .doc(activityId)
                    .delete();
                console.log(`🧹 Cleaned up push token for completed activity ${activityId}`);
            }
            
            return null;
        } catch (error) {
            console.error('❌ Error notifying Live Activity:', error);
            return null;
        }
    });

/**
 * Key optimizations based on the article:
 * 
 * 1. Only triggers on actual state changes (pause/resume/stop)
 * 2. No periodic updates - iOS handles timer display
 * 3. Cleans up tokens when timer completes
 * 4. Minimal server load - only processes real changes
 * 
 * This approach aligns with Apple's best practices and the
 * article's recommendation to avoid frequent updates.
 */