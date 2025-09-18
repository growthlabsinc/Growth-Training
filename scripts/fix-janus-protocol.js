/**
 * Script to fix the Janus Protocol routine structure
 * The routine exists but has a decoding error in the schedule
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85',
});

const db = admin.firestore();

async function fixJanusProtocol() {
  console.log('🔧 Checking Janus Protocol routine...\n');
  
  try {
    // Get the existing Janus Protocol routine
    const doc = await db.collection('routines').doc('janus_protocol_12week').get();
    
    if (!doc.exists) {
      console.log('❌ Janus Protocol routine not found');
      return;
    }
    
    const data = doc.data();
    console.log('✅ Found Janus Protocol routine');
    console.log(`   Name: ${data.name}`);
    console.log(`   Duration: ${data.duration} days`);
    console.log(`   Schedule days: ${data.schedule?.length || 0}`);
    
    // Check if schedule needs fixing
    let needsUpdate = false;
    const updatedSchedule = [];
    
    if (data.schedule && Array.isArray(data.schedule)) {
      for (const day of data.schedule) {
        // Check if day has methods array
        if (!day.isRestDay && day.methodIds && !day.methods) {
          console.log(`\n⚠️  Day ${day.dayNumber} missing methods array`);
          needsUpdate = true;
          
          // Create methods array from methodIds
          const methods = [];
          if (Array.isArray(day.methodIds)) {
            day.methodIds.forEach((methodId, index) => {
              methods.push({
                methodId: methodId,
                duration: 20, // Default duration
                order: index
              });
            });
          }
          
          updatedSchedule.push({
            ...day,
            methods: methods
          });
        } else {
          updatedSchedule.push(day);
        }
      }
    }
    
    if (needsUpdate) {
      console.log('\n🔄 Updating Janus Protocol routine...');
      
      await db.collection('routines').doc('janus_protocol_12week').update({
        schedule: updatedSchedule,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log('✅ Successfully updated Janus Protocol routine!');
    } else {
      console.log('\n✅ Janus Protocol routine structure is correct');
    }
    
  } catch (error) {
    console.error('❌ Error fixing Janus Protocol:', error);
  }
}

// Run the fix
fixJanusProtocol()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });