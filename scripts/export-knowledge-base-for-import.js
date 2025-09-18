#!/usr/bin/env node

/**
 * Script to export knowledge base data in a format ready for Firebase Console import
 */

import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function exportForFirebase() {
  console.log('📚 Preparing Knowledge Base for Firebase Import');
  console.log('===========================================\n');
  
  try {
    // Load sample resources
    const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
    const resourcesData = await fs.readFile(resourcesPath, 'utf8');
    const resources = JSON.parse(resourcesData);
    
    console.log(`Found ${resources.length} resources to prepare\n`);
    
    // Prepare documents for Firestore import
    const firestoreData = {};
    
    for (const resource of resources) {
      // Extract keywords
      const text = `${resource.title} ${resource.content_text}`.toLowerCase();
      const words = text.match(/\b\w{3,}\b/g) || [];
      const keywords = [...new Set(words)].slice(0, 50);
      
      // Add specific method keywords
      if (text.includes('am1') || text.includes('angion method 1')) {
        keywords.push('am1', 'angion', 'method', 'beginner');
      }
      if (text.includes('am2') || text.includes('angion method 2')) {
        keywords.push('am2', 'arterial', 'intermediate');
      }
      if (text.includes('sabre')) {
        keywords.push('sabre', 'strike', 'percussion', 'advanced');
      }
      if (text.includes('vascion') || text.includes('am3')) {
        keywords.push('vascion', 'am3', 'advanced', 'corpus', 'spongiosum');
      }
      
      // Create Firestore document
      firestoreData[resource.resourceId] = {
        resourceId: resource.resourceId,
        title: resource.title,
        content: resource.content_text,
        category: resource.category,
        type: 'educational_resource',
        searchableContent: text,
        keywords: [...new Set(keywords)],
        metadata: {
          category: resource.category,
          contentLength: resource.content_text.length,
          hasVisualPlaceholder: !!resource.visual_placeholder_url
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
    }
    
    // Save to file
    const outputPath = path.join(__dirname, 'ai_coach_knowledge_export.json');
    await fs.writeFile(
      outputPath,
      JSON.stringify(firestoreData, null, 2),
      'utf8'
    );
    
    console.log(`✅ Export complete! File saved to:\n   ${outputPath}\n`);
    
    console.log('📋 Manual Import Instructions:');
    console.log('==============================\n');
    console.log('1. Go to Firebase Console:');
    console.log('   https://console.firebase.google.com/project/growth-70a85/firestore\n');
    
    console.log('2. Create the collection:');
    console.log('   - Click "Start collection"');
    console.log('   - Collection ID: ai_coach_knowledge');
    console.log('   - Click "Next"\n');
    
    console.log('3. Create first document:');
    console.log('   - Document ID: Click "Auto-ID"');
    console.log('   - Add a field: name="test", value="test"');
    console.log('   - Click "Save"\n');
    
    console.log('4. Import the data:');
    console.log('   - Click the three dots menu (⋮) next to "ai_coach_knowledge"');
    console.log('   - Select "Import documents"');
    console.log('   - Upload the file: ai_coach_knowledge_export.json');
    console.log('   - Follow the import wizard\n');
    
    console.log('5. Delete the test document:');
    console.log('   - After import, delete the test document you created\n');
    
    console.log('Alternative: Use Firestore REST API');
    console.log('===================================');
    console.log('You can also use the included curl commands:');
    console.log(`   bash ${path.join(__dirname, 'firestore-import-commands.sh')}\n`);
    
    // Generate curl commands
    await generateCurlCommands(firestoreData);
    
  } catch (error) {
    console.error('❌ Export failed:', error.message);
    process.exit(1);
  }
}

async function generateCurlCommands(data) {
  const PROJECT_ID = "growth-70a85";
  const COLLECTION = "ai_coach_knowledge";
  
  const commands = [
    '#!/bin/bash',
    '',
    '# Firestore REST API import commands',
    '# You need to get an access token first:',
    '# gcloud auth application-default print-access-token',
    '',
    'ACCESS_TOKEN="YOUR_ACCESS_TOKEN_HERE"',
    `PROJECT_ID="${PROJECT_ID}"`,
    `COLLECTION="${COLLECTION}"`,
    '',
    'echo "Creating knowledge base documents..."',
    ''
  ];
  
  for (const [docId, docData] of Object.entries(data)) {
    const docPath = `projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}/${docId}`;
    const fields = {};
    
    // Convert to Firestore field format
    for (const [key, value] of Object.entries(docData)) {
      if (typeof value === 'string') {
        fields[key] = { stringValue: value };
      } else if (typeof value === 'number') {
        fields[key] = { integerValue: value };
      } else if (Array.isArray(value)) {
        fields[key] = { 
          arrayValue: { 
            values: value.map(v => ({ stringValue: v })) 
          } 
        };
      } else if (typeof value === 'object') {
        fields[key] = { 
          mapValue: { 
            fields: Object.entries(value).reduce((acc, [k, v]) => {
              acc[k] = typeof v === 'string' ? { stringValue: v } : { integerValue: v };
              return acc;
            }, {})
          } 
        };
      }
    }
    
    const requestBody = JSON.stringify({ fields });
    
    commands.push(`# Create document: ${docData.title}`);
    commands.push(`curl -X POST \\`);
    commands.push(`  "https://firestore.googleapis.com/v1/${docPath}" \\`);
    commands.push(`  -H "Authorization: Bearer \${ACCESS_TOKEN}" \\`);
    commands.push(`  -H "Content-Type: application/json" \\`);
    commands.push(`  -d '${requestBody}'`);
    commands.push('');
  }
  
  const scriptPath = path.join(__dirname, 'firestore-import-commands.sh');
  await fs.writeFile(scriptPath, commands.join('\n'), 'utf8');
  await fs.chmod(scriptPath, '755');
  
  console.log(`✅ Curl commands saved to: ${scriptPath}\n`);
}

// Run the export
exportForFirebase();