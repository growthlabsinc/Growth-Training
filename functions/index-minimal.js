/**
 * Minimal index file to test deployment
 */

// Export Live Activity functions
exports.updateLiveActivity = require('./liveActivityUpdates').updateLiveActivity;
exports.updateLiveActivityTimer = require('./liveActivityUpdates').updateLiveActivityTimer;
exports.onTimerStateChange = require('./liveActivityUpdates').onTimerStateChange;
exports.testAPNsConnection = require('./liveActivityUpdates').testAPNsConnection;