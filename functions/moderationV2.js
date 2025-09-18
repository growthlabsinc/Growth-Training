const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// List of profanity words to check (extend as needed)
const profanityList = [
    // Add actual profanity words here
    'badword1', 'badword2', 'offensive1', 'offensive2'
];

// Auto-moderate new community routines
exports.moderateNewRoutine = onDocumentCreated(
    {
        document: 'routines/{routineId}',
        region: 'us-central1'
    },
    async (event) => {
        const routine = event.data.data();
        const routineId = event.params.routineId;
        
        // Only moderate community-shared routines
        if (!routine.shareWithCommunity) {
            console.log('Routine not shared with community, skipping moderation');
            return null;
        }
        
        console.log(`Moderating new routine: ${routineId}`);
        
        try {
            // Check for profanity in name and description
            const textToCheck = `${routine.name} ${routine.description}`.toLowerCase();
            const containsProfanity = profanityList.some(word => 
                textToCheck.includes(word.toLowerCase())
            );
            
            if (containsProfanity) {
                // Flag the routine
                await event.data.ref.update({
                    moderationStatus: 'flagged',
                    moderationReason: 'Profanity detected',
                    moderatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                
                console.log(`Routine ${routineId} flagged for profanity`);
            } else {
                // Auto-approve if no issues found
                await event.data.ref.update({
                    moderationStatus: 'approved',
                    moderatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                
                console.log(`Routine ${routineId} auto-approved`);
            }
            
            return null;
        } catch (error) {
            console.error('Error moderating routine:', error);
            return null;
        }
    }
);

// Process user reports
exports.processReport = onCall(
    {
        cors: true,
        region: 'us-central1',
        consumeAppCheckToken: false
    },
    async (request) => {
        // Require authentication
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'User must be authenticated to report content');
        }
        
        const { 
            contentId, 
            contentType, 
            reason, 
            details 
        } = request.data;
        
        // Validate input
        if (!contentId || !contentType || !reason) {
            throw new HttpsError('invalid-argument', 'Missing required fields');
        }
        
        const reporterId = request.auth.uid;
        
        try {
            // Create report document
            const reportData = {
                contentId,
                contentType,
                reason,
                details: details || '',
                reporterId,
                reportedAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'pending',
                resolved: false
            };
            
            const reportRef = await db.collection('reports').add(reportData);
            
            // Update report count on the content
            if (contentType === 'routine') {
                const routineRef = db.collection('routines').doc(contentId);
                await routineRef.update({
                    reportCount: admin.firestore.FieldValue.increment(1)
                });
                
                // Auto-flag if too many reports
                const routine = await routineRef.get();
                if (routine.exists && routine.data().reportCount >= 3) {
                    await routineRef.update({
                        moderationStatus: 'flagged',
                        moderationReason: 'Multiple user reports'
                    });
                }
            }
            
            console.log(`Report ${reportRef.id} created for ${contentType} ${contentId}`);
            
            return { 
                success: true, 
                reportId: reportRef.id,
                message: 'Report submitted successfully' 
            };
            
        } catch (error) {
            console.error('Error processing report:', error);
            throw new HttpsError('internal', 'Failed to process report');
        }
    }
);

// Ban a user
exports.banUser = onCall(
    {
        cors: true,
        region: 'us-central1',
        consumeAppCheckToken: false
    },
    async (request) => {
        // Check if requester is admin
        if (!request.auth || !request.auth.token.admin) {
            throw new HttpsError('permission-denied', 'Only admins can ban users');
        }
        
        const { userId, reason, duration } = request.data;
        
        if (!userId || !reason) {
            throw new HttpsError('invalid-argument', 'User ID and reason are required');
        }
        
        try {
            // Calculate ban expiry
            const banExpiry = duration 
                ? new Date(Date.now() + duration * 24 * 60 * 60 * 1000)
                : null; // Permanent ban if no duration
            
            // Create ban record
            await db.collection('bans').doc(userId).set({
                userId,
                reason,
                bannedAt: admin.firestore.FieldValue.serverTimestamp(),
                bannedBy: request.auth.uid,
                expiresAt: banExpiry,
                active: true
            });
            
            // Disable user's auth account
            await admin.auth().updateUser(userId, {
                disabled: true
            });
            
            // Hide all user's community content
            const batch = db.batch();
            
            // Hide user's routines
            const routinesSnapshot = await db.collection('routines')
                .where('userId', '==', userId)
                .where('shareWithCommunity', '==', true)
                .get();
                
            routinesSnapshot.forEach(doc => {
                batch.update(doc.ref, {
                    shareWithCommunity: false,
                    moderationStatus: 'removed',
                    moderationReason: `User banned: ${reason}`
                });
            });
            
            await batch.commit();
            
            console.log(`User ${userId} banned successfully`);
            
            return { 
                success: true,
                message: `User banned ${duration ? `for ${duration} days` : 'permanently'}` 
            };
            
        } catch (error) {
            console.error('Error banning user:', error);
            throw new HttpsError('internal', 'Failed to ban user');
        }
    }
);

// General content moderation
exports.moderateContent = onCall(
    {
        cors: true,
        region: 'us-central1',
        consumeAppCheckToken: false
    },
    async (request) => {
        // Check if requester is admin or moderator
        if (!request.auth || (!request.auth.token.admin && !request.auth.token.moderator)) {
            throw new HttpsError('permission-denied', 'Only admins and moderators can moderate content');
        }
        
        const { 
            contentId, 
            contentType, 
            action, 
            reason 
        } = request.data;
        
        if (!contentId || !contentType || !action) {
            throw new HttpsError('invalid-argument', 'Missing required fields');
        }
        
        try {
            const moderatorId = request.auth.uid;
            let contentRef;
            
            // Get reference based on content type
            switch (contentType) {
                case 'routine':
                    contentRef = db.collection('routines').doc(contentId);
                    break;
                case 'comment':
                    contentRef = db.collection('comments').doc(contentId);
                    break;
                default:
                    throw new HttpsError('invalid-argument', 'Invalid content type');
            }
            
            // Apply moderation action
            const updateData = {
                moderationStatus: action, // 'approved', 'flagged', 'removed'
                moderationReason: reason || '',
                moderatedBy: moderatorId,
                moderatedAt: admin.firestore.FieldValue.serverTimestamp()
            };
            
            if (action === 'removed') {
                updateData.shareWithCommunity = false;
            }
            
            await contentRef.update(updateData);
            
            // Update related reports
            const reportsSnapshot = await db.collection('reports')
                .where('contentId', '==', contentId)
                .where('contentType', '==', contentType)
                .where('resolved', '==', false)
                .get();
                
            const batch = db.batch();
            reportsSnapshot.forEach(doc => {
                batch.update(doc.ref, {
                    resolved: true,
                    resolvedBy: moderatorId,
                    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
                    resolution: action
                });
            });
            
            await batch.commit();
            
            console.log(`Content ${contentType}:${contentId} moderated with action: ${action}`);
            
            return { 
                success: true,
                message: `Content ${action} successfully` 
            };
            
        } catch (error) {
            console.error('Error moderating content:', error);
            throw new HttpsError('internal', 'Failed to moderate content');
        }
    }
);

// Cleanup old reports (scheduled function)
exports.cleanupOldReports = onSchedule(
    {
        schedule: 'every 24 hours',
        timeZone: 'America/New_York',
        region: 'us-central1'
    },
    async (event) => {
        console.log('Running cleanup of old reports...');
        
        try {
            // Delete resolved reports older than 30 days
            const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
            
            const oldReportsSnapshot = await db.collection('reports')
                .where('resolved', '==', true)
                .where('resolvedAt', '<', thirtyDaysAgo)
                .limit(500) // Process in batches
                .get();
                
            const batch = db.batch();
            let deleteCount = 0;
            
            oldReportsSnapshot.forEach(doc => {
                batch.delete(doc.ref);
                deleteCount++;
            });
            
            if (deleteCount > 0) {
                await batch.commit();
                console.log(`Deleted ${deleteCount} old reports`);
            } else {
                console.log('No old reports to delete');
            }
            
            return null;
        } catch (error) {
            console.error('Error cleaning up reports:', error);
            return null;
        }
    }
);

// Check if user is banned
exports.checkUserBanned = onCall(
    {
        cors: true,
        region: 'us-central1',
        consumeAppCheckToken: false
    },
    async (request) => {
        const { userId } = request.data;
        
        if (!userId) {
            throw new HttpsError('invalid-argument', 'User ID is required');
        }
        
        try {
            const banDoc = await db.collection('bans').doc(userId).get();
            
            if (!banDoc.exists) {
                return { banned: false };
            }
            
            const banData = banDoc.data();
            
            // Check if ban is still active
            if (!banData.active) {
                return { banned: false };
            }
            
            // Check if ban has expired
            if (banData.expiresAt && banData.expiresAt.toDate() < new Date()) {
                // Update ban status
                await banDoc.ref.update({ active: false });
                
                // Re-enable user account
                await admin.auth().updateUser(userId, {
                    disabled: false
                });
                
                return { banned: false };
            }
            
            return { 
                banned: true,
                reason: banData.reason,
                expiresAt: banData.expiresAt ? banData.expiresAt.toDate().toISOString() : null
            };
            
        } catch (error) {
            console.error('Error checking ban status:', error);
            throw new HttpsError('internal', 'Failed to check ban status');
        }
    }
);