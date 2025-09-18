#!/bin/bash

echo "🤖 Quick AI Coach Knowledge Base Setup"
echo "====================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if we're logged in to Firebase
echo "📋 Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ You're not logged in to Firebase. Please run:"
    echo "   firebase login"
    exit 1
fi

echo "✅ Firebase authentication confirmed"
echo ""

# Set the project
echo "🔧 Setting Firebase project to growth-70a85..."
firebase use growth-70a85

echo ""
echo "📚 Running knowledge base update script..."
echo ""

# Run the update script
cd scripts
node update-ai-coach-knowledge.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Knowledge base setup completed successfully!"
    echo ""
    echo "The AI Coach now has access to all content in sample-resources.json including:"
    echo "- Understanding Vascular Health Fundamentals"
    echo "- Proper Technique Execution Guide"
    echo "- The Vascularity Progression Timeline"
    echo "- Common Abbreviations and Terminology (AM1, AM2, etc.)"
    echo "- Angion Methods Complete List"
    echo "- Hand Techniques Breakdown"
    echo "- Personal Journey experiences"
    echo "- AM 2.0 Erection Level Guidance"
    echo "- SABRE Techniques documentation"
    echo ""
    echo "Test it by asking the AI Coach questions like:"
    echo '- "What is AM1?"'
    echo '- "Explain Angion Method 1.0"'
    echo '- "What are the hand techniques for AM1?"'
else
    echo ""
    echo "❌ Knowledge base setup failed"
    echo ""
    echo "Common issues:"
    echo "1. Missing Firebase Admin credentials"
    echo "2. Incorrect project permissions"
    echo ""
    echo "To fix authentication issues:"
    echo "1. Go to Firebase Console > Project Settings > Service Accounts"
    echo "2. Generate a new private key"
    echo "3. Save it and run:"
    echo "   export GOOGLE_APPLICATION_CREDENTIALS='/path/to/serviceAccountKey.json'"
    echo "4. Then run this script again"
fi