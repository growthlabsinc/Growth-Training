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

const debugEducationalResources = async () => {
  console.log('=== Educational Resources Debug Report ===\n');
  
  try {
    // 1. Check if the collection exists and count documents
    console.log('1. Checking collection existence and document count...');
    const snapshot = await db.collection('educationalResources').get();
    console.log(`   Collection 'educationalResources' contains ${snapshot.size} documents\n`);
    
    if (snapshot.size === 0) {
      console.log('   ❌ No documents found in educationalResources collection');
      console.log('   This explains why the app shows no resources.\n');
      return;
    }
    
    // 2. Check document structure and field mapping
    console.log('2. Checking document structure...');
    const docs = snapshot.docs.slice(0, 3); // Check first 3 documents
    
    for (const doc of docs) {
      const data = doc.data();
      console.log(`   Document ID: ${doc.id}`);
      console.log(`   Fields present: ${Object.keys(data).join(', ')}`);
      
      // Check required fields according to iOS model
      const requiredFields = ['title', 'content_text', 'category'];
      const missingFields = requiredFields.filter(field => !(field in data));
      
      if (missingFields.length > 0) {
        console.log(`   ❌ Missing required fields: ${missingFields.join(', ')}`);
      } else {
        console.log(`   ✅ All required fields present`);
      }
      
      // Check category values
      if (data.category) {
        console.log(`   Category value: "${data.category}"`);
        const validCategories = ['Basics', 'Technique', 'Science', 'Safety', 'Progression'];
        if (!validCategories.includes(data.category)) {
          console.log(`   ⚠️  Category "${data.category}" doesn't match iOS enum values: ${validCategories.join(', ')}`);
        }
      }
      
      console.log('   ---');
    }
    
    // 3. Check sample data structure
    console.log('3. Checking sample data structure...');
    const sampleDataPath = path.resolve(__dirname, '../data/sample-resources.json');
    const sampleData = JSON.parse(fs.readFileSync(sampleDataPath, 'utf8'));
    const firstSample = sampleData[0];
    
    console.log(`   Sample data fields: ${Object.keys(firstSample).join(', ')}`);
    console.log(`   Sample category: "${firstSample.category}"`);
    
    // Check for field name mismatches
    const firestoreDoc = docs[0]?.data();
    if (firestoreDoc) {
      console.log('\n4. Field mapping analysis:');
      
      // iOS expects these field names:
      const iosFieldMapping = {
        'title': 'title',
        'content_text': 'contentText', 
        'category': 'category',
        'visual_placeholder_url': 'visualPlaceholderUrl'
      };
      
      for (const [firestoreField, iosProperty] of Object.entries(iosFieldMapping)) {
        if (firestoreField in firestoreDoc) {
          console.log(`   ✅ ${firestoreField} -> ${iosProperty} mapping OK`);
        } else {
          console.log(`   ❌ ${firestoreField} field missing (maps to ${iosProperty})`);
        }
      }
    }
    
    // 5. Check category enum mismatch
    console.log('\n5. Category enum analysis:');
    const categories = new Set();
    snapshot.docs.forEach(doc => {
      const category = doc.data().category;
      if (category) categories.add(category);
    });
    
    console.log(`   Categories in Firestore: ${Array.from(categories).join(', ')}`);
    console.log(`   iOS enum expects: Basics, Technique, Science, Safety, Progression`);
    
    const iOSCategories = ['Basics', 'Technique', 'Science', 'Safety', 'Progression'];
    const firestoreCategories = Array.from(categories);
    const mismatchedCategories = firestoreCategories.filter(cat => !iOSCategories.includes(cat));
    
    if (mismatchedCategories.length > 0) {
      console.log(`   ❌ Mismatched categories: ${mismatchedCategories.join(', ')}`);
      console.log(`   This could cause ResourceCategory enum parsing to fail!`);
    }
    
  } catch (error) {
    console.error('Error during debug:', error);
  }
};

// Main function
const main = async () => {
  try {
    await debugEducationalResources();
    process.exit(0);
  } catch (error) {
    console.error('Debug failed:', error);
    process.exit(1);
  }
};

main();