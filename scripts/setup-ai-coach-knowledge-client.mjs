#!/usr/bin/env node

/**
 * Client-side script to set up AI Coach knowledge base using Firebase Web SDK
 * This uses Firebase Auth to authenticate as a user
 */

import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, collection, doc, setDoc, getDocs, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { readFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import * as readline from 'readline';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAKJqgUv4Galjb4iKmm88P8dPMGlMJB7GA",
  authDomain: "growth-70a85.firebaseapp.com",
  projectId: "growth-70a85",
  storageBucket: "growth-70a85.firebasestorage.app",
  messagingSenderId: "732875330330",
  appId: "1:732875330330:ios:ba965c87a36c4d3ee2b3a6"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const KNOWLEDGE_COLLECTION = 'ai_coach_knowledge';

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
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
  
  const stopWords = new Set([
    'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'as', 'are', 'was',
    'were', 'been', 'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
    'would', 'should', 'may', 'might', 'must', 'can', 'could', 'to', 'of',
    'in', 'for', 'with', 'without', 'about', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'up', 'down', 'out', 'off', 'over',
    'under', 'again', 'further', 'then', 'once'
  ]);
  
  const words = combinedText
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 2 && !stopWords.has(word));
  
  const uniqueWords = [...new Set(words)];
  
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
  
  return [...new Set([...uniqueWords, ...methodKeywords])].slice(0, 50);
}

async function setupKnowledgeBase() {
  try {
    console.log('AI Coach Knowledge Base Setup');
    console.log('=============================\n');
    
    // Get user credentials
    console.log('Please enter your Firebase admin credentials:');
    const email = await question('Email: ');
    const password = await question('Password: ');
    
    console.log('\nAuthenticating...');
    
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      console.log(`✅ Authenticated as: ${userCredential.user.email}`);
    } catch (error) {
      console.error('❌ Authentication failed:', error.message);
      process.exit(1);
    }
    
    const resources = await loadSampleResources();
    const methods = await loadSampleMethods();
    
    console.log(`\n📚 Found ${resources.length} resources and ${methods.length} methods to add`);
    
    const knowledgeRef = collection(db, KNOWLEDGE_COLLECTION);
    
    // Clear existing resources
    console.log('\n🗑️  Clearing existing knowledge base...');
    const existing = await getDocs(knowledgeRef);
    const deletePromises = [];
    existing.forEach(docSnap => {
      deletePromises.push(deleteDoc(docSnap.ref));
    });
    await Promise.all(deletePromises);
    console.log(`Deleted ${deletePromises.length} existing documents`);
    
    // Add resources
    console.log('\n📝 Adding educational resources...');
    let addedCount = 0;
    
    for (const resource of resources) {
      const docId = resource.resourceId;
      const docRef = doc(knowledgeRef, docId);
      
      const docData = {
        resourceId: resource.resourceId,
        title: resource.title,
        content: resource.content_text,
        category: resource.category,
        type: 'educational_resource',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        searchableContent: `${resource.title} ${resource.content_text}`.toLowerCase(),
        keywords: extractKeywords(resource.title, resource.content_text),
        metadata: {
          category: resource.category,
          hasVisualPlaceholder: !!resource.visual_placeholder_url,
          contentLength: resource.content_text.length
        }
      };
      
      await setDoc(docRef, docData);
      addedCount++;
      
      if (addedCount % 5 === 0) {
        console.log(`  Added ${addedCount}/${resources.length} resources...`);
      }
    }
    
    console.log(`✅ Added all ${resources.length} educational resources`);
    
    // Add methods
    console.log('\n📝 Adding growth methods...');
    addedCount = 0;
    
    for (const method of methods) {
      const docId = `method_${method.id}`;
      const docRef = doc(knowledgeRef, docId);
      
      const docData = {
        methodId: method.id,
        title: method.title,
        content: `${method.description}\n\nInstructions:\n${method.instructions}`,
        stage: method.stage,
        type: 'growth_method',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        searchableContent: `${method.title} ${method.description} ${method.instructions}`.toLowerCase(),
        keywords: extractKeywords(method.title, method.description, method.instructions),
        metadata: {
          stage: method.stage,
          equipment: method.equipment || [],
          progressionCriteria: method.progressionCriteria,
          safetyNotes: method.safetyNotes
        }
      };
      
      await setDoc(docRef, docData);
      addedCount++;
      
      if (addedCount % 5 === 0) {
        console.log(`  Added ${addedCount}/${methods.length} methods...`);
      }
    }
    
    console.log(`✅ Added all ${methods.length} growth methods`);
    
    console.log('\n🎉 Knowledge base setup complete!');
    console.log(`📊 Total documents created: ${resources.length + methods.length}`);
    console.log('\n🤖 To test the AI Coach:');
    console.log('1. Open the app and go to the AI Coach tab');
    console.log('2. Try asking questions like:');
    console.log('   - "What is AM1?"');
    console.log('   - "Explain the Vascion technique"');
    console.log('   - "What are SABRE techniques?"');
    console.log('   - "Tell me about progression timelines"');
    
    rl.close();
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error setting up knowledge base:', error);
    rl.close();
    process.exit(1);
  }
}

// Run the setup
setupKnowledgeBase();