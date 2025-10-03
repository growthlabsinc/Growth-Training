/**
 * Update PE Knowledge Base Documents
 * Story 3.2: Deploy PE Knowledge Base - Maintenance Script
 *
 * This script allows updating individual knowledge documents
 * without redeploying the entire knowledge base.
 */

const admin = require('firebase-admin');
const { createKnowledgeDocument, peKnowledgeBase } = require('./deployPEKnowledge');

// Initialize Firebase Admin using default credentials (gcloud auth)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

/**
 * Update a specific knowledge document
 * @param {string} documentId - The document ID to update
 * @param {object} updates - Fields to update
 */
async function updateKnowledgeDocument(documentId, updates) {
  try {
    const docRef = db.collection('ai_coach_knowledge').doc(documentId);

    // Add updatedAt timestamp
    const updateData = {
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await docRef.update(updateData);
    console.log(`✅ Updated document: ${documentId}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to update ${documentId}: ${error.message}`);
    return false;
  }
}

/**
 * Update all documents in a category
 * @param {string} category - Category to update
 */
async function updateCategory(category) {
  console.log(`\n📁 Updating ${category} category...`);

  if (!peKnowledgeBase[category]) {
    console.error(`❌ Category '${category}' not found`);
    return false;
  }

  let successCount = 0;
  const documents = peKnowledgeBase[category];

  for (const doc of documents) {
    try {
      await db.collection('ai_coach_knowledge').doc(doc.id).set(doc);
      console.log(`  ✅ ${doc.title}`);
      successCount++;
    } catch (error) {
      console.error(`  ❌ Failed to update ${doc.title}: ${error.message}`);
    }
  }

  console.log(`📊 Updated ${successCount}/${documents.length} documents in ${category}`);
  return successCount === documents.length;
}

/**
 * Refresh a specific document by ID
 * @param {string} documentId - Document ID to refresh
 */
async function refreshDocument(documentId) {
  console.log(`\n🔄 Refreshing document: ${documentId}`);

  // Find the document in our knowledge base
  let foundDoc = null;
  for (const [category, documents] of Object.entries(peKnowledgeBase)) {
    foundDoc = documents.find(doc => doc.id === documentId);
    if (foundDoc) break;
  }

  if (!foundDoc) {
    console.error(`❌ Document '${documentId}' not found in knowledge base`);
    return false;
  }

  try {
    await db.collection('ai_coach_knowledge').doc(documentId).set(foundDoc);
    console.log(`✅ Refreshed: ${foundDoc.title}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to refresh ${documentId}: ${error.message}`);
    return false;
  }
}

/**
 * List all available documents and categories
 */
function listAvailableContent() {
  console.log('\n📋 Available Content:\n');

  for (const [category, documents] of Object.entries(peKnowledgeBase)) {
    console.log(`📁 ${category.toUpperCase()} (${documents.length} documents):`);
    documents.forEach(doc => {
      console.log(`   - ${doc.id}: ${doc.title}`);
    });
    console.log();
  }
}

/**
 * Validate knowledge base integrity
 */
async function validateKnowledgeBase() {
  console.log('\n🔍 Validating Knowledge Base...\n');

  try {
    const snapshot = await db.collection('ai_coach_knowledge').get();
    const deployedDocs = new Set();

    snapshot.forEach(doc => {
      deployedDocs.add(doc.id);
    });

    // Check all documents from knowledge base exist
    let allValid = true;
    for (const [category, documents] of Object.entries(peKnowledgeBase)) {
      console.log(`📁 Checking ${category}...`);

      for (const doc of documents) {
        if (deployedDocs.has(doc.id)) {
          console.log(`  ✅ ${doc.id}`);
        } else {
          console.log(`  ❌ MISSING: ${doc.id}`);
          allValid = false;
        }
      }
    }

    // Check for extra documents
    const expectedIds = new Set();
    for (const documents of Object.values(peKnowledgeBase)) {
      documents.forEach(doc => expectedIds.add(doc.id));
    }

    const extraDocs = Array.from(deployedDocs).filter(id => !expectedIds.has(id));
    if (extraDocs.length > 0) {
      console.log('\n⚠️ Extra documents found:');
      extraDocs.forEach(id => console.log(`  - ${id}`));
    }

    console.log(`\n📊 Validation ${allValid ? 'PASSED' : 'FAILED'}`);
    return allValid;

  } catch (error) {
    console.error(`❌ Validation failed: ${error.message}`);
    return false;
  }
}

/**
 * Main function to handle command line arguments
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('📚 PE Knowledge Update Tool\n');
    console.log('Usage:');
    console.log('  node updatePEKnowledge.js --list                    # List all content');
    console.log('  node updatePEKnowledge.js --validate                # Validate knowledge base');
    console.log('  node updatePEKnowledge.js --category [name]         # Update entire category');
    console.log('  node updatePEKnowledge.js --refresh [document-id]   # Refresh specific document');
    console.log('  node updatePEKnowledge.js --help                    # Show this help');
    console.log();
    console.log('Examples:');
    console.log('  node updatePEKnowledge.js --category safety');
    console.log('  node updatePEKnowledge.js --refresh pe-length-001');
    return;
  }

  const [command, value] = args;

  switch (command) {
    case '--list':
      listAvailableContent();
      break;

    case '--validate':
      await validateKnowledgeBase();
      break;

    case '--category':
      if (!value) {
        console.error('❌ Category name required');
        process.exit(1);
      }
      const success = await updateCategory(value);
      process.exit(success ? 0 : 1);

    case '--refresh':
      if (!value) {
        console.error('❌ Document ID required');
        process.exit(1);
      }
      const refreshed = await refreshDocument(value);
      process.exit(refreshed ? 0 : 1);

    case '--help':
      console.log('📚 PE Knowledge Update Tool Help\n');
      console.log('This tool helps maintain the PE knowledge base deployed to Firebase.');
      console.log('It allows updating individual documents or entire categories without');
      console.log('redeploying the complete knowledge base.\n');
      console.log('Available categories: length, girth, eq, safety, equipment, progression');
      break;

    default:
      console.error(`❌ Unknown command: ${command}`);
      console.log('Use --help for usage information');
      process.exit(1);
  }
}

// Execute if run directly
if (require.main === module) {
  main().catch(error => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  updateKnowledgeDocument,
  updateCategory,
  refreshDocument,
  validateKnowledgeBase
};