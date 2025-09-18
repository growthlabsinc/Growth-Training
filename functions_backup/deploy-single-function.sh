#!/bin/bash

echo "Attempting to deploy manageLiveActivityUpdates function..."
echo "This may timeout, but the function might still deploy."
echo ""

# Try to deploy just the single function
timeout 30 firebase deploy --only functions:manageLiveActivityUpdates --force 2>&1 | grep -E "(Error|Success|deployed|failed|timeout)" || true

echo ""
echo "Checking deployment status..."
sleep 5

# Check if function is responding
echo ""
echo "Testing function endpoint..."
curl -s -X POST https://us-central1-growth-70a85.cloudfunctions.net/manageLiveActivityUpdates \
  -H "Content-Type: application/json" \
  -d '{"data":{"test":"true"}}' | head -1

echo ""
echo "To check if the fix is deployed, run:"
echo "firebase functions:log --lines 50 | grep 'Parse Error'"
echo ""
echo "If you see 'Parse Error: Expected HTTP/', the old code is still running."
echo "If you don't see this error, the new HTTP/2 code is deployed."