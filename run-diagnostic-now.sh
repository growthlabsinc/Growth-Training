#!/bin/bash

# APNs Diagnostic Script
# Using the push token from the Live Activity just started

PUSH_TOKEN="801003ba001eb0f19f11bce3b057d0d69dc1c959c7eeb16a3156008452e4d781cac311e2c279c4dae7b05fb921a9bd5cd2b6f6c959d1e1b459159070e7dab6762c18fc75c05405d21551c1666ca2a29b"
ACTIVITY_ID="9FFAEB73-FEFC-4CB7-BE64-F57BCB9D9477"

echo "Running APNs diagnostic..."
echo "Push Token: ${PUSH_TOKEN:0:20}..."
echo "Activity ID: $ACTIVITY_ID"

# Get ID token for authentication
ID_TOKEN=$(gcloud auth print-identity-token 2>/dev/null)

if [ -z "$ID_TOKEN" ]; then
    echo "Error: Could not get auth token. Make sure you're logged in with gcloud"
    exit 1
fi

# Call the diagnostic function
curl -X POST https://collectapnsdiagnostics-i7nqvdntua-uc.a.run.app \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "pushToken": "'$PUSH_TOKEN'",
      "activityId": "'$ACTIVITY_ID'"
    }
  }'

echo ""
echo "Diagnostic request sent. Check Firebase logs for results:"
echo "firebase functions:log --only collectAPNsDiagnostics --lines 200"