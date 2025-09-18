/**
 * Migration script to update existing Live Activity tokens with environment information
 * This can be run once to update existing tokens
 */

const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

async function migrateTokens() {
  const db = admin.firestore();
  
  try {
    // Get all Live Activity tokens
    const tokensSnapshot = await db.collection('liveActivityTokens').get();
    
    console.log(`Found ${tokensSnapshot.size} tokens to check`);
    
    let updatedCount = 0;
    
    for (const doc of tokensSnapshot.docs) {
      const data = doc.data();
      
      // Skip if already has widgetBundleId
      if (data.widgetBundleId) {
        console.log(`Token ${doc.id} already has widgetBundleId, skipping`);
        continue;
      }
      
      // Try to determine environment from user data or other context
      let environment = 'production'; // Default to production
      let bundleId = 'com.growthlabs.growthmethod';
      
      // You could check user documents or other data to determine environment
      // For now, we'll default to production which is the most common case
      
      const updates = {
        environment: environment,
        bundleId: bundleId,
        widgetBundleId: `${bundleId}.GrowthTimerWidget`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      await doc.ref.update(updates);
      updatedCount++;
      
      console.log(`Updated token ${doc.id} with environment: ${environment}`);
    }
    
    console.log(`✅ Migration complete. Updated ${updatedCount} tokens`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

// Export for use as a function
exports.migrateLiveActivityTokens = async (req, res) => {
  await migrateTokens();
  res.send({ success: true });
};

// Allow running directly
if (require.main === module) {
  migrateTokens().then(() => process.exit(0));
}