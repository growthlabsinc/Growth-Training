#!/bin/bash

# Script to fix Firebase Functions authentication issues
# This allows the generateAIResponse function to be called without authentication

PROJECT_ID="growth-70a85"
FUNCTION_NAME="generateAIResponse"
REGION="us-central1"

echo "Setting IAM policy for $FUNCTION_NAME to allow unauthenticated access..."

# Use gcloud to add allUsers binding for Cloud Functions Invoker role
# This allows the function to be called without authentication
gcloud functions add-iam-policy-binding $FUNCTION_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --member="allUsers" \
  --role="roles/cloudfunctions.invoker" \
  2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ Successfully updated IAM policy for $FUNCTION_NAME"
else
  echo "❌ Failed to update IAM policy. Trying alternative method..."
  
  # Alternative: Use Firebase CLI to update function
  firebase functions:config:set auth.allow_unauthenticated=true --project=$PROJECT_ID
fi

echo "Done!"