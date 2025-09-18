const admin = require('firebase-admin');
const serviceAccount = require('../Growth/Resources/Plist/dev.GoogleService-Info.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: serviceAccount.project_info.project_id,
    clientEmail: `firebase-adminsdk@${serviceAccount.project_info.project_id}.iam.gserviceaccount.com`,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
  })
});

const db = admin.firestore();

// Define proper image URLs for each educational resource
// Using Unsplash URLs for high-quality, free stock photos
const resourceImageUrls = {
  'basics-vascular-health': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80', // Red blood cells
  'technique-proper-execution': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80', // Exercise form
  'progression-vascularity-timeline': 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=800&q=80', // Timeline/calendar
  'basics-abbreviations-glossary': 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800&q=80', // Open book
  'complete-angion-methods-list': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80', // Fitness/health
  'angion-methods-hand-techniques-breakdown': 'https://images.unsplash.com/photo-1583088580009-2d947c3e5c84?w=800&q=80', // Hands
  'personal-journey-angion-transformation': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800&q=80', // Success/achievement
  'am20-erection-level-guidance': 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=800&q=80', // Medical guidance
  'sabre-techniques-birth-and-development': 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=800&q=80', // Innovation/development
  'path-of-eleven-sabre-progressive-workout': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80', // Workout progression
  'sabre-erection-concerns-faq': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80', // Medical consultation
  'sabre-user-feedback-experiences': 'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800&q=80', // Community/feedback
  'arterialization-blood-flow-science': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80', // Blood flow
  'janus-protocol-four-week-rotating': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800&q=80' // Training schedule
};

async function updateEducationalResourceImages() {
  try {
    console.log('Fetching educational resources...');
    
    const resourcesSnapshot = await db.collection('educationalResources').get();
    
    if (resourcesSnapshot.empty) {
      console.log('No educational resources found in the database.');
      return;
    }
    
    console.log(`Found ${resourcesSnapshot.size} educational resources.`);
    
    const batch = db.batch();
    let updateCount = 0;
    
    resourcesSnapshot.forEach((doc) => {
      const resourceId = doc.id;
      const data = doc.data();
      
      if (resourceImageUrls[resourceId]) {
        batch.update(doc.ref, {
          visual_placeholder_url: resourceImageUrls[resourceId],
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
        console.log(`Updating image for: ${data.title || resourceId}`);
      } else {
        console.log(`No image URL defined for resource: ${resourceId}`);
      }
    });
    
    if (updateCount > 0) {
      await batch.commit();
      console.log(`\nSuccessfully updated ${updateCount} educational resources with proper image URLs.`);
    } else {
      console.log('\nNo resources needed updating.');
    }
    
  } catch (error) {
    console.error('Error updating educational resources:', error);
  } finally {
    process.exit();
  }
}

// Run the update
updateEducationalResourceImages();