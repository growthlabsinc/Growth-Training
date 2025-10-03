#!/bin/bash

# Firebase Functions Configuration Script for App Store Connect
# This script configures Firebase Functions with App Store Connect credentials

set -e

echo "🔧 Firebase Functions Configuration for App Store Connect"
echo "========================================================"

# Check if firebase-tools is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ firebase-tools is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if we're in the functions directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the functions directory"
    exit 1
fi

# Source environment variables if .env exists
if [ -f "config/.env" ]; then
    echo "📄 Loading configuration from .env file..."
    export $(grep -v '^#' config/.env | xargs)
else
    echo "❌ No .env file found. Please copy .env.template to .env and fill in your values"
    exit 1
fi

# Validate required variables
required_vars=(
    "APPSTORE_KEY_ID"
    "APPSTORE_ISSUER_ID"
    "APPSTORE_BUNDLE_ID"
    "APPSTORE_SHARED_SECRET"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

echo "✅ All required variables found"

# Configure Firebase Functions environment
echo ""
echo "🚀 Configuring Firebase Functions environment..."

# Set App Store Connect configuration
firebase functions:config:set \
    appstore.key_id="$APPSTORE_KEY_ID" \
    appstore.issuer_id="$APPSTORE_ISSUER_ID" \
    appstore.bundle_id="$APPSTORE_BUNDLE_ID" \
    appstore.shared_secret="$APPSTORE_SHARED_SECRET"

# Set environment configuration
firebase functions:config:set \
    appstore.environment="${FIREBASE_ENV:-development}" \
    appstore.use_sandbox="${APPSTORE_USE_SANDBOX:-true}"

# Set monitoring configuration (if provided)
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    firebase functions:config:set monitoring.slack_webhook="$SLACK_WEBHOOK_URL"
fi

if [ ! -z "$MONITORING_EMAIL" ]; then
    firebase functions:config:set monitoring.alert_email="$MONITORING_EMAIL"
fi

# Set cache configuration
firebase functions:config:set \
    cache.valid_hours="${CACHE_VALID_DURATION_HOURS:-24}" \
    cache.invalid_hours="${CACHE_INVALID_DURATION_HOURS:-1}" \
    cache.pending_minutes="${CACHE_PENDING_DURATION_MINUTES:-5}"

echo ""
echo "✅ Firebase Functions configuration complete!"
echo ""
echo "📋 Current configuration:"
firebase functions:config:get

echo ""
echo "🔐 Private Key Setup Instructions:"
echo "1. Upload your AuthKey_${APPSTORE_KEY_ID}.p8 file to Firebase Storage"
echo "2. Or place it in functions/keys/ directory (git ignored)"
echo "3. Update the key path in your deployment"

echo ""
echo "🚀 Next steps:"
echo "1. Deploy functions: firebase deploy --only functions"
echo "2. Configure webhooks in App Store Connect"
echo "3. Test with sandbox environment"
echo "4. Monitor logs: firebase functions:log"

echo ""
echo "✨ Configuration complete!"