const admin = require('firebase-admin');
const serviceAccount = require('../functions/service-account-prod.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyMethods() {
    console.log('🔍 Verifying Firebase Methods Structure...\n');
    
    try {
        const snapshot = await db.collection('growthMethods').get();
        
        console.log(`Found ${snapshot.size} methods in Firebase\n`);
        
        snapshot.forEach(doc => {
            const data = doc.data();
            console.log(`📋 Method: ${data.title} (ID: ${doc.id})`);
            console.log(`   Stage: ${data.stage}`);
            console.log(`   Has steps array: ${data.steps ? 'YES' : 'NO'}`);
            
            if (data.steps) {
                console.log(`   Number of steps: ${data.steps.length}`);
                data.steps.forEach((step, index) => {
                    console.log(`     Step ${index + 1}: ${step.title}`);
                });
            } else {
                console.log(`   Instructions text: ${data.instructionsText ? data.instructionsText.substring(0, 50) + '...' : 'None'}`);
            }
            
            console.log('');
        });
        
    } catch (error) {
        console.error('Error fetching methods:', error);
    }
    
    process.exit();
}

verifyMethods();