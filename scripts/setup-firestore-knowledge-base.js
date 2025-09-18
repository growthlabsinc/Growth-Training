#!/usr/bin/env node

/**
 * Script to set up the AI Coach knowledge base in Firestore
 * This script uses Firebase Admin SDK to create and populate the knowledge base
 */

const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Configuration
const PROJECT_ID = 'growth-70a85';
const KNOWLEDGE_COLLECTION = 'ai_coach_knowledge';

async function initializeFirebase() {
  try {
    // Check if running in a Google Cloud environment
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('Using service account from GOOGLE_APPLICATION_CREDENTIALS');
      admin.initializeApp({
        projectId: PROJECT_ID
      });
    } else {
      // Try to use Application Default Credentials
      console.log('Attempting to use Application Default Credentials...');
      admin.initializeApp({
        projectId: PROJECT_ID
      });
    }
    
    console.log('✅ Firebase Admin initialized successfully');
    return admin.firestore();
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
    console.log('\nTo fix this, you have several options:');
    console.log('\n1. Use Firebase CLI (recommended):');
    console.log('   firebase login');
    console.log('   gcloud auth application-default login');
    console.log('\n2. Use a service account:');
    console.log('   - Go to Firebase Console > Project Settings > Service Accounts');
    console.log('   - Generate a new private key');
    console.log('   - Run: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"');
    process.exit(1);
  }
}

