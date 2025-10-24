#!/usr/bin/env node

/**
 * Test Vertex AI Direct - "How do I jelq?" Query
 *
 * This test directly calls the Vertex AI proxy function to verify:
 * 1. Knowledge base search is working
 * 2. Vertex AI is generating responses (not just keyword search)
 * 3. The response includes content from our deployed jelqing guide
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/test-vertex-ai-jelq.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

// Import the AI Coach function
const { generateAIResponse } = require('../functions/vertexAiProxy/index.js');

/**
 * Test the AI Coach with jelqing query
 */
async function testJelqingQuery() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Test Vertex AI Integration - "How do I jelq?"            ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
  console.log(`🤖 Function: vertexAiProxy.generateAIResponse`);
  console.log(`🎯 Testing: Full RAG pipeline (Search + Vertex AI)\n`);

  const query = 'How do I jelq?';

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📝 Query: "${query}"`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    console.log('⏳ Calling AI Coach function...\n');

    const startTime = Date.now();

    // Call the function with simulated auth context
    const response = await generateAIResponse({
      query: query,
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

    const duration = Date.now() - startTime;

    console.log(`✅ Response received in ${duration}ms\n`);

    // Analyze the response
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 RESPONSE ANALYSIS');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Check if sources were used (RAG)
    const usedKnowledge = response.sources && response.sources.length > 0;
    console.log(`📚 Knowledge Base Used: ${usedKnowledge ? '✅ YES' : '❌ NO'}`);

    if (usedKnowledge) {
      console.log(`📑 Sources Retrieved: ${response.sources.length}`);
      console.log('\n🔍 Sources Used:');
      response.sources.forEach((source, index) => {
        console.log(`   ${index + 1}. ${source.title}`);
        console.log(`      Category: ${source.category || 'N/A'}`);
        console.log(`      Priority: ${source.priority || 'N/A'}/10`);
      });

      // Check if jelqing guide was used
      const jelqGuideUsed = response.sources.some(s =>
        s.id === 'jelqing_technique_guide' ||
        (s.title && s.title.toLowerCase().includes('jelq'))
      );
      console.log(`\n🎯 Jelqing Guide Used: ${jelqGuideUsed ? '✅ YES' : '❌ NO'}`);
    }

    // Analyze response text
    const responseText = response.text || '';
    console.log(`\n📝 Response Length: ${responseText.length} characters`);

    // Check for key jelqing content
    const keyContent = {
      'erection level': responseText.toLowerCase().includes('40') && responseText.toLowerCase().includes('70'),
      'technique/setup': responseText.toLowerCase().includes('warm') || responseText.toLowerCase().includes('setup'),
      'safety': responseText.toLowerCase().includes('safety') || responseText.toLowerCase().includes('injury'),
      'grip': responseText.toLowerCase().includes('ok') && responseText.toLowerCase().includes('grip'),
      'stroke': responseText.toLowerCase().includes('stroke') || responseText.toLowerCase().includes('base'),
      'disclaimer': responseText.toLowerCase().includes('disclaimer') || responseText.toLowerCase().includes('consult')
    };

    console.log('\n✅ Key Content Checks:');
    Object.entries(keyContent).forEach(([key, present]) => {
      const status = present ? '✅' : '❌';
      console.log(`   ${status} ${key}: ${present ? 'Present' : 'Missing'}`);
    });

    const contentScore = Object.values(keyContent).filter(v => v).length;
    const contentPercentage = (contentScore / Object.keys(keyContent).length) * 100;
    console.log(`\n📊 Content Quality Score: ${contentScore}/${Object.keys(keyContent).length} (${contentPercentage.toFixed(0)}%)`);

    // Display the actual response
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('💬 ACTUAL AI RESPONSE');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log(responseText);
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Verification summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎯 VERIFICATION SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const checks = {
      'Knowledge Base Search': usedKnowledge,
      'Jelqing Guide Found': usedKnowledge && response.sources.some(s =>
        s.id === 'jelqing_technique_guide' ||
        (s.title && s.title.toLowerCase().includes('jelq'))
      ),
      'AI Generated Response': responseText.length > 100,
      'Content Quality': contentPercentage >= 60,
      'Response Time': duration < 30000 // 30 seconds
    };

    console.log('Verification Checks:');
    Object.entries(checks).forEach(([check, passed]) => {
      const status = passed ? '✅ PASS' : '❌ FAIL';
      console.log(`   ${status} ${check}`);
    });

    const allPassed = Object.values(checks).every(v => v);

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (allPassed) {
      console.log('🎉 SUCCESS: Vertex AI + RAG working correctly!');
      console.log('✅ AI Coach is using Vertex AI to generate responses');
      console.log('✅ Knowledge base is being searched and used');
      console.log('✅ Jelqing guide content is incorporated');
    } else {
      console.log('⚠️  PARTIAL SUCCESS: Some checks failed');
      console.log('Review the failed checks above for details');
    }
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return {
      success: allPassed,
      duration,
      responseLength: responseText.length,
      sourcesUsed: usedKnowledge ? response.sources.length : 0,
      contentScore: contentPercentage,
      response: response
    };

  } catch (error) {
    console.error('❌ ERROR:', error.message);
    console.error('\nFull error:', error);

    if (error.message.includes('API key')) {
      console.log('\n💡 TIP: This may be an authentication issue.');
      console.log('   Vertex AI requires service account credentials.');
    } else if (error.message.includes('quota')) {
      console.log('\n💡 TIP: This may be a quota or billing issue.');
      console.log('   Check that Vertex AI is enabled and billing is active.');
    } else if (error.message.includes('timeout')) {
      console.log('\n💡 TIP: Vertex AI may be slow to respond.');
      console.log('   This is normal for first requests (cold start).');
    }

    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    const result = await testJelqingQuery();

    if (result.success) {
      console.log('✅ Test PASSED - AI Coach verified working with Vertex AI\n');
      process.exit(0);
    } else if (result.error) {
      console.log('❌ Test FAILED - Error occurred\n');
      process.exit(1);
    } else {
      console.log('⚠️  Test PARTIAL - Some checks failed\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Test crashed:', error);
    process.exit(1);
  }
}

// Run the test
main();
