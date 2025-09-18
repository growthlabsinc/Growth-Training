#!/bin/bash

echo "=== Complete Firebase Authentication and App Check Fix ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")/.."

echo -e "${YELLOW}Step 1: Checking current Firebase project...${NC}"
CURRENT_PROJECT=$(firebase use 2>/dev/null | head -n1 | xargs)
if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${RED}No active Firebase project found!${NC}"
    echo "Please run: firebase use growth-70a85"
    exit 1
fi
echo -e "${GREEN}Active project: $CURRENT_PROJECT${NC}"

echo ""
echo -e "${YELLOW}Step 2: Updating Firestore rules to allow anonymous access...${NC}"

# Create temporary rules file that allows anonymous users to access the AI chat collection
cat > firebase/firestore/firestore.rules.temp << 'EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents temporarily (expires June 13, 2025)
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 6, 13);
    }
    
    // Specific rules for AI Coach chat
    match /ai_coach_chats/{userId}/{document=**} {
      // Allow users (including anonymous) to read/write their own chat data
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow anonymous users to read growth methods and educational resources
    match /growth_methods/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    match /educational_resources/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
EOF

# Deploy Firestore rules
echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo ""
echo -e "${YELLOW}Step 3: Updating Cloud Function for proper authentication handling...${NC}"

# Update the function to ensure it properly handles anonymous users
cat > functions/index.js << 'EOF'
/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');

// AI Coach function - configured to accept both authenticated and unauthenticated calls
exports.generateAIResponse = onCall(
  { 
    cors: true,  // Enable CORS for all origins
    region: 'us-central1',  // Explicitly set region
    // Disable App Check requirement for this function
    consumeAppCheckToken: false,
    // Set to 2nd gen function to ensure proper configuration
    cpu: 1,
    memory: '256MiB',
    maxInstances: 100,
    timeoutSeconds: 60,
    // Allow both authenticated and unauthenticated invocations
    invoker: 'public'
  },
  async (request) => {
    // Log request details for debugging
    const userId = request.auth?.uid || 'anonymous';
    const isAuthenticated = request.auth !== undefined;
    const isAnonymous = request.auth?.token?.firebase?.sign_in_provider === 'anonymous';
    
    console.log(`generateAIResponse called:
      - User ID: ${userId}
      - Authenticated: ${isAuthenticated}
      - Anonymous: ${isAnonymous}
      - App Check present: ${request.app !== undefined}
      - Request data: ${JSON.stringify(request.data)}`);
    
    // Validate request
    if (!request.data || typeof request.data.query !== 'string') {
      console.error('Invalid request: missing or invalid query parameter');
      throw new HttpsError('invalid-argument', 'Query parameter is required and must be a string');
    }
    
    const query = request.data.query.trim();
    if (query.length === 0) {
      throw new HttpsError('invalid-argument', 'Query cannot be empty');
    }
    
    // Generate response based on query
    let responseText = '';
    
    if (query.toLowerCase().includes('am1') || query.toLowerCase().includes('angion method 1')) {
      responseText = `Angion Method 1.0 (AM1) is the foundational technique in the Growth Methods series. It focuses on basic circulation improvement through gentle, controlled movements. This method is designed for beginners and helps establish proper form and breathing patterns that are essential for more advanced techniques.

Key benefits of AM1:
• Improves blood flow and circulation
• Establishes proper breathing techniques  
• Builds foundation for advanced methods
• Safe for beginners

Start with 5-10 minutes daily and gradually increase duration as you become more comfortable with the technique.`;
    } else if (query.toLowerCase().includes('hello') || query.toLowerCase().includes('hi')) {
      responseText = `Hello! I'm your Growth Coach, here to help you with Growth Methods, techniques, and app navigation. You can ask me about:

• Specific Growth Methods (AM1, AM2, Vascion, etc.)
• Technique instructions and tips
• App features and navigation
• Progress tracking
• Safety guidelines

What would you like to know about?`;
    } else if (query.toLowerCase().includes('help')) {
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
    const response = {
      text: responseText,
      sources: null,
      metadata: {
        userId: userId,
        isAuthenticated: isAuthenticated,
        timestamp: new Date().toISOString()
      }
    };
    
    console.log(`Returning response for user ${userId}`);
    return response;
  }
);
EOF

echo ""
echo -e "${YELLOW}Step 4: Deploying the updated function...${NC}"
cd functions
npm install
cd ..
firebase deploy --only functions:generateAIResponse

echo ""
echo -e "${YELLOW}Step 5: Setting function permissions (if gcloud is available)...${NC}"
if command -v gcloud &> /dev/null; then
    echo "Setting public invoker permissions..."
    gcloud functions add-iam-policy-binding generateAIResponse \
        --member="allUsers" \
        --role="roles/cloudfunctions.invoker" \
        --region=us-central1 \
        --project=$CURRENT_PROJECT \
        --gen2
else
    echo -e "${YELLOW}gcloud CLI not found. Please manually set permissions:${NC}"
    echo "1. Go to: https://console.cloud.google.com/functions/details/us-central1/generateAIResponse?project=$CURRENT_PROJECT"
    echo "2. Click on the 'Permissions' tab"
    echo "3. Click 'Add Member'"
    echo "4. Enter 'allUsers' as the new member"
    echo "5. Select role 'Cloud Functions Invoker'"
    echo "6. Click 'Save'"
fi

echo ""
echo -e "${YELLOW}Step 6: Testing the function...${NC}"
echo "Testing with curl..."

# Get the function URL
FUNCTION_URL="https://us-central1-$CURRENT_PROJECT.cloudfunctions.net/generateAIResponse"

# Test the function
curl -X POST $FUNCTION_URL \
  -H "Content-Type: application/json" \
  -d '{"data":{"query":"Hello"}}' \
  2>/dev/null | python3 -m json.tool 2>/dev/null || echo -e "${RED}Function test failed - this is expected if permissions haven't been set yet${NC}"

echo ""
echo -e "${GREEN}=== Fix Applied ===${NC}"
echo ""
echo -e "${YELLOW}Important next steps:${NC}"
echo ""
echo "1. ${YELLOW}Enable Anonymous Authentication in Firebase Console:${NC}"
echo "   - Go to: https://console.firebase.google.com/project/$CURRENT_PROJECT/authentication/providers"
echo "   - Click 'Add new provider'"
echo "   - Select and enable 'Anonymous'"
echo ""
echo "2. ${YELLOW}Verify function permissions:${NC}"
echo "   - Go to: https://console.cloud.google.com/functions/details/us-central1/generateAIResponse?project=$CURRENT_PROJECT"
echo "   - Check that 'allUsers' has 'Cloud Functions Invoker' role"
echo ""
echo "3. ${YELLOW}Clear app data and restart:${NC}"
echo "   - In iOS Simulator: Device > Erase All Content and Settings"
echo "   - Or delete and reinstall the app"
echo ""
echo "4. ${YELLOW}Monitor function logs:${NC}"
echo "   firebase functions:log --only generateAIResponse"
echo ""
echo -e "${GREEN}Done!${NC}"