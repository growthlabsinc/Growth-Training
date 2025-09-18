import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Process routine reports
export const processRoutineReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    try {
      // Validate report data
      if (!report.reportedItemId || !report.reportedItemType || !report.reason) {
        console.error('Invalid report data:', reportId);
        return;
      }

      // Check urgency based on reason
      const urgentReasons = ['harmful', 'impersonation', 'copyright'];
      const isUrgent = urgentReasons.includes(report.reason);

      // Update report with processing info
      await snap.ref.update({
        status: 'pending',
        isUrgent,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If urgent, notify moderators
      if (isUrgent) {
        await notifyModerators(reportId, report);
      }

      // Check if item has multiple reports
      const reportCount = await checkReportCount(report.reportedItemId, report.reportedItemType);
      
      // Auto-hide content if threshold reached
      if (reportCount >= 3) {
        await autoHideContent(report.reportedItemId, report.reportedItemType);
      }

      // Log for analytics
      await logModerationEvent('report_created', {
        reportId,
        itemType: report.reportedItemType,
        reason: report.reason,
        isUrgent,
      });

    } catch (error) {
      console.error('Error processing report:', error);
      await snap.ref.update({
        status: 'error',
        error: error.message,
      });
    }
  });

// Process user bans
export const processUserBan = functions.https.onCall(async (data, context) => {
  // Check if caller is admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can ban users');
  }

  const { userId, reason, duration } = data;

  if (!userId || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const banExpiry = duration ? 
      new Date(Date.now() + duration * 24 * 60 * 60 * 1000) : 
      null; // Permanent ban

    // Add to banned users collection
    await db.collection('moderation').doc('bannedUsers').collection('users').doc(userId).set({
      userId,
      reason,
      bannedAt: admin.firestore.FieldValue.serverTimestamp(),
      bannedBy: context.auth.uid,
      expiresAt: banExpiry,
      isPermanent: !duration,
    });

    // Disable user's auth account
    await admin.auth().updateUser(userId, {
      disabled: true,
    });

    // Hide all user's content
    await hideUserContent(userId);

    // Log moderation action
    await logModerationEvent('user_banned', {
      userId,
      reason,
      moderatorId: context.auth.uid,
      duration: duration || 'permanent',
    });

    return { success: true, message: 'User banned successfully' };
  } catch (error) {
    console.error('Error banning user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to ban user');
  }
});

// Check and lift expired bans
export const checkExpiredBans = functions.pubsub.schedule('every 1 hours').onRun(async () => {
  const now = admin.firestore.Timestamp.now();
  
  const expiredBans = await db.collection('moderation')
    .doc('bannedUsers')
    .collection('users')
    .where('expiresAt', '<=', now)
    .where('isPermanent', '==', false)
    .get();

  for (const doc of expiredBans.docs) {
    const ban = doc.data();
    
    try {
      // Re-enable user account
      await admin.auth().updateUser(ban.userId, {
        disabled: false,
      });

      // Remove from banned users
      await doc.ref.delete();

      // Restore user content visibility
      await restoreUserContent(ban.userId);

      await logModerationEvent('ban_lifted', {
        userId: ban.userId,
        originalReason: ban.reason,
      });
    } catch (error) {
      console.error('Error lifting ban for user:', ban.userId, error);
    }
  }
});

// Update routine statistics
export const updateRoutineStats = functions.firestore
  .document('routines/{routineId}/ratings/{ratingId}')
  .onWrite(async (change, context) => {
    const routineId = context.params.routineId;
    
    try {
      // Get all ratings for this routine
      const ratingsSnapshot = await db.collection('routines')
        .doc(routineId)
        .collection('ratings')
        .get();

      let totalRating = 0;
      let ratingCount = 0;

      ratingsSnapshot.forEach(doc => {
        const rating = doc.data().rating;
        if (rating) {
          totalRating += rating;
          ratingCount++;
        }
      });

      const averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      // Update routine document
      await db.collection('routines').doc(routineId).update({
        averageRating,
        ratingCount,
        lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update statistics collection
      await db.collection('routines').doc(routineId)
        .collection('statistics').doc('stats').set({
          averageRating,
          ratingCount,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

    } catch (error) {
      console.error('Error updating routine stats:', error);
    }
  });

// Helper functions

async function notifyModerators(reportId: string, report: any) {
  // Implementation would send push notifications or emails to moderators
  console.log('Notifying moderators of urgent report:', reportId);
}

async function checkReportCount(itemId: string, itemType: string): Promise<number> {
  const reports = await db.collection('reports')
    .where('reportedItemId', '==', itemId)
    .where('reportedItemType', '==', itemType)
    .where('status', 'in', ['pending', 'reviewing'])
    .get();
  
  return reports.size;
}

async function autoHideContent(itemId: string, itemType: string) {
  if (itemType === 'routine') {
    await db.collection('routines').doc(itemId).update({
      isHidden: true,
      hiddenAt: admin.firestore.FieldValue.serverTimestamp(),
      hiddenReason: 'auto_moderation',
    });
  }
}

async function hideUserContent(userId: string) {
  // Hide all user's routines
  const routines = await db.collection('routines')
    .where('createdBy', '==', userId)
    .get();

  const batch = db.batch();
  
  routines.forEach(doc => {
    batch.update(doc.ref, {
      isHidden: true,
      hiddenAt: admin.firestore.FieldValue.serverTimestamp(),
      hiddenReason: 'user_banned',
    });
  });

  await batch.commit();
}

async function restoreUserContent(userId: string) {
  const routines = await db.collection('routines')
    .where('createdBy', '==', userId)
    .where('hiddenReason', '==', 'user_banned')
    .get();

  const batch = db.batch();
  
  routines.forEach(doc => {
    batch.update(doc.ref, {
      isHidden: false,
      hiddenAt: admin.firestore.FieldValue.delete(),
      hiddenReason: admin.firestore.FieldValue.delete(),
    });
  });

  await batch.commit();
}

async function logModerationEvent(action: string, data: any) {
  await db.collection('moderation').doc('logs').collection('events').add({
    action,
    data,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}