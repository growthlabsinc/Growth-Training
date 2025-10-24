#!/usr/bin/env node

/**
 * Test AI Coach End-to-End via HTTP - "How do I jelq?" Query
 *
 * Tests the ACTUAL AI Coach (Vertex AI + RAG) by calling the deployed function.
 * This simulates a real user asking the Growth Coach a question.
 *
 * Usage:
 *   node scripts/test-ai-coach-http.js
 */

const https = require('https');
const { GoogleAuth } = require('google-auth-library');

const FUNCTION_URL = 'https://us-central1-growth-training-app.cloudfunctions.net/generateAIResponse';

/**
 * Get Firebase ID token for authentication
 */
async function getIdToken() {
  const auth = new GoogleAuth({
    scopes: 'https://www.googleapis.com/auth/cloud-platform',
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}

/**
 * Call AI Coach function
 */
async function callAICoach(query, idToken) {
  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify({
      data: {
        query: query,
        conversationHistory: [],
        userId: 'test-user',
        userExperienceLevel: 'beginner',
        primaryGoal: 'girth'
      }
    });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': requestBody.length,
        'Authorization': `Bearer ${idToken}`
      }
    };

    const req = https.request(FUNCTION_URL, options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          console.log('Raw response:', data.substring(0, 500));
          const response = JSON.parse(data);
          resolve(response);
        } catch (error) {
          reject(new Error(`Failed to parse response: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(requestBody);
    req.end();
  });
}

/**
 * Test AI Coach with various jelqing questions
 */
async function testAICoachJelqing() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Test AI Coach (Vertex AI + RAG) - Jelqing Questions      ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log('📦 Project: growth-training-app');
  console.log('🤖 AI Model: Gemini 2.0 Flash Lite with RAG');
  console.log('📚 Knowledge Base: Firestore ai_coach_knowledge collection\n');

  const testQueries = [
    {
      query: 'How do I jelq?',
      expectedKeywords: ['jelq', 'technique', 'pressure', 'erection', 'safety'],
      expectedTopics: ['setup', 'execution', 'common mistakes', 'safety']
    },
    {
      query: 'What erection level should I use for jelqing?',
      expectedKeywords: ['40', '70', 'percent', 'erection', 'jelq'],
      expectedTopics: ['erection level', '40-70%', 'not fully erect']
    },
    {
      query: 'Is jelqing safe?',
      expectedKeywords: ['safety', 'warning', 'injury', 'careful', 'warm'],
      expectedTopics: ['safety warnings', 'injury prevention', 'warning signs']
    }
  ];

  const results = [];

  // Get authentication token
  console.log('🔐 Getting authentication token...\n');
  const idToken = await getIdToken();

  for (const test of testQueries) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`\n📝 Query: "${test.query}"\n`);

    try {
      const startTime = Date.now();

      const response = await callAICoach(test.query, idToken);

      const duration = Date.now() - startTime;

      // Extract response data
      const responseData = response.result || response.data || response;
      const responseText = (responseData.text || responseData.response || '').toLowerCase();
      const sources = responseData.sources || [];

      // Analyze response
      const foundKeywords = test.expectedKeywords.filter(kw =>
        responseText.includes(kw.toLowerCase())
      );
      const foundTopics = test.expectedTopics.filter(topic =>
        responseText.includes(topic.toLowerCase())
      );

      const keywordCoverage = (foundKeywords.length / test.expectedKeywords.length) * 100;
      const topicCoverage = (foundTopics.length / test.expectedTopics.length) * 100;

      // Check if knowledge base was used
      const usedKnowledge = sources.length > 0;
      const jelqGuideUsed = usedKnowledge && sources.some(s =>
        s.id === 'jelqing_technique_guide' || (s.title && s.title.toLowerCase().includes('jelq'))
      );

      // Display results
      console.log(`⏱️  Response Time: ${duration}ms`);
      console.log(`📚 Knowledge Sources Used: ${usedKnowledge ? sources.length : 0}`);

      if (usedKnowledge) {
        console.log(`   Sources: ${sources.map(s => s.title || s.id).join(', ')}`);
        console.log(`   🎯 Jelqing Guide Used: ${jelqGuideUsed ? '✅ Yes' : '❌ No'}`);
      }

      console.log(`\n📊 Content Analysis:`);
      console.log(`   Keywords Found: ${foundKeywords.length}/${test.expectedKeywords.length} (${keywordCoverage.toFixed(0)}%)`);
      console.log(`   Found: ${foundKeywords.join(', ')}`);
      console.log(`   Topics Covered: ${foundTopics.length}/${test.expectedTopics.length} (${topicCoverage.toFixed(0)}%)`);
      console.log(`   Covered: ${foundTopics.join(', ')}`);

      console.log(`\n💬 AI Response (first 500 chars):`);
      console.log(`   ${(responseData.text || responseData.response || 'No response text').substring(0, 500)}...\n`);

      // Success criteria
      const passed = keywordCoverage >= 60 && topicCoverage >= 50 && jelqGuideUsed;

      console.log(`\n${passed ? '✅ PASS' : '❌ FAIL'}: ${test.query}`);

      results.push({
        query: test.query,
        passed,
        keywordCoverage,
        topicCoverage,
        jelqGuideUsed,
        responseLength: (responseData.text || responseData.response || '').length,
        duration,
        usedKnowledge
      });

    } catch (error) {
      console.log(`❌ ERROR: ${error.message}\n`);
      console.error(error);

      results.push({
        query: test.query,
        passed: false,
        error: error.message
      });
    }
  }

  return results;
}

/**
 * Generate test report
 */
function generateReport(results) {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║  AI Coach Test Report                                      ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  const totalTests = results.length;
  const passedTests = results.filter(r => r.passed).length;
  const successRate = (passedTests / totalTests) * 100;

  console.log('📊 OVERALL RESULTS:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Total Tests:           ${totalTests}`);
  console.log(`Passed:                ${passedTests} / ${totalTests} (${successRate.toFixed(1)}%)`);
  console.log('');

  // Individual test results
  console.log('📋 TEST BREAKDOWN:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  results.forEach((result, index) => {
    const status = result.passed ? '✅ PASS' : '❌ FAIL';

    if (result.error) {
      console.log(`${index + 1}. ${status}: "${result.query}"`);
      console.log(`   Error: ${result.error}\n`);
    } else {
      console.log(`${index + 1}. ${status}: "${result.query}"`);
      console.log(`   Keyword Coverage:  ${result.keywordCoverage.toFixed(0)}%`);
      console.log(`   Topic Coverage:    ${result.topicCoverage.toFixed(0)}%`);
      console.log(`   Jelq Guide Used:   ${result.jelqGuideUsed ? 'Yes' : 'No'}`);
      console.log(`   Response Length:   ${result.responseLength} chars`);
      console.log(`   Response Time:     ${result.duration}ms`);
      console.log(`   Knowledge Used:    ${result.usedKnowledge ? 'Yes' : 'No'}\n`);
    }
  });

  // Performance metrics
  const validResults = results.filter(r => !r.error);
  if (validResults.length > 0) {
    const avgDuration = validResults.reduce((sum, r) => sum + r.duration, 0) / validResults.length;
    const avgResponseLength = validResults.reduce((sum, r) => sum + r.responseLength, 0) / validResults.length;
    const avgKeywordCoverage = validResults.reduce((sum, r) => sum + r.keywordCoverage, 0) / validResults.length;

    console.log('⚡ PERFORMANCE METRICS:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Average Response Time:     ${avgDuration.toFixed(0)}ms`);
    console.log(`Average Response Length:   ${avgResponseLength.toFixed(0)} chars`);
    console.log(`Average Keyword Coverage:  ${avgKeywordCoverage.toFixed(1)}%`);
    console.log('');
  }

  // Final verdict
  console.log('🎯 FINAL VERDICT:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  if (successRate === 100) {
    console.log('🎉 EXCELLENT: All tests passed!');
    console.log('The AI Coach successfully answers jelqing questions using Vertex AI with the deployed knowledge base.');
  } else if (successRate >= 66) {
    console.log('✅ GOOD: Most tests passed.');
    console.log('The AI Coach can answer jelqing questions using Vertex AI, with some areas for improvement.');
  } else {
    console.log('⚠️  NEEDS IMPROVEMENT: Many tests failed.');
    console.log('The AI Coach may not be using the jelqing knowledge base effectively with Vertex AI.');
  }
  console.log('');

  return {
    successRate,
    totalTests,
    passedTests
  };
}

/**
 * Main execution
 */
async function main() {
  try {
    console.log('⚙️  Initializing test environment...\n');

    // Run tests
    const results = await testAICoachJelqing();

    // Generate report
    const summary = generateReport(results);

    // Exit with appropriate code
    if (summary.successRate >= 66) {
      console.log('✅ Test suite PASSED\n');
      process.exit(0);
    } else {
      console.log('❌ Test suite FAILED\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Test suite crashed:', error);
    process.exit(1);
  }
}

// Run the script
main();
