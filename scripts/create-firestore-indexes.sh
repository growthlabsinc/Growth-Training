#!/bin/bash
# Create Firestore Indexes for AI Coach Knowledge Base
# Story 3.3: Develop Training Protocol Knowledge

echo "🔥 Creating Firestore Indexes for AI Coach Knowledge Base"
echo "Project: growth-training-app"
echo ""

# Index for keywords search with priority ordering
echo "📋 Creating index: keywords (array) + priority (desc) + __name__ (asc)"
gcloud firestore indexes composite create \
  --collection-group=ai_coach_knowledge \
  --field-config=field-path=keywords,array-config=contains \
  --field-config=field-path=priority,order=descending \
  --field-config=field-path=__name__,order=ascending \
  --project=growth-training-app

# Index for category search with priority ordering
echo "📋 Creating index: category (asc) + priority (desc) + __name__ (asc)"
gcloud firestore indexes composite create \
  --collection-group=ai_coach_knowledge \
  --field-config=field-path=category,order=ascending \
  --field-config=field-path=priority,order=descending \
  --field-config=field-path=__name__,order=ascending \
  --project=growth-training-app

echo ""
echo "✅ Index creation commands sent to Firestore"
echo "⏳ Note: Indexes may take a few minutes to build"
echo "🔗 Check status at: https://console.firebase.google.com/project/growth-training-app/firestore/indexes"