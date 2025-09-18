const functions = require('firebase-functions/v1');

// Minimal test function
exports.test = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
});