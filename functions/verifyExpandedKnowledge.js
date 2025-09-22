#!/usr/bin/env node
/**
 * Verify Expanded PE Knowledge Deployment
 * Story 3.3: Develop Training Protocol Knowledge
 *
 * This script verifies that all 50+ PE knowledge documents are properly deployed
 * and meet the requirements specified in Epic 3.
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

async function analyzeKnowledgeBase() {
  console.log('📊 Fetching PE knowledge documents from Firestore...');

  try {
    const snapshot = await db.collection('ai_coach_knowledge').get();

    if (snapshot.empty) {
      console.log('❌ No documents found in ai_coach_knowledge collection');
      return { categoryCount: {}, issues: [], priorityDist: {} };
    }

    const categoryCount = {};
    const priorityDist = {};
    const issues = [];

    snapshot.forEach(doc => {
      const data = doc.data();

      // Count categories
      const category = data.category || 'unknown';
      categoryCount[category] = (categoryCount[category] || 0) + 1;

      // Count priorities
      const priority = data.priority || 5;
      priorityDist[priority] = (priorityDist[priority] || 0) + 1;

      // Validate content
      const docId = data.id || doc.id;
      const title = data.title || '';
      const content = data.content || '';
      const keywords = data.keywords || [];

      if (!title) {
        issues.push(`Document ${docId}: Missing title`);
      }

      if (content.length < 500) {
        issues.push(`Document ${docId}: Content too short (${content.length} chars)`);
      }

      if (keywords.length < 3) {
        issues.push(`Document ${docId}: Insufficient keywords (${keywords.length})`);
      }

      // Check for medical disclaimer
      if (!content.includes('Medical Disclaimer')) {
        issues.push(`Document ${docId}: Missing medical disclaimer`);
      }

      // Check for safety content in appropriate categories
      if (['length', 'girth', 'equipment'].includes(category) && !content.toLowerCase().includes('safety')) {
        issues.push(`Document ${docId}: Missing safety warnings`);
      }
    });

    return { categoryCount, issues, priorityDist };

  } catch (error) {
    console.error('❌ Error fetching documents:', error);
    return { categoryCount: {}, issues: [], priorityDist: {} };
  }
}

function verifyRequirements(categoryCount) {
  const requirements = [
    { category: 'length', required: 15, description: 'Length training techniques' },
    { category: 'girth', required: 12, description: 'Girth training techniques' },
    { category: 'eq', required: 8, description: 'EQ improvement content' },
    { category: 'equipment', required: 10, description: 'Equipment usage guides' },
    { category: 'progression', required: 5, description: 'Progression guidelines' },
    { category: 'safety', required: 3, description: 'Safety documents' }
  ];

  const results = [];

  requirements.forEach(req => {
    const actual = categoryCount[req.category] || 0;
    if (actual >= req.required) {
      results.push(`✅ ${req.description}: ${actual}/${req.required}`);
    } else {
      results.push(`❌ ${req.description}: ${actual}/${req.required}`);
    }
  });

  // Check total count
  const total = Object.values(categoryCount).reduce((sum, count) => sum + count, 0);
  if (total >= 50) {
    results.push(`✅ Total documents: ${total}/50+`);
  } else {
    results.push(`❌ Total documents: ${total}/50+`);
  }

  return results;
}

function printReport(categoryCount, issues, priorityDist, requirements) {
  console.log('\n' + '='.repeat(60));
  console.log('📋 EXPANDED PE KNOWLEDGE VERIFICATION REPORT');
  console.log('='.repeat(60));

  // Document counts by category
  console.log('\n📊 Document Counts by Category:');
  let total = 0;
  Object.entries(categoryCount).sort().forEach(([category, count]) => {
    console.log(`  ${category.charAt(0).toUpperCase() + category.slice(1)}: ${count} documents`);
    total += count;
  });
  console.log(`  TOTAL: ${total} documents`);

  // Priority distribution
  console.log('\n🎯 Priority Distribution:');
  Object.entries(priorityDist).sort().forEach(([priority, count]) => {
    console.log(`  Priority ${priority}: ${count} documents`);
  });

  // Requirements verification
  console.log('\n✔️  Requirements Verification:');
  requirements.forEach(req => {
    console.log(`  ${req}`);
  });

  // Issues found
  if (issues.length > 0) {
    console.log(`\n⚠️  Issues Found (${issues.length}):`);
    issues.slice(0, 10).forEach(issue => {
      console.log(`  - ${issue}`);
    });
    if (issues.length > 10) {
      console.log(`  ... and ${issues.length - 10} more issues`);
    }
  } else {
    console.log('\n✅ No issues found!');
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  if (total >= 50 && issues.length === 0) {
    console.log('🎉 SUCCESS: All requirements met!');
  } else if (total >= 50) {
    console.log('⚠️  PARTIAL SUCCESS: Document count met but issues found');
  } else {
    console.log('❌ FAILED: Requirements not met');
  }
  console.log('='.repeat(60));
}

async function main() {
  console.log('🔍 Verifying Expanded PE Knowledge Deployment');
  console.log('Story 3.3: Develop Training Protocol Knowledge\n');

  // Analyze knowledge base
  const { categoryCount, issues, priorityDist } = await analyzeKnowledgeBase();

  if (Object.keys(categoryCount).length === 0) {
    console.log('❌ Unable to verify knowledge base - no data retrieved');
    process.exit(1);
  }

  // Verify requirements
  const requirements = verifyRequirements(categoryCount);

  // Print report
  printReport(categoryCount, issues, priorityDist, requirements);

  // Exit with appropriate code
  const total = Object.values(categoryCount).reduce((sum, count) => sum + count, 0);
  const success = total >= 50 && issues.length === 0;
  process.exit(success ? 0 : 1);
}

if (require.main === module) {
  main().catch(error => {
    console.error('❌ Verification failed:', error);
    process.exit(1);
  });
}

module.exports = { analyzeKnowledgeBase, verifyRequirements, printReport };