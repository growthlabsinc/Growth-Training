#!/bin/bash

echo "🔐 Setting up Firebase Functions Secrets"
echo "======================================="
echo ""
echo "This script will help you set up the required secrets for Firebase Functions."
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

echo "📋 Required Secrets:"
echo "1. APNS_AUTH_KEY - Your APNs authentication key (p8 file content)"
echo "2. APNS_KEY_ID - Your APNs Key ID (e.g., 55LZB28UY2)"
echo "3. APNS_TEAM_ID - Your Apple Team ID (e.g., 62T6J77P6R)"
echo "4. APP_STORE_CONNECT_KEY_ID - App Store Connect API Key ID"
echo "5. APP_STORE_CONNECT_ISSUER_ID - App Store Connect Issuer ID"
echo "6. APP_STORE_SHARED_SECRET - App Store shared secret for receipt validation"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local prompt_text=$2
    local is_file=$3
    
    echo ""
    echo "Setting up $secret_name..."
    echo "$prompt_text"
    
    if [ "$is_file" = "true" ]; then
        read -p "Enter file path: " file_path
        if [ -f "$file_path" ]; then
            firebase functions:secrets:set $secret_name < "$file_path"
        else
            echo "❌ File not found: $file_path"
            return 1
        fi
    else
        read -p "Enter value: " secret_value
        echo "$secret_value" | firebase functions:secrets:set $secret_name
    fi
}

# Check current project
echo "🔍 Current Firebase project:"
firebase use
echo ""

read -p "Is this the correct project? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Please run 'firebase use <project-id>' to select the correct project first."
    exit 1
fi

# Set up APNs secrets
echo ""
echo "📱 Setting up APNs (Apple Push Notification service) secrets..."
echo ""

# APNS Auth Key
echo "For APNS_AUTH_KEY, you need the content of your .p8 file from Apple Developer."
echo "This file should be named something like AuthKey_XXXXXXXXXX.p8"
set_secret "APNS_AUTH_KEY" "Enter the path to your APNs .p8 key file:" true

# APNS Key ID
set_secret "APNS_KEY_ID" "Enter your APNs Key ID (the XXXXXXXXXX part from AuthKey_XXXXXXXXXX.p8):" false

# APNS Team ID
set_secret "APNS_TEAM_ID" "Enter your Apple Team ID (found in Apple Developer account):" false

# Set up App Store Connect secrets
echo ""
echo "🏪 Setting up App Store Connect secrets..."
echo ""

# App Store Connect Key ID
set_secret "APP_STORE_CONNECT_KEY_ID" "Enter your App Store Connect API Key ID:" false

# App Store Connect Issuer ID
set_secret "APP_STORE_CONNECT_ISSUER_ID" "Enter your App Store Connect Issuer ID:" false

# App Store Shared Secret
set_secret "APP_STORE_SHARED_SECRET" "Enter your App Store shared secret (for receipt validation):" false

echo ""
echo "✅ Secret setup complete!"
echo ""
echo "📋 To verify your secrets are set, run:"
echo "   firebase functions:secrets:list"
echo ""
echo "🚀 To deploy your functions with the new secrets:"
echo "   firebase deploy --only functions"
echo ""
echo "⚠️  Note: After deploying, it may take a few minutes for the secrets to become available."