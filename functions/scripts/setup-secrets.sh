#!/bin/bash

# Setup Firebase Secret Manager for API Keys
# This script securely stores sensitive credentials in Firebase

echo "🔐 Setting up Firebase Secret Manager for API Keys"
echo "================================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first."
    exit 1
fi

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI not found. Please install it first."
    exit 1
fi

PROJECT_ID="growth-70a85"

echo "📋 Setting up secrets for project: $PROJECT_ID"

# Enable Secret Manager API
echo "🔧 Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Create secrets for App Store Connect
echo "🔑 Creating secrets for App Store Connect credentials..."

# 1. Store the private key
if [ -f "keys/AuthKey_2A6PYJ67CD.p8" ]; then
    echo "📤 Uploading App Store Connect private key..."
    gcloud secrets create appstore-private-key \
        --data-file=keys/AuthKey_2A6PYJ67CD.p8 \
        --project=$PROJECT_ID \
        --replication-policy="automatic" || echo "Secret already exists"
else
    echo "⚠️  Private key file not found at keys/AuthKey_2A6PYJ67CD.p8"
fi

# 2. Store configuration as JSON
echo "📤 Creating App Store configuration secret..."
cat > /tmp/appstore-config.json << EOF
{
  "keyId": "${APPSTORE_KEY_ID:-2A6PYJ67CD}",
  "issuerId": "${APPSTORE_ISSUER_ID:-87056e63-dddd-4e67-989e-e0e4950b84e5}",
  "bundleId": "${APPSTORE_BUNDLE_ID:-com.growthlabs.growthmethod}",
  "sharedSecret": "${APPSTORE_SHARED_SECRET:-a0023e4976154ebe84aa547f475e20d1}"
}
EOF

gcloud secrets create appstore-config \
    --data-file=/tmp/appstore-config.json \
    --project=$PROJECT_ID \
    --replication-policy="automatic" || echo "Secret already exists"

rm /tmp/appstore-config.json

# 3. Grant Firebase Functions access to secrets
echo "🔓 Granting Firebase Functions access to secrets..."

# Get the default service account
SERVICE_ACCOUNT="$PROJECT_ID@appspot.gserviceaccount.com"

# Grant access to read secrets
gcloud secrets add-iam-policy-binding appstore-private-key \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID

gcloud secrets add-iam-policy-binding appstore-config \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID

echo "✅ Secret Manager setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Update your Firebase Functions to use Secret Manager"
echo "2. Delete local key files: rm -rf functions/keys/"
echo "3. Update deployment scripts to not require local keys"
echo ""
echo "🔍 To view secrets:"
echo "   gcloud secrets list --project=$PROJECT_ID"
echo ""
echo "🔒 To access secrets in functions:"
echo "   const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');"
echo "   const client = new SecretManagerServiceClient();"