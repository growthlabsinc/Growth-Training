// Temporary index.js for optimized Live Activity deployment
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin
if (!admin.apps.length) {
    admin.initializeApp();
}

// Import optimized Live Activity functions
const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates-optimized');
const { onTimerStateChange } = require('./onTimerStateChange-optimized');
const { updateLiveActivity } = require('./liveActivityUpdates');

// Export optimized functions
exports.manageLiveActivityUpdates = manageLiveActivityUpdates;
exports.onTimerStateChange = onTimerStateChange;
exports.updateLiveActivity = updateLiveActivity;

// Export other existing functions from original index
const originalExports = require('./index');
Object.keys(originalExports).forEach(key => {
    if (!['manageLiveActivityUpdates', 'onTimerStateChange', 'updateLiveActivity'].includes(key)) {
        exports[key] = originalExports[key];
    }
});
