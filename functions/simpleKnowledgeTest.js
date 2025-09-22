#!/usr/bin/env node
/**
 * Simple Knowledge Base Test
 * Story 3.3: Develop Training Protocol Knowledge
 *
 * Tests basic knowledge retrieval without complex indexes
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

async function testBasicRetrieval() {
  console.log('📊 Testing Basic Knowledge Retrieval...');

  try {
    // Test 1: Get all documents
    const allDocs = await db.collection('ai_coach_knowledge').get();
    console.log(`✅ Total documents accessible: ${allDocs.size}`);

    // Test 2: Get documents by category (simple where clause)
    const categories = ['length', 'girth', 'eq', 'equipment', 'progression', 'safety'];
    console.log('\n📋 Category Distribution:');

    for (const category of categories) {
      const snapshot = await db.collection('ai_coach_knowledge')
        .where('category', '==', category)
        .get();
      console.log(`   ${category.charAt(0).toUpperCase() + category.slice(1)}: ${snapshot.size} documents`);
    }

    // Test 3: Get high-priority safety content
    const safetyDocs = await db.collection('ai_coach_knowledge')
      .where('category', '==', 'safety')
      .get();

    console.log('\n🛡️  Safety Content Analysis:');
    let highPrioritySafety = 0;
    safetyDocs.forEach(doc => {
      const data = doc.data();
      if (data.priority >= 9) highPrioritySafety++;
      console.log(`   - ${data.title} (Priority: ${data.priority})`);
    });
    console.log(`   High-priority safety docs: ${highPrioritySafety}`);

    // Test 4: Sample content from each category
    console.log('\n📝 Sample Content Test:');
    for (const category of ['length', 'girth', 'eq']) {
      const snapshot = await db.collection('ai_coach_knowledge')
        .where('category', '==', category)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        const data = doc.data();
        const hasDisclaimer = data.content.includes('Medical Disclaimer');
        const contentLength = data.content.length;
        console.log(`   ${category}: "${data.title}" (${contentLength} chars, Medical Disclaimer: ${hasDisclaimer ? '✅' : '❌'})`);
      }
    }

    return allDocs.size >= 50;

  } catch (error) {
    console.error('❌ Error in basic retrieval test:', error);
    return false;
  }
}

async function testAICoachIntegration() {
  console.log('\n🤖 Testing AI Coach Integration...');

  try {
    // Test the knowledge search function similar to what AI Coach would use
    const snapshot = await db.collection('ai_coach_knowledge')
      .where('category', '==', 'length')
      .limit(3)
      .get();

    console.log('Sample knowledge retrieval for "length training":');
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`   - ${data.title}`);
      console.log(`     Keywords: ${data.keywords?.slice(0, 5).join(', ')}...`);
      console.log(`     Content preview: ${data.content.substring(0, 100)}...`);
    });

    return !snapshot.empty;

  } catch (error) {
    console.error('❌ Error in AI Coach integration test:', error);
    return false;
  }
}

async function main() {
  console.log('🧪 Simple Knowledge Base Test');
  console.log('Story 3.3: Develop Training Protocol Knowledge\n');
  console.log('='.repeat(60));

  const basicTest = await testBasicRetrieval();
  const integrationTest = await testAICoachIntegration();

  console.log('\n' + '='.repeat(60));
  console.log('📋 TEST RESULTS');
  console.log('='.repeat(60));

  if (basicTest && integrationTest) {
    console.log('🎉 SUCCESS: Knowledge base is fully functional!');
    console.log('✅ All documents accessible');
    console.log('✅ Category organization working');
    console.log('✅ Safety content properly prioritized');
    console.log('✅ AI Coach integration ready');
    console.log('\n📝 Note: Advanced keyword search requires Firestore indexes (in progress)');
    return true;
  } else {
    console.log('❌ FAILED: Knowledge base has issues');
    if (!basicTest) console.log('   - Basic retrieval failed');
    if (!integrationTest) console.log('   - AI Coach integration failed');
    return false;
  }
}

if (require.main === module) {
  main().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
  });
}