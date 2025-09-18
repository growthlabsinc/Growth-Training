#!/usr/bin/env node

/**
 * Simplified script to set up AI Coach knowledge base
 * Uses Firebase project configuration directly
 */

const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

console.log('🤖 Simple AI Coach Knowledge Base Setup');
console.log('=====================================\n');

// Try different authentication methods
async function initializeApp() {
  try {
    // Method 1: Check for existing GOOGLE_APPLICATION_CREDENTIALS
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('Using service account from GOOGLE_APPLICATION_CREDENTIALS');
      const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'growth-70a85'
      });
      return true;
    }

    // Method 2: Try using default credentials (works on Google Cloud)
    try {
      admin.initializeApp({
        projectId: 'growth-70a85'
      });
      console.log('Using default application credentials');
      return true;
    } catch (defaultError) {
      // Continue to next method
    }

    // Method 3: Provide instructions for manual setup
    console.log('❌ No authentication method available\n');
    console.log('To set up authentication, you have two options:\n');
    console.log('Option 1: Download a service account key');
    console.log('1. Go to: https://console.firebase.google.com/project/growth-70a85/settings/serviceaccounts/adminsdk');
    console.log('2. Click "Generate new private key"');
    console.log('3. Save the JSON file somewhere secure');
    console.log('4. Run: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-key.json"');
    console.log('5. Run this script again\n');
    
    console.log('Option 2: Set up manually in Firebase Console');
    console.log('1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore');
    console.log('2. Create a new collection called "ai_coach_knowledge"');
    console.log('3. Use the import feature to upload the knowledge base data\n');
    
    return false;
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    return false;
  }
}

// Main setup function
async function setupKnowledgeBase() {
  const initialized = await initializeApp();
  if (!initialized) {
    process.exit(1);
  }

  const db = admin.firestore();
  const COLLECTION = 'ai_coach_knowledge';
  
  try {
    // Load sample resources
    const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
    const resourcesData = await fs.readFile(resourcesPath, 'utf8');
    const resources = JSON.parse(resourcesData);
    
    console.log(`\n📚 Found ${resources.length} resources to import\n`);
    
    // Clear existing collection
    console.log('Clearing existing knowledge base...');
    const collection = db.collection(COLLECTION);
    const snapshot = await collection.get();
    
    if (!snapshot.empty) {
      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Deleted ${snapshot.size} existing documents\n`);
    }
    
    // Import resources
    console.log('Importing resources...\n');
    let successCount = 0;
    
    for (const resource of resources) {
      try {
        // Extract keywords for search
        const text = `${resource.title} ${resource.content_text}`.toLowerCase();
        const words = text.match(/\b\w{3,}\b/g) || [];
        const keywords = [...new Set(words)].slice(0, 50);
        
        // Add specific method keywords
        if (text.includes('am1') || text.includes('angion method 1')) {
          keywords.push('am1', 'angion', 'method', 'beginner');
        }
        if (text.includes('am2') || text.includes('angion method 2')) {
          keywords.push('am2', 'arterial');
        }
        if (text.includes('sabre')) {
          keywords.push('sabre', 'strike', 'percussion');
        }
        if (text.includes('vascion')) {
          keywords.push('vascion', 'am3', 'advanced');
        }
        
        // Create document
        await collection.doc(resource.resourceId).set({
          resourceId: resource.resourceId,
          title: resource.title,
          content: resource.content_text,
          category: resource.category,
          type: 'educational_resource',
          searchableContent: text,
          keywords: [...new Set(keywords)],
          metadata: {
            category: resource.category,
            contentLength: resource.content_text.length
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        successCount++;
        console.log(`✅ Added: ${resource.title}`);
        
      } catch (error) {
        console.error(`❌ Failed to add ${resource.title}:`, error.message);
      }
    }
    
    console.log(`\n✅ Successfully imported ${successCount} of ${resources.length} resources\n`);
    
    // Test the knowledge base
    console.log('Testing knowledge base...\n');
    
    // Test search for AM1
    const am1Test = await collection
      .where('keywords', 'array-contains', 'am1')
      .limit(1)
      .get();
    
    if (!am1Test.empty) {
      console.log('✅ Test 1 passed: Found AM1 content');
    } else {
      console.log('❌ Test 1 failed: AM1 content not found');
    }
    
    // Test search for SABRE
    const sabreTest = await collection
      .where('keywords', 'array-contains', 'sabre')
      .limit(1)
      .get();
    
    if (!sabreTest.empty) {
      console.log('✅ Test 2 passed: Found SABRE content');
    } else {
      console.log('❌ Test 2 failed: SABRE content not found');
    }
    
    console.log('\n🎉 Knowledge base setup complete!');
    console.log('\nThe AI Coach can now answer questions about:');
    console.log('• AM1, AM2, Vascion (AM3)');
    console.log('• SABRE techniques');
    console.log('• Abbreviations and terminology');
    console.log('• Progression timelines');
    console.log('• Hand techniques');
    console.log('• And much more!\n');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run the setup
setupKnowledgeBase();