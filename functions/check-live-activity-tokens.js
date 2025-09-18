const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}

async function checkLiveActivityTokens() {
    const db = admin.firestore();
    
    try {
        console.log('Checking Live Activity tokens in Firestore...\n');
        
        // Get all live activity tokens
        const snapshot = await db.collection('liveActivityTokens')
            .orderBy('createdAt', 'desc')
            .limit(5)
            .get();
        
        if (snapshot.empty) {
            console.log('No Live Activity tokens found in Firestore');
            return;
        }
        
        console.log(`Found ${snapshot.size} recent Live Activity tokens:\n`);
        
        snapshot.forEach((doc) => {
            const data = doc.data();
            console.log(`Document ID: ${doc.id}`);
            console.log(`Activity ID: ${data.activityId}`);
            console.log(`User ID: ${data.userId}`);
            console.log(`Push Token: ${data.pushToken?.substring(0, 20)}...`);
            console.log(`Environment: ${data.environment || 'unknown'}`);
            console.log(`Bundle ID: ${data.bundleId || 'unknown'}`);
            console.log(`Widget Bundle ID: ${data.widgetBundleId || 'unknown'}`);
            console.log(`Created At: ${data.createdAt?.toDate() || 'unknown'}`);
            console.log('---\n');
        });
        
        // Also check active timers
        console.log('\nChecking active timers...\n');
        const timerSnapshot = await db.collection('activeTimers')
            .limit(5)
            .get();
            
        if (timerSnapshot.empty) {
            console.log('No active timers found');
        } else {
            console.log(`Found ${timerSnapshot.size} active timers:`);
            timerSnapshot.forEach((doc) => {
                const data = doc.data();
                console.log(`\nUser ID: ${doc.id}`);
                console.log(`Action: ${data.action}`);
                console.log(`Method: ${data.contentState?.methodName}`);
                console.log(`Is Paused: ${data.contentState?.isPaused}`);
                console.log(`Start Time: ${data.contentState?.startTime}`);
            });
        }
        
    } catch (error) {
        console.error('Error checking Live Activity tokens:', error);
    }
}

checkLiveActivityTokens();