#!/usr/bin/env node

import { exec } from 'child_process';
import { promisify } from 'util';
import https from 'https';

const execAsync = promisify(exec);

async function testAM1Search() {
  const { stdout } = await execAsync('~/google-cloud-sdk/bin/gcloud auth application-default print-access-token');
  const accessToken = stdout.trim();
  
  const options = {
    hostname: 'firestore.googleapis.com',
    path: '/v1/projects/growth-70a85/databases/(default)/documents/ai_coach_knowledge',
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
          
          console.log('🔍 Final AM1 Keyword Test\n');
          
          // Count documents with am1 keyword
          const am1Docs = [];
          documents.forEach(doc => {
            const keywords = doc.fields.keywords?.arrayValue?.values?.map(v => v.stringValue) || [];
            if (keywords.includes('am1')) {
              am1Docs.push({
                title: doc.fields.title?.stringValue,
                hasContent: !!doc.fields.content?.stringValue,
                contentLength: doc.fields.content?.stringValue?.length || 0
              });
            }
          });
          
          console.log(`Documents with 'am1' keyword: ${am1Docs.length}\n`);
          
          am1Docs.forEach(doc => {
            console.log(`✅ ${doc.title}`);
            console.log(`   Content: ${doc.hasContent ? `Yes (${doc.contentLength} chars)` : 'No'}`);
          });
          
          if (am1Docs.length > 0) {
            console.log('\n✅ SUCCESS! The AI Coach should now respond to "AM1" queries!');
            console.log('\nThese documents will be returned when users ask:');
            console.log('• "What is AM1?"');
            console.log('• "Explain AM1"');
            console.log('• "Tell me about AM1"');
          } else {
            console.log('\n❌ No documents have the "am1" keyword yet.');
          }
          
          resolve();
        }
      });
    });
  });
}

testAM1Search().catch(console.error);