const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

async function checkAllDuplicates() {
  console.log('🔍 Checking for all duplicate exercises...\n');
  
  const snapshot = await db.collection('growth_exercises').get();
  const exercises = [];
  
  snapshot.forEach(doc => {
    exercises.push({
      id: doc.id,
      title: doc.data().title,
      stage: doc.data().stage,
      duration: doc.data().estimatedDurationMinutes
    });
  });
  
  console.log(`Total exercises: ${exercises.length}\n`);
  
  // Group by title
  const byTitle = {};
  exercises.forEach(ex => {
    if (!byTitle[ex.title]) {
      byTitle[ex.title] = [];
    }
    byTitle[ex.title].push(ex);
  });
  
  // Find duplicates
  const duplicates = Object.entries(byTitle).filter(([title, exs]) => exs.length > 1);
  
  if (duplicates.length === 0) {
    console.log('✅ No duplicates found!');
  } else {
    console.log(`⚠️  Found ${duplicates.length} exercises with duplicates:\n`);
    duplicates.forEach(([title, exs]) => {
      console.log(`📌 "${title}" (${exs.length} versions):`);
      exs.forEach(ex => {
        console.log(`   - ${ex.id} | Stage ${ex.stage} | ${ex.duration}min`);
      });
      console.log('');
    });
  }
  
  // Show exercises by stage
  console.log('\n📊 Exercises by Stage:');
  [1, 2, 3].forEach(stage => {
    const stageExercises = exercises.filter(ex => ex.stage === stage);
    console.log(`\nStage ${stage}: ${stageExercises.length} exercises`);
    stageExercises.forEach(ex => {
      console.log(`  - ${ex.id}`);
    });
  });
}

checkAllDuplicates().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
