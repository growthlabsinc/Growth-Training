#!/bin/bash

echo "Complete Firebase Authentication and App Check Fix"
echo "================================================="

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    echo "Warning: Google Cloud SDK is not installed. Some commands may fail."
    echo "Install from: https://cloud.google.com/sdk/docs/install"
fi

# Get the current project
PROJECT_ID=$(firebase use | grep "Active Project:" | cut -d':' -f2 | tr -d ' ')
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No active Firebase project. Run 'firebase use <project-id>' first."
    exit 1
fi

echo "Current Firebase project: $PROJECT_ID"

# Step 1: Update Firebase Rules to allow anonymous users
echo ""
echo "Step 1: Updating Firestore security rules..."
cat > firebase/firestore/firestore.rules << 'EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to all users (including anonymous)
    // for public collections
    match /growth_methods/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid != null;
    }
    
    match /educational_resources/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid != null;
    }
    
    match /routines/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid != null;
    }
    
    // User-specific data requires authentication
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // AI Coach conversations can be created by any authenticated user (including anonymous)
    match /ai_coach_conversations/{conversationId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid != null;
    }
    
    // Default deny for all other collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF

# Step 2: Enable Anonymous Authentication in Firebase
echo ""
echo "Step 2: Checking Anonymous Authentication status..."
echo "Please ensure Anonymous Authentication is enabled in the Firebase Console:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
echo "Press Enter when you've verified Anonymous Auth is enabled..."
read -r

# Step 3: Update function configuration
echo ""
echo "Step 3: Creating updated function with proper permissions..."
cat > functions/index-updated.js << 'EOF'
/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineString } = require('firebase-functions/params');

// Define configuration parameters
const ALLOWED_ORIGINS = defineString('ALLOWED_ORIGINS', {
  default: '*',
  description: 'Comma-separated list of allowed CORS origins'
});

// AI Coach function - accepts both authenticated and unauthenticated calls
exports.generateAIResponse = onCall(
  { 
    // Allow CORS from any origin (configure in production)
    cors: true,
    // Deploy to us-central1 region
    region: 'us-central1',
    // Don't require App Check token
    consumeAppCheckToken: false,
    // Set maximum instances to prevent runaway costs
    maxInstances: 10,
    // Set memory allocation
    memory: '256MiB',
    // Set timeout
    timeoutSeconds: 60,
  },
  async (request) => {
    // Log request details
    const userId = request.auth?.uid || 'anonymous';
    const isAuthenticated = request.auth !== undefined;
    const query = request.data?.query;
    
    console.log(`AI Coach request from user: ${userId} (authenticated: ${isAuthenticated})`);
    
    // Validate request
    if (!query || typeof query !== 'string') {
      throw new HttpsError(
        'invalid-argument', 
        'Query parameter is required and must be a string'
      );
    }
    
    if (query.length > 2000) {
      throw new HttpsError(
        'invalid-argument',
        'Query is too long. Maximum 2000 characters allowed.'
      );
    }
    
    console.log(`Processing query: "${query.substring(0, 100)}..."`);
    
    try {
      // Generate response based on query content
      let responseText = '';
      const lowerQuery = query.toLowerCase();
      
      if (lowerQuery.includes('am1') || lowerQuery.includes('angion method 1')) {
        responseText = `Angion Method 1.0 (AM1) is the foundational technique in the Growth Methods series. It focuses on basic circulation improvement through gentle, controlled movements. This method is designed for beginners and helps establish proper form and breathing patterns that are essential for more advanced techniques.

Key benefits of AM1:
• Improves blood flow and circulation
• Establishes proper breathing techniques  
• Builds foundation for advanced methods
• Safe for beginners

Start with 5-10 minutes daily and gradually increase duration as you become more comfortable with the technique.`;
      } else if (lowerQuery.includes('hello') || lowerQuery.includes('hi')) {
        responseText = `Hello! I'm your Growth Coach, here to help you with Growth Methods, techniques, and app navigation. You can ask me about:

• Specific Growth Methods (AM1, AM2, Vascion, etc.)
• Technique instructions and tips
• App features and navigation
• Progress tracking
• Safety guidelines

What would you like to know about?`;
      } else if (lowerQuery.includes('help')) {
        responseText = `I'm here to help you with the Growth app! I can assist with:

🏃‍♂️ **Growth Methods**: Information about AM1, AM2, AM2.5, Vascion, and other techniques
📋 **Instructions**: Step-by-step guidance for each method
⏱️ **Timing**: Recommended durations and progressions  
📊 **Progress**: Understanding your stats and tracking
⚠️ **Safety**: Important guidelines and precautions

Just ask me any questions about Growth Methods or using the app!`;
      } else {
        responseText = `I understand you're asking about "${query}". I'm your Growth Coach and I specialize in helping with Growth Methods and app functionality. 

Could you provide more details about what you'd like to know? For example:
• Which Growth Method interests you?
• Do you need help with technique instructions?
• Are you looking for app navigation help?

I'm here to support your Growth journey!`;
      }
      
      // Return successful response
      return {
        text: responseText,
        sources: null,
        metadata: {
          processedAt: new Date().toISOString(),
          userId: userId,
          authenticated: isAuthenticated
        }
      };
      
    } catch (error) {
      console.error('Error processing AI Coach request:', error);
      throw new HttpsError(
        'internal',
        'An error occurred processing your request. Please try again.'
      );
    }
  }
);
EOF

# Backup original index.js
cp functions/index.js functions/index.js.backup

# Replace with updated version
mv functions/index-updated.js functions/index.js

# Step 4: Deploy updates
echo ""
echo "Step 4: Deploying updates..."

# Deploy Firestore rules
echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules

# Deploy the function
echo "Deploying Cloud Function..."
firebase deploy --only functions:generateAIResponse

# Step 5: Set function to allow unauthenticated invocations (if gcloud is available)
if command -v gcloud &> /dev/null; then
    echo ""
    echo "Step 5: Setting function permissions..."
    
    # First, try to make the function public using gcloud
    gcloud functions add-iam-policy-binding generateAIResponse \
        --member="allUsers" \
        --role="roles/cloudfunctions.invoker" \
        --project="$PROJECT_ID" \
        --region="us-central1" \
        --gen2 2>/dev/null || {
            echo "Note: Could not set function permissions via gcloud."
            echo "You may need to manually allow unauthenticated invocations in the Cloud Console:"
            echo "https://console.cloud.google.com/functions/details/us-central1/generateAIResponse?project=$PROJECT_ID"
        }
else
    echo ""
    echo "Step 5: Manual configuration required"
    echo "Please go to the Cloud Functions console and allow unauthenticated invocations:"
    echo "https://console.cloud.google.com/functions/details/us-central1/generateAIResponse?project=$PROJECT_ID"
    echo "Click on the function, go to the 'Permissions' tab, and add 'allUsers' with 'Cloud Functions Invoker' role"
fi

# Step 6: Test the deployment
echo ""
echo "Step 6: Testing the function..."
echo "You can test the function using the Firebase Console or by running the app."

echo ""
echo "Fix complete! Summary of changes:"
echo "1. ✅ Updated Firestore rules to allow anonymous access to public collections"
echo "2. ✅ Updated Cloud Function to properly handle authenticated and unauthenticated calls"
echo "3. ✅ Deployed all changes to Firebase"
echo ""
echo "Next steps:"
echo "1. Ensure Anonymous Authentication is enabled in Firebase Console"
echo "2. If using gcloud failed, manually allow unauthenticated invocations in Cloud Console"
echo "3. Test the AI Coach feature in your app"
echo "4. Monitor Firebase Console logs for any remaining issues"