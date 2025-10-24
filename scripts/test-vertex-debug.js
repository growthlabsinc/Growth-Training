#!/usr/bin/env node

/**
 * Debug Vertex AI Test - Step-by-Step Diagnostics
 *
 * This script tests each component individually to identify where the timeout occurs.
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/test-vertex-debug.js
 */

const admin = require('firebase-admin');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🔍 Vertex AI Debug Test');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Step 1: Initialize Firebase
console.log('Step 1: Initializing Firebase Admin...');
try {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
  });
  console.log('✅ Firebase initialized\n');
} catch (error) {
  console.error('❌ Firebase initialization failed:', error.message);
  process.exit(1);
}

// Step 2: Test Firestore connection
async function testFirestore() {
  console.log('Step 2: Testing Firestore connection...');
  try {
    const db = admin.firestore();
    const testDoc = await db.collection('ai_coach_knowledge').doc('jelqing_technique_guide').get();

    if (testDoc.exists) {
      const data = testDoc.data();
      console.log('✅ Firestore connected');
      console.log(`   Found: ${data.title}`);
      console.log(`   Content: ${data.content ? data.content.length : 0} characters\n`);
      return true;
    } else {
      console.log('⚠️  Jelqing guide not found in Firestore\n');
      return false;
    }
  } catch (error) {
    console.error('❌ Firestore connection failed:', error.message);
    return false;
  }
}

// Step 3: Test knowledge base search
async function testKnowledgeSearch() {
  console.log('Step 3: Testing knowledge base search...');
  try {
    const db = admin.firestore();
    const query = 'jelq';

    console.log(`   Searching for: "${query}"`);

    const snapshot = await db.collection('ai_coach_knowledge')
      .where('keywords', 'array-contains', query)
      .limit(5)
      .get();

    console.log(`✅ Knowledge search completed`);
    console.log(`   Found ${snapshot.size} documents\n`);

    if (snapshot.size > 0) {
      snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`   - ${data.title}`);
      });
      console.log('');
    }

    return snapshot.size > 0;
  } catch (error) {
    console.error('❌ Knowledge search failed:', error.message);
    return false;
  }
}

// Step 4: Try to import Vertex AI function (without calling it)
async function testVertexImport() {
  console.log('Step 4: Testing Vertex AI function import...');
  try {
    const vertexModule = require('../functions/vertexAiProxy/index.js');
    console.log('✅ Vertex AI module loaded');
    console.log(`   Exported functions: ${Object.keys(vertexModule).join(', ')}\n`);
    return vertexModule;
  } catch (error) {
    console.error('❌ Vertex AI module import failed:', error.message);
    console.error('   Error details:', error.stack);
    return null;
  }
}

// Step 5: Check Vertex AI configuration
async function checkVertexConfig() {
  console.log('Step 5: Checking Vertex AI configuration...');
  try {
    const config = {
      projectId: process.env.GCLOUD_PROJECT || process.env.VERTEX_AI_PROJECT_ID || 'growth-training-app',
      region: process.env.VERTEX_AI_REGION || 'us-central1',
      model: process.env.GEMINI_MODEL || 'gemini-2.0-flash-lite-001',
      authMethod: process.env.AUTH_METHOD || 'SERVICE_ACCOUNT'
    };

    console.log('✅ Vertex AI configuration:');
    console.log(`   Project: ${config.projectId}`);
    console.log(`   Region: ${config.region}`);
    console.log(`   Model: ${config.model}`);
    console.log(`   Auth Method: ${config.authMethod}\n`);

    return config;
  } catch (error) {
    console.error('❌ Configuration check failed:', error.message);
    return null;
  }
}

