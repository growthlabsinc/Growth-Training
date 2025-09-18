const admin = require('firebase-admin');

// Initialize admin SDK
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'growth-70a85'
    });
}

const db = admin.firestore();

async function checkTimerState(userId) {
    try {
        console.log(`Checking timer state for user: ${userId}`);
        
        // Check activeTimers collection
        const timerDoc = await db.collection('activeTimers').doc(userId).get();
        
        if (timerDoc.exists) {
            console.log('Timer state found!');
            const data = timerDoc.data();
            console.log('Full document data:', JSON.stringify(data, null, 2));
            
            if (data.contentState) {
                console.log('\nContent state structure:');
                console.log('- startTime:', data.contentState.startTime);
                console.log('- endTime:', data.contentState.endTime);
                console.log('- isPaused:', data.contentState.isPaused);
                console.log('- sessionType:', data.contentState.sessionType);
                console.log('- methodName:', data.contentState.methodName);
            }
            
            console.log('\nOther fields:');
            console.log('- action:', data.action);
            console.log('- activityId:', data.activityId);
            console.log('- updatedAt:', data.updatedAt);
        } else {
            console.log('No timer state found for this user');
            
            // Check if there are any documents in activeTimers
            const snapshot = await db.collection('activeTimers').limit(5).get();
            console.log(`\nFound ${snapshot.size} documents in activeTimers collection`);
            
            snapshot.forEach(doc => {
                console.log(`- Document ID: ${doc.id}`);
            });
        }
        
        // Also check liveActivityTokens
        const tokensSnapshot = await db.collection('liveActivityTokens').where('userId', '==', userId).limit(5).get();
        console.log(`\n\nFound ${tokensSnapshot.size} live activity tokens for this user`);
        
        tokensSnapshot.forEach(doc => {
            const data = doc.data();
            console.log(`- Activity ID: ${doc.id}`);
            console.log(`  - Method ID: ${data.methodId}`);
            console.log(`  - Created: ${data.createdAt}`);
        });
        
    } catch (error) {
        console.error('Error checking timer state:', error);
    }
}

// Check for the specific user from the logs
const userId = '7126AZm26LTJ2w4kfQmYeOAhEpV2';
checkTimerState(userId).then(() => process.exit(0));