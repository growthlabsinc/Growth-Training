#!/usr/bin/env node

/**
 * Direct Firebase Deployment Script
 * 
 * This script updates Angion Methods in Firestore.
 * 
 * Usage:
 * 1. First, authenticate with Firebase CLI:
 *    firebase login
 * 
 * 2. Then run this script:
 *    node firebase-direct-deploy.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Angion Methods Multi-Step Deployment\n');

// Methods to deploy
const methods = [
  {
    id: 'angion_method_1_0',
    file: 'angion-method-1-0-multistep.json',
    name: 'Angion Method 1.0'
  },
  {
    id: 'angio_pumping',
    file: 'angion-methods-multistep/angio-pumping.json',
    name: 'Angio Pumping'
  },
  {
    id: 'angion_method_2_0',
    file: 'angion-methods-multistep/angion-method-2-0.json',
    name: 'Angion Method 2.0'
  },
  {
    id: 'jelq_2_0',
    file: 'angion-methods-multistep/jelq-2-0.json',
    name: 'Jelq 2.0'
  },
  {
    id: 'vascion',
    file: 'angion-methods-multistep/vascion.json',
    name: 'Vascion'
  }
];

console.log('📋 Preparing to update the following methods:');
methods.forEach(m => console.log(`   - ${m.name}`));
console.log('');

// Check if user is authenticated
try {
  execSync('firebase projects:list > /dev/null 2>&1');
} catch (error) {
  console.error('❌ Error: Not authenticated with Firebase CLI');
  console.error('   Please run: firebase login');
  process.exit(1);
}

console.log('✅ Firebase CLI authenticated\n');

// Process each method
for (const method of methods) {
  console.log(`\n📝 Processing ${method.name}...`);
  
  try {
    // Read the JSON file
    const filePath = path.join(__dirname, method.file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    // Add update timestamp and flags
    data.updatedAt = new Date().toISOString();
    data.hasMultipleSteps = true;
    data.isActive = true;
    
    // Create temp file with the data
    const tempFile = path.join(__dirname, `temp-${method.id}.json`);
    fs.writeFileSync(tempFile, JSON.stringify(data, null, 2));
    
    // Use Firebase CLI to update the document
    console.log(`   ⏳ Updating in Firestore...`);
    
    // Build the Firebase CLI command
    const command = `firebase firestore:set growthMethods/${method.id} < ${tempFile} --merge --project growth-70a85`;
    
    try {
      execSync(command, { stdio: 'pipe' });
      console.log(`   ✅ ${method.name} updated successfully`);
    } catch (cmdError) {
      console.error(`   ❌ Failed to update ${method.name}:`, cmdError.message);
    }
    
    // Clean up temp file
    fs.unlinkSync(tempFile);
    
  } catch (error) {
    console.error(`   ❌ Error processing ${method.name}:`, error.message);
  }
}

console.log('\n🎉 Deployment process complete!');
console.log('\n📱 Next steps:');
console.log('   1. Open the Growth app');
console.log('   2. Navigate to Methods section');
console.log('   3. Verify each Angion Method shows multiple steps');
console.log('   4. Test the timer functionality with new intervals\n');