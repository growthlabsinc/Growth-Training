#!/bin/bash

# Script to validate App Store Connect API configuration
# Usage: ./scripts/validate-appstore-config.sh

set -e

echo "🔍 Validating App Store Connect API configuration..."
echo ""

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
else
    echo "❌ .env.local file not found"
    exit 1
fi

# Initialize status
CONFIG_VALID=true

# Check environment variables
echo "📋 Checking environment variables..."
if [ -z "$APP_STORE_CONNECT_KEY_ID" ]; then
    echo "❌ APP_STORE_CONNECT_KEY_ID not set"
    CONFIG_VALID=false
else
    echo "✅ Key ID: $APP_STORE_CONNECT_KEY_ID"
fi

if [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    echo "❌ APP_STORE_CONNECT_ISSUER_ID not set"
    CONFIG_VALID=false
else
    echo "✅ Issuer ID: $APP_STORE_CONNECT_ISSUER_ID"
fi

# Check private key file
echo ""
echo "🔑 Checking private key file..."
if [ -z "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo "❌ APP_STORE_CONNECT_PRIVATE_KEY_PATH not set"
    CONFIG_VALID=false
elif [ ! -f "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo "❌ Private key file not found at: $APP_STORE_CONNECT_PRIVATE_KEY_PATH"
    CONFIG_VALID=false
else
    echo "✅ Private key found at: $APP_STORE_CONNECT_PRIVATE_KEY_PATH"
    # Check file permissions
    PERMS=$(stat -f "%Lp" "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" 2>/dev/null || stat -c "%a" "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" 2>/dev/null)
    if [ "$PERMS" != "600" ] && [ "$PERMS" != "400" ]; then
        echo "⚠️  Warning: Key file permissions are $PERMS (should be 600 or 400)"
    fi
fi

# Check .gitignore
echo ""
echo "🚫 Checking .gitignore..."
if grep -q "\.keys/" .gitignore && grep -q "\*.p8" .gitignore; then
    echo "✅ Key files are properly ignored by Git"
else
    echo "⚠️  Warning: Make sure .keys/ and *.p8 are in .gitignore"
fi

# Check Firebase configuration
echo ""
echo "☁️  Checking Firebase Functions configuration..."
if command -v firebase &> /dev/null; then
    FIREBASE_CONFIG=$(firebase functions:config:get appstore 2>/dev/null || echo "")
    if [ -z "$FIREBASE_CONFIG" ] || [ "$FIREBASE_CONFIG" = "{}" ]; then
        echo "⚠️  App Store config not set in Firebase Functions"
        echo "   Run: ./scripts/configure-appstore-connect.sh"
    else
        echo "✅ Firebase Functions configuration found:"
        echo "$FIREBASE_CONFIG" | jq . 2>/dev/null || echo "$FIREBASE_CONFIG"
    fi
else
    echo "⚠️  Firebase CLI not installed"
fi

# Check project structure
echo ""
echo "📁 Checking project structure..."
if [ -f "Growth/Core/Models/SubscriptionProduct.swift" ]; then
    echo "✅ SubscriptionProduct.swift found"
    # Check for correct product IDs
    if grep -q "basic_monthly" "Growth/Core/Models/SubscriptionProduct.swift"; then
        echo "✅ Product IDs updated to App Store Connect format"
    else
        echo "⚠️  Product IDs may not match App Store Connect format"
    fi
else
    echo "❌ SubscriptionProduct.swift not found"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CONFIG_VALID" = true ]; then
    echo "✅ App Store Connect API configuration is valid!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Run ./scripts/configure-appstore-connect.sh to set up Firebase"
    echo "2. Create app in App Store Connect"
    echo "3. Configure subscription products"
    echo "4. Generate shared secret and update .env.local"
else
    echo "❌ Configuration issues found. Please fix them before proceeding."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"