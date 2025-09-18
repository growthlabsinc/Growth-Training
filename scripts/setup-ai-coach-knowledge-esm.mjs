#!/usr/bin/env node

/**
 * ES Module version of the AI Coach knowledge base setup script
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { readFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const PROJECT_ID = 'growth-70a85';
const KNOWLEDGE_COLLECTION = 'ai_coach_knowledge';

async function initializeFirebase() {
  try {
    const app = initializeApp({
      projectId: PROJECT_ID
    });
    
    console.log('✅ Firebase Admin initialized successfully');
    return getFirestore(app);
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
    const resourcesPath = join(__dirname, '..', 'data', 'sample-resources.json');
    const data = await readFile(resourcesPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('❌ Failed to load sample-resources.json:', error.message);
    process.exit(1);
  }
}

async function loadSampleMethods() {
  try {
    const methodsPath = join(__dirname, '..', 'data', 'sample-methods.json');
    const data = await readFile(methodsPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.log('⚠️  No sample-methods.json found, continuing with resources only');
    return [];
  }
}

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
  
  // Add specific method keywords
  const methodKeywords = [];
  const textLower = combinedText;
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
  
  // Combine and return top keywords (limit to prevent document bloat)
  return [...new Set([...uniqueWords, ...methodKeywords])].slice(0, 50);
}

async function setupKnowledgeBase() {
  try {
    console.log('Starting AI Coach knowledge base setup...');
    
    const db = await initializeFirebase();
    const resources = await loadSampleResources();
    const methods = await loadSampleMethods();
    
    console.log(`Found ${resources.length} resources and ${methods.length} methods to add`);
    
    const knowledgeRef = db.collection(KNOWLEDGE_COLLECTION);
    
    // Clear existing resources (optional - comment out to append instead)
    console.log('Clearing existing knowledge base...');
    const existing = await knowledgeRef.get();
    const deletePromises = [];
    existing.forEach(doc => {
      deletePromises.push(doc.ref.delete());
    });
    await Promise.all(deletePromises);
    console.log(`Deleted ${deletePromises.length} existing documents`);
    
    // Add resources
    let batch = db.batch();
    let batchCount = 0;
    
    for (const resource of resources) {
      const docId = resource.resourceId;
      const docRef = knowledgeRef.doc(docId);
      
      const docData = {
        resourceId: resource.resourceId,
        title: resource.title,
        content: resource.content_text,
        category: resource.category,
        type: 'educational_resource',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        searchableContent: `${resource.title} ${resource.content_text}`.toLowerCase(),
        keywords: extractKeywords(resource.title, resource.content_text),
        metadata: {
          category: resource.category,
          hasVisualPlaceholder: !!resource.visual_placeholder_url,
          contentLength: resource.content_text.length
        }
      };
      
      batch.set(docRef, docData);
      batchCount++;
      
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`Committed batch of ${batchCount} documents`);
        batch = db.batch();
        batchCount = 0;
      }
    }
    
    // Commit remaining resource documents
    if (batchCount > 0) {
      await batch.commit();
      console.log(`Committed batch of ${batchCount} resource documents`);
    }
    
    // Add methods
    batch = db.batch();
    batchCount = 0;
    
    for (const method of methods) {
      const docId = `method_${method.methodId}`;
      const docRef = knowledgeRef.doc(docId);
      
      const docData = {
        methodId: method.methodId,
        title: method.title,
        content: `${method.description}\n\nInstructions:\n${method.instructions_text}`,
        stage: method.stage,
        type: 'growth_method',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        searchableContent: `${method.title} ${method.description} ${method.instructions_text}`.toLowerCase(),
        keywords: extractKeywords(method.title, method.description, method.instructions_text),
        metadata: {
          stage: method.stage,
          equipment: method.equipment_needed || [],
          progressionCriteria: method.progression_criteria,
          safetyNotes: method.safety_notes
        }
      };
      
      batch.set(docRef, docData);
      batchCount++;
      
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`Committed batch of ${batchCount} method documents`);
        batch = db.batch();
        batchCount = 0;
      }
    }
    
    // Commit remaining method documents
    if (batchCount > 0) {
      await batch.commit();
      console.log(`Committed batch of ${batchCount} method documents`);
    }
    
    console.log('\n✅ Knowledge base setup complete!');
    console.log(`Total documents created: ${resources.length + methods.length}`);
    console.log('\nTo test the AI Coach:');
    console.log('1. Open the app and go to the AI Coach');
    console.log('2. Try asking questions like:');
    console.log('   - "What is AM1?"');
    console.log('   - "Explain the Vascion technique"');
    console.log('   - "What are SABRE techniques?"');
    console.log('   - "Tell me about progression timelines"');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting up knowledge base:', error);
    process.exit(1);
  }
}

// Run the setup
setupKnowledgeBase();