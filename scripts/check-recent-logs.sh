#!/bin/bash

# Get Firebase logs for errors from last 24 hours
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

# Get timestamp for 24 hours ago
TIMESTAMP_24H=$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ')

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://logging.googleapis.com/v2/entries:list" \
  -d "{
    \"resourceNames\": [\"projects/growth-training-app\"],
    \"filter\": \"severity>=WARNING AND timestamp>=\\\"$TIMESTAMP_24H\\\"\",
    \"orderBy\": \"timestamp desc\",
    \"pageSize\": 30
  }" > /tmp/firebase-recent-logs.json

echo "📋 Firebase Errors/Warnings (Last 24 Hours):"
echo "============================================"
python3 << 'EOF'
import json
from collections import defaultdict

with open('/tmp/firebase-recent-logs.json') as f:
    data = json.load(f)

entries = data.get('entries', [])
print(f"\nTotal entries found: {len(entries)}\n")

if not entries:
    print("✅ No errors or warnings in the last 24 hours!")
else:
    # Group by function
    by_function = defaultdict(list)

    for entry in entries:
        resource = entry.get('resource', {})
        labels = resource.get('labels', {})
        function_name = labels.get('function_name') or labels.get('service_name') or 'unknown'
        by_function[function_name].append(entry)

    # Print summary
    print("📊 Summary by Function:")
    print("-" * 50)
    for func, func_entries in sorted(by_function.items(), key=lambda x: len(x[1]), reverse=True):
        error_count = sum(1 for e in func_entries if e.get('severity') == 'ERROR')
        warning_count = sum(1 for e in func_entries if e.get('severity') == 'WARNING')
        print(f"  {func}:")
        print(f"    ERROR: {error_count}, WARNING: {warning_count}, Total: {len(func_entries)}")
    print()

    # Print first 5 most recent
    print("🔴 Most Recent Issues:")
    print("-" * 50)
    for i, entry in enumerate(entries[:5], 1):
        severity = entry.get('severity', 'N/A')
        timestamp = entry.get('timestamp', 'N/A')

        message = (entry.get('textPayload') or
                  entry.get('jsonPayload', {}).get('message') or
                  str(entry.get('jsonPayload', {}))[:200] or
                  'No message')

        resource = entry.get('resource', {})
        labels = resource.get('labels', {})
        function_name = labels.get('function_name') or labels.get('service_name') or 'unknown'

        print(f"\n{i}. [{severity}] {timestamp}")
        print(f"   Function: {function_name}")
        print(f"   Message: {message[:300]}")
EOF
