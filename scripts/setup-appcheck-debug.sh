#!/bin/bash

# Setup App Check Debug Token for CI/Testing Environments
# This script helps configure App Check debug tokens for automated testing

set -e

echo "🔐 App Check Debug Token Setup"
echo "=============================="

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -t, --token TOKEN    Set the App Check debug token"
    echo "  -e, --env ENV        Environment (dev/staging/prod)"
    echo "  -h, --help          Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 --token YOUR_DEBUG_TOKEN --env dev"
    exit 1
}

# Parse command line arguments
TOKEN=""
ENVIRONMENT="dev"

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            TOKEN="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate token
if [ -z "$TOKEN" ]; then
    echo "❌ Error: Debug token is required"
    echo ""
    echo "To get your debug token:"
    echo "1. Run the app in simulator with -FIRDebugEnabled flag"
    echo "2. Copy the token from console output"
    echo "3. Run this script with: $0 --token YOUR_TOKEN"
    exit 1
fi

# Create environment file for CI
ENV_FILE=".env.appcheck"
echo "Creating $ENV_FILE..."

cat > "$ENV_FILE" << EOF
# App Check Debug Configuration
# Generated on $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

FIREBASE_APP_CHECK_DEBUG_TOKEN=$TOKEN
FIREBASE_ENVIRONMENT=$ENVIRONMENT
EOF

echo "✅ Created $ENV_FILE with debug token"

# Add to .gitignore if not already present
if ! grep -q ".env.appcheck" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# App Check debug tokens" >> .gitignore
    echo ".env.appcheck" >> .gitignore
    echo "✅ Added .env.appcheck to .gitignore"
fi

# Instructions for CI setup
echo ""
echo "📋 CI Setup Instructions:"
echo "========================="
echo ""
echo "1. GitHub Actions:"
echo "   - Add FIREBASE_APP_CHECK_DEBUG_TOKEN as a repository secret"
echo "   - In your workflow file, add:"
echo "     env:"
echo "       FIREBASE_APP_CHECK_DEBUG_TOKEN: \${{ secrets.FIREBASE_APP_CHECK_DEBUG_TOKEN }}"
echo ""
echo "2. Fastlane:"
echo "   - Add to your Fastfile:"
echo "     ENV['FIREBASE_APP_CHECK_DEBUG_TOKEN'] = ENV['FIREBASE_APP_CHECK_DEBUG_TOKEN']"
echo ""
echo "3. Xcode Cloud:"
echo "   - Add as environment variable in workflow settings"
echo ""
echo "⚠️  Security Reminders:"
echo "- Never commit debug tokens to version control"
echo "- Rotate tokens regularly"
echo "- Use different tokens for different environments"
echo "- Revoke compromised tokens immediately in Firebase Console"

# Verify token format (basic check)
if [[ ${#TOKEN} -lt 20 ]]; then
    echo ""
    echo "⚠️  Warning: Token seems unusually short. Make sure you copied the entire token."
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Register this token in Firebase Console:"
echo "   https://console.firebase.google.com/project/growth-70a85/appcheck/apps"
echo "2. Click 'Manage debug tokens' and add this token"
echo "3. Give it a descriptive name (e.g., 'CI Environment - $ENVIRONMENT')"