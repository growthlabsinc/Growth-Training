#!/bin/bash

# Script to restore all missing standard routines to Firebase

echo "🚀 Restoring standard routines to Firebase..."
echo ""

# Navigate to scripts directory
cd "$(dirname "$0")" || exit 1

# Check if service account file exists
if [ ! -f "service-account.json" ]; then
    echo "❌ Error: service-account.json not found in scripts directory"
    echo "Please ensure your Firebase service account JSON file is in the scripts directory"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install firebase-admin
fi

# Run the restoration script
echo "🔄 Running routine restoration..."
node restore-all-standard-routines.js

echo ""
echo "✅ Done! Check the output above for details."