async function loadSampleResources() {
  try {
    const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
    const data = await fs.readFile(resourcesPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('❌ Failed to load sample-resources.json:', error.message);
    process.exit(1);
  }
}

async function loadSampleMethods() {
  try {
    const methodsPath = path.join(__dirname, '..', 'data', 'sample-methods.json');
    const data = await fs.readFile(methodsPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.log('⚠️  No sample-methods.json found, continuing with resources only');
    return [];
  }
}

function extractKeywords(texts) {
  const text = texts.join(' ').toLowerCase();
  const words = text.match(/\b\w{3,}\b/g) || [];
  
  // Common stop words to exclude
  const stopWords = new Set([
    'the', 'and', 'for', 'with', 'this', 'that', 'from', 'are', 'was', 'were',
    'been', 'have', 'has', 'had', 'will', 'would', 'should', 'may', 'might',
    'can', 'could', 'about', 'into', 'through', 'during', 'before', 'after'
  ]);
  
  // Extract unique meaningful words
  const keywords = [...new Set(words)]
    .filter(word => !stopWords.has(word))
    .slice(0, 50); // Limit to 50 keywords
  
  // Add specific method keywords
  const methodKeywords = [];
  const textLower = text.toLowerCase();
  if (textLower.includes('am1') || textLower.includes('angion method 1')) {
    methodKeywords.push('am1', 'angion', 'method', 'beginner');
  }
  if (textLower.includes('am2') || textLower.includes('angion method 2')) {
    methodKeywords.push('am2', 'arterial', 'intermediate');
  }
  if (textLower.includes('vascion') || textLower.includes('am3')) {
    methodKeywords.push('vascion', 'am3', 'advanced', 'corpus', 'spongiosum');
  }
  if (textLower.includes('sabre')) {
    methodKeywords.push('sabre', 'strike', 'percussion', 'bayliss');
  }
  
  return [...new Set([...keywords, ...methodKeywords])];
}

async function populateKnowledgeBase(db) {
  console.log('\n📚 Populating knowledge base...\n');
  
  const knowledgeRef = db.collection(KNOWLEDGE_COLLECTION);
  
  // Clear existing collection (optional)
  console.log('🗑️  Clearing existing knowledge base...');
  const existing = await knowledgeRef.get();
  const batch = db.batch();
  existing.forEach(doc => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  console.log(`   Deleted ${existing.size} existing documents\n`);
  
  // Load resources
  const resources = await loadSampleResources();
  const methods = await loadSampleMethods();
  
  console.log(`📄 Found ${resources.length} educational resources`);
  console.log(`📄 Found ${methods.length} growth methods\n`);
  
  // Process resources
  let successCount = 0;
  const resourceBatch = db.batch();
  
  for (const resource of resources) {
    try {
      const docId = resource.resourceId;
      const docRef = knowledgeRef.doc(docId);
      
      const docData = {
        resourceId: resource.resourceId,
        title: resource.title,
        content: resource.content_text,
        category: resource.category,
        type: 'educational_resource',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        
        // Search optimization
        searchableContent: `${resource.title} ${resource.content_text}`.toLowerCase(),
        keywords: extractKeywords([resource.title, resource.content_text]),
        
        // Metadata
        metadata: {
          category: resource.category,
          contentLength: resource.content_text.length,
          hasVisualPlaceholder: !!resource.visual_placeholder_url
        }
      };
      
      resourceBatch.set(docRef, docData);
      successCount++;
      console.log(`✅ Added: ${resource.title}`);
      
    } catch (error) {
      console.error(`❌ Failed to add resource ${resource.resourceId}:`, error.message);
    }
  }
  
  await resourceBatch.commit();
  console.log(`\n✅ Successfully added ${successCount} educational resources\n`);
  
  // Process methods
  if (methods.length > 0) {
    const methodBatch = db.batch();
    let methodCount = 0;
    
    for (const method of methods) {
      try {
        const docId = `method_${method.methodId}`;
        const docRef = knowledgeRef.doc(docId);
        
        const docData = {
          methodId: method.methodId,
          title: method.title,
          content: `${method.description}\n\nInstructions:\n${method.instructions_text}`,
          stage: method.stage,
          type: 'growth_method',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          
          // Search optimization
          searchableContent: `${method.title} ${method.description} ${method.instructions_text}`.toLowerCase(),
          keywords: extractKeywords([method.title, method.description, method.instructions_text]),
          
          // Metadata
          metadata: {
            stage: method.stage,
            equipment: method.equipment_needed || [],
            progressionCriteria: method.progression_criteria,
            safetyNotes: method.safety_notes
          }
        };
        
        methodBatch.set(docRef, docData);
        methodCount++;
        console.log(`✅ Added method: ${method.title}`);
        
      } catch (error) {
        console.error(`❌ Failed to add method ${method.methodId}:`, error.message);
      }
    }
    
    await methodBatch.commit();
    console.log(`\n✅ Successfully added ${methodCount} growth methods\n`);
  }
  
  return successCount + methods.length;
}

async function createIndexes(db) {
  console.log('📋 Note: Firestore indexes may need to be created manually');
  console.log('   If queries fail, check the Firebase Console for index creation links\n');
}

async function testKnowledgeBase(db) {
  console.log('🧪 Testing knowledge base queries...\n');
  
  const knowledgeRef = db.collection(KNOWLEDGE_COLLECTION);
  
  // Test 1: Search for AM1
  console.log('Test 1: Searching for "AM1"...');
  const am1Query = await knowledgeRef
    .where('keywords', 'array-contains', 'am1')
    .limit(3)
    .get();
  console.log(`   Found ${am1Query.size} results\n`);
  
  // Test 2: Search for SABRE
  console.log('Test 2: Searching for "SABRE"...');
  const sabreQuery = await knowledgeRef
    .where('keywords', 'array-contains', 'sabre')
    .limit(3)
    .get();
  console.log(`   Found ${sabreQuery.size} results\n`);
  
  // Test 3: Get total count
  const allDocs = await knowledgeRef.get();
  console.log(`📊 Total documents in knowledge base: ${allDocs.size}\n`);
}

async function main() {
  console.log('🚀 AI Coach Knowledge Base Setup Script');
  console.log('=====================================\n');
  
  try {
    // Initialize Firebase
    const db = await initializeFirebase();
    
    // Populate knowledge base
    const docCount = await populateKnowledgeBase(db);
    
    // Create indexes note
    await createIndexes(db);
    
    // Test queries
    await testKnowledgeBase(db);
    
    console.log('✅ Knowledge base setup completed successfully!');
    console.log(`   Total documents: ${docCount}`);
    console.log('\n🎉 The AI Coach now has access to:');
    console.log('   - Vascular Health Fundamentals');
    console.log('   - Technique Execution Guides');
    console.log('   - Vascularity Progression Timeline');
    console.log('   - Abbreviations and Terminology');
    console.log('   - Complete Angion Methods List');
    console.log('   - Hand Techniques Breakdown');
    console.log('   - Personal Journey Experiences');
    console.log('   - AM 2.0 Erection Level Guidance');
    console.log('   - SABRE Techniques Documentation');
    console.log('   - And more!\n');
    console.log('📱 Test in the app by asking questions like:');
    console.log('   - "What is AM1?"');
    console.log('   - "How do I perform Angion Method 1.0?"');
    console.log('   - "What does CS mean?"');
    console.log('   - "Explain SABRE techniques"');
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run the script
main();