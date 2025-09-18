#!/usr/bin/env node

/**
 * Add AM1 keywords to documents that are specifically about AM1
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
    return null;
  }
}

async function getDocument(docId, accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}/${docId}`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    };
    
    https.get(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Failed: ${res.statusCode}`));
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
    
    const patchData = JSON.stringify({ fields: fieldsFormatted });
    
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
      res.on('data', (chunk) => { data += chunk; });
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

async function addAM1ToRelevantDocs() {
  console.log('🔧 Adding AM1 to Relevant Documents');
  console.log('===================================\n');
  
  const accessToken = await getAccessToken();
  if (!accessToken) {
    console.error('❌ Could not get access token');
    process.exit(1);
  }
  
  // Documents that should definitely have AM1 keywords
  const docsToUpdate = [
    {
      id: 'complete-angion-methods-list',
      reason: 'Contains comprehensive AM1 instructions'
    },
    {
      id: 'angion-methods-hand-techniques-breakdown',
      reason: 'Details AM1 hand technique'
    },
    {
      id: 'personal-journey-angion-transformation',
      reason: 'Discusses AM1 in personal experience'
    },
    {
      id: 'progression-vascularity-timeline',
      reason: 'Mentions AM1 in progression'
    }
  ];
  
  for (const docInfo of docsToUpdate) {
    try {
      console.log(`📄 Processing: ${docInfo.id}`);
      console.log(`   Reason: ${docInfo.reason}`);
      
      const doc = await getDocument(docInfo.id, accessToken);
      const currentKeywords = doc.fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
      
      // Create set and ensure AM1 keywords are present
      const keywordSet = new Set(currentKeywords);
      
      // Add all AM1 variations
      keywordSet.add('am1');
      keywordSet.add('am 1');
      keywordSet.add('angion method 1');
      keywordSet.add('angion 1');
      
      const newKeywords = Array.from(keywordSet).slice(0, 20);
      
      // Only update if we actually added new keywords
      if (newKeywords.length > currentKeywords.length) {
        await updateKeywords(doc.name, newKeywords, accessToken);
        console.log(`   ✅ Added AM1 keywords`);
        const am1Keywords = newKeywords.filter(k => k.toLowerCase().includes('am1') || (k.toLowerCase().includes('am') && k.includes('1')));
        console.log(`   AM1 keywords: ${am1Keywords.join(', ')}`);
      } else {
        console.log(`   ℹ️  Already has AM1 keywords`);
      }
      
      console.log('');
    } catch (error) {
      console.error(`   ❌ Failed: ${error.message}\n`);
    }
  }
  
  console.log('✅ AM1 Keywords Added to Relevant Documents!');
  console.log('\nNow testing final search...\n');
}

addAM1ToRelevantDocs().catch(error => {
  console.error('❌ Update failed:', error);
  process.exit(1);
});