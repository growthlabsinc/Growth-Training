const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

async function findAllPAC() {
  const snapshot = await db.collection('growth_exercises').get();
  
  console.log('🔍 Searching for ALL PAC-related exercises in Firestore...\n');
  
  const pacExercises = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    const title = data.title || '';
    const desc = data.description || '';
    
    if (title.toLowerCase().includes('pac') || 
        title.toLowerCase().includes('pump') && title.toLowerCase().includes('clamp') ||
        title.toLowerCase().includes('assisted')) {
      pacExercises.push({
        id: doc.id,
        title: data.title,
        description: data.description,
        stage: data.stage,
        duration: data.estimatedDurationMinutes
      });
    }
  });
  
  if (pacExercises.length === 0) {
    console.log('❌ No PAC exercises found in Firestore!');
    console.log('\nAll PAC exercises have been deleted. Need to redeploy from script.');
  } else {
    console.log(`Found ${pacExercises.length} PAC-related exercise(s):\n`);
    pacExercises.forEach(ex => {
      console.log(`ID: ${ex.id}`);
      console.log(`Title: ${ex.title}`);
      console.log(`Description: ${ex.description}`);
      console.log(`Stage: ${ex.stage} | Duration: ${ex.duration}min`);
      console.log('---');
    });
  }
}

findAllPAC().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
