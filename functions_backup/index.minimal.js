// Minimal test function that requires only firebase-functions
exports.helloWorld = {
  platform: 'gcfv2',
  httpsTrigger: {},
  entryPoint: 'helloWorld',
  handler: (req, res) => {
    res.send('Hello from Firebase!');
  }
};