#!/bin/bash

echo "=== Testing AI Coach Function ==="
echo ""
echo "This script will test if the function is now accessible."
echo ""

# Test with curl (should now work with the IAM bindings)
echo "Testing direct HTTP call..."
curl -X POST https://us-central1-growth-70a85.cloudfunctions.net/generateAIResponse \
  -H "Content-Type: application/json" \
  -d '{"data":{"query":"Hello"}}' \
  -w "\n\nHTTP Status: %{http_code}\n" \
  2>/dev/null

echo ""
echo "Expected results:"
echo "- If you see 'UNAUTHENTICATED' with HTTP 200, the IAM fix worked!"
echo "- The function is now accessible, but still requires Firebase auth"
echo "- Your app should now work properly when authenticated"