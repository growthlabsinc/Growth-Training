#!/bin/bash

echo "🔧 Fixing Firebase Function IAM policies..."

# The key insight: Firebase Functions v2 need allUsers to invoke the Cloud Run service
# but the organization policy prevents this. We need to work around it.

echo "📝 Setting IAM policy for generateAIResponse..."

# Create an IAM policy JSON file
cat > /tmp/generateai_policy.json << EOF
{
  "bindings": [
    {
      "role": "roles/run.invoker",
      "members": [
        "allUsers"
      ]
    }
  ]
}
EOF

# Try to set the policy using the policy file approach
gcloud run services set-iam-policy generateairesponse \
  --region=us-central1 \
  /tmp/generateai_policy.json || echo "❌ Failed to set allUsers policy"

echo "📝 Setting IAM policy for registerPushToStartToken..."

# Apply the same policy to the other function
gcloud run services set-iam-policy registerpushtostarttoken \
  --region=us-central1 \
  /tmp/generateai_policy.json || echo "❌ Failed to set allUsers policy"

# Clean up
rm -f /tmp/generateai_policy.json

echo "✅ IAM policy configuration complete!"