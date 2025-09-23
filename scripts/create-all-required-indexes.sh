#!/bin/bash

# Script to create all required Firestore indexes for the Growth app
# Based on the original project's index requirements

echo "🔥 Creating All Required Firestore Indexes for Growth Training App"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}CURRENT INDEXES (Already Created):${NC}"
echo "✅ 1. sessionLogs: userId + startTime"
echo "✅ 2. session_logs: userId + createdAt"
echo "✅ 3. sessionLogs: userId + endTime"
echo "✅ 4. ai_coach_knowledge: category + priority"
echo ""

echo -e "${YELLOW}REQUIRED INDEXES TO CREATE:${NC}"
echo ""

# These are the actual composite index URLs that will pre-fill the fields
echo -e "${GREEN}Direct Links to Create Indexes:${NC}"
echo ""

echo "1. educationalResources: category + title"
echo "   URL to create:"
echo -e "${GREEN}   https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cm1wcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9lZHVjYXRpb25hbFJlc291cmNlcy9pbmRleGVzL18QARoMCghjYXRlZ29yeRABCgkKBXRpdGxlEAEaDAoIX19uYW1lX18QAQ${NC}"
echo ""

echo "2. gains_entries: userId + timestamp"
echo "   URL to create:"
echo -e "${GREEN}   https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9nYWluc19lbnRyaWVzL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGg0KCXRpbWVzdGFtcBAC${NC}"

echo ""
echo -e "${BLUE}Note: The 'goals' collection index is excluded as requested.${NC}"
echo ""

echo -e "${YELLOW}Instructions:${NC}"
echo "1. Command+Click (Mac) or Ctrl+Click (Windows/Linux) each green URL above"
echo "2. Each link will open in your browser with pre-filled fields"
echo "3. Just click 'Create Index' for each one"
echo "4. Wait for the indexes to build (usually takes 2-5 minutes)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to open Firebase Console
read -p "Do you want to open these links in your browser automatically? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Opening Firebase Console with pre-filled index configurations..."

    # Open educationalResources index
    open "https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cm1wcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9lZHVjYXRpb25hbFJlc291cmNlcy9pbmRleGVzL18QARoMCghjYXRlZ29yeRABCgkKBXRpdGxlEAEaDAoIX19uYW1lX18QAQ"

    sleep 2

    # Open gains_entries index
    open "https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9nYWluc19lbnRyaWVzL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGg0KCXRpbWVzdGFtcBAC"

    echo -e "${GREEN}✅ Links opened in browser with pre-filled fields${NC}"
    echo ""
    echo "Just click 'Create Index' in each tab!"
fi

echo ""
echo -e "${BLUE}📝 Index Usage Summary:${NC}"
echo ""
echo "• sessionLogs indexes: For querying user practice sessions"
echo "• educationalResources index: For filtering educational content"
echo "• gains_entries index: For tracking user measurements over time"
echo "• ai_coach_knowledge index: For AI coach knowledge base queries"
echo ""
echo "✨ Once all indexes are created, the app will have full query functionality!"