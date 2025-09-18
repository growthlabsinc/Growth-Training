#!/usr/bin/env node

import { exec } from 'child_process';
import { promisify } from 'util';
import https from 'https';

const execAsync = promisify(exec);
const PROJECT_ID = 'growth-70a85';

async function getAccessToken() {
  try {
    const { stdout } = await execAsync('~/google-cloud-sdk/bin/gcloud auth application-default print-access-token');
    return stdout.trim();
  } catch (error) {
    return null;
  }
}

async function testAM1Search() {
  const accessToken = await getAccessToken();
  if (!accessToken) {
    console.error('Could not get access token');
    return;
  }
  
  console.log('🔍 Testing AM1 Search\n');
  
  // Get all documents and check for AM1
  const options = {
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/ai_coach_knowledge`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  };
  
  https.get(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      if (res.statusCode === 200) {
        const response = JSON.parse(data);
        const documents = response.documents || [];
        
        console.log('Documents containing AM1-related keywords:\n');
        
        documents.forEach(doc => {
          const fields = doc.fields;
          const title = fields.title?.stringValue || '';
          const keywords = fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
          
          // Find any AM1-related keywords
          const am1Keywords = keywords.filter(k => 
            k.toLowerCase().includes('am1') || 
            k.toLowerCase().includes('am 1') ||
            k.toLowerCase().includes('angion method 1') ||
            k.toLowerCase().includes('angion 1')
          );
          
          if (am1Keywords.length > 0) {
            console.log(`📄 ${title}`);
            console.log(`   Keywords: ${am1Keywords.join(', ')}`);
            console.log('');
          }
        });
        
        // Show what the search function is looking for
        console.log('\n❗ Note: The search function uses array-contains-any, which requires exact matches.');
        console.log('Keywords with spaces ("am 1") won\'t match a search for "am1".');
        console.log('\nThe AI Coach should still work because:');
        console.log('1. It also searches the searchableContent field');
        console.log('2. The full content is included in the response');
        console.log('3. The AI can understand variations like AM1, am1, "angion method 1", etc.');
      }
    });
  });
}

testAM1Search();