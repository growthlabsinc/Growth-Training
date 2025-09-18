/**
 * Script to fix all routines by adding empty methods array to rest days
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85',
});

const db = admin.firestore();

async function fixAllRoutines() {
  console.log('🔧 Starting to fix all routines...\n');
  
  try {
    // Get all routines
    const routinesSnapshot = await db.collection('routines').get();
    console.log(`📊 Found ${routinesSnapshot.size} routines to check\n`);
    
    let fixedCount = 0;
    let skippedCount = 0;
    
    for (const doc of routinesSnapshot.docs) {
      const data = doc.data();
      console.log(`\n🔍 Checking routine: ${data.name} (${doc.id})`);
      
      if (!data.schedule || !Array.isArray(data.schedule)) {
        console.log('   ⚠️  No schedule found, skipping');
        skippedCount++;
        continue;
      }
      
      let needsUpdate = false;
      const updatedSchedule = data.schedule.map(day => {
        // If it's a rest day and has no methods array, add an empty one
        if (day.isRestDay && !day.methods) {
          console.log(`   📝 Day ${day.dayNumber}: Adding empty methods array to rest day`);
          needsUpdate = true;
          return {
            ...day,
            methods: []
          };
        }
        return day;
      });
      
      if (needsUpdate) {
        console.log(`   🔄 Updating ${data.name}...`);
        await db.collection('routines').doc(doc.id).update({
          schedule: updatedSchedule,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`   ✅ Successfully fixed ${data.name}`);
        fixedCount++;
      } else {
        console.log(`   ✅ ${data.name} is already correct`);
        skippedCount++;
      }
    }
    
    console.log('\n📊 Summary:');
    console.log(`   - Fixed: ${fixedCount} routines`);
    console.log(`   - Already correct: ${skippedCount} routines`);
    console.log(`   - Total: ${routinesSnapshot.size} routines`);
    
  } catch (error) {
    console.error('❌ Error fixing routines:', error);
  }
}

// Run the fix
fixAllRoutines()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });