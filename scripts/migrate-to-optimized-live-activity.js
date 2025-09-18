#!/usr/bin/env node

/**
 * Migration script to update Firebase Functions for optimized Live Activity updates
 * This script will:
 * 1. Backup current functions
 * 2. Deploy optimized versions
 * 3. Verify deployment
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Starting Live Activity optimization migration...\n');

// Step 1: Create backups
console.log('📦 Creating backups of current functions...');
const functionsDir = path.join(__dirname, '..', 'functions');
const backupDir = path.join(functionsDir, 'backup-before-optimization');

try {
    if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
    }
    
    // Backup current files
    const filesToBackup = [
        'manageLiveActivityUpdates.js',
        'onTimerStateChange.js',
        'index.js'
    ];
    
    filesToBackup.forEach(file => {
        const src = path.join(functionsDir, file);
        const dest = path.join(backupDir, file);
        if (fs.existsSync(src)) {
            fs.copyFileSync(src, dest);
            console.log(`✅ Backed up ${file}`);
        }
    });
} catch (error) {
    console.error('❌ Error creating backups:', error.message);
    process.exit(1);
}

// Step 2: Update index.js to use optimized functions
console.log('\n📝 Updating index.js to use optimized functions...');
const indexPath = path.join(functionsDir, 'index.js');
const indexContent = fs.readFileSync(indexPath, 'utf8');

// Check if we need to update the exports
if (!indexContent.includes('manageLiveActivityUpdates-optimized')) {
    const updatedIndex = indexContent.replace(
        /exports\.manageLiveActivityUpdates = require\(['"]\.\/manageLiveActivityUpdates['"]\)\.manageLiveActivityUpdates;?/,
        "exports.manageLiveActivityUpdates = require('./manageLiveActivityUpdates-optimized').manageLiveActivityUpdates;"
    ).replace(
        /exports\.onTimerStateChange = require\(['"]\.\/onTimerStateChange['"]\)\.onTimerStateChange;?/,
        "exports.onTimerStateChange = require('./onTimerStateChange-optimized').onTimerStateChange;"
    );
    
    fs.writeFileSync(indexPath, updatedIndex);
    console.log('✅ Updated index.js');
} else {
    console.log('✅ index.js already using optimized functions');
}

// Step 3: Deploy the optimized functions
console.log('\n🚀 Deploying optimized Firebase Functions...');
console.log('This may take a few minutes...\n');

try {
    process.chdir(functionsDir);
    
    // Install dependencies if needed
    console.log('📦 Checking dependencies...');
    execSync('npm install', { stdio: 'inherit' });
    
    // Deploy specific functions
    console.log('\n🔥 Deploying to Firebase...');
    execSync('firebase deploy --only functions:manageLiveActivityUpdates,functions:onTimerStateChange', { 
        stdio: 'inherit' 
    });
    
    console.log('\n✅ Functions deployed successfully!');
} catch (error) {
    console.error('\n❌ Deployment failed:', error.message);
    console.log('\n🔄 Rolling back index.js...');
    fs.writeFileSync(indexPath, indexContent);
    process.exit(1);
}

// Step 4: Provide next steps
console.log('\n📋 Migration completed! Next steps:\n');
console.log('1. Test the optimized Live Activity:');
console.log('   - Start a timer in your app');
console.log('   - Verify the Live Activity appears and updates smoothly');
console.log('   - Check Firebase logs: firebase functions:log');
console.log('');
console.log('2. Monitor the improvement:');
console.log('   - Before: ~10 updates per second');
console.log('   - After: Updates only on state changes');
console.log('');
console.log('3. Update your iOS app (if needed):');
console.log('   - Ensure Timer state includes activityId');
console.log('   - Call sendStateUpdate action on pause/resume');
console.log('');
console.log('4. If issues occur, rollback with:');
console.log('   cp functions/backup-before-optimization/* functions/');
console.log('   firebase deploy --only functions');
console.log('');
console.log('🎉 Your Live Activity is now optimized for minimal push notifications!');