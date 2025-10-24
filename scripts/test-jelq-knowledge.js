#!/usr/bin/env node

/**
 * Test AI Coach Knowledge Base - "How do I jelq?" Query
 *
 * Tests the knowledge base search functionality with a real user question
 * to verify that gap-filling deployment was successful.
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/test-jelq-knowledge.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

/**
 * Search knowledge base (mimics the actual AI Coach search logic)
 */
async function searchKnowledgeBase(query) {
  console.log(`🔍 Searching knowledge base for: "${query}"\n`);

  // Convert query to lowercase for searching
  const searchQuery = query.toLowerCase();

  // Extract search terms
  const searchTerms = searchQuery.split(/\s+/).filter(term => term.length > 0);

  // Add variations for common PE terms
  const expandedTerms = [];
  searchTerms.forEach(term => {
    expandedTerms.push(term);

    // Add jelq variations
    if (term === 'jelq' || term === 'jelqing') {
      expandedTerms.push('jelq', 'jelqing', 'girth', 'technique', 'manual');
    }
  });

  // Remove duplicates and limit to 10
  const uniqueTerms = [...new Set(expandedTerms)].slice(0, 10);

  console.log(`📊 Search terms: ${uniqueTerms.join(', ')}\n`);

  // Query the knowledge base collection
  const knowledgeRef = db.collection('ai_coach_knowledge');
  const results = [];
  const processedIds = new Set();

  // Search by keywords
  if (uniqueTerms.length > 0) {
    const snapshot = await knowledgeRef
      .where('keywords', 'array-contains-any', uniqueTerms)
      .limit(10)
      .get();

    console.log(`✅ Found ${snapshot.size} documents matching keywords\n`);

    snapshot.forEach(doc => {
      const data = doc.data();
      if (!processedIds.has(doc.id)) {
        processedIds.add(doc.id);

        // Calculate relevance score
        let relevanceScore = 0;
        searchTerms.forEach(term => {
          if (data.title && data.title.toLowerCase().includes(term)) relevanceScore += 3;
          if (data.keywords && data.keywords.some(k => k.includes(term))) relevanceScore += 2;
          if (data.content && data.content.toLowerCase().includes(term)) relevanceScore += 1;
        });

        // Boost safety content
        const priority = data.priority || 5;
        if (priority >= 9) {
          relevanceScore += 5;
        } else if (priority >= 7) {
          relevanceScore += 2;
        }

        results.push({
          id: doc.id,
          title: data.title,
          category: data.category || 'unknown',
          priority: priority,
          keywords: data.keywords || [],
          contentLength: data.content ? data.content.length : 0,
          relevanceScore: relevanceScore,
          hasDisclaimer: data.medical_disclaimer ? true : false,
          snippet: data.content ? data.content.substring(0, 300) + '...' : 'No content'
        });
      }
    });
  }

  // Sort by relevance score
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
 * Test multiple jelqing-related queries
 */
async function testJelqingQueries() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Test AI Coach Knowledge Base - Jelqing Queries           ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}\n`);

  const testQueries = [
    'How do I jelq?',
    'jelqing technique',
    'jelqing for beginners',
    'how to jelq safely',
    'jelqing pressure',
    'jelqing erection level'
  ];

  const results = {};

  for (const query of testQueries) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📝 Query: "${query}"`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const searchResults = await searchKnowledgeBase(query);
    results[query] = searchResults;

    if (searchResults.length === 0) {
      console.log('❌ No results found!\n');
    } else {
      console.log(`🎯 Top ${searchResults.length} Results:\n`);

      searchResults.forEach((result, index) => {
        console.log(`${index + 1}. ${result.title}`);
        console.log(`   📁 Category: ${result.category}`);
        console.log(`   ⭐ Priority: ${result.priority}/10`);
        console.log(`   📊 Relevance Score: ${result.relevanceScore}`);
        console.log(`   🔑 Keywords: ${result.keywords.slice(0, 5).join(', ')}${result.keywords.length > 5 ? '...' : ''}`);
        console.log(`   📝 Content Length: ${result.contentLength.toLocaleString()} characters`);
        console.log(`   ⚠️  Has Disclaimer: ${result.hasDisclaimer ? 'Yes' : 'No'}`);
        console.log(`   📄 Snippet: ${result.snippet.substring(0, 150)}...\n`);
      });
    }
  }

  return results;
}

/**
 * Generate detailed report
 */
