const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function verifyDocuments() {
  try {
    console.log('🔍 Verifying all growth_exercises documents can be parsed...\n');

    const snapshot = await db.collection('growth_exercises').get();
    const results = {
      total: 0,
      parseable: 0,
      unparseable: [],
      byStage: { 0: [], 1: [], 2: [], 3: [] }
    };

    snapshot.forEach(doc => {
      results.total++;
      const data = doc.data();

      // Check required fields for GrowthMethod model
      const hasRequiredFields =
        doc.documentID !== null &&
        'stage' in data &&
        typeof data.stage === 'number' &&
        'title' in data &&
        typeof data.title === 'string';

      if (hasRequiredFields) {
        results.parseable++;
        const stage = data.stage;
        results.byStage[stage] = results.byStage[stage] || [];
        results.byStage[stage].push({
          id: doc.id,
          title: data.title,
          category: data.category || 'uncategorized'
        });
      } else {
        results.unparseable.push({
          id: doc.id,
          missingFields: [],
          title: data.title || 'NO TITLE'
        });

        if (!('stage' in data)) {
          results.unparseable[results.unparseable.length - 1].missingFields.push('stage');
        }
        if (!('title' in data)) {
          results.unparseable[results.unparseable.length - 1].missingFields.push('title');
        }
      }
    });

    // Display results
    console.log('📊 PARSING VERIFICATION RESULTS');
    console.log('================================');
    console.log(`Total documents: ${results.total}`);
    console.log(`✅ Parseable: ${results.parseable} (${((results.parseable/results.total)*100).toFixed(1)}%)`);
    console.log(`❌ Unparseable: ${results.unparseable.length} (${((results.unparseable.length/results.total)*100).toFixed(1)}%)`);

    if (results.unparseable.length > 0) {
      console.log('\n⚠️ UNPARSEABLE DOCUMENTS:');
      results.unparseable.forEach(doc => {
        console.log(`  - ${doc.id}: Missing ${doc.missingFields.join(', ')}`);
      });
    }

    console.log('\n📚 DOCUMENTS BY STAGE:');
    console.log('\nStage 0 - Educational/Safety (' + results.byStage[0].length + ' documents):');
    results.byStage[0].forEach(doc => {
      console.log(`  • ${doc.title} (${doc.category})`);
    });

    console.log('\nStage 1 - Beginner (' + results.byStage[1].length + ' documents):');
    results.byStage[1].forEach(doc => {
      console.log(`  • ${doc.title} (${doc.category})`);
    });

    console.log('\nStage 2 - Intermediate (' + results.byStage[2].length + ' documents):');
    results.byStage[2].forEach(doc => {
      console.log(`  • ${doc.title} (${doc.category})`);
    });

    console.log('\nStage 3 - Advanced (' + results.byStage[3].length + ' documents):');
    results.byStage[3].forEach(doc => {
      console.log(`  • ${doc.title} (${doc.category})`);
    });

    if (results.parseable === results.total) {
      console.log('\n✅ SUCCESS: All documents are now parseable by the GrowthMethod model!');
    } else {
      console.log('\n⚠️ WARNING: Some documents still cannot be parsed. Please review the unparseable list above.');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }

  process.exit(0);
}

verifyDocuments();