#!/bin/bash

# Script to configure App Store Connect API credentials in Firebase Functions
# Usage: ./scripts/configure-appstore-connect.sh

set -e

echo "🔐 Configuring App Store Connect API for Firebase Functions..."

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
else
    echo "❌ .env.local file not found. Please create it first."
    exit 1
fi

# Validate required variables
if [ -z "$APP_STORE_CONNECT_KEY_ID" ]; then
    echo "❌ APP_STORE_CONNECT_KEY_ID not set in .env.local"
    exit 1
fi

if [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    echo "❌ APP_STORE_CONNECT_ISSUER_ID not set in .env.local"
    exit 1
fi

if [ ! -f "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo "❌ Private key file not found at $APP_STORE_CONNECT_PRIVATE_KEY_PATH"
    exit 1
fi

echo "✅ Environment variables loaded successfully"
echo "   Key ID: $APP_STORE_CONNECT_KEY_ID"
echo "   Issuer ID: $APP_STORE_CONNECT_ISSUER_ID"
echo "   Key Path: $APP_STORE_CONNECT_PRIVATE_KEY_PATH"

# Copy the private key to Firebase functions directory
echo ""
echo "📋 Copying private key to functions directory..."
mkdir -p functions/keys
cp "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" "functions/keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"
chmod 600 "functions/keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"

# Set Firebase Functions configuration
echo ""
echo "🔧 Setting Firebase Functions configuration..."

# Note: APP_STORE_SHARED_SECRET should be set after obtaining it from App Store Connect
if [ ! -z "$APP_STORE_SHARED_SECRET" ]; then
    firebase functions:config:set \
        appstore.key_id="$APP_STORE_CONNECT_KEY_ID" \
        appstore.issuer_id="$APP_STORE_CONNECT_ISSUER_ID" \
        appstore.shared_secret="$APP_STORE_SHARED_SECRET"
else
    echo "⚠️  APP_STORE_SHARED_SECRET not set. Setting partial configuration..."
    firebase functions:config:set \
        appstore.key_id="$APP_STORE_CONNECT_KEY_ID" \
        appstore.issuer_id="$APP_STORE_CONNECT_ISSUER_ID"
    echo ""
    echo "📝 Note: You'll need to add the shared secret later using:"
    echo "   firebase functions:config:set appstore.shared_secret='YOUR_SECRET'"
fi

# Verify configuration
echo ""
echo "🔍 Verifying Firebase Functions configuration..."
firebase functions:config:get appstore

echo ""
echo "✅ App Store Connect API configuration complete!"
echo ""
echo "📝 Next steps:"
echo "1. Log into App Store Connect"
echo "2. Create the app with bundle ID: com.growthlabs.growthmethod"
echo "3. Generate a shared secret for subscriptions"
echo "4. Update .env.local with APP_STORE_SHARED_SECRET"
echo "5. Run this script again to update the configuration"
echo ""
echo "⚠️  Remember: Never commit .env.local or .keys/ directory to Git!"