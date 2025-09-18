import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const serviceAccount = JSON.parse(
    readFileSync(join(__dirname, '../functions/service-account-prod.json'), 'utf8')
);

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyStepsDisplay() {
    console.log('🔍 Verifying Steps Display in Firebase...\n');
    
    try {
        // Get specific method that's showing issues
        const angionMethod = await db.collection('growthMethods').doc('am1_0').get();
        
        if (angionMethod.exists) {
            const data = angionMethod.data();
            console.log('📋 Angion Method 1.0 Data:');
            console.log('   Title:', data.title);
            console.log('   Has steps array:', data.steps ? 'YES' : 'NO');
            
            if (data.steps) {
                console.log('   Number of steps:', data.steps.length);
                console.log('\n   Steps:');
                data.steps.forEach((step, index) => {
                    console.log(`     ${index + 1}. ${step.title}`);
                    console.log(`        Description: ${step.description.substring(0, 50)}...`);
                    console.log(`        Duration: ${step.duration ? step.duration / 60 + ' min' : 'Not specified'}`);
                });
            }
            
            console.log('\n   Instructions text preview:', data.instructionsText ? data.instructionsText.substring(0, 100) + '...' : 'None');
            
            // Check if title contains "(Detailed)"
            if (data.title.includes('(Detailed)')) {
                console.log('\n⚠️  WARNING: Title contains "(Detailed)" - this should be cleaned in the UI');
            }
        } else {
            console.log('❌ Method am1_0 not found in Firebase');
        }
        
    } catch (error) {
        console.error('Error fetching method:', error);
    }
    
    process.exit();
}

verifyStepsDisplay();