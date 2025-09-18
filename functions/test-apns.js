const { initializeApp } = require('firebase-admin/app');
const { getFunctions } = require('firebase-admin/functions');

// Initialize admin SDK
const app = initializeApp();
const functions = getFunctions(app);

// Call the test function
async function test() {
  try {
    console.log('Calling testAPNsConnection...');
    const result = await functions.taskQueue('testAPNsConnection').enqueue({});
    console.log('Result:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
  }
}

test();
