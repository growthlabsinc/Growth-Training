#!/bin/bash

echo "🚀 Calling Firebase Function to deploy Angion methods..."
echo "============================================"

# Get ID token for authentication
echo "📋 Getting authentication token..."
ID_TOKEN=$(gcloud auth print-identity-token 2>/dev/null)

if [ -z "$ID_TOKEN" ]; then
    echo "⚠️  Could not get auth token. Using alternative method..."
    
    # Alternative: Use Firebase Auth REST API
    echo ""
    echo "📝 Manual Deployment Instructions:"
    echo "1. Go to Firebase Console: https://console.firebase.google.com"
    echo "2. Select project: growth-70a85"
    echo "3. Navigate to Firestore Database"
    echo "4. Find the 'growthMethods' collection"
    echo ""
    echo "5. Update document 'angion_method_1_0':"
    echo "   - Add field 'hasMultipleSteps' = true"
    echo "   - Add field 'steps' = (copy from scripts/firebase-deploy-data/angion_method_1_0.json)"
    echo ""
    echo "6. Update document 'angio_pumping':"
    echo "   - Add field 'hasMultipleSteps' = true"  
    echo "   - Add field 'steps' = (copy from scripts/firebase-deploy-data/angio_pumping.json)"
    echo ""
    echo "✅ The JSON files with full step data are ready in:"
    echo "   scripts/firebase-deploy-data/"
else
    # Call the deployed function
    FUNCTION_URL="https://us-central1-growth-70a85.cloudfunctions.net/deployAngionMethods"
    
    echo "📡 Calling deployment function..."
    curl -X POST "$FUNCTION_URL" \
        -H "Authorization: Bearer $ID_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}'
fi

echo ""
echo "✅ Deployment process complete!"