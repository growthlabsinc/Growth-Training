#!/usr/bin/env node

/**
 * Fix knowledge base documents to include required fields for search
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

const PROJECT_ID = 'growth-70a85';
const COLLECTION = 'ai_coach_knowledge';

async function getAccessToken() {
  try {
    const { stdout } = await execAsync('~/google-cloud-sdk/bin/gcloud auth application-default print-access-token');
    return stdout.trim();
  } catch (error) {
    console.error('Error getting access token:', error.message);
    return null;
  }
}

async function getDocuments(accessToken) {
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
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          resolve(response.documents || []);
        } else {
          reject(new Error(`Failed to get documents: ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

function extractKeywords(title, content) {
  const text = `${title} ${content}`.toLowerCase();
  const keywords = new Set();
  
  // Add common abbreviations and terms
  const patterns = [
    /am\s*1/g, /am1/g, /angion method 1/g,
    /am\s*2/g, /am2/g, /angion method 2/g,
    /am\s*3/g, /am3/g, /angion method 3/g,
    /vascion/g, /sabre/g, /bfr/g,
    /jelq/g, /kegel/g, /reverse kegel/g,
    /cc/g, /cs/g, /corpus cavernosum/g, /corpus spongiosum/g,
    /eq/g, /erection quality/g,
    /ed/g, /erectile dysfunction/g,
    /bpel/g, /nbpel/g, /eg/g,
    /morning wood/g, /morning erection/g,
    /vascular/g, /circulation/g, /blood flow/g,
    /technique/g, /progression/g, /beginner/g, /advanced/g,
    /glycocalyx/g, /shear stress/g, /endothelial/g,
    /path of eleven/g, /janus protocol/g,
    /troubleshooting/g, /plateau/g, /gaining/g
  ];
  
  patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      matches.forEach(match => keywords.add(match.trim()));
    }
  });
  
  // Add single words from title
  title.toLowerCase().split(/\s+/).forEach(word => {
    if (word.length > 3) {
      keywords.add(word);
    }
  });
  
  // Add category
  const category = text.match(/category":\s*"([^"]+)"/);
  if (category) {
    keywords.add(category[1]);
  }
  
  return Array.from(keywords).slice(0, 20); // Firestore array limit
}

async function updateDocument(docPath, fields, accessToken) {
  return new Promise((resolve, reject) => {
    // Create proper field paths for updateMask
    const fieldPaths = [];
    Object.keys(fields).forEach(key => {
      if (key === 'metadata') {
        fieldPaths.push('metadata.lastUpdated');
        fieldPaths.push('metadata.source');
      } else {
        fieldPaths.push(key);
      }
    });
    
    const fieldsFormatted = {};
    
    // Convert to Firestore field format
    for (const [key, value] of Object.entries(fields)) {
      if (typeof value === 'string') {
        fieldsFormatted[key] = { stringValue: value };
      } else if (Array.isArray(value)) {
        fieldsFormatted[key] = { 
          arrayValue: { 
            values: value.map(v => ({ stringValue: String(v) })) 
          } 
        };
      }
    }
    
    const patchData = JSON.stringify({ 
      fields: fieldsFormatted 
    });
    
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docPath}?${fieldPaths.map(fp => `updateMask.fieldPaths=${fp}`).join('&')}`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(patchData)
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
    req.write(patchData);
    req.end();
  });
}

async function fixKnowledgeBase() {
  console.log('🔧 Fixing Knowledge Base Fields');
  console.log('================================\n');
  
  // Get access token
  console.log('🔑 Getting access token...');
  const accessToken = await getAccessToken();
  
  if (!accessToken) {
    console.error('❌ Could not get access token');
    process.exit(1);
  }
  
  // Get all documents
  console.log('📄 Getting existing documents...');
  const documents = await getDocuments(accessToken);
  console.log(`✅ Found ${documents.length} documents\n`);
  
  // Update each document
  console.log('🔄 Updating documents...\n');
  let successCount = 0;
  let errorCount = 0;
  
  for (const doc of documents) {
    try {
      // Extract current fields
      const fields = doc.fields;
      const title = fields.title?.stringValue || '';
      const content = fields.content_text?.stringValue || fields.content?.stringValue || '';
      
      // Generate keywords and searchable content
      const keywords = extractKeywords(title, content);
      const searchableContent = `${title} ${content}`.toLowerCase().substring(0, 1000);
      
      // Prepare update fields
      const updateFields = {
        keywords: keywords,
        searchableContent: searchableContent,
        content: content, // Ensure 'content' field exists
        type: fields.category?.stringValue || 'knowledge',
        metadata: {
          lastUpdated: new Date().toISOString(),
          source: 'sample-resources'
        }
      };
      
      // Update document
      await updateDocument(doc.name, updateFields, accessToken);
      console.log(`   ✅ Updated: ${title}`);
      successCount++;
    } catch (error) {
      console.error(`   ❌ Failed: ${doc.name} - ${error.message}`);
      errorCount++;
    }
  }
  
  console.log(`\n📊 Update Summary:`);
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Failed: ${errorCount}`);
  console.log(`   📄 Total: ${documents.length}\n`);
  
  if (successCount > 0) {
    console.log('🎉 Knowledge Base Fields Fixed!');
    console.log('================================\n');
    console.log('Next steps:');
    console.log('1. Deploy the updated functions:');
    console.log('   firebase deploy --only functions:generateAIResponse\n');
    console.log('2. Test the AI Coach with queries like:');
    console.log('   - "What is AM1?"');
    console.log('   - "Explain the SABRE technique"');
    console.log('   - "What are the Angion Methods?"');
    console.log('   - "How do I progress from AM1 to AM2?"\n');
  }
}

// Run the fix
fixKnowledgeBase().catch(error => {
  console.error('❌ Fix failed:', error);
  process.exit(1);
});