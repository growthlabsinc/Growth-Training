#!/usr/bin/env node

import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc, getDoc, serverTimestamp, collection, writeBatch } from 'firebase/firestore';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Firebase configuration - using development
const firebaseConfig = {
  apiKey: "AIzaSyC-iNr6VkDx38j2g-rPoH1CRYV8XlQTVpY",
  authDomain: "growth-70a85.firebaseapp.com",
  projectId: "growth-70a85",
  storageBucket: "growth-70a85.appspot.com",
  messagingSenderId: "645068839446",
  appId: "1:645068839446:ios:778265634d87eb7ef89fdd"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Methods to deploy
const methodsToReplace = [
  {
    fileName: 'angion-method-1-0-multistep.json',
    methodId: 'angion_method_1_0',
    name: 'Angion Method 1.0'
  },
  {
    fileName: 'angion-methods-multistep/angio-pumping.json',
    methodId: 'angio_pumping',
    name: 'Angio Pumping'
  },
  {
    fileName: 'angion-methods-multistep/angion-method-2-0.json',
    methodId: 'angion_method_2_0',
    name: 'Angion Method 2.0'
  },
  {
    fileName: 'angion-methods-multistep/jelq-2-0.json',
    methodId: 'jelq_2_0',
    name: 'Jelq 2.0'
  },
  {
    fileName: 'angion-methods-multistep/vascion.json',
    methodId: 'vascion',
    name: 'Vascion'
  }
];

async function deployMethods() {
  console.log('🚀 Starting Angion Methods multi-step deployment...\n');
  
  const batch = writeBatch(db);
  let successCount = 0;
  
  for (const method of methodsToReplace) {
    console.log(`📋 Processing ${method.name}...`);
    
    try {
      // Read the JSON file
      const filePath = path.join(__dirname, method.fileName);
      const methodData = JSON.parse(readFileSync(filePath, 'utf8'));
      
      // Get existing method to preserve user data
      const existingDoc = await getDoc(doc(db, 'growthMethods', method.methodId));
      
      if (existingDoc.exists()) {
        const existingData = existingDoc.data();
        // Preserve user data
        methodData.createdAt = existingData.createdAt || new Date().toISOString();
        methodData.viewCount = existingData.viewCount || 0;
        methodData.averageRating = existingData.averageRating || 0;
        methodData.totalRatings = existingData.totalRatings || 0;
        console.log(`  ✅ Preserving user data for ${method.name}`);
      } else {
        methodData.createdAt = new Date().toISOString();
        methodData.viewCount = 0;
        methodData.averageRating = 0;
        methodData.totalRatings = 0;
      }
      
      // Add/update common fields
      methodData.updatedAt = new Date().toISOString();
      methodData.isActive = true;
      methodData.hasMultipleSteps = true;
      
      // Add to batch
      batch.set(doc(db, 'growthMethods', method.methodId), methodData);
      successCount++;
      console.log(`  ✅ Prepared ${method.name} for deployment`);
      
    } catch (error) {
      console.error(`  ❌ Error processing ${method.name}:`, error.message);
    }
  }
  
  if (successCount > 0) {
    console.log(`\n⏳ Deploying ${successCount} methods to Firebase...`);
    try {
      await batch.commit();
      console.log('\n🎉 All methods deployed successfully!');
      console.log('\n📝 Summary:');
      console.log(`  - Methods deployed: ${successCount}/${methodsToReplace.length}`);
      console.log(`  - Each method now has detailed step-by-step instructions`);
      console.log(`  - Timer configurations updated for step progression`);
    } catch (error) {
      console.error('\n❌ Error committing batch:', error);
    }
  } else {
    console.log('\n❌ No methods were prepared for deployment');
  }
  
  process.exit();
}

// Run the deployment
deployMethods().catch(error => {
  console.error('❌ Deployment failed:', error);
  process.exit(1);
});