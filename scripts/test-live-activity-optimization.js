#!/usr/bin/env node

/**
 * Test script to verify Live Activity optimization
 * Monitors Firebase Function logs to show the reduction in push notifications
 */

const admin = require('firebase-admin');
const { exec } = require('child_process');

// Initialize admin SDK
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

console.log('🧪 Live Activity Optimization Test\n');

// Function to count push notification sends in logs
async function analyzeLogs(duration = 60) {
    console.log(`📊 Analyzing Firebase Function logs for ${duration} seconds...\n`);
    
    const startTime = Date.now();
    let updateCount = 0;
    let stateChangeCount = 0;
    
    // Start monitoring logs
    const logProcess = exec('firebase functions:log --only manageLiveActivityUpdates -n 1000');
    
    logProcess.stdout.on('data', (data) => {
        const log = data.toString();
        
        // Count different types of updates
        if (log.includes('Update #')) {
            updateCount++;
        }
        if (log.includes('State change detected')) {
            stateChangeCount++;
        }
        if (log.includes('Timer update sent successfully')) {
            console.log('📤 Push notification sent');
        }
    });
    
    // Monitor for specified duration
    await new Promise(resolve => setTimeout(resolve, duration * 1000));
    
    logProcess.kill();
    
    const elapsed = (Date.now() - startTime) / 1000;
    
    console.log('\n📈 Results:');
    console.log(`Duration: ${elapsed.toFixed(1)} seconds`);
    console.log(`Periodic updates: ${updateCount}`);
    console.log(`State change updates: ${stateChangeCount}`);
    console.log(`Updates per second: ${(updateCount / elapsed).toFixed(2)}`);
    
    if (updateCount > 10) {
        console.log('\n⚠️  WARNING: Still sending frequent updates!');
        console.log('The optimization may not be properly deployed.');
    } else {
        console.log('\n✅ Optimization successful!');
        console.log('Push notifications are only sent for state changes.');
    }
}

// Function to simulate timer state changes
async function simulateTimerActivity(userId = 'test-user') {
    console.log('🎮 Simulating timer activity...\n');
    
    const activityId = `test-${Date.now()}`;
    
    try {
        // Start timer
        console.log('▶️  Starting timer...');
        await db.collection('activeTimers').doc(userId).set({
            activityId,
            action: 'start',
            contentState: {
                isPaused: false,
                startTime: admin.firestore.Timestamp.now(),
                endTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 300000)), // 5 min
                sessionType: 'countdown',
                totalDuration: 300,
                elapsedTimeAtLastUpdate: 0,
                remainingTimeAtLastUpdate: 300
            }
        });
        
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
        
        // Pause timer
        console.log('⏸️  Pausing timer...');
        await db.collection('activeTimers').doc(userId).update({
            action: 'pause',
            'contentState.isPaused': true,
            'contentState.elapsedTimeAtLastUpdate': 10,
            'contentState.remainingTimeAtLastUpdate': 290
        });
        
        await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds
        
        // Resume timer
        console.log('▶️  Resuming timer...');
        await db.collection('activeTimers').doc(userId).update({
            action: 'resume',
            'contentState.isPaused': false,
            'contentState.elapsedTimeAtLastUpdate': 10,
            'contentState.remainingTimeAtLastUpdate': 290
        });
        
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
        
        // Stop timer
        console.log('⏹️  Stopping timer...');
        await db.collection('activeTimers').doc(userId).update({
            action: 'stop',
            'contentState.elapsedTimeAtLastUpdate': 20,
            'contentState.remainingTimeAtLastUpdate': 280
        });
        
        console.log('\n✅ Timer simulation completed');
        
    } catch (error) {
        console.error('❌ Error simulating timer:', error);
    }
}

// Main test function
async function runTest() {
    console.log('Choose test mode:');
    console.log('1. Analyze current logs');
    console.log('2. Simulate timer and analyze');
    console.log('3. Compare before/after (requires both versions)');
    
    const mode = process.argv[2] || '1';
    
    switch (mode) {
        case '1':
            await analyzeLogs(60);
            break;
            
        case '2':
            // Start log analysis in background
            const logPromise = analyzeLogs(40);
            
            // Wait a bit then simulate timer
            await new Promise(resolve => setTimeout(resolve, 5000));
            await simulateTimerActivity();
            
            // Wait for log analysis to complete
            await logPromise;
            break;
            
        case '3':
            console.log('\n📊 Before optimization (if using old version):');
            console.log('Expected: ~10 updates per second');
            console.log('Push notifications sent continuously');
            
            console.log('\n📊 After optimization:');
            console.log('Expected: Updates only on state changes');
            console.log('Push notifications: ~4 for a typical session');
            
            await analyzeLogs(30);
            break;
            
        default:
            console.log('Invalid mode. Use: node test-live-activity-optimization.js [1|2|3]');
    }
    
    process.exit(0);
}

// Run the test
runTest().catch(error => {
    console.error('Test failed:', error);
    process.exit(1);
});