const { onCall } = require('firebase-functions/v2/https');

exports.testFunction = onCall({ cors: true }, async (request) => {
  return { message: 'Test function works!' };
});