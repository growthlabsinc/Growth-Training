const { onCall } = require('firebase-functions/v2/https');

exports.testFunction = onCall({ region: 'us-central1' }, async (request) => {
  return { message: 'Test function works!' };
});

console.log('Test function loaded');