/**
 * Minimal index for deploying Live Activity functions
 */

// Export only the Live Activity functions
const liveActivityFunctions = require('./liveActivityUpdates');
exports.updateLiveActivity = liveActivityFunctions.updateLiveActivity;
exports.updateLiveActivityTimer = liveActivityFunctions.updateLiveActivityTimer;
exports.onTimerStateChange = liveActivityFunctions.onTimerStateChange;