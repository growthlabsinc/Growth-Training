#!/usr/bin/env node

/**
 * Add AM1, AM2, AM3 as specific keywords to improve search
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import https from 'https';

const execAsync = promisify(exec);
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

async function getDocument(docId, accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}/${docId}`,
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
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Failed to get document: ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

async function updateKeywords(docPath, newKeywords, accessToken) {
  return new Promise((resolve, reject) => {
    const fieldsFormatted = {
      keywords: { 
        arrayValue: { 
          values: newKeywords.map(v => ({ stringValue: String(v) })) 
        } 
      }
    };
    
    const patchData = JSON.stringify({ 
      fields: fieldsFormatted 
    });
    
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docPath}?updateMask.fieldPaths=keywords`,
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

async function fixAMKeywords() {
  console.log('🔧 Adding AM1/AM2/AM3 Keywords');
  console.log('===============================\n');
  
  // Get access token
  const accessToken = await getAccessToken();
  if (!accessToken) {
    console.error('❌ Could not get access token');
    process.exit(1);
  }
  
  // Documents that should have AM1, AM2, AM3 keywords
  const docsToUpdate = [
    {
      id: 'complete-angion-methods-list',
      addKeywords: ['am1', 'am2', 'am3', 'angion 1', 'angion 2', 'angion 3']
    },
    {
      id: 'angion-methods-hand-techniques-breakdown',
      addKeywords: ['am1', 'am2', 'am3', 'angion 1', 'angion 2', 'angion 3']
    },
    {
      id: 'am20-erection-level-guidance',
      addKeywords: ['am2', 'am 2.0', 'angion 2']
    },
    {
      id: 'personal-journey-angion-transformation',
      addKeywords: ['am1', 'am2', 'am3']
    }
  ];
  
  for (const docInfo of docsToUpdate) {
    try {
      console.log(`\n📄 Updating: ${docInfo.id}`);
      
      // Get current document
      const doc = await getDocument(docInfo.id, accessToken);
      const currentKeywords = doc.fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
      
      // Add new keywords (avoiding duplicates)
      const keywordSet = new Set(currentKeywords);
      docInfo.addKeywords.forEach(k => keywordSet.add(k));
      const newKeywords = Array.from(keywordSet).slice(0, 20); // Firestore limit
      
      // Update document
      await updateKeywords(doc.name, newKeywords, accessToken);
      console.log(`   ✅ Added keywords: ${docInfo.addKeywords.join(', ')}`);
      
    } catch (error) {
      console.error(`   ❌ Failed: ${error.message}`);
    }
  }
  
  console.log('\n\n✅ Keywords Updated!');
  console.log('The AI Coach should now respond to:');
  console.log('• "What is AM1?"');
  console.log('• "What is AM2?"');
  console.log('• "Explain AM3"');
  console.log('• And variations of these queries\n');
}

// Run update
fixAMKeywords().catch(error => {
  console.error('❌ Update failed:', error);
  process.exit(1);
});