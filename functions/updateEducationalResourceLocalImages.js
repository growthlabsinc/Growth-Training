const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Educational resource local image names mapping based on the imagesets we created
const resourceLocalImageNames = {
  // Basic/Introduction articles
  'beginners-guide-angion': 'beginners-guide-angion',
  'angion-method-basics': 'beginners-guide-angion',
  'preparing-for-angion': 'preparing-angion-foundations',
  'angion-foundations': 'preparing-angion-foundations',
  
  // Intermediate articles
  'intermediate-angion': 'intermediate-angion-2-0',
  'intermediate-mastering-angion': 'intermediate-angion-2-0',
  'cardiovascular-training': 'intermediate-cardiovascular-training',
  'intermediate-cardiovascular': 'intermediate-cardiovascular-training',
  
  // Advanced articles
  'advanced-angion': 'advanced-angion-vascion',
  'advanced-vascion': 'advanced-angion-vascion',
  'the-vascion': 'advanced-angion-vascion',
  
  // Health and methodology articles
  'holistic-male-health': 'holistic-male-health',
  'male-sexual-health': 'holistic-male-health',
  'holistic-health-growth': 'holistic-male-health',
  
  // Evolution and methodology
  'angion-method-evolution': 'angion-method-evolving',
  'evolving-approach': 'angion-method-evolving',
  'angion-evolution': 'angion-method-evolving',
  
  // Blood vessel science and mechanisms
  'blood-vessel-growth': 'blood-vessel-growth-mechanisms',
  'core-mechanisms': 'blood-vessel-growth-mechanisms',
  'vessel-growth-science': 'blood-vessel-growth-mechanisms',
  'vascular-science': 'blood-vessel-growth-mechanisms'
};

// HTTPS function to update educational resource local images
exports.updateEducationalResourceLocalImages = functions.https.onRequest(async (req, res) => {
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
      const title = data.title || '';
      
      // Try to match by resource ID first, then by title keywords
      let localImageName = resourceLocalImageNames[resourceId];
      
      if (!localImageName) {
        // Try to match by title content (case-insensitive)
        const titleLower = title.toLowerCase();
        
        if (titleLower.includes('beginner') && titleLower.includes('guide')) {
          localImageName = 'beginners-guide-angion';
        } else if (titleLower.includes('preparing') || titleLower.includes('foundation')) {
          localImageName = 'preparing-angion-foundations';
        } else if (titleLower.includes('intermediate') && titleLower.includes('2.0')) {
          localImageName = 'intermediate-angion-2-0';
        } else if (titleLower.includes('intermediate') && titleLower.includes('cardiovascular')) {
          localImageName = 'intermediate-cardiovascular-training';
        } else if (titleLower.includes('advanced') && (titleLower.includes('vascion') || titleLower.includes('angion'))) {
          localImageName = 'advanced-angion-vascion';
        } else if (titleLower.includes('holistic') && titleLower.includes('male')) {
          localImageName = 'holistic-male-health';
        } else if (titleLower.includes('evolving') || titleLower.includes('evolution')) {
          localImageName = 'angion-method-evolving';
        } else if (titleLower.includes('blood vessel') || titleLower.includes('core mechanisms') || titleLower.includes('vessel growth')) {
          localImageName = 'blood-vessel-growth-mechanisms';
        }
      }
      
      if (localImageName) {
        batch.update(doc.ref, {
          local_image_name: localImageName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        updates.push({
          resourceId,
          title: title,
          localImageName: localImageName
        });
        console.log(`Matched "${title}" -> ${localImageName}`);
      } else {
        console.log(`No match found for: "${title}" (ID: ${resourceId})`);
      }
    });
    
    if (updateCount > 0) {
      await batch.commit();
      res.status(200).json({
        message: `Successfully updated ${updateCount} educational resources with local image names.`,
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
exports.updateEducationalResourceLocalImagesCallable = functions.https.onCall(async (data, context) => {
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
      const data = doc.data();
      const title = data.title || '';
      
      // Try to match by resource ID first, then by title keywords
      let localImageName = resourceLocalImageNames[resourceId];
      
      if (!localImageName) {
        // Try to match by title content (case-insensitive)
        const titleLower = title.toLowerCase();
        
        if (titleLower.includes('beginner') && titleLower.includes('guide')) {
          localImageName = 'beginners-guide-angion';
        } else if (titleLower.includes('preparing') || titleLower.includes('foundation')) {
          localImageName = 'preparing-angion-foundations';
        } else if (titleLower.includes('intermediate') && titleLower.includes('2.0')) {
          localImageName = 'intermediate-angion-2-0';
        } else if (titleLower.includes('intermediate') && titleLower.includes('cardiovascular')) {
          localImageName = 'intermediate-cardiovascular-training';
        } else if (titleLower.includes('advanced') && (titleLower.includes('vascion') || titleLower.includes('angion'))) {
          localImageName = 'advanced-angion-vascion';
        } else if (titleLower.includes('holistic') && titleLower.includes('male')) {
          localImageName = 'holistic-male-health';
        } else if (titleLower.includes('evolving') || titleLower.includes('evolution')) {
          localImageName = 'angion-method-evolving';
        } else if (titleLower.includes('blood vessel') || titleLower.includes('core mechanisms') || titleLower.includes('vessel growth')) {
          localImageName = 'blood-vessel-growth-mechanisms';
        }
      }
      
      if (localImageName) {
        batch.update(doc.ref, {
          local_image_name: localImageName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        updates.push({
          resourceId,
          title: title,
          localImageName: localImageName
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