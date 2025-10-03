const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Educational resource image URLs mapping
const resourceImageUrls = {
  'basics-vascular-health': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80',
  'technique-proper-execution': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
  'progression-vascularity-timeline': 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=800&q=80',
  'basics-abbreviations-glossary': 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800&q=80',
  'complete-angion-methods-list': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
  'angion-methods-hand-techniques-breakdown': 'https://images.unsplash.com/photo-1583088580009-2d947c3e5c84?w=800&q=80',
  'personal-journey-angion-transformation': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800&q=80',
  'am20-erection-level-guidance': 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=800&q=80',
  'sabre-techniques-birth-and-development': 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=800&q=80',
  'path-of-eleven-sabre-progressive-workout': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
  'sabre-erection-concerns-faq': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80',
  'sabre-user-feedback-experiences': 'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800&q=80',
  'arterialization-blood-flow-science': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80',
  'janus-protocol-four-week-rotating': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800&q=80'
};

// HTTPS function to update educational resource images
exports.updateEducationalResourceImages = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    console.log('Fetching educational resources...');
    
    const resourcesSnapshot = await db.collection('educationalResources').get();
    
    if (resourcesSnapshot.empty) {
      res.status(404).json({ message: 'No educational resources found in the database.' });
      return;
    }
    
    console.log(`Found ${resourcesSnapshot.size} educational resources.`);
    
    const batch = db.batch();
    let updateCount = 0;
    const updates = [];
    
    resourcesSnapshot.forEach((doc) => {
      const resourceId = doc.id;
      const data = doc.data();
      
      if (resourceImageUrls[resourceId]) {
        batch.update(doc.ref, {
          visual_placeholder_url: resourceImageUrls[resourceId],
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        updates.push({
          resourceId,
          title: data.title,
          newImageUrl: resourceImageUrls[resourceId]
        });
      }
    });
    
    if (updateCount > 0) {
      await batch.commit();
      res.status(200).json({
        message: `Successfully updated ${updateCount} educational resources with proper image URLs.`,
        updates
      });
    } else {
      res.status(200).json({ message: 'No resources needed updating.' });
    }
    
  } catch (error) {
    console.error('Error updating educational resources:', error);
    res.status(500).json({ error: error.message });
  }
});

// Callable function for client-side invocation
exports.updateEducationalResourceImagesCallable = functions.https.onCall(async (data, context) => {
  try {
    const db = admin.firestore();
    
    const resourcesSnapshot = await db.collection('educationalResources').get();
    
    if (resourcesSnapshot.empty) {
      return { success: false, message: 'No educational resources found.' };
    }
    
    const batch = db.batch();
    let updateCount = 0;
    const updates = [];
    
    resourcesSnapshot.forEach((doc) => {
      const resourceId = doc.id;
      const docData = doc.data();
      
      if (resourceImageUrls[resourceId]) {
        batch.update(doc.ref, {
          visual_placeholder_url: resourceImageUrls[resourceId],
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        updates.push({
          resourceId,
          title: docData.title,
          newImageUrl: resourceImageUrls[resourceId]
        });
      }
    });
    
    if (updateCount > 0) {
      await batch.commit();
      return {
        success: true,
        message: `Updated ${updateCount} resources.`,
        updates
      };
    } else {
      return { success: true, message: 'No resources needed updating.' };
    }
    
  } catch (error) {
    console.error('Error updating educational resources:', error);
    return { success: false, error: error.message };
  }
});