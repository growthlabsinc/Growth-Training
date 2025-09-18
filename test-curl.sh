#!/bin/bash

# Development push token
PUSH_TOKEN="806694954f389a10eed7d0051e467a96100dbbfe3d19bc8ce0f2c324e40a926d67dc2279c9a9e73ff1688558696e9829fad3d27d9e3ab982836782055800da888bd660b1382f8f55ef0cc8f09e1af600"
ACTIVITY_ID="DEV-TEST-$(date +%s)"

# Prepare the request data
REQUEST_DATA=$(cat <<EOF
{
  "data": {
    "pushToken": "$PUSH_TOKEN",
    "activityId": "$ACTIVITY_ID"
  }
}
EOF
)

echo "🚀 Testing callable function with curl..."
echo "Activity ID: $ACTIVITY_ID"
echo "Push Token: ${PUSH_TOKEN:0:20}..."
echo ""

# Call the function
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_DATA" \
  "https://collectapnsdiagnostics-7lb4hvy3wa-uc.a.run.app")

echo "Response: $RESPONSE"

# Parse the response with jq if available
if command -v jq &> /dev/null; then
  echo ""
  echo "=== PARSED RESULTS ==="
  echo "$RESPONSE" | jq -r '
    if .result.diagnostics then
      "✅ APNs Status: \(.result.diagnostics.statusCode)
🔑 Key ID: \(.result.diagnostics.keyId)
👥 Team ID: \(.result.diagnostics.teamId)
📦 Bundle ID: \(.result.diagnostics.bundleId)
📄 Response: \(.result.diagnostics.responseBody)"
    else
      "Error: \(.error.message // "Unknown error")"
    end
  '
fi