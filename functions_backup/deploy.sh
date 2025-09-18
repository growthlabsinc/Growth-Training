#\!/bin/bash
echo "Deploying Firebase Functions..."

# Clean up any cached files
rm -rf lib/

# Deploy functions
firebase deploy --only functions --force

echo "Deployment complete"
