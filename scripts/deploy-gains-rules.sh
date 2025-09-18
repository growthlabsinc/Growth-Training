#!/bin/bash

echo "Deploying Gains Entry Firestore Rules"
echo "====================================="
echo ""
echo "This script will deploy the updated Firestore rules to enable gains tracking."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Navigate to project directory
cd /Users/tradeflowj/Desktop/Growth

echo "📋 New rules for gains_entries collection:"
echo "  - Authenticated users can read all gains entries"
echo "  - Users can only create entries with their own userId"
echo "  - Users can only update/delete their own entries"
echo "  - Required fields: userId, timestamp, length, girth, erectionQuality"
echo ""

echo "🚀 Deploying Firestore rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Firestore rules deployed successfully!"
    echo ""
    echo "The gains tracking feature should now work properly."
    echo "Users will be able to:"
    echo "  1. Create new measurement entries"
    echo "  2. View their own measurements"
    echo "  3. Update their measurements"
    echo "  4. See statistics and progress"
else
    echo ""
    echo "❌ Deployment failed. Please check your Firebase configuration."
fi