/**
 * Fix for timer date corruption issue in Live Activities
 * 
 * The issue: Dates are being stored incorrectly, showing as 1994 instead of 2025
 * This causes massive elapsed time calculations (31+ years)
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize admin if needed
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Fix corrupted timer dates in activeTimers collection
 */
exports.fixTimerDates = onCall(
    {
        region: 'us-central1',
        consumeAppCheckToken: false
    },
    async (request) => {
        console.log('🔧 [fixTimerDates] Starting date fix process...');
        
        const { userId, activityId } = request.data;
        
        if (!userId) {
            throw new HttpsError('invalid-argument', 'userId is required');
        }
        
        try {
            // Get the current timer document
            const timerDoc = await db.collection('activeTimers').document(userId).get();
            
            if (!timerDoc.exists) {
                console.log('❌ No timer document found for user:', userId);
                return { success: false, message: 'No active timer found' };
            }
            
            const timerData = timerDoc.data();
            const contentState = timerData.contentState || {};
            
            console.log('📊 Current timer data:', JSON.stringify(timerData, null, 2));
            
            // Check if dates need fixing
            const now = new Date();
            let needsFix = false;
            let fixedContentState = { ...contentState };
            
            // Check startTime
            if (contentState.startTime) {
                let startTime;
                if (contentState.startTime._seconds) {
                    startTime = new Date(contentState.startTime._seconds * 1000);
                } else if (contentState.startTime.toDate) {
                    startTime = contentState.startTime.toDate();
                }
                
                // If the start time is more than 1 year in the past, it's likely corrupted
                const yearInMs = 365 * 24 * 60 * 60 * 1000;
                if (startTime && (now - startTime) > yearInMs) {
                    console.log('⚠️ Start time appears corrupted:', startTime.toISOString());
                    needsFix = true;
                    
                    // Calculate a reasonable start time based on elapsed time
                    const elapsedSeconds = contentState.elapsedTimeAtLastUpdate || 0;
                    const correctedStartTime = new Date(now.getTime() - (elapsedSeconds * 1000));
                    fixedContentState.startTime = admin.firestore.Timestamp.fromDate(correctedStartTime);
                    console.log('✅ Fixed start time to:', correctedStartTime.toISOString());
                }
            }
            
            // Check endTime for countdown timers
            if (contentState.endTime && contentState.sessionType === 'countdown') {
                let endTime;
                if (contentState.endTime._seconds) {
                    endTime = new Date(contentState.endTime._seconds * 1000);
                } else if (contentState.endTime.toDate) {
                    endTime = contentState.endTime.toDate();
                }
                
                // If the end time is more than 1 year different from now, it's likely corrupted
                const yearInMs = 365 * 24 * 60 * 60 * 1000;
                if (endTime && Math.abs(now - endTime) > yearInMs) {
                    console.log('⚠️ End time appears corrupted:', endTime.toISOString());
                    needsFix = true;
                    
                    // Calculate a reasonable end time based on remaining time
                    const remainingSeconds = contentState.remainingTimeAtLastUpdate || 60;
                    const correctedEndTime = new Date(now.getTime() + (remainingSeconds * 1000));
                    fixedContentState.endTime = admin.firestore.Timestamp.fromDate(correctedEndTime);
                    console.log('✅ Fixed end time to:', correctedEndTime.toISOString());
                }
            }
            
            // Reset elapsed and remaining times if they're unreasonable
            if (contentState.elapsedTimeAtLastUpdate > 86400) { // More than 24 hours
                console.log('⚠️ Elapsed time unreasonable:', contentState.elapsedTimeAtLastUpdate);
                fixedContentState.elapsedTimeAtLastUpdate = 0;
                needsFix = true;
            }
            
            if (contentState.remainingTimeAtLastUpdate > 86400) { // More than 24 hours
                console.log('⚠️ Remaining time unreasonable:', contentState.remainingTimeAtLastUpdate);
                fixedContentState.remainingTimeAtLastUpdate = 60; // Default to 60 seconds
                needsFix = true;
            }
            
            // Update the document if fixes were needed
            if (needsFix) {
                console.log('🔧 Applying fixes to timer document...');
                
                await db.collection('activeTimers').document(userId).update({
                    contentState: fixedContentState,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    dateFixed: true,
                    fixedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                
                console.log('✅ Timer dates fixed successfully');
                
                // Also trigger a push update to refresh the Live Activity
                if (activityId) {
                    console.log('📤 Triggering push update for activity:', activityId);
                    // This would call your existing update function
                }
                
                return {
                    success: true,
                    message: 'Timer dates fixed',
                    fixes: {
                        startTime: fixedContentState.startTime?.toDate?.()?.toISOString(),
                        endTime: fixedContentState.endTime?.toDate?.()?.toISOString(),
                        elapsedTime: fixedContentState.elapsedTimeAtLastUpdate,
                        remainingTime: fixedContentState.remainingTimeAtLastUpdate
                    }
                };
            } else {
                console.log('✅ Timer dates appear to be correct, no fixes needed');
                return {
                    success: true,
                    message: 'No fixes needed',
                    currentDates: {
                        startTime: contentState.startTime?.toDate?.()?.toISOString(),
                        endTime: contentState.endTime?.toDate?.()?.toISOString()
                    }
                };
            }
            
        } catch (error) {
            console.error('❌ Error fixing timer dates:', error);
            throw new HttpsError('internal', error.message);
        }
    }
);

/**
 * Utility to validate and fix a single activity's timer state
 */
async function validateAndFixTimerState(userId, activityId) {
    try {
        const timerDoc = await db.collection('activeTimers').document(userId).get();
        
        if (!timerDoc.exists) {
            return { success: false, message: 'No timer found' };
        }
        
        const data = timerDoc.data();
        const contentState = data.contentState || {};
        
        // Ensure dates are reasonable
        const now = new Date();
        const maxElapsedTime = 12 * 60 * 60; // 12 hours max
        const maxDuration = 8 * 60 * 60; // 8 hours max
        
        let updates = {};
        let needsUpdate = false;
        
        // Validate elapsed time
        if (contentState.elapsedTimeAtLastUpdate > maxElapsedTime) {
            updates['contentState.elapsedTimeAtLastUpdate'] = 0;
            needsUpdate = true;
        }
        
        // Validate dates
        if (contentState.startTime) {
            const startTime = contentState.startTime.toDate ? contentState.startTime.toDate() : new Date(contentState.startTime._seconds * 1000);
            const timeDiff = Math.abs(now - startTime);
            
            if (timeDiff > 365 * 24 * 60 * 60 * 1000) { // More than a year
                updates['contentState.startTime'] = admin.firestore.Timestamp.now();
                needsUpdate = true;
            }
        }
        
        if (needsUpdate) {
            updates['updatedAt'] = admin.firestore.FieldValue.serverTimestamp();
            await db.collection('activeTimers').document(userId).update(updates);
            return { success: true, message: 'Timer state validated and fixed' };
        }
        
        return { success: true, message: 'Timer state is valid' };
        
    } catch (error) {
        console.error('Error validating timer state:', error);
        return { success: false, error: error.message };
    }
}

// Only export the functions defined above
module.exports = {
    fixTimerDates: exports.fixTimerDates,
    validateAndFixTimerState
};