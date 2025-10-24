#!/usr/bin/env node

/**
 * Test Phase 2 Knowledge Base Articles
 *
 * Tests search functionality for newly deployed Phase 2 articles:
 * 1. Equipment Selection & Safety Guide
 * 2. Troubleshooting Common Problems
 * 3. Routine Planning & Customization
 * 4. Plateau Breaking Strategies
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/test-phase2-knowledge.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

/**
 * Search knowledge base (same logic as AI Coach)
 */
async function searchKnowledgeBase(query) {
  const searchQuery = query.toLowerCase();
  const searchTerms = searchQuery.split(/\s+/).filter(term => term.length > 0);

  // Expand common terms
  const expandedTerms = [];
  searchTerms.forEach(term => {
    expandedTerms.push(term);

    // Add equipment variations
    if (term === 'pump' || term === 'pumping') {
      expandedTerms.push('pump', 'pumping', 'vacuum', 'device');
    }
    if (term === 'routine') {
      expandedTerms.push('routine', 'schedule', 'plan', 'program');
    }
    if (term === 'stuck' || term === 'plateau') {
      expandedTerms.push('plateau', 'stuck', 'gains', 'stopped');
    }
  });

  const uniqueTerms = [...new Set(expandedTerms)].slice(0, 10);

  const knowledgeRef = db.collection('ai_coach_knowledge');
  const results = [];
  const processedIds = new Set();

  if (uniqueTerms.length > 0) {
    const snapshot = await knowledgeRef
      .where('keywords', 'array-contains-any', uniqueTerms)
      .limit(10)
      .get();

    snapshot.forEach(doc => {
      const data = doc.data();
      if (!processedIds.has(doc.id)) {
        processedIds.add(doc.id);

        let relevanceScore = 0;
        searchTerms.forEach(term => {
          if (data.title && data.title.toLowerCase().includes(term)) relevanceScore += 3;
          if (data.keywords && data.keywords.some(k => k.includes(term))) relevanceScore += 2;
          if (data.content && data.content.toLowerCase().includes(term)) relevanceScore += 1;
        });

        const priority = data.priority || 5;
        if (priority >= 9) relevanceScore += 5;
        else if (priority >= 7) relevanceScore += 2;

        results.push({
          id: doc.id,
          title: data.title,
          category: data.category || 'unknown',
          priority: priority,
          keywords: data.keywords || [],
          contentLength: data.content ? data.content.length : 0,
          relevanceScore: relevanceScore
        });
      }
    });
  }

  results.sort((a, b) => {
    if (a.priority >= 9 && b.priority < 9) return -1;
    if (b.priority >= 9 && a.priority < 9) return 1;
    if (a.relevanceScore !== b.relevanceScore) {
      return b.relevanceScore - a.relevanceScore;
    }
    return b.priority - a.priority;
  });

  return results.slice(0, 5);
}

/**
 * Test Phase 2 queries
 */
