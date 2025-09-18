// Minimal isolated test to find what's blocking
console.log('Starting isolated test...');

// Test 1: Just export a simple function
exports.testSimple = async () => {
  return { success: true };
};

console.log('Test complete!');