const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

async function restoreCorrectPAC() {
  console.log('🔄 Fixing PAC Exercise\n');
  
  // Delete the wrong one (stage3_pump_assisted_clamping - 20min)
  console.log('🗑️  Deleting: stage3_pump_assisted_clamping (20min version)');
  await db.collection('growth_exercises').doc('stage3_pump_assisted_clamping').delete();
  console.log('✅ Deleted\n');
  
  // Verify pump_assisted_clamping_pac still exists (25min version to keep)
  const keepDoc = await db.collection('growth_exercises').doc('pump_assisted_clamping_pac').get();
  
  if (keepDoc.exists) {
    const data = keepDoc.data();
    console.log('✅ Correct PAC exercise confirmed:');
    console.log(`   ID: pump_assisted_clamping_pac`);
    console.log(`   Title: ${data.title}`);
    console.log(`   Stage: ${data.stage}`);
    console.log(`   Duration: ${data.estimatedDurationMinutes} min`);
  } else {
    console.log('❌ ERROR: pump_assisted_clamping_pac not found!');
    console.log('This exercise may have been deleted. Need to redeploy it.');
  }
  
  //Check final PAC count
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
  
  console.log(`\n📊 Final PAC count: ${pacExercises.length}`);
  pacExercises.forEach(ex => {
    console.log(`   - ${ex.id} | ${ex.title} | Stage ${ex.stage} | ${ex.duration}min`);
  });
}

restoreCorrectPAC().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