async function testPhase2Queries() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Test Phase 2 Knowledge Base Articles                     ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}\n`);

  const testQueries = [
    {
      query: 'What pump should I buy?',
      expectedArticle: 'equipment_selection_safety_guide',
      expectedKeywords: ['pump', 'equipment', 'bathmate', 'safety']
    },
    {
      query: 'I have no gains',
      expectedArticle: 'troubleshooting_common_problems',
      expectedKeywords: ['no gains', 'plateau', 'troubleshoot', 'problem']
    },
    {
      query: 'How do I build a routine?',
      expectedArticle: 'routine_planning_customization',
      expectedKeywords: ['routine', 'planning', 'schedule', 'beginner']
    },
    {
      query: 'I hit a plateau',
      expectedArticle: 'plateau_breaking_strategies',
      expectedKeywords: ['plateau', 'stuck', 'breakthrough', 'decon']
    },
    {
      query: 'Equipment safety tips',
      expectedArticle: 'equipment_selection_safety_guide',
      expectedKeywords: ['equipment', 'safety', 'gauge', 'pressure']
    },
    {
      query: 'My EQ is declining',
      expectedArticle: 'troubleshooting_common_problems',
      expectedKeywords: ['eq', 'problem', 'overtraining', 'recovery']
    },
    {
      query: 'Beginner routine length and girth',
      expectedArticle: 'routine_planning_customization',
      expectedKeywords: ['beginner', 'routine', 'length', 'girth']
    },
    {
      query: 'Not seeing progress',
      expectedArticle: 'plateau_breaking_strategies',
      expectedKeywords: ['plateau', 'gains', 'progress', 'stuck']
    }
  ];

  const results = {};
  let totalTests = testQueries.length;
  let passedTests = 0;

  for (const test of testQueries) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📝 Query: "${test.query}"`);
    console.log(`🎯 Expected: ${test.expectedArticle}\n`);

    const searchResults = await searchKnowledgeBase(test.query);
    results[test.query] = searchResults;

    if (searchResults.length === 0) {
      console.log('❌ No results found!\n');
      continue;
    }

    const foundExpected = searchResults.some(r => r.id === test.expectedArticle);
    const expectedRank = searchResults.findIndex(r => r.id === test.expectedArticle) + 1;

    console.log(`📚 Top ${searchResults.length} Results:\n`);
    searchResults.forEach((result, index) => {
      const isExpected = result.id === test.expectedArticle;
      const marker = isExpected ? '🎯' : '  ';
      console.log(`${marker} ${index + 1}. ${result.title}`);
      console.log(`     Category: ${result.category} | Priority: ${result.priority}/10 | Score: ${result.relevanceScore}`);
      console.log(`     Content: ${result.contentLength.toLocaleString()} chars\n`);
    });

    if (foundExpected && expectedRank <= 3) {
      console.log(`✅ PASS: Found expected article at rank #${expectedRank}\n`);
      passedTests++;
    } else if (foundExpected) {
      console.log(`⚠️ PARTIAL: Found expected article but at rank #${expectedRank} (expected top 3)\n`);
    } else {
      console.log(`❌ FAIL: Expected article not found in top 5\n`);
    }
  }

  return { totalTests, passedTests, results };
}

/**
 * Generate report
 */
function generateReport(summary) {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║  Phase 2 Knowledge Base Test Report                       ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  const successRate = (summary.passedTests / summary.totalTests) * 100;

  console.log('📊 OVERALL RESULTS:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Total Queries Tested:     ${summary.totalTests}`);
  console.log(`Successful Matches:       ${summary.passedTests} / ${summary.totalTests} (${successRate.toFixed(1)}%)`);
  console.log('');

  console.log('🎯 SUCCESS CRITERIA:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  const criteria = [
    {
      name: 'All queries find relevant articles',
      passed: successRate >= 80,
      actual: `${successRate.toFixed(1)}%`,
      target: '≥80%'
    }
  ];

  criteria.forEach(criterion => {
    const status = criterion.passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${status}: ${criterion.name}`);
    console.log(`   Actual: ${criterion.actual} | Target: ${criterion.target}`);
  });
  console.log('');

  if (successRate >= 80) {
    console.log('🎉 OVERALL VERDICT: SUCCESS');
    console.log('Phase 2 articles are successfully indexed and searchable.');
    console.log('AI Coach can now answer equipment, troubleshooting, routine, and plateau questions!\n');
  } else {
    console.log('⚠️  OVERALL VERDICT: NEEDS IMPROVEMENT');
    console.log('Some Phase 2 queries are not finding expected articles.\n');
  }

  return { success: successRate >= 80 };
}

/**
 * Main execution
 */
async function main() {
  try {
    const summary = await testPhase2Queries();
    const report = generateReport(summary);

    if (report.success) {
      console.log('✅ Phase 2 knowledge base test PASSED\n');
      process.exit(0);
    } else {
      console.log('⚠️  Phase 2 knowledge base test FAILED\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Test failed:', error);
    process.exit(1);
  }
}

main();