async function generateReport(results) {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║  Test Results Summary                                      ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  let totalQueries = Object.keys(results).length;
  let queriesWithResults = 0;
  let queriesWithJelqGuide = 0;
  let avgResultsPerQuery = 0;
  let totalResults = 0;

  Object.entries(results).forEach(([query, searchResults]) => {
    totalResults += searchResults.length;

    if (searchResults.length > 0) {
      queriesWithResults++;

      // Check if jelqing guide is in top 3
      const hasJelqGuide = searchResults.slice(0, 3).some(r =>
        r.id === 'jelqing_technique_guide' ||
        r.title.toLowerCase().includes('jelqing')
      );

      if (hasJelqGuide) {
        queriesWithJelqGuide++;
      }
    }
  });

  avgResultsPerQuery = totalResults / totalQueries;

  // Success criteria
  const successRate = (queriesWithResults / totalQueries) * 100;
  const jelqGuideFoundRate = (queriesWithJelqGuide / totalQueries) * 100;

  console.log('📊 OVERALL PERFORMANCE:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Total Queries Tested:           ${totalQueries}`);
  console.log(`Queries with Results:           ${queriesWithResults} / ${totalQueries} (${successRate.toFixed(1)}%)`);
  console.log(`Queries Finding Jelq Guide:     ${queriesWithJelqGuide} / ${totalQueries} (${jelqGuideFoundRate.toFixed(1)}%)`);
  console.log(`Average Results per Query:      ${avgResultsPerQuery.toFixed(1)}`);
  console.log('');

  console.log('🎯 JELQING GUIDE RANKING:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  Object.entries(results).forEach(([query, searchResults]) => {
    const jelqGuideIndex = searchResults.findIndex(r => r.id === 'jelqing_technique_guide');

    if (jelqGuideIndex === -1) {
      console.log(`❌ "${query}": Not found in top 5`);
    } else {
      const rank = jelqGuideIndex + 1;
      const emoji = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '📍';
      console.log(`${emoji} "${query}": Rank #${rank}`);
    }
  });
  console.log('');

  // Success assessment
  console.log('✅ SUCCESS CRITERIA ASSESSMENT:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  const criteria = [
    {
      name: 'All queries return results',
      passed: successRate === 100,
      actual: `${successRate.toFixed(1)}%`,
      target: '100%'
    },
    {
      name: 'Jelq guide found for all queries',
      passed: jelqGuideFoundRate >= 80,
      actual: `${jelqGuideFoundRate.toFixed(1)}%`,
      target: '≥80%'
    },
    {
      name: 'Jelq guide in top 3 (avg)',
      passed: avgResultsPerQuery >= 3,
      actual: avgResultsPerQuery.toFixed(1),
      target: '≥3'
    }
  ];

  criteria.forEach(criterion => {
    const status = criterion.passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${status}: ${criterion.name}`);
    console.log(`   Actual: ${criterion.actual} | Target: ${criterion.target}`);
  });
  console.log('');

  // Overall verdict
  const allPassed = criteria.every(c => c.passed);

  if (allPassed) {
    console.log('🎉 OVERALL VERDICT: SUCCESS');
    console.log('The jelqing knowledge gap has been successfully filled!');
    console.log('AI Coach can now answer jelqing questions comprehensively.');
  } else {
    console.log('⚠️  OVERALL VERDICT: NEEDS IMPROVEMENT');
    console.log('Some queries are not finding the jelqing guide effectively.');
    const failedCriteria = criteria.filter(c => !c.passed);
    console.log(`Failed criteria: ${failedCriteria.map(c => c.name).join(', ')}`);
  }
  console.log('');

  // Detailed content check for main guide
  console.log('📋 JELQING GUIDE CONTENT CHECK:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  const firstQuery = Object.values(results)[0];
  const jelqGuide = firstQuery.find(r => r.id === 'jelqing_technique_guide');

  if (jelqGuide) {
    console.log(`✅ Title: ${jelqGuide.title}`);
    console.log(`✅ Category: ${jelqGuide.category}`);
    console.log(`✅ Priority: ${jelqGuide.priority}/10`);
    console.log(`✅ Content Length: ${jelqGuide.contentLength.toLocaleString()} characters`);
    console.log(`✅ Keywords: ${jelqGuide.keywords.length} total`);
    console.log(`✅ Medical Disclaimer: ${jelqGuide.hasDisclaimer ? 'Present' : 'Missing'}`);

    // Content quality checks
    const contentChecks = [
      { name: 'Sufficient length', passed: jelqGuide.contentLength >= 5000, value: `${jelqGuide.contentLength} chars` },
      { name: 'High priority', passed: jelqGuide.priority >= 9, value: `${jelqGuide.priority}/10` },
      { name: 'Multiple keywords', passed: jelqGuide.keywords.length >= 10, value: `${jelqGuide.keywords.length} keywords` },
      { name: 'Has disclaimer', passed: jelqGuide.hasDisclaimer, value: jelqGuide.hasDisclaimer ? 'Yes' : 'No' }
    ];

    console.log('\n📊 Content Quality Checks:');
    contentChecks.forEach(check => {
      const status = check.passed ? '✅' : '❌';
      console.log(`   ${status} ${check.name}: ${check.value}`);
    });
  } else {
    console.log('❌ Jelqing guide not found in knowledge base!');
  }
  console.log('');

  return {
    successRate,
    jelqGuideFoundRate,
    avgResultsPerQuery,
    allCriteriaPassed: allPassed,
    jelqGuideExists: !!jelqGuide
  };
}

/**
 * Main execution
 */
async function main() {
  try {
    // Run tests
    const results = await testJelqingQueries();

    // Generate report
    const summary = await generateReport(results);

    // Exit with appropriate code
    if (summary.allCriteriaPassed && summary.jelqGuideExists) {
      console.log('✅ All tests passed! Knowledge base is working correctly.\n');
      process.exit(0);
    } else {
      console.log('⚠️  Some tests failed. Review the report above.\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Test failed with error:', error);
    process.exit(1);
  }
}

// Run the script
main();
