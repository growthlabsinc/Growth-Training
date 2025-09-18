#!/bin/bash

echo "Fixing Firebase Functions authentication issue..."

# Navigate to functions directory
cd functions

# Install dependencies if not already installed
if [ ! -d "node_modules" ]; then
    echo "Installing Firebase Functions dependencies..."
    npm install
fi

# Deploy the function with public access
echo "Deploying generateAIResponse function with public access..."
firebase deploy --only functions:generateAIResponse

# Check deployment status
echo "Checking function deployment status..."
firebase functions:list

echo "Done! The generateAIResponse function should now accept unauthenticated requests."
echo ""
echo "If you still see UNAUTHENTICATED errors, try:"
echo "1. Clear the app data and restart"
echo "2. Check Firebase Console > Functions to ensure the function is deployed"
echo "3. Verify the function has 'Allow unauthenticated' enabled in the Cloud Console"