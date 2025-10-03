const functions = require('firebase-functions');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
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
    'routines/{routineId}',
    async (event) => {
        const snap = event.data;
        const context = event;
        const routine = snap.data();
        
        // Only moderate community-shared routines
        if (!routine.shareWithCommunity) {
            console.log('Routine not shared with community, skipping moderation');
            return null;
        }
        
        console.log(`Moderating new routine: ${context.params.routineId}`);
        
        // Combine text fields for checking
        const textToCheck = `${routine.name || ''} ${routine.description || ''} ${JSON.stringify(routine.stages || [])}`.toLowerCase();
        
        // Check for profanity
        const containsProfanity = profanityList.some(word => 
            textToCheck.includes(word.toLowerCase())
        );
        
        // Check for suspicious patterns (e.g., excessive caps, spam patterns)
        const excessiveCaps = (routine.name || '').split('').filter(c => c === c.toUpperCase() && c !== c.toLowerCase()).length > 
                             (routine.name || '').length * 0.7;
        
        const spamPatterns = [
            /(.)\1{4,}/g, // Repeated characters (e.g., "aaaa")
            /\b(buy|sale|discount|click here|visit)\b/gi, // Commercial spam
            /\b\d{3,}\b/g, // Phone numbers or long number sequences
            /\bhttps?:\/\//gi // URLs
        ];
        
        const containsSpam = spamPatterns.some(pattern => pattern.test(textToCheck));
        
        // Determine moderation status
        let moderationStatus = 'approved';
        let moderationReason = null;
        
        if (containsProfanity) {
            moderationStatus = 'rejected';
            moderationReason = 'profanity';
        } else if (containsSpam || excessiveCaps) {
            moderationStatus = 'flagged';
            moderationReason = containsSpam ? 'spam' : 'excessive_caps';
        }
        
        // Update routine with moderation status
        await snap.ref.update({
            moderationStatus,
            moderationReason,
            moderatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log(`Routine ${context.params.routineId} moderated: ${moderationStatus}`);
        
        // If flagged or rejected, notify admins
        if (moderationStatus !== 'approved') {
            // TODO: Send notification to admin dashboard or email
            console.log(`Alert: Routine ${context.params.routineId} requires review - ${moderationReason}`);
        }
        
        return null;
    }
);

// Process reports
exports.processReport = onDocumentCreated(
    'reports/{reportId}',
    async (event) => {
        const snap = event.data;
        const context = event;
        const report = snap.data();
        console.log(`Processing new report: ${context.params.reportId}`);
        
        // Handle different content types
        if (report.contentType === 'routine') {
            const routineRef = db.collection('routines').doc(report.contentId);
            
            try {
                const routine = await routineRef.get();
                if (!routine.exists) {
                    console.error(`Routine ${report.contentId} not found`);
                    return null;
                }
                
                const currentReports = routine.data().reportCount || 0;
                const newReportCount = currentReports + 1;
                
                // Auto-flag if reaches threshold
                const FLAG_THRESHOLD = 3;
                const REMOVE_THRESHOLD = 10;
                
                let updateData = {
                    reportCount: newReportCount,
                    lastReportedAt: admin.firestore.FieldValue.serverTimestamp()
                };
                
                if (newReportCount >= REMOVE_THRESHOLD) {
                    updateData.moderationStatus = 'removed';
                    updateData.moderationReason = 'excessive_reports';
                    console.log(`Routine ${report.contentId} auto-removed due to excessive reports`);
                } else if (newReportCount >= FLAG_THRESHOLD) {
                    updateData.moderationStatus = 'flagged';
                    updateData.flaggedAt = admin.firestore.FieldValue.serverTimestamp();
                    console.log(`Routine ${report.contentId} flagged for review`);
                }
                
                await routineRef.update(updateData);
                
                // Add to moderation queue if flagged
                if (newReportCount >= FLAG_THRESHOLD) {
                    await db.collection('moderation').doc('queue').collection('items').add({
                        contentId: report.contentId,
                        contentType: 'routine',
                        reportCount: newReportCount,
                        latestReport: report,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        status: 'pending'
                    });
                }
                
            } catch (error) {
                console.error('Error processing routine report:', error);
            }
        } else if (report.contentType === 'user') {
            // Handle user reports
            console.log(`User report for ${report.contentId} - manual review required`);
            
            // Add to moderation queue for manual review
            await db.collection('moderation').doc('queue').collection('userReports').add({
                userId: report.contentId,
                report: report,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'pending'
            });
        }
        
        return null;
    }
);

// Admin function to ban user
exports.banUser = onCall(
    { region: 'us-central1' },
    async (request) => {
        const data = request.data;
        const context = request;
        
        // Verify admin privileges
        if (!context.auth || !context.auth.token.admin) {
            throw new HttpsError(
                'permission-denied',
                'Must be an admin to ban users'
            );
        }
    
    const { userId, reason, permanent = false } = data;
    
    if (!userId || !reason) {
        throw new HttpsError(
            'invalid-argument',
            'userId and reason are required'
        );
    }
    
    console.log(`Admin ${context.auth.uid} banning user ${userId} for: ${reason}`);
    
    try {
        // Add to banned users collection
        await db.collection('moderation').doc('bannedUsers').collection('users').doc(userId).set({
            bannedAt: admin.firestore.FieldValue.serverTimestamp(),
            bannedBy: context.auth.uid,
            reason: reason,
            permanent: permanent,
            unbannedAt: permanent ? null : admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
            )
        });
        
        // Remove/hide all their content
        const routines = await db.collection('routines')
            .where('createdBy', '==', userId)
            .where('shareWithCommunity', '==', true)
            .get();
        
        const batch = db.batch();
        routines.forEach(doc => {
            batch.update(doc.ref, {
                moderationStatus: 'removed',
                removedReason: 'user_banned',
                removedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        
        await batch.commit();
        
        console.log(`Successfully banned user ${userId} and removed ${routines.size} routines`);
        
        return { 
            success: true, 
            routinesRemoved: routines.size 
        };
        
    } catch (error) {
        console.error('Error banning user:', error);
        throw new HttpsError(
            'internal',
            'Failed to ban user'
        );
    }
});

// Admin function to moderate content
exports.moderateContent = onCall(
    { region: 'us-central1' },
    async (request) => {
        const data = request.data;
        const context = request;
        
        // Verify admin or moderator privileges
        if (!context.auth || (!context.auth.token.admin && !context.auth.token.moderator)) {
            throw new HttpsError(
                'permission-denied',
                'Must be an admin or moderator'
            );
        }
    
    const { contentId, contentType, action, reason } = data;
    
    if (!contentId || !contentType || !action) {
        throw new HttpsError(
            'invalid-argument',
            'contentId, contentType, and action are required'
        );
    }
    
    console.log(`Moderator ${context.auth.uid} taking action ${action} on ${contentType} ${contentId}`);
    
    try {
        if (contentType === 'routine') {
            const routineRef = db.collection('routines').doc(contentId);
            
            let updateData = {
                moderationStatus: action === 'approve' ? 'approved' : 
                                 action === 'reject' ? 'rejected' : 'removed',
                moderatedBy: context.auth.uid,
                moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
                moderationNote: reason || null
            };
            
            await routineRef.update(updateData);
            
            // Update moderation queue
            const queueItems = await db.collection('moderation').doc('queue').collection('items')
                .where('contentId', '==', contentId)
                .get();
            
            const batch = db.batch();
            queueItems.forEach(doc => {
                batch.update(doc.ref, {
                    status: 'resolved',
                    resolvedBy: context.auth.uid,
                    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
                    resolution: action
                });
            });
            await batch.commit();
            
            return { success: true };
        }
        
        throw new HttpsError(
            'invalid-argument',
            `Unsupported content type: ${contentType}`
        );
        
    } catch (error) {
        console.error('Error moderating content:', error);
        throw new HttpsError(
            'internal',
            'Failed to moderate content'
        );
    }
});

// Scheduled function to clean up old reports
exports.cleanupOldReports = onSchedule(
    { 
        schedule: 'every 168 hours', // Run weekly (7 days * 24 hours)
        region: 'us-central1'
    },
    async (event) => {
        console.log('Running weekly cleanup of old reports');
    
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    try {
        // Clean up resolved reports older than 30 days
        const oldReports = await db.collection('reports')
            .where('status', '==', 'resolved')
            .where('resolutionDate', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
            .limit(500) // Process in batches
            .get();
        
        const batch = db.batch();
        oldReports.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Deleted ${oldReports.size} old resolved reports`);
        
        // Clean up old moderation queue items
        const oldQueueItems = await db.collection('moderation').doc('queue').collection('items')
            .where('status', '==', 'resolved')
            .where('resolvedAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
            .limit(500)
            .get();
        
        const batch2 = db.batch();
        oldQueueItems.forEach(doc => {
            batch2.delete(doc.ref);
        });
        
        await batch2.commit();
        console.log(`Deleted ${oldQueueItems.size} old moderation queue items`);
        
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
    
    return null;
});

// Function to check if user is banned
exports.checkUserBanned = onCall(
    { region: 'us-central1' },
    async (request) => {
        const data = request.data;
        const context = request;
        
        if (!context.auth) {
            throw new HttpsError(
                'unauthenticated',
                'Must be authenticated'
            );
        }
    
    const userId = data.userId || context.auth.uid;
    
    try {
        const banDoc = await db.collection('moderation').doc('bannedUsers')
            .collection('users').doc(userId).get();
        
        if (!banDoc.exists) {
            return { banned: false };
        }
        
        const banData = banDoc.data();
        
        // Check if ban has expired
        if (!banData.permanent && banData.unbannedAt) {
            const unbanDate = banData.unbannedAt.toDate();
            if (new Date() > unbanDate) {
                // Ban expired, remove it
                await banDoc.ref.delete();
                return { banned: false };
            }
        }
        
        return {
            banned: true,
            reason: banData.reason,
            permanent: banData.permanent,
            unbannedAt: banData.unbannedAt ? banData.unbannedAt.toDate() : null
        };
        
    } catch (error) {
        console.error('Error checking ban status:', error);
        throw new HttpsError(
            'internal',
            'Failed to check ban status'
        );
    }
    }
);