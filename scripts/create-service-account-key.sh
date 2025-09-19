#!/bin/bash

# Create Service Account Key for Firebase Admin SDK
# This script helps create a service account key for local development

set -e

PROJECT_ID="growth-training-app"
KEY_FILE="./keys/firebase-admin-sdk.json"

echo "==================================="
echo "Firebase Admin SDK Key Generator"
echo "Project: $PROJECT_ID"
echo "==================================="
echo ""

# Check if keys directory exists
if [ ! -d "keys" ]; then
    echo "Creating keys directory..."
    mkdir -p keys
fi

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Warning: Key file already exists at $KEY_FILE"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "Checking authentication status..."
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
echo "Active account: $CURRENT_ACCOUNT"

# Check if we can access the project
echo "Verifying project access..."
if ! gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo "❌ Cannot access project $PROJECT_ID"
    echo ""
    echo "Please ensure you're authenticated with the correct account:"
    echo "  gcloud auth login"
    echo "  gcloud config set project $PROJECT_ID"
    exit 1
fi

# List service accounts
echo ""
echo "Looking for Firebase Admin SDK service account..."
SERVICE_ACCOUNT=$(gcloud iam service-accounts list \
    --project=$PROJECT_ID \
    --filter="email:firebase-adminsdk" \
    --format="value(email)" \
    2>/dev/null | head -1)

if [ -z "$SERVICE_ACCOUNT" ]; then
    echo "❌ Firebase Admin SDK service account not found"
    echo ""
    echo "Manual steps required:"
    echo "1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/settings/serviceaccounts/adminsdk"
    echo "2. Click 'Generate new private key'"
    echo "3. Save the file as: $KEY_FILE"
    exit 1
fi

echo "Found service account: $SERVICE_ACCOUNT"

# Create the key
echo ""
echo "Creating service account key..."
if gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" 2>/dev/null; then

    # Set appropriate permissions
    chmod 600 "$KEY_FILE"

    echo ""
    echo "✅ Success! Key created at: $KEY_FILE"
    echo ""
    echo "Security reminders:"
    echo "• This file contains sensitive credentials"
    echo "• Never commit this file to Git (already in .gitignore)"
    echo "• Delete old keys from GCP Console when rotating"
    echo ""
    echo "To use this key in your code:"
    echo "  export GOOGLE_APPLICATION_CREDENTIALS=\"$PWD/$KEY_FILE\""
else
    echo "❌ Failed to create key"
    echo ""
    echo "Alternative method:"
    echo "1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/settings/serviceaccounts/adminsdk"
    echo "2. Click 'Generate new private key'"
    echo "3. Save the file as: $KEY_FILE"
    exit 1
fi