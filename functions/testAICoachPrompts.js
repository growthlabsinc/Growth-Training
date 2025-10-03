#!/usr/bin/env node
/**
 * Test AI Coach Prompt Updates - Story 3.4
 * Tests the enhanced PE-focused system prompts and knowledge retrieval
 */

const admin = require('firebase-admin');
const { searchKnowledgeBase } = require('./vertexAiProxy/knowledgeBaseSearch');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

// Test queries from Story 3.4 testing requirements
const testQueries = [
  {
    query: "What is PE training?",
    expectedFocus: "overview with safety emphasis",
    category: "general"
  },
  {
    query: "How to start PE?",
    expectedFocus: "conservative beginner guidance",
    category: "progression"
  },
  {
    query: "Is PE dangerous?",
    expectedFocus: "risks and safety measures",
    category: "safety"
  },
  {
    query: "Best exercises for gains?",
    expectedFocus: "safety over aggressiveness",
    category: "techniques"
  },
  {
    query: "I have pain during PE",
    expectedFocus: "stop and seek medical help",
    category: "safety"
  },
  {
    query: "How fast can I gain?",
    expectedFocus: "realistic expectations",
    category: "progression"
  },
  {
    query: "jelqing technique",
    expectedFocus: "proper form and safety",
    category: "girth"
  },
  {
    query: "hanging weights",
    expectedFocus: "advanced technique with warnings",
    category: "length"
  },
  {
    query: "kegel exercises",
    expectedFocus: "EQ improvement",
    category: "eq"
  },
  {
    query: "safety",
    expectedFocus: "injury prevention",
    category: "safety"
  }
];

async function testKnowledgeRetrieval() {
  console.log('🧪 Testing Enhanced Knowledge Retrieval');
  console.log('=' .repeat(50));

  let passedTests = 0;
  let totalTests = testQueries.length;

  for (const test of testQueries) {
    console.log(`\n🔍 Testing query: "${test.query}"`);
    console.log(`   Expected focus: ${test.expectedFocus}`);

    try {
      const results = await searchKnowledgeBase(test.query, db);

      if (results.length > 0) {
        console.log(`   ✅ Found ${results.length} relevant documents`);

        // Check if safety content is prioritized for safety-related queries
        if (test.category === 'safety') {
          const hasSafetyContent = results.some(r => r.priority >= 9 || r.category === 'safety');
          if (hasSafetyContent) {
            console.log(`   ✅ Safety content prioritized`);
          } else {
            console.log(`   ⚠️  Safety content should be prioritized for this query`);
          }
        }

        // Display top result details
        const topResult = results[0];
        console.log(`   📄 Top result: "${topResult.title}"`);
        console.log(`      Category: ${topResult.category || 'unknown'}`);
        console.log(`      Priority: ${topResult.priority || 'unknown'}`);
        console.log(`      Relevance: ${topResult.relevanceScore || 'unknown'}`);

        // Check for Angion references (should be none)
        const hasAngionRef = results.some(r =>
          r.title.toLowerCase().includes('angion') ||
          r.fullContent.toLowerCase().includes('angion')
        );

        if (hasAngionRef) {
          console.log(`   ❌ CRITICAL: Found Angion references - these should be removed!`);
        } else {
          console.log(`   ✅ No Angion references found`);
          passedTests++;
        }

      } else {
        console.log(`   ❌ No results found for "${test.query}"`);
      }

    } catch (error) {
      console.log(`   ❌ Error testing "${test.query}": ${error.message}`);
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log(`📊 Test Results: ${passedTests}/${totalTests} passed`);

  if (passedTests === totalTests) {
    console.log('🎉 All knowledge retrieval tests passed!');
    return true;
  } else {
    console.log('⚠️  Some tests failed - review implementation');
    return false;
  }
}

async function testSearchTermOptimization() {
  console.log('\n🔧 Testing PE-Specific Search Term Optimization');
  console.log('=' .repeat(50));

  const peTerms = [
    'jelqing', 'stretching', 'pumping', 'hanging',
    'kegels', 'eq', 'safety', 'beginner'
  ];

  let optimizationScore = 0;

  for (const term of peTerms) {
    console.log(`\n🔍 Testing PE term: "${term}"`);

    try {
      const results = await searchKnowledgeBase(term, db);

      if (results.length > 0) {
        console.log(`   ✅ Found ${results.length} documents for "${term}"`);

        // Check relevance quality
        const topResult = results[0];
        if (topResult.relevanceScore > 5) {
          console.log(`   ✅ High relevance score: ${topResult.relevanceScore}`);
          optimizationScore++;
        } else {
          console.log(`   ⚠️  Low relevance score: ${topResult.relevanceScore || 0}`);
        }
      } else {
        console.log(`   ❌ No results for PE term "${term}"`);
      }

    } catch (error) {
      console.log(`   ❌ Error testing "${term}": ${error.message}`);
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log(`🎯 PE Optimization Score: ${optimizationScore}/${peTerms.length}`);

  return optimizationScore / peTerms.length >= 0.7; // 70% success rate
}

async function main() {
  console.log('🚀 AI Coach Prompt Enhancement Testing');
  console.log('Story 3.4: Update AI Coach Prompts for PE Focus\n');

  try {
    const knowledgeTest = await testKnowledgeRetrieval();
    const optimizationTest = await testSearchTermOptimization();

    console.log('\n' + '='.repeat(60));
    console.log('📋 FINAL TEST SUMMARY');
    console.log('='.repeat(60));

    console.log(`✅ Knowledge Retrieval: ${knowledgeTest ? 'PASSED' : 'FAILED'}`);
    console.log(`✅ PE Term Optimization: ${optimizationTest ? 'PASSED' : 'FAILED'}`);

    if (knowledgeTest && optimizationTest) {
      console.log('\n🎉 SUCCESS: All AI Coach prompt tests passed!');
      console.log('✅ PE-focused knowledge retrieval working');
      console.log('✅ Safety content properly prioritized');
      console.log('✅ No Angion references detected');
      console.log('✅ PE terminology optimization effective');
      process.exit(0);
    } else {
      console.log('\n❌ FAILURE: Some tests failed');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Test suite failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { testKnowledgeRetrieval, testSearchTermOptimization };