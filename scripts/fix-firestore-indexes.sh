#!/bin/bash

# Script to fix Firestore indexes for the Growth app

echo "🔥 Firestore Index Configuration for Growth Training App"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}CURRENT SITUATION:${NC}"
echo ""
echo "Based on your Firebase Console screenshot:"
echo -e "${RED}❌ Unused Index:${NC} session_logs with userId + createdAt (ID: ClCAgQi3kJAK)"
echo "   - This field 'createdAt' is NOT used in the code"
echo "   - This index can be DELETED"
echo ""
echo -e "${BLUE}🔨 Building Index:${NC} sessionLogs with userId + startTime (ID: ClCAgJm14AK)"
echo "   - This is CORRECT and needed for WeekCalendarViewModel queries"
echo "   - Keep this one!"
echo ""
echo -e "${YELLOW}⚠️  Missing Index:${NC} You still need to create one more index"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}REQUIRED INDEXES:${NC}"
echo ""
echo "The app needs these TWO indexes on the sessionLogs collection:"
echo ""
echo "1. ✅ Index for start time queries (WeekCalendarViewModel, FirestoreService)"
echo "   Collection: sessionLogs"
echo "   Fields: userId (Ascending) + startTime (Ascending)"
echo "   Status: Currently building (ClCAgJm14AK)"
echo ""
echo "2. ❌ Index for end time queries (StreakTracker, ProgressViewModel)"
echo "   Collection: sessionLogs"
echo "   Fields: userId (Ascending) + endTime (Descending)"
echo "   Status: NEEDS TO BE CREATED"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}ACTION ITEMS:${NC}"
echo ""
echo "1. DELETE the unused index with 'createdAt' field (ClCAgQi3kJAK)"
echo "   - Go to Firebase Console > Firestore > Indexes"
echo "   - Find the index with userId + createdAt"
echo "   - Click the 3-dot menu and select 'Delete'"
echo ""
echo "2. CREATE the missing endTime index:"
echo "   URL to create:"
echo -e "${GREEN}   https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cldwcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zZXNzaW9uTG9ncy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoLCgdlbmRUaW1lEAIaDAoIX19uYW1lX18QAg${NC}"
echo ""
echo "3. WAIT for the index that's currently building to complete (ClCAgJm14AK)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to open the link
read -p "Do you want to open Firebase Console to create the missing index? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Opening Firebase Console..."
    open "https://console.firebase.google.com/v1/r/project/growth-training-app/firestore/indexes?create_composite=Cldwcm9qZWN0cy9ncm93dGgtdHJhaW5pbmctYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zZXNzaW9uTG9ncy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoLCgdlbmRUaW1lEAIaDAoIX19uYW1lX18QAg"
    echo -e "${GREEN}✅ Link opened in browser${NC}"
fi

echo ""
echo -e "${BLUE}📝 Summary of SessionLog fields used in queries:${NC}"
echo "   • userId - User identifier"
echo "   • startTime - When the session started (Date/Timestamp)"
echo "   • endTime - When the session ended (Date/Timestamp)"
echo "   • duration - Session duration in minutes (Int)"
echo ""
echo "The 'createdAt' field is NOT part of the SessionLog model"
echo "and is not used anywhere in the codebase."
echo ""
echo "✨ Once both indexes are ready, all query errors will be resolved!"