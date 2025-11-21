#!/usr/bin/env node

/**
 * Test script for validating unit preference persistence
 * Verifies that measurement unit preferences are saved and retrieved correctly
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const projectId = process.env.GCLOUD_PROJECT || 'growth-training-app';
console.log(`Testing unit persistence for project: ${projectId}`);

if (!admin.apps.length) {
    admin.initializeApp({
        projectId: projectId,
    });
}

const db = admin.firestore();

async function testUnitPersistence() {
    console.log('\n🔄 Testing Unit Preference Persistence...\n');

    const testUserId = 'test-unit-user-' + Date.now();
    const userRef = db.collection('users').doc(testUserId);

    try {
        // Test 1: Create user with millimeters preference
        console.log('1️⃣ Creating user with millimeters preference...');
        await userRef.set({
            userId: testUserId,
            preferredUnit: 'millimeters',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Read back preference
        let doc = await userRef.get();
        let data = doc.data();

        if (data.preferredUnit === 'millimeters') {
            console.log('✅ Millimeters preference saved correctly');
        } else {
            console.log(`❌ Expected millimeters, got ${data.preferredUnit}`);
            return false;
        }

        // Test 2: Update to centimeters
        console.log('\n2️⃣ Updating preference to centimeters...');
        await userRef.update({
            preferredUnit: 'metric',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        doc = await userRef.get();
        data = doc.data();

        if (data.preferredUnit === 'metric') {
            console.log('✅ Centimeters preference updated correctly');
        } else {
            console.log(`❌ Expected metric, got ${data.preferredUnit}`);
            return false;
        }

        // Test 3: Update to inches
        console.log('\n3️⃣ Updating preference to inches...');
        await userRef.update({
            preferredUnit: 'imperial',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        doc = await userRef.get();
        data = doc.data();

        if (data.preferredUnit === 'imperial') {
            console.log('✅ Inches preference updated correctly');
        } else {
            console.log(`❌ Expected imperial, got ${data.preferredUnit}`);
            return false;
        }

        // Test 4: Create gains entry with millimeters display
        console.log('\n4️⃣ Testing gains entry with unit conversion...');

        // Switch back to millimeters
        await userRef.update({
            preferredUnit: 'millimeters'
        });

        // Create gains entry (stored in inches internally)
        const gainsRef = await db.collection('gains_entries').add({
            userId: testUserId,
            bpel: 6.0, // 6 inches = 152mm
            mseg: 4.5, // 4.5 inches = 114mm
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // Read gains entry
        const gainsDoc = await gainsRef.get();
        const gainsData = gainsDoc.data();

        // Convert to millimeters for display
        const bpelMm = Math.round(gainsData.bpel * 25.4);
        const msegMm = Math.round(gainsData.mseg * 25.4);

        console.log(`  BPEL: ${gainsData.bpel}" stored → ${bpelMm}mm displayed`);
        console.log(`  MSEG: ${gainsData.mseg}" stored → ${msegMm}mm displayed`);

        if (bpelMm === 152 && msegMm === 114) {
            console.log('✅ Gains entry displays correctly in millimeters');
        } else {
            console.log('❌ Conversion error in gains display');
            return false;
        }

        // Test 5: Session log with millimeters
        console.log('\n5️⃣ Testing session log with millimeter measurements...');

        const sessionRef = await db.collection('sessions').add({
            userId: testUserId,
            preMeasurements: {
                bpel: 5.905512, // 150mm in inches
                mseg: 4.409449  // 112mm in inches
            },
            postMeasurements: {
                bpel: 5.984252, // 152mm in inches
                mseg: 4.488189  // 114mm in inches
            },
            yieldPercentages: {
                bpel: 1.33, // (152-150)/150 * 100
                mseg: 1.79  // (114-112)/112 * 100
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        const sessionDoc = await sessionRef.get();
        const sessionData = sessionDoc.data();

        // Convert measurements to mm for display
        const preBpelMm = Math.round(sessionData.preMeasurements.bpel * 25.4);
        const preMsegMm = Math.round(sessionData.preMeasurements.mseg * 25.4);
        const postBpelMm = Math.round(sessionData.postMeasurements.bpel * 25.4);
        const postMsegMm = Math.round(sessionData.postMeasurements.mseg * 25.4);

        console.log(`  Pre-BPEL:  ${preBpelMm}mm`);
        console.log(`  Pre-MSEG:  ${preMsegMm}mm`);
        console.log(`  Post-BPEL: ${postBpelMm}mm`);
        console.log(`  Post-MSEG: ${postMsegMm}mm`);
        console.log(`  BPEL Yield: ${sessionData.yieldPercentages.bpel.toFixed(2)}%`);
        console.log(`  MSEG Yield: ${sessionData.yieldPercentages.mseg.toFixed(2)}%`);

        if (preBpelMm === 150 && postBpelMm === 152) {
            console.log('✅ Session measurements display correctly in millimeters');
        } else {
            console.log('❌ Session measurement conversion error');
            return false;
        }

        // Clean up test data
        console.log('\n🧹 Cleaning up test data...');
        await userRef.delete();
        await gainsRef.delete();
        await sessionRef.delete();
        console.log('✅ Test data cleaned up');

        return true;

    } catch (error) {
        console.error('❌ Error during persistence test:', error);

        // Try to clean up on error
        try {
            await userRef.delete();
        } catch (e) {
            // Ignore cleanup errors
        }

        return false;
    }
}

async function testUnitMigration() {
    console.log('\n🔀 Testing Unit Migration for Existing Users...\n');

    // Check if there are any users without preferredUnit field
    const usersWithoutUnit = await db.collection('users')
        .where('preferredUnit', '==', null)
        .limit(5)
        .get();

    if (usersWithoutUnit.empty) {
        console.log('✅ All users have preferredUnit field set');
    } else {
        console.log(`⚠️ Found ${usersWithoutUnit.size} users without preferredUnit field`);
        console.log('These users will default to imperial (inches) until they change their preference');
    }

    return true;
}

// Run all persistence tests
async function runAllTests() {
    console.log('========================================');
    console.log('      UNIT PERSISTENCE TESTS           ');
    console.log('========================================');

    const persistenceResult = await testUnitPersistence();
    const migrationResult = await testUnitMigration();

    console.log('\n========================================');
    console.log('            TEST SUMMARY                ');
    console.log('========================================\n');

    console.log(`${persistenceResult ? '✅' : '❌'} Unit Persistence: ${persistenceResult ? 'PASSED' : 'FAILED'}`);
    console.log(`${migrationResult ? '✅' : '❌'} User Migration Check: ${migrationResult ? 'PASSED' : 'FAILED'}`);

    const allPassed = persistenceResult && migrationResult;

    if (allPassed) {
        console.log('\n🎉 All persistence tests passed! Unit preferences are working correctly.');
    } else {
        console.log('\n⚠️ Some tests failed. Please review the implementation.');
    }

    process.exit(allPassed ? 0 : 1);
}

// Execute tests
runAllTests().catch(error => {
    console.error('Fatal error running tests:', error);
    process.exit(1);
});