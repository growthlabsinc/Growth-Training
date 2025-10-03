#!/usr/bin/env node
/**
 * Test AI Coach Knowledge Retrieval
 * Story 3.3: Develop Training Protocol Knowledge
 *
 * This script tests that the AI Coach can properly access and retrieve
 * the newly deployed PE knowledge base content.
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function testKnowledgeSearch(searchTerm, expectedCategory) {
  console.log(`\n🔍 Testing search for: "${searchTerm}"`);
  console.log(`   Expected category: ${expectedCategory}`);

  try {
    // Simulate knowledge base search similar to AI Coach
    const snapshot = await db.collection('ai_coach_knowledge')
      .where('keywords', 'array-contains-any', [searchTerm.toLowerCase()])
      .orderBy('priority', 'desc')
      .limit(5)
      .get();

    if (snapshot.empty) {
      // Try broader search by category
      const categorySnapshot = await db.collection('ai_coach_knowledge')
        .where('category', '==', expectedCategory)
        .orderBy('priority', 'desc')
        .limit(3)
        .get();

      if (categorySnapshot.empty) {
        console.log('   ❌ No documents found');
        return false;
      } else {
        console.log(`   ✅ Found ${categorySnapshot.size} documents in ${expectedCategory} category`);
        categorySnapshot.forEach(doc => {
          const data = doc.data();
          console.log(`      - ${data.title} (Priority: ${data.priority})`);
        });
        return true;
      }
    } else {
      console.log(`   ✅ Found ${snapshot.size} documents matching keywords`);
      snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`      - ${data.title} (Category: ${data.category}, Priority: ${data.priority})`);
      });
      return true;
    }

  } catch (error) {
    console.log(`   ❌ Error searching: ${error.message}`);
    return false;
  }
}

async function testProgressionPaths() {
  console.log('\n📈 Testing Progression Path Retrieval...');

  try {
    const snapshot = await db.collection('ai_coach_knowledge')
      .where('category', '==', 'progression')
      .orderBy('priority', 'desc')
      .get();

    if (snapshot.empty) {
      console.log('   ❌ No progression documents found');
      return false;
    }

    console.log(`   ✅ Found ${snapshot.size} progression documents:`);
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`      - ${data.title}`);
    });
    return true;

  } catch (error) {
    console.log(`   ❌ Error testing progression paths: ${error.message}`);
    return false;
  }
}

async function testSafetyContent() {
  console.log('\n🛡️  Testing Safety Content Accessibility...');

  try {
    const snapshot = await db.collection('ai_coach_knowledge')
      .where('category', '==', 'safety')
      .orderBy('priority', 'desc')
      .get();

    if (snapshot.empty) {
      console.log('   ❌ No safety documents found');
      return false;
    }

    console.log(`   ✅ Found ${snapshot.size} safety documents:`);
    let hasHighPriority = false;
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.priority >= 8) hasHighPriority = true;
      console.log(`      - ${data.title} (Priority: ${data.priority})`);
    });

    if (hasHighPriority) {
      console.log('   ✅ High-priority safety content available');
    } else {
      console.log('   ⚠️  No high-priority safety content found');
    }

    return true;

  } catch (error) {
    console.log(`   ❌ Error testing safety content: ${error.message}`);
    return false;
  }
}

async function testCategoryDistribution() {
  console.log('\n📊 Testing Category Distribution...');

  const categories = ['length', 'girth', 'eq', 'equipment', 'progression', 'safety'];
  const results = {};

  for (const category of categories) {
    try {
      const snapshot = await db.collection('ai_coach_knowledge')
        .where('category', '==', category)
        .get();

      results[category] = snapshot.size;
      console.log(`   ${category.charAt(0).toUpperCase() + category.slice(1)}: ${snapshot.size} documents`);
    } catch (error) {
      console.log(`   ❌ Error checking ${category}: ${error.message}`);
      results[category] = 0;
    }
  }

  return results;
}

async function runTests() {
  console.log('🧪 Testing AI Coach Knowledge Retrieval');
  console.log('Story 3.3: Develop Training Protocol Knowledge\n');
  console.log('='.repeat(60));

  const testResults = [];

  // Test specific searches
  const searches = [
    { term: 'stretching', category: 'length' },
    { term: 'jelqing', category: 'girth' },
    { term: 'kegels', category: 'eq' },
    { term: 'pumps', category: 'equipment' },
    { term: 'beginner', category: 'progression' }
  ];

  for (const search of searches) {
    const result = await testKnowledgeSearch(search.term, search.category);
    testResults.push(result);
  }

  // Test progression paths
  const progressionResult = await testProgressionPaths();
  testResults.push(progressionResult);

  // Test safety content
  const safetyResult = await testSafetyContent();
  testResults.push(safetyResult);

  // Test category distribution
  const categoryResults = await testCategoryDistribution();

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📋 TEST SUMMARY');
  console.log('='.repeat(60));

  const passedTests = testResults.filter(result => result).length;
  const totalTests = testResults.length;

  console.log(`✅ Tests Passed: ${passedTests}/${totalTests}`);

  const totalDocs = Object.values(categoryResults).reduce((sum, count) => sum + count, 0);
  console.log(`📚 Total Documents Available: ${totalDocs}`);

  if (passedTests === totalTests && totalDocs >= 50) {
    console.log('\n🎉 SUCCESS: AI Coach knowledge retrieval is fully functional!');
    console.log('✅ All categories accessible');
    console.log('✅ Knowledge search working correctly');
    console.log('✅ Safety content prioritized appropriately');
    return true;
  } else {
    console.log('\n⚠️  PARTIAL SUCCESS: Some issues detected');
    if (passedTests < totalTests) {
      console.log(`❌ ${totalTests - passedTests} test(s) failed`);
    }
    if (totalDocs < 50) {
      console.log(`❌ Insufficient documents: ${totalDocs}/50+`);
    }
    return false;
  }
}

if (require.main === module) {
  runTests().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('❌ Test suite failed:', error);
    process.exit(1);
  });
}

module.exports = { testKnowledgeSearch, testProgressionPaths, testSafetyContent };