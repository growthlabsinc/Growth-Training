#!/bin/bash

echo "🤖 AI Coach Knowledge Base Deployment"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Step 1: Check Firebase authentication
echo "📋 Step 1: Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ You're not logged in to Firebase${NC}"
    echo "Please run: firebase login"
    exit 1
fi
echo -e "${GREEN}✅ Firebase authentication confirmed${NC}"

# Step 2: Set the project
echo ""
echo "🔧 Step 2: Setting Firebase project..."
firebase use growth-70a85
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set Firebase project${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Project set to growth-70a85${NC}"

# Step 3: Check for Google Application Default Credentials
echo ""
echo "🔑 Step 3: Checking authentication for Firestore access..."

# Try to set up application default credentials
gcloud auth application-default print-access-token > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Application Default Credentials not found${NC}"
    echo ""
    echo "Setting up authentication..."
    echo "This will open a browser window for authentication."
    echo ""
    
    # Try to set up ADC
    gcloud auth application-default login
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to set up authentication${NC}"
        echo ""
        echo "Alternative: Use a service account key"
        echo "1. Go to Firebase Console > Project Settings > Service Accounts"
        echo "2. Generate a new private key"
        echo "3. Run: export GOOGLE_APPLICATION_CREDENTIALS='/path/to/key.json'"
        echo "4. Then run this script again"
        exit 1
    fi
fi
echo -e "${GREEN}✅ Authentication configured${NC}"

# Step 4: Deploy Firestore rules
echo ""
echo "📜 Step 4: Deploying Firestore security rules..."
firebase deploy --only firestore:rules
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Failed to deploy Firestore rules${NC}"
    echo "The knowledge base will still work, but security rules may not be updated"
else
    echo -e "${GREEN}✅ Firestore rules deployed${NC}"
fi

# Step 5: Run the knowledge base setup
echo ""
echo "📚 Step 5: Populating knowledge base..."
echo ""

cd scripts
node setup-firestore-knowledge-base.js

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Failed to populate knowledge base${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Authentication problems - try the service account method"
    echo "2. Network issues - check your internet connection"
    echo "3. Permissions - ensure your account has Firestore access"
    exit 1
fi

cd ..

# Step 6: Deploy Firebase Functions
echo ""
echo "🚀 Step 6: Deploying updated Firebase Functions..."
firebase deploy --only functions:generateAIResponse

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy Firebase Functions${NC}"
    echo "The knowledge base is set up, but the AI Coach may not use it until functions are deployed"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Firebase Functions deployed successfully!${NC}"

# Success message
echo ""
echo "🎉 Knowledge Base Setup Complete!"
echo "================================"
echo ""
echo "The AI Coach now has access to all content including:"
echo "• Understanding Vascular Health Fundamentals"
echo "• Proper Technique Execution Guide"
echo "• The Vascularity Progression Timeline"
echo "• Common Abbreviations (AM1, AM2, CS, CC, etc.)"
echo "• Complete Angion Methods List with detailed instructions"
echo "• Hand Techniques Breakdown"
echo "• Personal Journey experiences"
echo "• AM 2.0 Erection Level Guidance"
echo "• SABRE Techniques documentation"
echo "• Path of the Eleven workout plan"
echo "• User feedback and FAQs"
echo ""
echo "📱 Test it in the app by asking:"
echo '• "What is AM1?"'
echo '• "How do I perform Angion Method 1.0?"'
echo '• "Explain the hand techniques for AM1"'
echo '• "What does CS mean?"'
echo '• "What are SABRE techniques?"'
echo '• "What is the vascularity progression timeline?"'
echo ""
echo -e "${YELLOW}Note: It may take 1-2 minutes for all changes to propagate${NC}"