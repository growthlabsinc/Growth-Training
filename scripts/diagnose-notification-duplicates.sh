#!/bin/bash

# Diagnose and Fix Duplicate Notification Issues
# This script helps identify and resolve duplicate notifications from multiple app builds

echo "🔍 Diagnosing Duplicate Notification Issues"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check bundle identifiers
check_bundle_ids() {
    echo -e "\n${YELLOW}Checking Bundle Identifiers...${NC}"

    # Check main app bundle ID
    BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER = " Growth.xcodeproj/project.pbxproj | grep -v Widget | head -1 | cut -d'=' -f2 | tr -d ' ;')
    echo "Main App Bundle ID: $BUNDLE_ID"

    # Check if different configurations have different IDs
    DEBUG_COUNT=$(grep "PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID" Growth.xcodeproj/project.pbxproj | wc -l)
    echo "Bundle ID occurrences: $DEBUG_COUNT"

    if [ "$DEBUG_COUNT" -gt 2 ]; then
        echo -e "${RED}⚠️ Warning: Same bundle ID used for multiple configurations${NC}"
        echo "This can cause duplicate notifications when multiple builds are installed"
    fi
}

# Function to check Firebase configurations
check_firebase_configs() {
    echo -e "\n${YELLOW}Checking Firebase Configuration Files...${NC}"

    # List all GoogleService-Info files
    CONFIGS=$(find . -name "*GoogleService-Info*.plist" 2>/dev/null)

    if [ -z "$CONFIGS" ]; then
        echo -e "${RED}No Firebase configuration files found${NC}"
    else
        echo "Found Firebase configurations:"
        for config in $CONFIGS; do
            echo "  - $config"

            # Extract bundle ID from plist if possible
            if command -v plutil &> /dev/null; then
                CONFIG_BUNDLE_ID=$(plutil -p "$config" 2>/dev/null | grep BUNDLE_ID | cut -d'"' -f4)
                if [ ! -z "$CONFIG_BUNDLE_ID" ]; then
                    echo "    Bundle ID: $CONFIG_BUNDLE_ID"
                fi
            fi
        done
    fi
}

# Function to check for multiple app installations
check_multiple_installations() {
    echo -e "\n${YELLOW}Checking for Multiple App Installations...${NC}"

    echo "To check on your device:"
    echo "1. Open Settings > General > iPhone Storage"
    echo "2. Look for multiple instances of 'Growth' app"
    echo "3. If found, delete older/unused versions"

    echo -e "\n${YELLOW}Quick Fix Options:${NC}"
    echo "1. Delete all versions of the app from your device"
    echo "2. Clean install only the version you need (Xcode OR TestFlight/App Store)"
    echo "3. Use different bundle IDs for development builds"
}

# Function to suggest solutions
suggest_solutions() {
    echo -e "\n${GREEN}Recommended Solutions:${NC}"
    echo "==========================================="

    echo -e "\n${GREEN}Option 1: Use Different Bundle IDs (Recommended)${NC}"
    echo "1. In Xcode, select your project"
    echo "2. Select the app target"
    echo "3. Go to Build Settings > Product Bundle Identifier"
    echo "4. Set different IDs for Debug and Release:"
    echo "   Debug: com.growthlabs.growthtraining.dev"
    echo "   Release: com.growthlabs.growthtraining"

    echo -e "\n${GREEN}Option 2: Clean Device Installation${NC}"
    echo "1. Delete ALL versions of the app from device"
    echo "2. Reset notification permissions:"
    echo "   Settings > General > Transfer or Reset > Reset > Reset Location & Privacy"
    echo "3. Install only one version (development OR production)"

    echo -e "\n${GREEN}Option 3: Token Deduplication (Already Implemented)${NC}"
    echo "The app now includes automatic token deduplication:"
    echo "- Each build type registers with unique identifier"
    echo "- Old tokens from same device are automatically cleaned"
    echo "- Stale tokens (>30 days) are removed periodically"
}

# Function to check Firebase console
check_firebase_console() {
    echo -e "\n${YELLOW}Firebase Console Actions:${NC}"
    echo "==========================================="

    echo "1. Check registered tokens:"
    echo "   https://console.firebase.google.com/project/growth-training-app/firestore"
    echo "   Navigate to: users > [your-user-id] > deviceTokens"

    echo "2. Look for multiple tokens with same deviceId"
    echo "3. Delete old/unused tokens manually if needed"

    echo -e "\n${YELLOW}To view active tokens in the app (Debug):${NC}"
    echo "Add this code to a debug view:"
    echo 'DeviceTokenManager.shared.getActiveTokens(userId: userId) { tokens, _ in'
    echo '    print("Active tokens: \(tokens)")'
    echo '}'
}

# Main execution
echo "Starting diagnosis..."

check_bundle_ids
check_firebase_configs
check_multiple_installations
check_firebase_console
suggest_solutions

echo -e "\n${GREEN}✅ Diagnosis Complete${NC}"
echo "==========================================="
echo "The app now includes automatic token deduplication."
echo "New installations will automatically clean up old tokens."
echo "For immediate fix: Delete all app versions and reinstall only one."