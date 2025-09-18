# Firebase Functions Recovery Guide

## When to Use This Guide
Use this recovery procedure when Firebase Functions deployment fails with:
- Corrupted node_modules that can't be deleted
- Package-lock.json sync errors
- Persistent npm ci failures during deployment
- Module resolution errors
- Timeout errors during function initialization

## Step-by-Step Recovery Process

### 1. Backup Current Functions
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-fresh
mv functions functions_backup_$(date +%Y%m%d_%H%M%S)
```

### 2. Create Fresh Functions Directory
```bash
mkdir functions
cd functions
```

### 3. Create Minimal package.json
```bash
cat > package.json << 'EOF'
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "20"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.1.0",
    "firebase-functions": "^6.3.2"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0"
  },
  "private": true
}
EOF
```

### 4. Create Minimal index.js
```bash
cat > index.js << 'EOF'
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

console.log('Functions loaded successfully');
EOF
```

### 5. Create .gitignore
```bash
echo "node_modules/" > .gitignore
```

### 6. Clean Install Dependencies
```bash
# Ensure no stale package-lock.json exists
rm -f package-lock.json

# Clean npm cache
npm cache clean --force

# Fresh install
npm install
```

### 7. Update Firebase CLI (if needed)
```bash
npm install -g firebase-tools@latest
firebase --version  # Should be 14.9.0 or higher
```

### 8. Deploy Test Function
```bash
# Deploy from project root
cd /Users/tradeflowj/Desktop/Dev/growth-fresh
firebase deploy --only functions --force
```

### 9. Verify Deployment
```bash
firebase functions:list
```

## Restoring Original Functions

Once the minimal deployment succeeds:

### 1. Copy Required Files
```bash
cd functions
cp ../functions_backup/vertexAiProxy.js ./
cp ../functions_backup/fallbackKnowledge.js ./
cp ../functions_backup/addMissingRoutines.js ./
cp ../functions_backup/liveActivityUpdates.js ./
cp ../functions_backup/manageLiveActivityUpdates.js ./
cp ../functions_backup/moderation.js ./
cp ../functions_backup/updateEducationalResourceImages.js ./
cp -r ../functions_backup/vertexAiProxy ./
```

### 2. Add Dependencies Incrementally
```bash
# Add one dependency at a time and test
npm install @google-cloud/vertexai@^0.5.0
npm install cors@^2.8.5
npm install jsonwebtoken@^9.0.2
npm install @google-cloud/secret-manager@^5.6.0
npm install axios@^1.6.0
```

### 3. Update index.js
Copy the full index.js from backup and test deployment after each major function addition.

## Root Cause Analysis

### Why This Recovery Was Necessary

1. **Corrupted node_modules Structure**
   - Duplicate folders with special characters (e.g., ".bin 2")
   - Empty or corrupted package.json files in dependencies
   - File system issues preventing normal deletion

2. **Package Manager State Issues**
   - package-lock.json out of sync with package.json
   - npm ci failing due to lockfile version mismatches
   - Cached corrupted packages

3. **Dependency Complexity**
   - Too many dependencies added without proper resolution
   - Version conflicts between packages
   - Firebase Functions v1 vs v2 API incompatibilities

4. **Build Environment Mismatches**
   - Local Node.js version vs Cloud Build environment
   - Different npm versions between local and deployment

### Prevention Strategies

1. **Regular Maintenance**
   - Periodically clean and rebuild node_modules
   - Keep package-lock.json in version control
   - Run `npm audit fix` regularly

2. **Incremental Changes**
   - Add dependencies one at a time
   - Test deployment after each significant change
   - Use exact versions in package.json

3. **Clean Development**
   - Use `npm ci` locally to match deployment behavior
   - Avoid manual node_modules modifications
   - Keep Firebase CLI updated

4. **Backup Strategy**
   - Regular backups of working functions
   - Version control for all function code
   - Document working dependency versions

## Quick Commands Reference

```bash
# Check functions status
firebase functions:list

# View function logs
firebase functions:log --only functionName

# Delete specific function
firebase functions:delete functionName --region us-central1 --force

# Test function locally
npm run serve

# Deploy specific function
firebase deploy --only functions:functionName
```

## Emergency Contacts
- Firebase Support: https://firebase.google.com/support
- Status Page: https://status.firebase.google.com
- GitHub Issues: https://github.com/firebase/firebase-tools/issues