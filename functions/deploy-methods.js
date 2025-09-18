const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin with default credentials
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-70a85'
  });
}

const db = admin.firestore();

async function deployMethods() {
  console.log('🚀 Deploying Angion Methods to Firebase...\n');

  const methods = [
    { id: 'angion_method_1_0', file: '../scripts/angion-method-1-0-multistep.json', name: 'Angion Method 1.0' },
    { id: 'angio_pumping', file: '../scripts/angion-methods-multistep/angio-pumping.json', name: 'Angio Pumping' },
    { id: 'angion_method_2_0', file: '../scripts/angion-methods-multistep/angion-method-2-0.json', name: 'Angion Method 2.0' },
    { id: 'jelq_2_0', file: '../scripts/angion-methods-multistep/jelq-2-0.json', name: 'Jelq 2.0' },
    { id: 'vascion', file: '../scripts/angion-methods-multistep/vascion.json', name: 'Vascion' }
  ];

  for (const method of methods) {
    try {
      console.log(`📝 Deploying ${method.name}...`);
      
      const data = JSON.parse(fs.readFileSync(path.join(__dirname, method.file), 'utf8'));
      
      // Preserve existing data
      const existing = await db.collection('growthMethods').doc(method.id).get();
      if (existing.exists) {
        const existingData = existing.data();
        data.createdAt = existingData.createdAt || admin.firestore.FieldValue.serverTimestamp();
        data.viewCount = existingData.viewCount || 0;
        data.averageRating = existingData.averageRating || 0;
        data.totalRatings = existingData.totalRatings || 0;
      } else {
        // New document
        data.createdAt = admin.firestore.FieldValue.serverTimestamp();
        data.viewCount = 0;
        data.averageRating = 0;
        data.totalRatings = 0;
      }
      
      // Add timestamps
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      data.hasMultipleSteps = true;
      data.isActive = true;
      
      await db.collection('growthMethods').doc(method.id).set(data, { merge: true });
      console.log(`   ✅ ${method.name} deployed successfully`);
      
    } catch (error) {
      console.error(`   ❌ Error deploying ${method.name}:`, error.message);
    }
  }
  
  console.log('\n✅ Deployment complete!');
  process.exit(0);
}

// Set credentials from environment
process.env.GOOGLE_APPLICATION_CREDENTIALS = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(process.env.HOME, '.config/gcloud/application_default_credentials.json');

deployMethods().catch(console.error);