#!/usr/bin/env node

/**
 * Debug AI Coach search functionality
 */

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

async function testDirectFirestoreSearch(query) {
  const accessToken = await getAccessToken();
  if (!accessToken) {
    console.error('Could not get access token');
    return;
  }
  
  console.log(`\n🔍 Testing Firestore search for: "${query}"`);
  console.log('=' + '='.repeat(50));
  
  // Get all documents
  const options = {
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/ai_coach_knowledge`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  };
  
  return new Promise((resolve) => {
    https.get(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          const documents = response.documents || [];
          
          console.log(`\nTotal documents in knowledge base: ${documents.length}`);
          
          // Search simulation
          const searchQuery = query.toLowerCase();
          const searchTerms = searchQuery.split(/\s+/).filter(term => term.length > 0);
          
          console.log(`\nSearch terms: [${searchTerms.join(', ')}]`);
          console.log('\nDocuments that should match:\n');
          
          let matchCount = 0;
          documents.forEach(doc => {
            const fields = doc.fields;
            const title = fields.title?.stringValue || '';
            const keywords = fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
            const searchableContent = fields.searchableContent?.stringValue || '';
            const content = fields.content?.stringValue || fields.content_text?.stringValue || '';
            
            // Check various matching conditions
            let matches = false;
            let matchReason = '';
            
            // Check keywords
            const keywordMatch = keywords.some(k => 
              searchTerms.some(term => k.toLowerCase() === term.toLowerCase())
            );
            if (keywordMatch) {
              matches = true;
              matchReason = 'keyword match';
            }
            
            // Check title
            if (!matches && searchTerms.some(term => title.toLowerCase().includes(term))) {
              matches = true;
              matchReason = 'title match';
            }
            
            // Check searchable content
            if (!matches && searchTerms.some(term => searchableContent.includes(term))) {
              matches = true;
              matchReason = 'searchableContent match';
            }
            
            if (matches) {
              matchCount++;
              console.log(`✅ ${title}`);
              console.log(`   Match reason: ${matchReason}`);
              console.log(`   Keywords: ${keywords.slice(0, 5).join(', ')}...`);
              console.log(`   Has content: ${content.length > 0 ? 'Yes' : 'No'} (${content.length} chars)`);
              console.log('');
            }
          });
          
          if (matchCount === 0) {
            console.log('❌ No documents matched the search criteria');
            console.log('\nChecking why AM1 might not match:');
            
            // Debug AM1 specifically
            documents.forEach(doc => {
              const fields = doc.fields;
              const keywords = fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
              const am1Keywords = keywords.filter(k => k.toLowerCase().includes('am') && k.toLowerCase().includes('1'));
              if (am1Keywords.length > 0) {
                console.log(`\n${fields.title?.stringValue}:`);
                console.log(`  AM1-related keywords: ${am1Keywords.join(', ')}`);
              }
            });
          }
          
          console.log(`\nTotal matches: ${matchCount}`);
          resolve();
        }
      });
    });
  });
}

async function main() {
  console.log('🔧 AI Coach Knowledge Base Debug');
  console.log('================================');
  
  // Test various queries
  const testQueries = ['AM1', 'am1', 'What is AM1', "What's AM1?"];
  
  for (const query of testQueries) {
    await testDirectFirestoreSearch(query);
  }
  
  console.log('\n\n📊 Summary');
  console.log('==========');
  console.log('The knowledge base search should work if:');
  console.log('1. Keywords contain exact matches (e.g., "am1" or "am 1")');
  console.log('2. The search function is deployed with the updated code');
  console.log('3. The AI Coach function has permission to read Firestore');
  console.log('\nPossible issues:');
  console.log('1. The deployed function may be using old code');
  console.log('2. The search might be filtering out short terms');
  console.log('3. Case sensitivity issues in keyword matching');
}

main().catch(console.error);