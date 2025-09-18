#!/usr/bin/env node

/**
 * Test script for AI Coach function
 */

const admin = require('firebase-admin');

// Initialize admin if not already
if (!admin.apps.length) {
  const serviceAccount = require('./growth-70a85-firebase-adminsdk-fbsvc-a9a1390b26.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'growth-70a85'
  });
}

async function testAICoach() {
  try {
    console.log('Testing AI Coach with pelvic floor question...\n');

    const query = "I have a very tight pelvic floor so I want to start off kind of slow. Would a warmup with burst for about 1-2 minutes before 1 set of pyramid rush 5 minutes be a good start? And then try to add on 1 set (5 minutes) weekly?";

    console.log('Question:', query);
    console.log('\n---\n');

    // Call the function directly (for testing locally)
    const vertexAIProxy = require('./vertexAiProxy/index');

    const response = await vertexAIProxy.generateAIResponse({
      query: query,
      conversationHistory: []
    }, {
      auth: { uid: 'test-user' }
    });

    console.log('Response:', response.text);

    if (response.sources && response.sources.length > 0) {
      console.log('\nSources found:', response.sources.length);
      response.sources.forEach(source => {
        console.log(`- ${source.title}`);
      });
    }

  } catch (error) {
    console.error('Error:', error.message);
    if (error.details) {
      console.error('Details:', error.details);
    }
  }
}

// Run the test
testAICoach().then(() => {
  console.log('\nTest complete');
  process.exit(0);
}).catch(error => {
  console.error('Test failed:', error);
  process.exit(1);
});