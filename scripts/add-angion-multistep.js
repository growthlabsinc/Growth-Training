const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const db = admin.firestore();

// Read the multi-step Angion Method data
const angionMultistepData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'angion-method-1-0-multistep.json'), 'utf8')
);

async function addMultiStepMethod() {
  try {
    console.log('🚀 Adding Angion Method 1.0 (Multi-step) to Firebase...');
    
    // Add to growthMethods collection
    await db.collection('growthMethods').doc(angionMultistepData.id).set({
      ...angionMultistepData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      viewCount: 0,
      averageRating: 0,
      totalRatings: 0,
      isActive: true
    });
    
    console.log('✅ Successfully added Angion Method 1.0 (Multi-step)');
    
    // Optional: Update the original method to reference this detailed version
    await db.collection('growthMethods').doc('angion_method_1_0').update({
      detailedVersionId: angionMultistepData.id,
      hasDetailedVersion: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Updated original method with reference to detailed version');
    
    // Add to featured methods if needed
    const featuredDoc = await db.collection('featured').doc('methods').get();
    if (featuredDoc.exists) {
      const featuredData = featuredDoc.data();
      const methodIds = featuredData.methodIds || [];
      
      if (!methodIds.includes(angionMultistepData.id)) {
        methodIds.push(angionMultistepData.id);
        await db.collection('featured').doc('methods').update({
          methodIds: methodIds,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Added to featured methods');
      }
    }
    
    console.log('🎉 Angion Method 1.0 (Multi-step) has been successfully added to the database!');
    
  } catch (error) {
    console.error('❌ Error adding method:', error);
  } finally {
    process.exit();
  }
}

// Run the script
addMultiStepMethod();