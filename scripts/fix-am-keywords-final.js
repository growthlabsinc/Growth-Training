#!/usr/bin/env node

/**
 * Final fix for AM keywords - add both spaced and non-spaced versions
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

async function getDocuments(accessToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    };
    
    https.get(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          resolve(response.documents || []);
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

async function fixAMKeywords() {
  console.log('🔧 Final AM Keywords Fix');
  console.log('========================\n');
  
  const accessToken = await getAccessToken();
  if (!accessToken) {
    console.error('❌ Could not get access token');
    process.exit(1);
  }
  
  console.log('📄 Getting all documents...');
  const documents = await getDocuments(accessToken);
  console.log(`✅ Found ${documents.length} documents\n`);
  
  let updateCount = 0;
  
  for (const doc of documents) {
    try {
      const fields = doc.fields;
      const title = fields.title?.stringValue || '';
      const keywords = fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
      
      // Create a set to avoid duplicates
      const keywordSet = new Set(keywords);
      let needsUpdate = false;
      
      // Add non-spaced versions for any spaced AM keywords
      keywords.forEach(keyword => {
        if (keyword === 'am 1') {
          keywordSet.add('am1');
          needsUpdate = true;
        }
        if (keyword === 'am 2') {
          keywordSet.add('am2');
          needsUpdate = true;
        }
        if (keyword === 'am 3') {
          keywordSet.add('am3');
          needsUpdate = true;
        }
        // Also add spaced versions if we have non-spaced
        if (keyword === 'am1') {
          keywordSet.add('am 1');
          needsUpdate = true;
        }
        if (keyword === 'am2') {
          keywordSet.add('am 2');
          needsUpdate = true;
        }
        if (keyword === 'am3') {
          keywordSet.add('am 3');
          needsUpdate = true;
        }
      });
      
      // Check content for AM references and add relevant keywords
      const content = (fields.content?.stringValue || fields.content_text?.stringValue || '').toLowerCase();
      const searchableContent = (fields.searchableContent?.stringValue || '').toLowerCase();
      const fullText = `${title} ${content} ${searchableContent}`.toLowerCase();
      
      if (fullText.includes('am1') || fullText.includes('am 1') || fullText.includes('angion method 1')) {
        keywordSet.add('am1');
        keywordSet.add('am 1');
        needsUpdate = true;
      }
      
      if (fullText.includes('am2') || fullText.includes('am 2') || fullText.includes('angion method 2')) {
        keywordSet.add('am2');
        keywordSet.add('am 2');
        needsUpdate = true;
      }
      
      if (fullText.includes('am3') || fullText.includes('am 3') || fullText.includes('vascion')) {
        keywordSet.add('am3');
        keywordSet.add('am 3');
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        const newKeywords = Array.from(keywordSet).slice(0, 20); // Firestore limit
        await updateKeywords(doc.name, newKeywords, accessToken);
        updateCount++;
        console.log(`✅ Updated: ${title}`);
        const amKeywords = newKeywords.filter(k => k.includes('am') && /\d/.test(k));
        if (amKeywords.length > 0) {
          console.log(`   AM keywords: ${amKeywords.join(', ')}`);
        }
      }
    } catch (error) {
      console.error(`❌ Failed to update ${doc.name}: ${error.message}`);
    }
  }
  
  console.log(`\n📊 Summary:`);
  console.log(`   Updated ${updateCount} documents`);
  console.log(`\n✅ Keywords Fixed!`);
  console.log('\nThe AI Coach should now respond to:');
  console.log('• "AM1" or "am1"');
  console.log('• "AM2" or "am2"');  
  console.log('• "AM3" or "am3"');
  console.log('• And all variations!\n');
}

fixAMKeywords().catch(error => {
  console.error('❌ Fix failed:', error);
  process.exit(1);
});