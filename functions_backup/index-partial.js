/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Import the fixed manageLiveActivityUpdates function
const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates');

// Export the Live Activity management function
exports.manageLiveActivityUpdates = manageLiveActivityUpdates;

// Track routine downloads
exports.trackRoutineDownload = onCall({
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { routineId } = request.data;
  const userId = request.auth.uid;

  if (!routineId) {
    throw new HttpsError('invalid-argument', 'Routine ID is required');
  }

  try {
    const db = admin.firestore();
    
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

    return { success: true };
  } catch (error) {
    console.error('Error tracking download:', error);
    throw new HttpsError('internal', 'Failed to track download');
  }
});

// Update routine statistics when ratings change
exports.updateRoutineStats = onDocumentWritten({
  document: 'routines/{routineId}/ratings/{ratingId}',
  region: 'us-central1'
}, async (event) => {
  const routineId = event.params.routineId;
  const db = admin.firestore();
  
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

  } catch (error) {
    console.error('Error updating routine stats:', error);
  }
});

console.log('Functions index.js loaded successfully');