const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function checkDocuments() {
  try {
    // Check specific problematic documents
    const problemDocs = [
      'warning_signs_recognition',
      'when_to_stop_immediately'
    ];

    for (const docId of problemDocs) {
      const doc = await db.collection('growth_exercises').doc(docId).get();
      if (doc.exists) {
        console.log(`\n=== Document: ${docId} ===`);
        const data = doc.data();
        console.log('Fields present:', Object.keys(data).sort());
        console.log('Has stage field?', 'stage' in data);
        console.log('Title:', data.title);
        console.log('Category:', data.category);
        if (data.stage !== undefined) {
          console.log('Stage value:', data.stage);
        }
      } else {
        console.log(`Document ${docId} does not exist`);
      }
    }

    // Check a working document for comparison
    console.log('\n=== Working document example: wet_jelq ===');
    const workingDoc = await db.collection('growth_exercises').doc('wet_jelq').get();
    if (workingDoc.exists) {
      const data = workingDoc.data();
      console.log('Fields present:', Object.keys(data).sort());
      console.log('Stage value:', data.stage);
    }

    // Count all documents and categorize them
    console.log('\n=== Document Analysis ===');
    const snapshot = await db.collection('growth_exercises').get();
    let withStage = 0;
    let withoutStage = 0;
    const noStageIds = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      if ('stage' in data) {
        withStage++;
      } else {
        withoutStage++;
        noStageIds.push(doc.id);
      }
    });

    console.log(`Total documents: ${snapshot.size}`);
    console.log(`Documents with stage field: ${withStage}`);
    console.log(`Documents without stage field: ${withoutStage}`);
    if (noStageIds.length > 0) {
      console.log('Documents missing stage:', noStageIds.join(', '));
    }

  } catch (error) {
    console.error('Error:', error);
  }

  process.exit(0);
}

checkDocuments();