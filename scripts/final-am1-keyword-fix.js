#!/usr/bin/env node

/**
 * Final targeted fix - add am1 keyword to specific key documents
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import https from 'https';

const execAsync = promisify(exec);
const PROJECT_ID = 'growth-70a85';

async function getAccessToken() {
  const { stdout } = await execAsync('~/google-cloud-sdk/bin/gcloud auth application-default print-access-token');
  return stdout.trim();
}

async function addKeywordToDoc(docId, keywordToAdd, accessToken) {
  // First get current keywords
  const getOptions = {
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/ai_coach_knowledge/${docId}`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  };
  
  return new Promise((resolve, reject) => {
    https.get(getOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', async () => {
        if (res.statusCode === 200) {
          const doc = JSON.parse(data);
          const currentKeywords = doc.fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
          
          // Add new keyword if not present
          if (!currentKeywords.includes(keywordToAdd)) {
            currentKeywords.unshift(keywordToAdd); // Add at beginning
            const newKeywords = currentKeywords.slice(0, 20); // Respect limit
            
            // Update document
            const fieldsFormatted = {
              keywords: { 
                arrayValue: { 
                  values: newKeywords.map(v => ({ stringValue: v })) 
                } 
              }
            };
            
            const patchData = JSON.stringify({ fields: fieldsFormatted });
            
            const patchOptions = {
              hostname: 'firestore.googleapis.com',
              path: `/v1/${doc.name}?updateMask.fieldPaths=keywords`,
              method: 'PATCH',
              headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(patchData)
              }
            };
            
            const req = https.request(patchOptions, (patchRes) => {
              let patchData = '';
              patchRes.on('data', (chunk) => { patchData += chunk; });
              patchRes.on('end', () => {
                if (patchRes.statusCode === 200) {
                  resolve({ updated: true, title: doc.fields.title?.stringValue });
                } else {
                  reject(new Error(`Failed to update: ${patchRes.statusCode}`));
                }
              });
            });
            
            req.on('error', reject);
            req.write(patchData);
            req.end();
          } else {
            resolve({ updated: false, title: doc.fields.title?.stringValue });
          }
        } else {
          reject(new Error(`Failed to get document: ${res.statusCode}`));
        }
      });
    });
  });
}

async function fixAM1Keywords() {
  console.log('🎯 Targeted AM1 Keyword Fix');
  console.log('===========================\n');
  
  const accessToken = await getAccessToken();
  
  // Key documents that MUST have am1 keyword
  const criticalDocs = [
    'complete-angion-methods-list',
    'angion-methods-hand-techniques-breakdown',
    'personal-journey-angion-transformation',
    'progression-vascularity-timeline'
  ];
  
  console.log('Adding "am1" keyword to critical documents:\n');
  
  for (const docId of criticalDocs) {
    try {
      const result = await addKeywordToDoc(docId, 'am1', accessToken);
      if (result.updated) {
        console.log(`✅ Updated: ${result.title}`);
      } else {
        console.log(`ℹ️  Already has am1: ${result.title}`);
      }
    } catch (error) {
      console.error(`❌ Failed ${docId}: ${error.message}`);
    }
  }
  
  console.log('\n✅ Critical documents updated!');
  console.log('\nThe AI Coach will now find these documents when users search for "AM1"');
}

fixAM1Keywords().catch(console.error);