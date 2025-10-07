const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

async function checkPACExercises() {
  console.log('Checking for PAC exercises in Firestore...\n');
  
  // Get all exercises with "Pump" or "PAC" in the title
  const snapshot = await db.collection('growth_exercises').get();
  
  const pacExercises = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    const title = data.title || '';
    if (title.toLowerCase().includes('pump') && title.toLowerCase().includes('clamp')) {
      pacExercises.push({
        id: doc.id,
        title: data.title,
        stage: data.stage,
        duration: data.estimatedDurationMinutes
      });
    }
  });
  
  console.log(`Found ${pacExercises.length} PAC exercise(s):\n`);
  pacExercises.forEach(ex => {
    console.log(`ID: ${ex.id}`);
    console.log(`Title: ${ex.title}`);
    console.log(`Stage: ${ex.stage}`);
    console.log(`Duration: ${ex.duration} min`);
    console.log('---');
  });
  
  if (pacExercises.length > 1) {
    console.log('\n⚠️  DUPLICATE FOUND! Multiple PAC exercises exist.');
    console.log('Old stage1 version should be deleted.');
  }
}

checkPACExercises().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
