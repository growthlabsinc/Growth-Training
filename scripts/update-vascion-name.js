import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK with service account
try {
  // Look for service account file in the same directory
  const serviceAccount = JSON.parse(fs.readFileSync(path.join(__dirname, 'service-account.json'), 'utf8'));
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  console.error('Make sure you have a valid service-account.json file in the scripts directory');
  process.exit(1);
}

// Get Firestore database reference
const db = admin.firestore();

async function updateVascionName() {
  try {
    console.log('Updating Vascion method name...');
    
    // Update the vascion document
    const docRef = db.collection('growthMethods').doc('vascion');
    const doc = await docRef.get();
    
    if (doc.exists) {
      await docRef.update({
        title: 'Angion Method 3.0 - Vascion',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log('✅ Successfully updated Vascion to "Angion Method 3.0 - Vascion"');
    } else {
      console.log('⚠️  Vascion method not found in Firestore');
    }
    
    // Also check for any routines that might reference this method
    console.log('\nChecking routines for method references...');
    const routinesSnapshot = await db.collection('routines').get();
    let routineUpdates = 0;
    
    for (const routineDoc of routinesSnapshot.docs) {
      const routineData = routineDoc.data();
      let needsUpdate = false;
      
      // Check if any schedule contains vascion method
      if (routineData.schedule && Array.isArray(routineData.schedule)) {
        for (const day of routineData.schedule) {
          if (day.methodIds && day.methodIds.includes('vascion')) {
            // The method ID remains 'vascion', only the display title changes
            needsUpdate = false; // No need to update routines
            break;
          }
        }
      }
      
      if (needsUpdate) {
        // Update routine if needed (currently not needed as IDs stay the same)
        routineUpdates++;
      }
    }
    
    console.log(`\n✅ Update complete. ${routineUpdates} routines updated.`);
    
  } catch (error) {
    console.error('Error updating Vascion name:', error);
  } finally {
    // Terminate the admin app
    await admin.app().delete();
  }
}

// Run the update
updateVascionName();