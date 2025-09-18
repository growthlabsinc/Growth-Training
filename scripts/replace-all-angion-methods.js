import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { readFileSync } from 'fs';

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin
const serviceAccount = JSON.parse(readFileSync(new URL('./service-account-key.json', import.meta.url)));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const db = admin.firestore();

// Methods to replace
const methodsToReplace = [
  {
    fileName: 'angion-method-1-0-multistep.json',
    methodId: 'angion_method_1_0',
    name: 'Angion Method 1.0'
  },
  {
    fileName: 'angion-methods-multistep/angio-pumping.json',
    methodId: 'angio_pumping',
    name: 'Angio Pumping'
  },
  {
    fileName: 'angion-methods-multistep/angion-method-2-0.json',
    methodId: 'angion_method_2_0',
    name: 'Angion Method 2.0'
  },
  {
    fileName: 'angion-methods-multistep/jelq-2-0.json',
    methodId: 'jelq_2_0',
    name: 'Jelq 2.0'
  },
  {
    fileName: 'angion-methods-multistep/vascion.json',
    methodId: 'vascion',
    name: 'Vascion'
  }
];

async function replaceAllMethods() {
  try {
    console.log('🚀 Starting Angion Methods multi-step replacement...\n');
    
    const batch = db.batch();
    let backupBatch = db.batch();
    let backupCount = 0;
    
    for (const method of methodsToReplace) {
      console.log(`📋 Processing ${method.name}...`);
      
      // Read the new multi-step data
      const filePath = path.join(__dirname, method.fileName);
      if (!fs.existsSync(filePath)) {
        console.log(`  ❌ File not found: ${method.fileName}`);
        continue;
      }
      
      const newMethodData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      
      // Backup existing method if it exists
      const existingDoc = await db.collection('growthMethods').doc(method.methodId).get();
      if (existingDoc.exists) {
        const backupData = existingDoc.data();
        backupBatch.set(
          db.collection('growthMethods_backup').doc(`${method.methodId}_${Date.now()}`),
          {
            ...backupData,
            backedUpAt: admin.firestore.FieldValue.serverTimestamp(),
            reason: 'Multi-step conversion'
          }
        );
        backupCount++;
        console.log(`  ✅ Backed up existing ${method.name}`);
        
        // Preserve important fields
        newMethodData.createdAt = backupData.createdAt || admin.firestore.FieldValue.serverTimestamp();
        newMethodData.viewCount = backupData.viewCount || 0;
        newMethodData.averageRating = backupData.averageRating || 0;
        newMethodData.totalRatings = backupData.totalRatings || 0;
      } else {
        console.log(`  ℹ️  No existing method found, creating new`);
        newMethodData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        newMethodData.viewCount = 0;
        newMethodData.averageRating = 0;
        newMethodData.totalRatings = 0;
      }
      
      // Add common fields
      newMethodData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      newMethodData.isActive = true;
      newMethodData.hasMultipleSteps = true;
      
      // Add to batch
      batch.set(db.collection('growthMethods').doc(method.methodId), newMethodData);
      console.log(`  ✅ Prepared ${method.name} for update`);
    }
    
    // Commit backups first
    if (backupCount > 0) {
      await backupBatch.commit();
      console.log(`\n✅ Created ${backupCount} backups`);
    }
    
    // Commit all updates
    await batch.commit();
    console.log('\n✅ All methods updated successfully!');
    
    // Update user progress records to note methods have been updated
    console.log('\n📊 Updating user progress records...');
    
    for (const method of methodsToReplace) {
      const progressSnapshot = await db.collectionGroup('methodProgress')
        .where('methodId', '==', method.methodId)
        .get();
      
      if (!progressSnapshot.empty) {
        const progressBatch = db.batch();
        let updateCount = 0;
        
        progressSnapshot.forEach(doc => {
          progressBatch.update(doc.ref, {
            methodUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            methodHasSteps: true,
            methodStructureVersion: '2.0'
          });
          updateCount++;
        });
        
        await progressBatch.commit();
        console.log(`  ✅ Updated ${updateCount} progress records for ${method.name}`);
      }
    }
    
    // Update any training routines that include these methods
    console.log('\n📋 Checking training routines...');
    const routinesSnapshot = await db.collection('trainingRoutines').get();
    let routineUpdateCount = 0;
    
    for (const routineDoc of routinesSnapshot.docs) {
      const routineData = routineDoc.data();
      let needsUpdate = false;
      
      if (routineData.stages) {
        routineData.stages.forEach(stage => {
          if (stage.methods) {
            stage.methods.forEach(method => {
              if (methodsToReplace.some(m => m.methodId === method.methodId)) {
                needsUpdate = true;
              }
            });
          }
        });
      }
      
      if (needsUpdate) {
        await routineDoc.ref.update({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          methodsUpdatedToMultiStep: true
        });
        routineUpdateCount++;
      }
    }
    
    console.log(`  ✅ Updated ${routineUpdateCount} training routines`);
    
    console.log('\n🎉 All Angion Methods have been successfully converted to multi-step format!');
    console.log('\n📝 Summary:');
    console.log(`  - Methods updated: ${methodsToReplace.length}`);
    console.log(`  - Backups created: ${backupCount}`);
    console.log(`  - Each method now has detailed step-by-step instructions`);
    console.log(`  - Timer configurations updated for step progression`);
    
  } catch (error) {
    console.error('\n❌ Error replacing methods:', error);
  } finally {
    process.exit();
  }
}

// Run the script
replaceAllMethods();