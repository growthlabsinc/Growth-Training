// Script to identify which module is causing the timeout

const modules = [
  { name: 'firebase-admin', path: 'firebase-admin' },
  { name: 'firebase-functions', path: 'firebase-functions' },
  { name: '@google-cloud/vertexai', path: '@google-cloud/vertexai' },
  { name: 'http2', path: 'http2' },
  { name: 'jsonwebtoken', path: 'jsonwebtoken' }
];

async function testModule(mod) {
  console.log(`Testing ${mod.name}...`);
  const start = Date.now();
  
  try {
    require(mod.path);
    const duration = Date.now() - start;
    console.log(`✓ ${mod.name} loaded in ${duration}ms`);
    return true;
  } catch (error) {
    console.error(`✗ ${mod.name} failed:`, error.message);
    return false;
  }
}

async function main() {
  for (const mod of modules) {
    await testModule(mod);
  }
  console.log('Module test complete');
  process.exit(0);
}

// Set a hard timeout
setTimeout(() => {
  console.error('Test timed out after 5 seconds');
  process.exit(1);
}, 5000);

main();