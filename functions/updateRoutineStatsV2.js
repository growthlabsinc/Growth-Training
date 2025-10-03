const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

// Update routine statistics when ratings change
exports.updateRoutineStats = onDocumentWritten(
    {
        document: 'routines/{routineId}/ratings/{ratingId}',
        region: 'us-central1'
    },
    async (event) => {
        const routineId = event.params.routineId;
        const db = admin.firestore();
        
        console.log(`Updating stats for routine: ${routineId}`);
        
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
                if (rating && typeof rating === 'number' && rating >= 1 && rating <= 5) {
                    totalRating += rating;
                    ratingCount++;
                }
            });

            const averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

            // Update routine document
            await db.collection('routines').doc(routineId).update({
                averageRating: Math.round(averageRating * 10) / 10, // Round to 1 decimal place
                ratingCount,
                lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
            });
            
            console.log(`Updated routine ${routineId}: avg=${averageRating}, count=${ratingCount}`);

        } catch (error) {
            console.error('Error updating routine stats:', error);
            // Don't throw error to prevent retries for non-critical updates
        }
        
        return null;
    }
);