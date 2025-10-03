#!/bin/bash

# Deploy Firebase Functions with environment variables for APNs

echo "🚀 Deploying Firebase Functions with APNs configuration..."

# Source the .env file
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "✅ Loaded configuration from .env file"
else
    echo "❌ .env file not found"
    exit 1
fi

# Deploy with environment variables
firebase deploy --only functions \
  --set-env-vars APNS_TEAM_ID="$APNS_TEAM_ID",APNS_KEY_ID="$APNS_KEY_ID",APNS_TOPIC="$APNS_TOPIC",APNS_AUTH_KEY="$APNS_AUTH_KEY"

echo "✅ Deployment complete!"