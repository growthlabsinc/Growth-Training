#\!/bin/bash

# Script to set up APNs configuration for Firebase Functions v2
# Usage: ./setup-apns-v2.sh

echo "🔧 Setting up APNs configuration for Firebase Functions v2..."

# Check if .env file exists
if [ \! -f .env ]; then
    echo "❌ .env file not found. Please create it first."
    exit 1
fi

# Source the .env file to get the values
set -a
source .env
set +a

# Validate that we have all required values
if [ -z "$APNS_TEAM_ID" ] || [ -z "$APNS_KEY_ID" ] || [ -z "$APNS_AUTH_KEY" ] || [ -z "$APNS_TOPIC" ]; then
    echo "❌ Missing required environment variables in .env file"
    echo "Please ensure the following are set:"
    echo "  - APNS_TEAM_ID"
    echo "  - APNS_KEY_ID"
    echo "  - APNS_AUTH_KEY"
    echo "  - APNS_TOPIC"
    exit 1
fi

echo "✅ Found APNs configuration in .env file"
echo "  - Team ID: $APNS_TEAM_ID"
echo "  - Key ID: $APNS_KEY_ID"
echo "  - Topic: $APNS_TOPIC"
echo "  - Auth Key: Present ($(echo "$APNS_AUTH_KEY" | wc -l) lines)"

# For Firebase Functions v2, we need to set these as environment variables in the project
echo ""
echo "📤 Setting Firebase environment configuration..."

# Set runtime environment variables for Functions v2
firebase functions:config:set \
  apns.team_id="$APNS_TEAM_ID" \
  apns.key_id="$APNS_KEY_ID" \
  apns.topic="$APNS_TOPIC"

# For the auth key, we need to be careful with newlines
# Save to a temporary file first
TEMP_KEY_FILE=$(mktemp)
echo "$APNS_AUTH_KEY" > "$TEMP_KEY_FILE"

# Read and set the key
firebase functions:config:set apns.auth_key="$(cat $TEMP_KEY_FILE)"

# Clean up
rm -f "$TEMP_KEY_FILE"

echo ""
echo "✅ APNs configuration set successfully\!"
echo ""
echo "Next steps:"
echo "1. Deploy the functions: firebase deploy --only functions"
echo "2. The functions will now have access to the APNs configuration"
echo ""
echo "Note: The .env file is used for local testing with the emulator."
echo "The config values are used in production."
