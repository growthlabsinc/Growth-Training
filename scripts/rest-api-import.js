#!/usr/bin/env node

/**
 * Import knowledge base using Firestore REST API
 * Uses Firebase CLI authentication
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import https from 'https';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const execAsync = promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PROJECT_ID = 'growth-training-app';
const COLLECTION = 'ai_coach_knowledge';

async function getAccessToken() {
  try {
    // Try to get token using Firebase CLI
    const { stdout } = await execAsync('firebase auth:application-default:print-access-token');
    return stdout.trim();
  } catch (error) {
    console.log('Could not get token from Firebase CLI, trying alternative...');
    
    // Try using gcloud if available
    try {
      const { stdout } = await execAsync('~/google-cloud-sdk/bin/gcloud auth application-default print-access-token');
      return stdout.trim();
    } catch (gcloudError) {
      // Try without full path as fallback
      try {
        const { stdout: stdout2 } = await execAsync('gcloud auth application-default print-access-token');
        return stdout2.trim();
      } catch (fallbackError) {
        return null;
      }
    }
  }
}

async function createDocument(docId, docData, accessToken) {
  return new Promise((resolve, reject) => {
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
            values: value.map(v => ({ stringValue: String(v) })) 
          } 
        };
      } else if (typeof value === 'object' && value !== null) {
        const mapFields = {};
        for (const [k, v] of Object.entries(value)) {
          if (typeof v === 'string') {
            mapFields[k] = { stringValue: v };
          } else if (typeof v === 'number') {
            mapFields[k] = { integerValue: v };
          } else if (typeof v === 'boolean') {
            mapFields[k] = { booleanValue: v };
          } else {
            mapFields[k] = { stringValue: String(v) };
          }
        }
        fields[key] = { mapValue: { fields: mapFields } };
      }
    }
    
    const postData = JSON.stringify({ fields });
    
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}?documentId=${docId}`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function deleteCollection(accessToken) {
  // First, list all documents
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    };
    
    https.get(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', async () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          const documents = response.documents || [];
          
          // Delete each document
          for (const doc of documents) {
            try {
              await deleteDocument(doc.name, accessToken);
            } catch (error) {
              console.error(`Failed to delete ${doc.name}:`, error.message);
            }
          }
          
          resolve(documents.length);
        } else {
          // Collection might not exist, which is fine
          resolve(0);
        }
      });
    }).on('error', reject);
  });
}

async function deleteDocument(documentPath, accessToken) {
  return new Promise((resolve, reject) => {
    const path = documentPath.replace(`projects/${PROJECT_ID}/databases/(default)/documents/`, '');
    
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/${documentPath}`,
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    };
    
    const req = https.request(options, (res) => {
      if (res.statusCode === 200 || res.statusCode === 204) {
        resolve();
      } else {
        reject(new Error(`Failed to delete: ${res.statusCode}`));
      }
    });
    
    req.on('error', reject);
    req.end();
  });
}

async function importData() {
  console.log('🚀 Firestore REST API Import');
  console.log('============================\n');
  
  // Get access token
  console.log('🔑 Getting access token...');
  const accessToken = await getAccessToken();
  
  if (!accessToken) {
    console.error('❌ Could not get access token');
    console.log('\nPlease ensure you are logged in:');
    console.log('  firebase login');
    console.log('  OR');
    console.log('  gcloud auth application-default login\n');
    process.exit(1);
  }
  
  console.log('✅ Got access token\n');
  
  // Load export data
  console.log('📄 Loading export data...');
  const exportPath = path.join(__dirname, 'ai_coach_knowledge_export.json');
  const exportData = JSON.parse(await fs.readFile(exportPath, 'utf8'));
  console.log(`✅ Loaded ${Object.keys(exportData).length} documents\n`);
  
  // Clear existing collection
  console.log('🗑️  Clearing existing collection...');
  const deletedCount = await deleteCollection(accessToken);
  if (deletedCount > 0) {
    console.log(`   Deleted ${deletedCount} existing documents\n`);
  }
  
  // Import documents
  console.log('📥 Importing documents...\n');
  let successCount = 0;
  let errorCount = 0;
  
  for (const [docId, docData] of Object.entries(exportData)) {
    try {
      await createDocument(docId, docData, accessToken);
      console.log(`   ✅ Imported: ${docData.title}`);
      successCount++;
    } catch (error) {
      console.error(`   ❌ Failed: ${docData.title} - ${error.message}`);
      errorCount++;
    }
  }
  
  console.log(`\n📊 Import Summary:`);
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Failed: ${errorCount}`);
  console.log(`   📄 Total: ${Object.keys(exportData).length}\n`);
  
  if (successCount > 0) {
    console.log('🎉 Knowledge Base Import Complete!');
    console.log('==================================\n');
    console.log('The AI Coach now has access to:');
    console.log('• AM1, AM2, Vascion (AM3) techniques');
    console.log('• SABRE techniques and safety information');
    console.log('• Common abbreviations and terminology');
    console.log('• Progression timelines');
    console.log('• And much more!\n');
    console.log('🚀 Deploy the updated functions:');
    console.log('   firebase deploy --only functions:generateAIResponse\n');
  }
}

// Run import
importData().catch(error => {
  console.error('❌ Import failed:', error);
  process.exit(1);
});