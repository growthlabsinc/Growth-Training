#!/bin/bash

# Script to set up Firebase Secret Manager for App Store Connect API
# Usage: ./scripts/setup-firebase-secrets.sh

set -e

echo "🔐 Setting up Firebase Secret Manager for App Store Connect..."
echo ""

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
else
    echo "❌ .env.local file not found. Please create it first."
    exit 1
fi

# Validate required variables
if [ -z "$APP_STORE_CONNECT_KEY_ID" ] || [ -z "$APP_STORE_CONNECT_ISSUER_ID" ] || [ -z "$APP_STORE_SHARED_SECRET" ]; then
    echo "❌ Missing required environment variables in .env.local"
    exit 1
fi

echo "📝 Using configuration:"
echo "   Key ID: $APP_STORE_CONNECT_KEY_ID"
echo "   Issuer ID: $APP_STORE_CONNECT_ISSUER_ID"
echo "   Shared Secret: ${APP_STORE_SHARED_SECRET:0:10}..."
echo ""

# Create secrets in Firebase
echo "🔧 Creating secrets in Firebase..."

# Create APP_STORE_CONNECT_KEY_ID secret
echo -n "$APP_STORE_CONNECT_KEY_ID" | firebase functions:secrets:set APP_STORE_CONNECT_KEY_ID

# Create APP_STORE_CONNECT_ISSUER_ID secret
echo -n "$APP_STORE_CONNECT_ISSUER_ID" | firebase functions:secrets:set APP_STORE_CONNECT_ISSUER_ID

# Create APP_STORE_SHARED_SECRET secret
echo -n "$APP_STORE_SHARED_SECRET" | firebase functions:secrets:set APP_STORE_SHARED_SECRET

echo ""
echo "📋 Granting access to functions..."

# Grant access to specific functions that need these secrets
firebase functions:secrets:access APP_STORE_CONNECT_KEY_ID validateSubscriptionReceipt handleAppStoreNotification
firebase functions:secrets:access APP_STORE_CONNECT_ISSUER_ID validateSubscriptionReceipt handleAppStoreNotification
firebase functions:secrets:access APP_STORE_SHARED_SECRET validateSubscriptionReceipt handleAppStoreNotification

echo ""
echo "🔍 Verifying secrets..."
firebase functions:secrets:get APP_STORE_CONNECT_KEY_ID
firebase functions:secrets:get APP_STORE_CONNECT_ISSUER_ID
firebase functions:secrets:get APP_STORE_SHARED_SECRET

echo ""
echo "✅ Firebase Secret Manager configuration complete!"
echo ""
echo "📝 Next steps:"
echo "1. Deploy the functions: firebase deploy --only functions"
echo "2. The secrets will be automatically loaded by the functions"
echo "3. Monitor function logs for any issues"
echo ""
echo "⚠️  Note: Secrets are project-specific. Set them for each environment:"
echo "   - Development: firebase use development"
echo "   - Staging: firebase use staging"
echo "   - Production: firebase use production"