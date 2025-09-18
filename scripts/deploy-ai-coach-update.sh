#!/bin/bash

# Script to update AI Coach knowledge base and deploy functions

echo "🤖 AI Coach Knowledge Base Update Script"
echo "======================================="
echo ""

# Check if we're in the right directory
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Step 1: Update the knowledge base in Firestore
echo "📚 Step 1: Updating knowledge base in Firestore..."
echo ""

cd scripts
node update-ai-coach-knowledge.js

if [ $? -ne 0 ]; then
    echo "❌ Failed to update knowledge base"
    exit 1
fi

cd ..

echo ""
echo "✅ Knowledge base updated successfully!"
echo ""

# Step 2: Deploy Firebase Functions
echo "🚀 Step 2: Deploying Firebase Functions..."
echo ""

firebase deploy --only functions:generateAIResponse

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Firebase Functions"
    exit 1
fi

echo ""
echo "✅ Firebase Functions deployed successfully!"
echo ""

echo "🎉 AI Coach update complete!"
echo ""
echo "Test the AI Coach with these sample questions:"
echo "- What is the vascularity progression timeline?"
echo "- Explain AM 2.0 erection level"
echo "- What are SABRE techniques?"
echo "- Tell me about common abbreviations like AM, BFR, CC"
echo "- How do I perform Angion Method 1.0?"
echo "- What's the difference between the hand techniques in AM1, AM2, and Vascion?"
echo ""
echo "Note: It may take a few minutes for the changes to propagate."