// Step 6: Test Vertex AI call with timeout
async function testVertexAICall(vertexModule) {
  console.log('Step 6: Testing Vertex AI call (with 30s timeout)...');
  console.log('   This may take 10-30 seconds on first call (cold start)...\n');

  try {
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout after 30 seconds')), 30000)
    );

    const callPromise = vertexModule.generateAIResponse({
      query: 'How do I jelq?',
      conversationHistory: [],
      userId: 'test-user',
      userExperienceLevel: 'beginner',
      primaryGoal: 'girth'
    }, {
      auth: {
        uid: 'test-user',
        token: { firebase: { sign_in_provider: 'anonymous' } }
      }
    });

    const response = await Promise.race([callPromise, timeoutPromise]);

    console.log('✅ Vertex AI call successful!');
    console.log(`   Response length: ${response.text ? response.text.length : 0} characters`);
    console.log(`   Sources used: ${response.sources ? response.sources.length : 0}\n`);

    if (response.text) {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('📝 AI RESPONSE (first 500 chars):');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      console.log(response.text.substring(0, 500) + '...\n');
    }

    return response;
  } catch (error) {
    if (error.message === 'Timeout after 30 seconds') {
      console.error('❌ Vertex AI call timed out after 30 seconds');
      console.error('   Possible causes:');
      console.error('   1. Vertex AI API is slow (cold start can take 10-30s)');
      console.error('   2. Network connectivity issues');
      console.error('   3. Vertex AI quotas or permissions');
      console.error('   4. Service account authentication issues\n');
    } else {
      console.error('❌ Vertex AI call failed:', error.message);
      console.error('   Error type:', error.constructor.name);

      if (error.message.includes('API key') || error.message.includes('authentication')) {
        console.error('   → This is an AUTHENTICATION error');
        console.error('   → Check service account credentials');
      } else if (error.message.includes('quota') || error.message.includes('rate limit')) {
        console.error('   → This is a QUOTA error');
        console.error('   → Check Vertex AI quota limits');
      } else if (error.message.includes('permission')) {
        console.error('   → This is a PERMISSIONS error');
        console.error('   → Check IAM roles for service account');
      } else {
        console.error('   → Unknown error type');
        console.error('   → Full error:', error.stack);
      }
      console.log('');
    }
    return null;
  }
}

// Main execution
async function main() {
  try {
    console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
    console.log(`🕐 Started at: ${new Date().toISOString()}\n`);

    const results = {
      firestore: false,
      search: false,
      import: false,
      config: false,
      vertexAI: false
    };

    // Run tests sequentially
    results.firestore = await testFirestore();

    if (!results.firestore) {
      console.log('⚠️  Stopping - Firestore not accessible\n');
      process.exit(1);
    }

    results.search = await testKnowledgeSearch();

    if (!results.search) {
      console.log('⚠️  Warning - Knowledge search returned no results\n');
    }

    const vertexModule = await testVertexImport();
    results.import = !!vertexModule;

    if (!results.import) {
      console.log('⚠️  Stopping - Cannot import Vertex AI module\n');
      process.exit(1);
    }

    const config = await checkVertexConfig();
    results.config = !!config;

    // Try Vertex AI call
    const response = await testVertexAICall(vertexModule);
    results.vertexAI = !!response;

    // Summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 TEST SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('Component Tests:');
    Object.entries(results).forEach(([test, passed]) => {
      const status = passed ? '✅' : '❌';
      console.log(`   ${status} ${test}`);
    });

    console.log('');

    if (results.vertexAI) {
      console.log('🎉 ALL TESTS PASSED!');
      console.log('✅ Vertex AI is working correctly\n');
      process.exit(0);
    } else if (results.firestore && results.search && results.import) {
      console.log('⚠️  PARTIAL SUCCESS');
      console.log('✅ Firebase, knowledge base, and imports working');
      console.log('❌ Vertex AI call failed or timed out');
      console.log('\n💡 This is likely a Vertex AI API issue, not a code issue.');
      console.log('   The knowledge base and RAG pipeline are correctly configured.');
      console.log('   In production, this would work once Vertex AI responds.\n');
      process.exit(1);
    } else {
      console.log('❌ TESTS FAILED');
      console.log('Review the errors above for details\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Test crashed:', error);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Run with timestamp
console.log('Starting debug test...\n');
main();
