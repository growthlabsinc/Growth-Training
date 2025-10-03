import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Track routine downloads
export const trackRoutineDownload = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { routineId } = data;
  const userId = context.auth.uid;

  if (!routineId) {
    throw new functions.https.HttpsError('invalid-argument', 'Routine ID is required');
  }

  try {
    // Update download count
    await db.collection('routines').doc(routineId)
      .collection('statistics').doc('stats').set({
        downloads: admin.firestore.FieldValue.increment(1),
        lastDownload: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

    // Track individual download
    await db.collection('routines').doc(routineId)
      .collection('downloads').doc(userId).set({
        userId,
        downloadedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Update creator stats
    const routine = await db.collection('routines').doc(routineId).get();
    if (routine.exists && routine.data()?.createdBy) {
      await updateCreatorStats(routine.data()!.createdBy, 'download');
    }

    return { success: true };
  } catch (error) {
    console.error('Error tracking download:', error);
    throw new functions.https.HttpsError('internal', 'Failed to track download');
  }
});

// Calculate trending routines
export const calculateTrendingRoutines = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const oneWeekAgo = new Date(now.toMillis() - 7 * 24 * 60 * 60 * 1000);

    try {
      // Get all public routines
      const routinesSnapshot = await db.collection('routines')
        .where('isPublic', '==', true)
        .where('isHidden', '==', false)
        .get();

      const trendingScores: Array<{
        routineId: string;
        score: number;
        data: any;
      }> = [];

      // Calculate trending score for each routine
      for (const doc of routinesSnapshot.docs) {
        const routine = doc.data();
        const routineId = doc.id;

        // Get recent stats
        const statsDoc = await db.collection('routines').doc(routineId)
          .collection('statistics').doc('stats').get();
        
        const stats = statsDoc.data() || {};

        // Get recent downloads
        const recentDownloads = await db.collection('routines').doc(routineId)
          .collection('downloads')
          .where('downloadedAt', '>=', oneWeekAgo)
          .get();

        // Get recent ratings
        const recentRatings = await db.collection('routines').doc(routineId)
          .collection('ratings')
          .where('timestamp', '>=', oneWeekAgo)
          .get();

        // Calculate trending score
        const downloadScore = recentDownloads.size * 10;
        const ratingScore = recentRatings.size * 5;
        const avgRatingBonus = (routine.averageRating || 0) * 20;
        const recencyBonus = routine.creationDate > oneWeekAgo ? 50 : 0;

        const totalScore = downloadScore + ratingScore + avgRatingBonus + recencyBonus;

        trendingScores.push({
          routineId,
          score: totalScore,
          data: {
            name: routine.name,
            createdBy: routine.createdBy,
            averageRating: routine.averageRating || 0,
            downloads: stats.downloads || 0,
          }
        });
      }

      // Sort by score and get top 20
      trendingScores.sort((a, b) => b.score - a.score);
      const topTrending = trendingScores.slice(0, 20);

      // Update trending collection
      const batch = db.batch();
      
      // Clear old trending
      const oldTrending = await db.collection('trending').get();
      oldTrending.forEach(doc => batch.delete(doc.ref));

      // Add new trending
      topTrending.forEach((item, index) => {
        const ref = db.collection('trending').doc();
        batch.set(ref, {
          routineId: item.routineId,
          rank: index + 1,
          score: item.score,
          ...item.data,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log('Updated trending routines:', topTrending.length);

    } catch (error) {
      console.error('Error calculating trending routines:', error);
    }
  });

// Update creator statistics
async function updateCreatorStats(creatorId: string, action: 'download' | 'rating') {
  const statsRef = db.collection('users').doc(creatorId)
    .collection('creatorStats').doc('stats');

  const increment = action === 'download' ? 
    { totalDownloads: admin.firestore.FieldValue.increment(1) } :
    { totalRatings: admin.firestore.FieldValue.increment(1) };

  await statsRef.set({
    ...increment,
    lastActivity: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

// Clean up old data
export const cleanupOldData = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    try {
      // Clean old resolved reports
      const oldReports = await db.collection('reports')
        .where('status', '==', 'resolved')
        .where('resolvedAt', '<', thirtyDaysAgo)
        .limit(100)
        .get();

      const batch = db.batch();
      oldReports.forEach(doc => batch.delete(doc.ref));
      await batch.commit();

      console.log('Cleaned up', oldReports.size, 'old reports');

    } catch (error) {
      console.error('Error cleaning up old data:', error);
    }
  });

// Verify creator status
export const verifyCreator = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can verify creators');
  }

  const { userId, verified } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
  }

  try {
    await db.collection('users').doc(userId).update({
      isVerified: verified,
      verifiedAt: verified ? admin.firestore.FieldValue.serverTimestamp() : null,
      verifiedBy: verified ? context.auth.uid : null,
    });

    return { success: true, message: `User ${verified ? 'verified' : 'unverified'} successfully` };
  } catch (error) {
    console.error('Error verifying creator:', error);
    throw new functions.https.HttpsError('internal', 'Failed to verify creator');
  }
});