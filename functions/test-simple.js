const { onCall } = require('firebase-functions/v2/https');

exports.testSimple = onCall({ cors: true }, async (request) => {
  return { message: 'Hello from Firebase!', timestamp: new Date().toISOString() };
});