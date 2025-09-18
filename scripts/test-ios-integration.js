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
    projectId: 'growth-70a85' // Production project ID (same as dev)
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  process.exit(1);
}

// Get Firestore database reference
const db = admin.firestore();

const testIOSIntegration = async () => {
  console.log('=== iOS Integration Test ===\n');
  
  try {
    // 1. Test fetching with the exact same logic as iOS
    console.log('1. Simulating iOS getAllEducationalResources() call...');
    const snapshot = await db.collection('educationalResources')
      .orderBy('title')
      .get();
    
    console.log(`   Raw query returned ${snapshot.size} documents\n`);
    
    // 2. Simulate iOS parsing logic
    console.log('2. Simulating iOS document parsing...');
    const resources = [];
    const failedDocuments = [];
    
    for (const doc of snapshot.docs) {
      try {
        const data = doc.data();
        
        // Check all required fields (as per iOS EducationalResource model)
        const requiredFields = ['title', 'content_text', 'category'];
        const missingFields = requiredFields.filter(field => !(field in data));
        
        if (missingFields.length > 0) {
          failedDocuments.push({
            id: doc.id,
            reason: `Missing required fields: ${missingFields.join(', ')}`
          });
          continue;
        }
        
        // Check category enum validation
        const validCategories = ['Basics', 'Technique', 'Science', 'Safety', 'Progression'];
        if (!validCategories.includes(data.category)) {
          failedDocuments.push({
            id: doc.id,
            reason: `Invalid category: "${data.category}" (valid: ${validCategories.join(', ')})`
          });
          continue;
        }
        
        // Simulate successful parsing
        const resource = {
          id: doc.id, // This would be set by @DocumentID
          title: data.title,
          contentText: data.content_text,
          category: data.category,
          visualPlaceholderUrl: data.visual_placeholder_url || null
        };
        
        resources.push(resource);
        
      } catch (error) {
        failedDocuments.push({
          id: doc.id,
          reason: `Parsing error: ${error.message}`
        });
      }
    }
    
    console.log(`   Successfully parsed: ${resources.length} documents`);
    console.log(`   Failed to parse: ${failedDocuments.length} documents\n`);
    
    if (failedDocuments.length > 0) {
      console.log('3. Failed documents analysis:');
      failedDocuments.forEach(failed => {
        console.log(`   ❌ ${failed.id}: ${failed.reason}`);
      });
      console.log('');
    }
    
    // 3. Test the filtering logic from iOS ViewModel
    console.log('4. Simulating iOS ViewModel filtering...');
    const validResources = resources.filter(resource => {
      if (resource.id && resource.id.trim() !== '') {
        return true;
      } else {
        console.log(`   Filtering out resource '${resource.title}' due to nil or empty ID`);
        return false;
      }
    });
    
    console.log(`   Resources after ID filtering: ${validResources.length}`);
    
    // 4. Final result analysis
    console.log('\n5. Final results:');
    console.log(`   Total documents in Firestore: ${snapshot.size}`);
    console.log(`   Successfully parsed by iOS: ${validResources.length}`);
    console.log(`   Parsing failures: ${failedDocuments.length}`);
    console.log(`   Empty ID filtering: ${resources.length - validResources.length}`);
    
    if (validResources.length === 0) {
      console.log('\n   ❌ NO RESOURCES WOULD BE DISPLAYED IN iOS APP');
      console.log('   This explains why the app shows "No educational resources available"');
    } else {
      console.log('\n   ✅ Resources should be visible in iOS app');
      console.log(`   First few resources that would display:`);
      validResources.slice(0, 3).forEach(resource => {
        console.log(`     - ${resource.title} (${resource.category})`);
      });
    }
    
    // 5. Test a sample document structure
    if (validResources.length > 0) {
      console.log('\n6. Sample resource structure:');
      const sample = validResources[0];
      console.log(`   ID: "${sample.id}"`);
      console.log(`   Title: "${sample.title}"`);
      console.log(`   Category: "${sample.category}"`);
      console.log(`   Content length: ${sample.contentText?.length || 0} characters`);
      console.log(`   Has image URL: ${sample.visualPlaceholderUrl ? 'Yes' : 'No'}`);
    }
    
  } catch (error) {
    console.error('Error during integration test:', error);
    throw error;
  }
};

// Main function
const main = async () => {
  try {
    await testIOSIntegration();
    process.exit(0);
  } catch (error) {
    console.error('Integration test failed:', error);
    process.exit(1);
  }
};

main();