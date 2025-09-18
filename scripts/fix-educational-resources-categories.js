import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
try {
  // Try service account first, then fall back to application default credentials
  let credential;
  try {
    const serviceAccountPath = path.join(__dirname, 'service-account.json');
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    credential = admin.credential.cert(serviceAccount);
    console.log('Using service account credentials');
  } catch (serviceError) {
    credential = admin.credential.applicationDefault();
    console.log('Using application default credentials');
  }

  admin.initializeApp({
    credential: credential,
    projectId: 'growth-70a85' // Production project ID
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  process.exit(1);
}

// Get Firestore database reference
const db = admin.firestore();

const fixCategoryCapitalization = async () => {
  console.log('=== Fixing Educational Resources Category Capitalization ===\n');
  
  try {
    // Get all documents from educationalResources collection
    const snapshot = await db.collection('educationalResources').get();
    console.log(`Found ${snapshot.size} documents to check\n`);
    
    if (snapshot.size === 0) {
      console.log('No documents found in educationalResources collection');
      return;
    }
    
    const categoryMapping = {
      'basics': 'Basics',
      'technique': 'Technique', 
      'science': 'Science',
      'safety': 'Safety',
      'progression': 'Progression'
    };
    
    let updatedCount = 0;
    let errorCount = 0;
    const batch = db.batch();
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const currentCategory = data.category;
      
      if (currentCategory && typeof currentCategory === 'string') {
        const lowercaseCategory = currentCategory.toLowerCase();
        const correctCategory = categoryMapping[lowercaseCategory];
        
        if (correctCategory && currentCategory !== correctCategory) {
          console.log(`Updating ${doc.id}: "${currentCategory}" -> "${correctCategory}"`);
          batch.update(doc.ref, { category: correctCategory });
          updatedCount++;
        } else if (!correctCategory) {
          console.log(`❌ Unrecognized category in ${doc.id}: "${currentCategory}"`);
          errorCount++;
        } else {
          console.log(`✅ ${doc.id} already has correct category: "${currentCategory}"`);
        }
      } else {
        console.log(`❌ ${doc.id} has missing or invalid category field`);
        errorCount++;
      }
    }
    
    if (updatedCount > 0) {
      console.log(`\nCommitting ${updatedCount} updates...`);
      await batch.commit();
      console.log(`✅ Successfully updated ${updatedCount} documents`);
    } else {
      console.log('\nNo updates needed - all categories are already correctly capitalized');
    }
    
    if (errorCount > 0) {
      console.log(`⚠️  ${errorCount} documents had issues that couldn't be fixed`);
    }
    
    console.log('\n=== Fix Complete ===');
    
  } catch (error) {
    console.error('Error fixing categories:', error);
    throw error;
  }
};

// Main function
const main = async () => {
  try {
    await fixCategoryCapitalization();
    process.exit(0);
  } catch (error) {
    console.error('Fix failed:', error);
    process.exit(1);
  }
};

main();