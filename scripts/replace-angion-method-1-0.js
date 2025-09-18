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

async function replaceAngionMethod() {
  try {
    console.log('🚀 Replacing Angion Method 1.0 with multi-step version...');
    
    // First, backup the existing method
    const existingDoc = await db.collection('growthMethods').doc('angion_method_1_0').get();
    if (existingDoc.exists) {
      const backupData = existingDoc.data();
      await db.collection('growthMethods_backup').doc('angion_method_1_0_original').set({
        ...backupData,
        backedUpAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log('✅ Backed up original method');
    }
    
    // Prepare the replacement data with the original ID
    const replacementData = {
      ...angionMultistepData,
      id: 'angion_method_1_0', // Keep the original ID
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // If the document exists, preserve some fields
    if (existingDoc.exists) {
      const existingData = existingDoc.data();
      replacementData.createdAt = existingData.createdAt || admin.firestore.FieldValue.serverTimestamp();
      replacementData.viewCount = existingData.viewCount || 0;
      replacementData.averageRating = existingData.averageRating || 0;
      replacementData.totalRatings = existingData.totalRatings || 0;
    } else {
      replacementData.createdAt = admin.firestore.FieldValue.serverTimestamp();
      replacementData.viewCount = 0;
      replacementData.averageRating = 0;
      replacementData.totalRatings = 0;
    }
    
    // Remove the extra ID field we don't need
    delete replacementData.id;
    
    // Replace the method in Firebase
    await db.collection('growthMethods').doc('angion_method_1_0').set(replacementData);
    
    console.log('✅ Successfully replaced Angion Method 1.0 with multi-step version');
    
    // Update any user progress records to note the method has been updated
    console.log('📊 Updating user progress records...');
    const progressSnapshot = await db.collectionGroup('methodProgress')
      .where('methodId', '==', 'angion_method_1_0')
      .get();
    
    const batch = db.batch();
    let updateCount = 0;
    
    progressSnapshot.forEach(doc => {
      batch.update(doc.ref, {
        methodUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        methodHasSteps: true
      });
      updateCount++;
    });
    
    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Updated ${updateCount} user progress records`);
    }
    
    console.log('🎉 Angion Method 1.0 has been successfully replaced with the multi-step version!');
    
  } catch (error) {
    console.error('❌ Error replacing method:', error);
  } finally {
    process.exit();
  }
}

// Run the script
replaceAngionMethod();