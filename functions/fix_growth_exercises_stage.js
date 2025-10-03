const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

async function fixMissingStage() {
  try {
    console.log('🔧 Starting to fix missing stage fields in growth_exercises...\n');

    const snapshot = await db.collection('growth_exercises').get();
    const batch = db.batch();
    let fixedCount = 0;

    // Documents that should be stage 0 (educational/safety)
    const educationalDocs = [
      'anatomy_education_guide',
      'equipment_safety_guide',
      'equipment_selection_guide',
      'faq_guide',
      'growth_theory_guide',
      'hanger_comparison_guide',
      'medical_consultation_guidelines',
      'nutrition_supplementation_guide',
      'measurement_tracking_guide',
      'lifestyle_factors_guide',
      'pre_exercise_safety_checklist',
      'warning_signs_recognition',
      'when_to_stop_immediately',
      'healing_optimization_protocol',
      'girth_recovery_protocol',
      'post_exercise_recovery_routine'
    ];

    // Documents that should be stage 1 (beginner)
    const beginnerDocs = [
      'heat_application_warmup',
      'preparatory_stretching_protocol',
      'pelvic_floor_relaxation',
      'vascular_health_exercise',
      'towel_raises',
      'helicopter_rotation_exercises',
      'dry_jelq_technique'
    ];

    // Documents that should be stage 2 (intermediate)
    const intermediateDocs = [
      'extender_guide',
      'vacuum_pump_guide',
      'vacuum_pumping_progression',
      'combination_pump_jelq',
      'stamina_focused_edging'
    ];

    // Documents that should be stage 3 (advanced)
    const advancedDocs = [
      'advanced_clamping_progression',
      'advanced_kegel_variations'
    ];

    snapshot.forEach(doc => {
      const data = doc.data();

      if (!('stage' in data)) {
        const docId = doc.id;
        let stage = 1; // Default to beginner

        // Determine appropriate stage based on document type
        if (educationalDocs.includes(docId)) {
          stage = 0; // Educational/safety content
        } else if (beginnerDocs.includes(docId)) {
          stage = 1;
        } else if (intermediateDocs.includes(docId)) {
          stage = 2;
        } else if (advancedDocs.includes(docId)) {
          stage = 3;
        } else {
          // Default based on title/category
          if (data.category === 'recovery' || data.category === 'safety') {
            stage = 0;
          } else if (data.title && data.title.toLowerCase().includes('advanced')) {
            stage = 3;
          }
        }

        console.log(`📝 Fixing ${docId}: Adding stage ${stage} (${getStageLabel(stage)})`);
        batch.update(doc.ref, {
          stage: stage,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        fixedCount++;
      }
    });

    if (fixedCount > 0) {
      console.log(`\n✅ Committing fixes for ${fixedCount} documents...`);
      await batch.commit();
      console.log('✅ Successfully fixed all documents missing stage field!');
    } else {
      console.log('✅ No documents needed fixing - all have stage field!');
    }

    // Verify the fix
    console.log('\n📊 Verification:');
    const verifySnapshot = await db.collection('growth_exercises').get();
    let stageCount = { 0: 0, 1: 0, 2: 0, 3: 0 };
    let missingStage = [];

    verifySnapshot.forEach(doc => {
      const data = doc.data();
      if ('stage' in data) {
        stageCount[data.stage] = (stageCount[data.stage] || 0) + 1;
      } else {
        missingStage.push(doc.id);
      }
    });

    console.log(`Stage 0 (Educational/Safety): ${stageCount[0]} documents`);
    console.log(`Stage 1 (Beginner): ${stageCount[1]} documents`);
    console.log(`Stage 2 (Intermediate): ${stageCount[2]} documents`);
    console.log(`Stage 3 (Advanced): ${stageCount[3]} documents`);

    if (missingStage.length > 0) {
      console.log(`⚠️ Still missing stage: ${missingStage.join(', ')}`);
    } else {
      console.log('✅ All documents now have stage field!');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }

  process.exit(0);
}

function getStageLabel(stage) {
  const labels = {
    0: 'Educational/Safety',
    1: 'Beginner',
    2: 'Intermediate',
    3: 'Advanced'
  };
  return labels[stage] || 'Unknown';
}

fixMissingStage();