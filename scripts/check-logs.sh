#!/bin/bash

# Get Firebase logs for errors
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://logging.googleapis.com/v2/entries:list" \
  -d '{
    "resourceNames": ["projects/growth-training-app"],
    "filter": "severity>=ERROR",
    "orderBy": "timestamp desc",
    "pageSize": 10
  }' > /tmp/firebase-logs.json

echo "📋 Recent Firebase Errors:"
echo "========================="
python3 << 'EOF'
import json

with open('/tmp/firebase-logs.json') as f:
    data = json.load(f)

entries = data.get('entries', [])
print(f"\nTotal error entries found: {len(entries)}\n")

if not entries:
    print("✅ No errors found!")
else:
    for i, entry in enumerate(entries[:10], 1):
        severity = entry.get('severity', 'N/A')
        timestamp = entry.get('timestamp', 'N/A')

        # Try to get message from different possible locations
        message = (entry.get('textPayload') or
                  entry.get('jsonPayload', {}).get('message') or
                  entry.get('protoPayload', {}).get('status', {}).get('message') or
                  'No message')

        # Get function name if available
        resource = entry.get('resource', {})
        labels = resource.get('labels', {})
        function_name = labels.get('function_name') or labels.get('service_name') or 'unknown'

        print(f"{i}. [{severity}] {timestamp}")
        print(f"   Function: {function_name}")
        print(f"   Message: {message[:200]}")
        print()
EOF
