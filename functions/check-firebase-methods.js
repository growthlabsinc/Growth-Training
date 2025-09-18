const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-70a85'
  });
}

const db = admin.firestore();

async function checkMethods() {
  console.log('🔍 Checking Angion Methods in Firebase...\n');

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
        console.log(`📋 ${data.title}:`);
        console.log(`   - Has steps array: ${Array.isArray(data.steps) ? 'YES' : 'NO'}`);
        console.log(`   - Number of steps: ${Array.isArray(data.steps) ? data.steps.length : 'N/A'}`);
        console.log(`   - hasMultipleSteps flag: ${data.hasMultipleSteps}`);
        
        // Check if it has old single-step structure
        if (data.instructions && typeof data.instructions === 'string') {
          console.log(`   ⚠️  Has old 'instructions' field (single step)`);
        }
        
        // Show first step if exists
        if (Array.isArray(data.steps) && data.steps.length > 0) {
          console.log(`   - First step: "${data.steps[0].title}"`);
        }
        
        console.log('');
      } else {
        console.log(`❌ ${id} not found in database\n`);
      }
    } catch (error) {
      console.error(`❌ Error checking ${id}:`, error.message);
    }
  }
}

// Set credentials
process.env.GOOGLE_APPLICATION_CREDENTIALS = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  require('path').join(process.env.HOME, '.config/gcloud/application_default_credentials.json');

checkMethods().catch(console.error).finally(() => process.exit(0));