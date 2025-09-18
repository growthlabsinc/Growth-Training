#\!/bin/bash

# Since we know the timer is running with activity ID 55D2E17F-D280-474F-8DFB-C55611A10120
# Let's assume a test push token format (we need the actual one from your device)

# Use a placeholder token for testing
PUSH_TOKEN="YOUR_ACTUAL_PUSH_TOKEN_HERE"
ACTIVITY_ID="55D2E17F-D280-474F-8DFB-C55611A10120"

# Get an ID token for authentication (using gcloud)
ID_TOKEN=$(gcloud auth print-identity-token)

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
