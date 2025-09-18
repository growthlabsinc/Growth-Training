const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase configuration
const projectId = 'growth-70a85';

// Check if service account key exists
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(__dirname, '../growth-70a85-firebase-adminsdk.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Service account key not found!');
  console.log('\nTo deploy, you need to:');
  console.log('1. Download service account key from Firebase Console');
  console.log('2. Place it at:', serviceAccountPath);
  console.log('3. Or set GOOGLE_APPLICATION_CREDENTIALS env variable');
  console.log('\nAlternatively, use the manual update instructions below.');
} else {
  // Initialize Firebase Admin
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
    projectId: projectId
  });
}

// Load step data from the comprehensive update file
const allUpdates = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'sabre-updates/all-sabre-updates.json'), 'utf8')
);

const sabreUpdates = allUpdates.methods;

console.log('🚀 SABRE Methods Update Script v2');
console.log('==================================');
console.log('Deploying SABRE techniques with detailed multi-step instructions\n');

async function deployUpdates() {
  if (!admin.apps.length) {
    console.log('⚠️  Firebase Admin not initialized - showing manual instructions only\n');
    showManualInstructions();
    return;
  }

  const db = admin.firestore();
  const batch = db.batch();
  
  console.log('🔄 Starting batch update...\n');

  try {
    // Process each SABRE method
    for (const [docId, updateData] of Object.entries(sabreUpdates)) {
      const docRef = db.collection('growthMethods').doc(docId);
      
      // Add timestamp and prepare update
      const finalUpdateData = {
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdatedBy: 'SABRE Update Script v2',
        updateSource: 'Janus Bifrons video transcript'
      };

      batch.update(docRef, finalUpdateData);
      console.log(`✅ Prepared update for ${docId}`);
    }

    // Commit the batch
    console.log('\n📤 Committing batch update...');
    await batch.commit();
    
    console.log('\n🎉 All SABRE methods updated successfully!');
    console.log('\nUpdated documents:');
    Object.keys(sabreUpdates).forEach(id => {
      console.log(`  - ${id}`);
    });

    // Verify updates
    console.log('\n🔍 Verifying updates...');
    for (const docId of Object.keys(sabreUpdates)) {
      const doc = await db.collection('growthMethods').doc(docId).get();
      if (doc.exists && doc.data().steps && doc.data().steps.length === 7) {
        console.log(`  ✅ ${docId}: Verified (${doc.data().steps.length} steps)`);
      } else {
        console.log(`  ❌ ${docId}: Verification failed`);
      }
    }

  } catch (error) {
    console.error('\n❌ Error during deployment:', error.message);
    console.log('\nFalling back to manual instructions...\n');
    showManualInstructions();
  }
}

function showManualInstructions() {
  console.log('📋 Manual Update Instructions:');
  console.log('================================\n');
  
  console.log('1. Go to Firebase Console: https://console.firebase.google.com');
  console.log('2. Select project: growth-70a85');
  console.log('3. Navigate to Firestore Database > growthMethods collection\n');

  console.log('📝 For each SABRE document, update these fields:\n');
  
  Object.entries(sabreUpdates).forEach(([id, data]) => {
    console.log(`\n${id.toUpperCase()}:`);
    console.log('─'.repeat(50));
    console.log(`Document ID: ${id}`);
    console.log(`Title: ${data.title}`);
    console.log(`Steps: ${data.steps.length} detailed steps`);
    console.log(`Duration: ${Math.round(data.timerConfig.totalDuration / 60)} minutes`);
    console.log('\nKey updates:');
    console.log('- Add/Update "steps" array with 7 steps');
    console.log('- Add/Update "timerConfig" object');
    console.log('- Add/Update "progressionCriteria" object');
    console.log('- Set "hasMultipleSteps": true');
    console.log('- Set "creator": "Janus Bifrons"');
    console.log('- Update description, instructionsText, safetyNotes, benefits');
  });

  console.log('\n\n💡 Key Points from Janus Video:');
  console.log('─'.repeat(50));
  console.log('• All SABRE types use same manual actions');
  console.log('• Differences are in speed (1-5/sec) and intensity (low/moderate)');
  console.log('• Sessions are timed (20-30 min), not rep-based');
  console.log('• Stop when fullness peaks and begins dropping');
  console.log('• Schedule: 1 day on, 2 days off (mandatory)');
  console.log('• Type C/D use 8-10" smooth metal rod (0.5" diameter)');
  console.log('• Must be performed lying down');
  console.log('• Never exceed 30 minutes (diminishing returns)');

  console.log('\n📁 Source Files:');
  console.log('─'.repeat(50));
  console.log('All update data: scripts/sabre-updates/all-sabre-updates.json');
  console.log('Individual steps:');
  console.log('  - scripts/sabre-updates/sabre_type_a_steps.json');
  console.log('  - scripts/sabre-updates/sabre_type_b_steps.json');
  console.log('  - scripts/sabre-updates/sabre_type_c_steps.json');
  console.log('  - scripts/sabre-updates/sabre_type_d_steps.json');
  
  console.log('\n📊 Update Summary:');
  console.log('─'.repeat(50));
  console.log('Type A: Foundation (1-3/sec, low force) - 40 min');
  console.log('Type B: High Speed (2-5/sec, low force) - 40 min');
  console.log('Type C: Rod Intro (1/sec, moderate force) - 53 min');
  console.log('Type D: Maximum (2-5/sec rod, moderate force) - 47 min');
}

// Alternative deployment using Firebase CLI
function generateFirebaseCLICommands() {
  console.log('\n\n🔧 Alternative: Firebase CLI Commands');
  console.log('=====================================\n');
  console.log('If you have firebase-tools installed globally:\n');
  
  Object.entries(sabreUpdates).forEach(([id, data]) => {
    // Create a sanitized JSON string for CLI
    const updateJson = JSON.stringify({
      steps: data.steps,
      timerConfig: data.timerConfig,
      progressionCriteria: data.progressionCriteria,
      hasMultipleSteps: true,
      creator: "Janus Bifrons",
      description: data.description,
      instructionsText: data.instructionsText,
      safetyNotes: data.safetyNotes,
      benefits: data.benefits
    });

    console.log(`# Update ${id}:`);
    console.log(`firebase firestore:set growthMethods/${id} '${updateJson}' --merge\n`);
  });
}

// Run the deployment
async function main() {
  try {
    await deployUpdates();
    
    console.log('\n\n✨ Deployment Summary');
    console.log('=====================');
    console.log(`Project: ${projectId}`);
    console.log(`Updated: ${Object.keys(sabreUpdates).length} SABRE methods`);
    console.log(`Timestamp: ${new Date().toISOString()}`);
    console.log('Source: Janus Bifrons video transcript');
    
    // Show CLI commands as alternative
    generateFirebaseCLICommands();
    
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

// Execute
main().catch(console.error);