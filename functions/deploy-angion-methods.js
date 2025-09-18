const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin with application default credentials
admin.initializeApp();

const db = admin.firestore();

// Methods to deploy
const methodsToReplace = [
  {
    fileName: '../scripts/angion-method-1-0-multistep.json',
    methodId: 'angion_method_1_0',
    name: 'Angion Method 1.0'
  },
  {
    fileName: '../scripts/angion-methods-multistep/angio-pumping.json',
    methodId: 'angio_pumping',
    name: 'Angio Pumping'
  },
  {
    fileName: '../scripts/angion-methods-multistep/angion-method-2-0.json',
    methodId: 'angion_method_2_0',
    name: 'Angion Method 2.0'
  },
  {
    fileName: '../scripts/angion-methods-multistep/jelq-2-0.json',
    methodId: 'jelq_2_0',
    name: 'Jelq 2.0'
  },
  {
    fileName: '../scripts/angion-methods-multistep/vascion.json',
    methodId: 'vascion',
    name: 'Vascion'
  }
];

async function deployMethods() {
  console.log('🚀 Starting Angion Methods multi-step deployment...\n');
  
  const batch = db.batch();
  let successCount = 0;
  
  for (const method of methodsToReplace) {
    console.log(`📋 Processing ${method.name}...`);
    
    try {
      // Read the JSON file
      const filePath = path.join(__dirname, method.fileName);
      const methodData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      
      // Get existing method to preserve user data
      const existingDoc = await db.collection('growthMethods').doc(method.methodId).get();
      
      if (existingDoc.exists) {
        const existingData = existingDoc.data();
        // Preserve user data
        methodData.createdAt = existingData.createdAt || admin.firestore.FieldValue.serverTimestamp();
        methodData.viewCount = existingData.viewCount || 0;
        methodData.averageRating = existingData.averageRating || 0;
        methodData.totalRatings = existingData.totalRatings || 0;
        console.log(`  ✅ Preserving user data for ${method.name}`);
      } else {
        methodData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        methodData.viewCount = 0;
        methodData.averageRating = 0;
        methodData.totalRatings = 0;
      }
      
      // Add/update common fields
      methodData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      methodData.isActive = true;
      methodData.hasMultipleSteps = true;
      
      // Add to batch
      batch.set(db.collection('growthMethods').doc(method.methodId), methodData);
      successCount++;
      console.log(`  ✅ Prepared ${method.name} for deployment`);
      
    } catch (error) {
      console.error(`  ❌ Error processing ${method.name}:`, error.message);
    }
  }
  
  if (successCount > 0) {
    console.log(`\n⏳ Deploying ${successCount} methods to Firebase...`);
    try {
      await batch.commit();
      console.log('\n🎉 All methods deployed successfully!');
      console.log('\n📝 Summary:');
      console.log(`  - Methods deployed: ${successCount}/${methodsToReplace.length}`);
      console.log(`  - Each method now has detailed step-by-step instructions`);
      console.log(`  - Timer configurations updated for step progression`);
    } catch (error) {
      console.error('\n❌ Error committing batch:', error);
    }
  } else {
    console.log('\n❌ No methods were prepared for deployment');
  }
  
  process.exit();
}

// Run the deployment
deployMethods().catch(error => {
  console.error('❌ Deployment failed:', error);
  process.exit(1);
});