const { exec } = require('child_process');
const path = require('path');

console.log('Starting programmatic deployment...');

// Deploy functions one by one to avoid timeout
const functionsToDelete = [
  'manageLiveActivityUpdates',
  'updateLiveActivityTimer', 
  'onTimerStateChange',
  'updateLiveActivity',
  'startLiveActivity'
];

const functionsToDeployInOrder = [
  'generateAIResponse',
  'addMissingRoutines',
  'trackRoutineDownload',
  'moderateNewRoutine',
  'processReport',
  'banUser',
  'moderateContent',
  'cleanupOldReports',
  'checkUserBanned',
  'updateEducationalResourceImages',
  'updateEducationalResourceImagesCallable'
];

async function runCommand(command) {
  return new Promise((resolve, reject) => {
    console.log(`Running: ${command}`);
    const child = exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error.message}`);
        reject(error);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
      }
      console.log(`Output: ${stdout}`);
      resolve(stdout);
    });
    
    // Log real-time output
    child.stdout.on('data', (data) => {
      process.stdout.write(data);
    });
    
    child.stderr.on('data', (data) => {
      process.stderr.write(data);
    });
  });
}

async function deleteFunction(funcName) {
  try {
    console.log(`\nDeleting function: ${funcName}`);
    await runCommand(`firebase functions:delete ${funcName} --force`);
    console.log(`✓ Deleted ${funcName}`);
  } catch (error) {
    console.log(`⚠️  Could not delete ${funcName} (may not exist)`);
  }
}

async function deployFunction(funcName) {
  try {
    console.log(`\nDeploying function: ${funcName}`);
    await runCommand(`firebase deploy --only functions:${funcName}`);
    console.log(`✓ Deployed ${funcName}`);
    return true;
  } catch (error) {
    console.error(`✗ Failed to deploy ${funcName}`);
    return false;
  }
}

async function main() {
  console.log('Step 1: Delete problematic functions...');
  for (const func of functionsToDelete) {
    await deleteFunction(func);
  }
  
  console.log('\nStep 2: Deploy working functions one by one...');
  const results = [];
  for (const func of functionsToDeployInOrder) {
    const success = await deployFunction(func);
    results.push({ function: func, success });
    
    // Add delay between deployments
    if (success) {
      console.log('Waiting 10 seconds before next deployment...');
      await new Promise(resolve => setTimeout(resolve, 10000));
    }
  }
  
  console.log('\n=== Deployment Summary ===');
  results.forEach(({ function: func, success }) => {
    console.log(`${success ? '✓' : '✗'} ${func}`);
  });
  
  console.log('\nNext steps:');
  console.log('1. Fix the Live Activity functions initialization issue');
  console.log('2. Deploy them manually via Google Cloud Console');
  console.log('3. Use the instructions in MANUAL_DEPLOYMENT.md');
}

main().catch(console.error);