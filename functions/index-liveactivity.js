/**
 * Minimal index file for deploying Live Activity functions only
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export only Live Activity functions
const liveActivityFunctions = require('./liveActivityUpdates');
exports.updateLiveActivity = liveActivityFunctions.updateLiveActivity;
exports.updateLiveActivityTimer = liveActivityFunctions.updateLiveActivityTimer;
exports.onTimerStateChange = liveActivityFunctions.onTimerStateChange;
exports.startLiveActivity = liveActivityFunctions.startLiveActivity;

console.log('Live Activity functions loaded successfully');