#!/bin/bash

echo "==============================================="
echo "Fixing Provisioning Profile Issue"
echo "==============================================="
echo ""

# Clean up old profiles
echo "1. Cleaning old provisioning profiles..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Open Xcode to download new profiles
echo "2. Opening Xcode preferences to download profiles..."
echo "   Please sign in to your Apple Developer account if needed"
echo ""
echo "Steps to follow in Xcode:"
echo "   1. Go to Xcode → Settings (⌘,)"
echo "   2. Click 'Accounts' tab"
echo "   3. Select your Apple ID (jonmwebb@gmail.com)"
echo "   4. Click 'Download Manual Profiles' button"
echo "   5. Wait for profiles to download"
echo ""
echo "Press Enter after downloading profiles..."
read

# Alternative: Use automatic signing
echo "3. Configuring automatic signing..."
echo ""
echo "In Xcode:"
echo "   1. Select Growth project in navigator"
echo "   2. Select Growth target"
echo "   3. Go to 'Signing & Capabilities' tab"
echo "   4. Check 'Automatically manage signing'"
echo "   5. Select Team: Growth Labs, Inc (62T6J77P6R)"
echo "   6. Xcode will create/download the correct profiles"
echo ""

echo "==============================================="
echo "Quick Fix: Switch to Automatic Signing"
echo "==============================================="
echo ""
echo "This is the easiest solution:"
echo "1. Open Growth.xcodeproj"
echo "2. Select the Growth target"
echo "3. Enable 'Automatically manage signing'"
echo "4. Select your team"
echo "5. Build and run"
echo ""
echo "Xcode will handle all provisioning profiles automatically!"
echo "==============================================="