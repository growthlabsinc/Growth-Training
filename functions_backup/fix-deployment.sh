#!/bin/bash

echo "Fixing Firebase Functions deployment..."

# 1. Kill any existing Firebase processes
echo "Killing existing Firebase processes..."
pkill -f firebase || true
pkill -f "node.*firebase" || true

# 2. Clear Firebase cache
echo "Clearing Firebase cache..."
rm -rf ~/.cache/firebase
rm -rf .firebase/

# 3. Update .gcloudignore to be more specific
echo "Updating .gcloudignore..."
cat > .gcloudignore << 'EOF'
# Ignore everything by default
**

# Include only what's needed
!*.js
!package.json
!package-lock.json
!.env.production

# Include subdirectories
!src/**
!vertexAiProxy/**

# Exclude test files and backups
test-*.js
*-backup.js
*-temp.js
index-*.js
!index.js

# Exclude build artifacts
*.log
*.zip
node_modules_old/
.DS_Store

# Exclude APNs key from deployment (should use Firebase config)
AuthKey_*.p8
EOF

# 4. Try deployment with minimal timeout check
echo "Attempting deployment..."
cd ..
firebase deploy --only functions --force

echo "If deployment still hangs, use: firebase deploy --only functions:generateAIResponse --force"
echo "Then deploy other functions individually"