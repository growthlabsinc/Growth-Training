/**
 * Test script to verify post-session measurements are being saved to Firestore
 * Usage: GCLOUD_PROJECT=growth-training-app node test-session-measurements.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
    });
}

const db = admin.firestore();

async function testSessionMeasurements() {
    console.log('🔍 Checking session measurements in Firestore...\n');

    try {
        // Get recent session logs
        const sessionsSnapshot = await db
            .collection('sessionLogs')
            .orderBy('endTime', 'desc')
            .limit(10)
            .get();

        if (sessionsSnapshot.empty) {
            console.log('❌ No session logs found in database');
            return;
        }

        console.log(`Found ${sessionsSnapshot.size} recent sessions:\n`);

        let sessionsWithPre = 0;
        let sessionsWithPost = 0;
        let sessionsWithBoth = 0;

        sessionsSnapshot.forEach((doc, index) => {
            const data = doc.data();
            const sessionDate = data.endTime?.toDate?.() || new Date();

            console.log(`📊 Session ${index + 1} (${doc.id})`);
            console.log(`   Date: ${sessionDate.toLocaleString()}`);
            console.log(`   User: ${data.userId}`);
            console.log(`   Duration: ${data.duration} minutes`);

            // Check for measurements
            const hasPre = data.preMeasurements && Object.keys(data.preMeasurements).length > 0;
            const hasPost = data.postMeasurements && Object.keys(data.postMeasurements).length > 0;

            if (hasPre) {
                sessionsWithPre++;
                console.log(`   ✅ Pre-measurements:`, data.preMeasurements);
            } else {
                console.log(`   ⚠️  No pre-measurements`);
            }

            if (hasPost) {
                sessionsWithPost++;
                console.log(`   ✅ Post-measurements:`, data.postMeasurements);

                // Calculate yield if both pre and post exist
                if (hasPre) {
                    sessionsWithBoth++;
                    console.log(`   📈 Yield calculations:`);
                    for (const [type, preValue] of Object.entries(data.preMeasurements)) {
                        const postValue = data.postMeasurements[type];
                        if (postValue && preValue > 0) {
                            const yield = ((postValue - preValue) / preValue) * 100;
                            console.log(`      ${type}: ${yield.toFixed(2)}%`);
                        }
                    }
                }
            } else {
                console.log(`   ❌ No post-measurements`);
            }

            console.log('');
        });

        // Summary statistics
        console.log('📊 Summary Statistics:');
        console.log(`   Total sessions analyzed: ${sessionsSnapshot.size}`);
        console.log(`   Sessions with pre-measurements: ${sessionsWithPre} (${(sessionsWithPre/sessionsSnapshot.size*100).toFixed(0)}%)`);
        console.log(`   Sessions with post-measurements: ${sessionsWithPost} (${(sessionsWithPost/sessionsSnapshot.size*100).toFixed(0)}%)`);
        console.log(`   Sessions with both: ${sessionsWithBoth} (${(sessionsWithBoth/sessionsSnapshot.size*100).toFixed(0)}%)`);

        if (sessionsWithPost === 0) {
            console.log('\n⚠️  WARNING: No sessions have post-measurements!');
            console.log('   This indicates the post-session measurement feature is not working correctly.');
            console.log('\n   Possible issues:');
            console.log('   1. Users are not capturing post-session measurements');
            console.log('   2. Post-measurements are not being saved to SessionLog');
            console.log('   3. The UI is not properly integrated with SessionCompletionViewModel');
        } else if (sessionsWithPost < sessionsWithPre) {
            console.log('\n⚠️  Post-measurements are being captured less frequently than pre-measurements');
            console.log('   This is expected if the feature was recently added.');
        } else {
            console.log('\n✅ Post-session measurements are being captured successfully!');
        }

        // Check for sessions created after the fix was implemented
        const fixDate = new Date('2025-11-19'); // Today's date when fix was implemented
        const recentSessions = sessionsSnapshot.docs.filter(doc => {
            const sessionDate = doc.data().endTime?.toDate?.() || new Date();
            return sessionDate > fixDate;
        });

        if (recentSessions.length > 0) {
            console.log(`\n📅 Sessions created after fix (${fixDate.toLocaleDateString()}):`);
            let postFixSessionsWithPost = 0;
            recentSessions.forEach(doc => {
                const data = doc.data();
                const hasPost = data.postMeasurements && Object.keys(data.postMeasurements).length > 0;
                if (hasPost) postFixSessionsWithPost++;
            });
            console.log(`   ${recentSessions.length} sessions found`);
            console.log(`   ${postFixSessionsWithPost} have post-measurements (${(postFixSessionsWithPost/recentSessions.length*100).toFixed(0)}%)`);
        }

    } catch (error) {
        console.error('❌ Error querying sessions:', error);
    }
}

// Run the test
testSessionMeasurements().then(() => {
    console.log('\n✅ Test complete');
    process.exit(0);
}).catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
});