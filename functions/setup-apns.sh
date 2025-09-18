#!/bin/bash

# Setup script for APNs authentication in Firebase Functions

echo "APNs Setup for Live Activity Push Notifications"
echo "=============================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Your APNs configuration
TEAM_ID="62T6J77P6R"
KEY_ID="3G84L8G52R"

# Check if .p8 file path is provided as argument
if [ -z "$1" ]; then
    read -p "Enter the path to your .p8 APNs key file (e.g., /Users/tradeflowj/Downloads/AuthKey_3G84L8G52R.p8): " KEY_PATH
else
    KEY_PATH="$1"
fi

# Validate inputs
if [ ${#TEAM_ID} -ne 10 ]; then
    echo "Error: Team ID must be exactly 10 characters"
    exit 1
fi

if [ ${#KEY_ID} -ne 10 ]; then
    echo "Error: Key ID must be exactly 10 characters"
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "Error: APNs key file not found at $KEY_PATH"
    exit 1
fi

# Read the key file
KEY_CONTENT=$(cat "$KEY_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')

# Set Firebase Functions config
echo ""
echo "Setting Firebase Functions configuration..."

firebase functions:config:set \
    apns.team_id="$TEAM_ID" \
    apns.key_id="$KEY_ID" \
    apns.bundle_id="com.growth" \
    apns.topic="com.growth.push-type.liveactivity"

# Store the key in Google Secret Manager (more secure than config)
echo ""
echo "Storing APNs key in Google Secret Manager..."

# Create the secret
echo "$KEY_CONTENT" | gcloud secrets create apns-auth-key \
    --data-file=- \
    --replication-policy="automatic" \
    --project=growth-70a85 \
    2>/dev/null || echo "Secret already exists, updating..."

# Update if it already exists
echo "$KEY_CONTENT" | gcloud secrets versions add apns-auth-key \
    --data-file=- \
    --project=growth-70a85

# Grant Firebase Functions access to the secret
gcloud secrets add-iam-policy-binding apns-auth-key \
    --member="serviceAccount:growth-70a85@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=growth-70a85

echo ""
echo "✅ APNs configuration complete!"
echo ""
echo "Next steps:"
echo "1. Update functions/liveActivityUpdates.js to use Secret Manager"
echo "2. Deploy functions: firebase deploy --only functions"
echo "3. Test Live Activity push notifications"