#!/usr/bin/env node

/**
 * Script to update AI Coach knowledge base in Firestore
 * This adds the sample resources to a Firestore collection that the AI Coach can query
 */

const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Initialize Firebase Admin
// Note: In production, use proper service account credentials
// For now, we'll use default credentials if available
try {
  // Try to use application default credentials
  admin.initializeApp({
    projectId: 'growth-70a85'
  });
} catch (error) {
  console.error('Failed to initialize Firebase Admin. Make sure you have proper credentials set up.');
  console.error('You can either:');
  console.error('1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to point to a service account key file');
  console.error('2. Run this script from a Google Cloud environment with proper permissions');
  process.exit(1);
}

const db = admin.firestore();

async function updateKnowledgeBase() {
  try {
    console.log('Starting AI Coach knowledge base update...');
    
    // Read sample resources
    const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
    const resourcesData = await fs.readFile(resourcesPath, 'utf8');
    const resources = JSON.parse(resourcesData);
    
    console.log(`Found ${resources.length} resources to add to knowledge base`);
    
    // Reference to the knowledge base collection
    const knowledgeRef = db.collection('ai_coach_knowledge');
    
    // Clear existing resources (optional - comment out to append instead)
    console.log('Clearing existing knowledge base...');
    const existing = await knowledgeRef.get();
    const deletePromises = [];
    existing.forEach(doc => {
      deletePromises.push(doc.ref.delete());
    });
    await Promise.all(deletePromises);
    console.log(`Deleted ${deletePromises.length} existing documents`);
    
    // Add each resource
    const batch = db.batch();
    let batchCount = 0;
    
    for (const resource of resources) {
      // Create document ID from resourceId
      const docId = resource.resourceId;
      const docRef = knowledgeRef.doc(docId);
      
      // Prepare document data
      const docData = {
        resourceId: resource.resourceId,
        title: resource.title,
        content: resource.content_text,
        category: resource.category,
        type: 'educational_resource',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        
        // Add searchable fields
        searchableContent: `${resource.title} ${resource.content_text}`.toLowerCase(),
        keywords: extractKeywords(resource.title, resource.content_text),
        
        // Metadata for better search
        metadata: {
          category: resource.category,
          hasVisualPlaceholder: !!resource.visual_placeholder_url,
          contentLength: resource.content_text.length
        }
      };
      
      batch.set(docRef, docData);
      batchCount++;
      
      // Firestore has a limit of 500 operations per batch
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`Committed batch of ${batchCount} documents`);
        batch = db.batch();
        batchCount = 0;
      }
    }
    
    // Commit any remaining documents
    if (batchCount > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${batchCount} documents`);
    }
    
    // Also add growth methods if available
    try {
      const methodsPath = path.join(__dirname, '..', 'data', 'sample-methods.json');
      const methodsData = await fs.readFile(methodsPath, 'utf8');
      const methods = JSON.parse(methodsData);
      
      console.log(`\nFound ${methods.length} methods to add to knowledge base`);
      
      const methodBatch = db.batch();
      let methodBatchCount = 0;
      
      for (const method of methods) {
        const docId = `method_${method.id}`;
        const docRef = knowledgeRef.doc(docId);
        
        const docData = {
          methodId: method.id,
          title: method.title,
          content: `${method.description}\n\nInstructions:\n${method.instructions}`,
          stage: method.stage,
          type: 'growth_method',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          
          // Add searchable fields
          searchableContent: `${method.title} ${method.description} ${method.instructions}`.toLowerCase(),
          keywords: extractKeywords(method.title, method.description, method.instructions),
          
          // Metadata
          metadata: {
            stage: method.stage,
            equipment: method.equipment || [],
            progressionCriteria: method.progressionCriteria,
            safetyNotes: method.safetyNotes
          }
        };
        
        methodBatch.set(docRef, docData);
        methodBatchCount++;
        
        if (methodBatchCount >= 500) {
          await methodBatch.commit();
          console.log(`Committed batch of ${methodBatchCount} method documents`);
          methodBatch = db.batch();
          methodBatchCount = 0;
        }
      }
      
      if (methodBatchCount > 0) {
        await methodBatch.commit();
        console.log(`Committed final batch of ${methodBatchCount} method documents`);
      }
      
    } catch (error) {
      console.log('No methods file found or error reading methods:', error.message);
    }
    
    console.log('\nKnowledge base update complete!');
    console.log('\nTo test the knowledge base:');
    console.log('1. Open the app and go to the AI Coach');
    console.log('2. Try asking questions like:');
    console.log('   - "What is the vascularity progression timeline?"');
    console.log('   - "Explain AM 2.0 erection level"');
    console.log('   - "What are SABRE techniques?"');
    console.log('   - "Tell me about the abbreviations used"');
    
  } catch (error) {
    console.error('Error updating knowledge base:', error);
    process.exit(1);
  }
}

// Helper function to extract keywords from text
function extractKeywords(...texts) {
  const combinedText = texts.join(' ').toLowerCase();
  
  // Common stop words to exclude
  const stopWords = new Set([
    'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'as', 'are', 'was',
    'were', 'been', 'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
    'would', 'should', 'may', 'might', 'must', 'can', 'could', 'to', 'of',
    'in', 'for', 'with', 'without', 'about', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'up', 'down', 'out', 'off', 'over',
    'under', 'again', 'further', 'then', 'once'
  ]);
  
  // Extract words and filter
  const words = combinedText
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 2 && !stopWords.has(word));
  
  // Get unique keywords
  const uniqueWords = [...new Set(words)];
  
  // Return top keywords (limit to prevent document bloat)
  return uniqueWords.slice(0, 50);
}

// Run the update
updateKnowledgeBase().then(() => {
  console.log('\nScript completed successfully');
  process.exit(0);
}).catch(error => {
  console.error('\nScript failed:', error);
  process.exit(1);
});