const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-70a85'
  });
}

const db = admin.firestore();

async function debugMethods() {
  console.log('🔍 Debugging Angion Methods in Firebase...\n');

  const methodIds = [
    'angion_method_1_0',
    'angio_pumping',
    'angion_method_2_0',
    'jelq_2_0',
    'vascion'
  ];

  for (const id of methodIds) {
    try {
      const doc = await db.collection('growthMethods').doc(id).get();
      if (doc.exists) {
        const data = doc.data();
        console.log(`\n📋 ${id}:`);
        console.log(`   Title: ${data.title}`);
        console.log(`   Has 'steps' field: ${data.steps !== undefined}`);
        console.log(`   Type of 'steps': ${typeof data.steps}`);
        console.log(`   Is steps an array: ${Array.isArray(data.steps)}`);
        
        if (Array.isArray(data.steps)) {
          console.log(`   Number of steps: ${data.steps.length}`);
          if (data.steps.length > 0) {
            console.log(`   First step structure:`);
            console.log(`     - Keys: ${Object.keys(data.steps[0]).join(', ')}`);
            console.log(`     - Title: ${data.steps[0].title}`);
            console.log(`     - StepNumber: ${data.steps[0].stepNumber}`);
          }
        }
        
        console.log(`   Has 'instructionsText': ${data.instructionsText !== undefined}`);
        console.log(`   instructionsText length: ${data.instructionsText?.length || 0}`);
        console.log(`   hasMultipleSteps flag: ${data.hasMultipleSteps}`);
        
        // Show all top-level keys
        console.log(`   All fields: ${Object.keys(data).sort().join(', ')}`);
      } else {
        console.log(`❌ ${id} not found`);
      }
    } catch (error) {
      console.error(`❌ Error checking ${id}:`, error.message);
    }
  }
  
  console.log('\n\n📊 Checking one full document structure...');
  const sampleDoc = await db.collection('growthMethods').doc('angion_method_1_0').get();
  if (sampleDoc.exists) {
    const data = sampleDoc.data();
    console.log(JSON.stringify(data, null, 2));
  }
}

// Set credentials
process.env.GOOGLE_APPLICATION_CREDENTIALS = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  require('path').join(process.env.HOME, '.config/gcloud/application_default_credentials.json');

debugMethods().catch(console.error).finally(() => process.exit(0));