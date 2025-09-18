#!/bin/bash

# Firebase Diagnostics Script
# This script helps identify common issues with Firebase configuration in iOS apps

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Firebase Diagnostics Script${NC}"
echo ""

# Check if we're in the project directory
if [ ! -d "Growth" ]; then
  echo -e "${RED}Error: Please run this script from the project root directory${NC}"
  exit 1
fi

# Checking Google Service Info plist files
echo -e "${YELLOW}Checking Firebase configuration files:${NC}"

DEV_PLIST="Growth/Resources/Plist/dev.GoogleService-Info.plist"
STAGING_PLIST="Growth/Resources/Plist/staging.GoogleService-Info.plist"
PROD_PLIST="Growth/Resources/Plist/GoogleService-Info.plist"

check_plist() {
  local plist=$1
  local env=$2
  
  if [ -f "$plist" ]; then
    echo -e "  ${GREEN}✓${NC} Found $env configuration: $plist"
    
    # Check for required keys
    if grep -q "API_KEY" "$plist" && grep -q "PROJECT_ID" "$plist" && grep -q "BUNDLE_ID" "$plist"; then
      echo -e "    ${GREEN}✓${NC} Has required keys"
      
      # Extract and check bundle ID
      BUNDLE_ID=$(plutil -extract "BUNDLE_ID" raw "$plist" 2>/dev/null)
      if [ $? -eq 0 ]; then
        echo -e "    ${GREEN}✓${NC} Bundle ID: $BUNDLE_ID"
        
        # Check if bundle ID matches the app's bundle ID
        APP_BUNDLE_ID=$(plutil -extract "CFBundleIdentifier" raw "Growth/Info.plist" 2>/dev/null || echo "Unknown")
        if [ "$BUNDLE_ID" != "$APP_BUNDLE_ID" ]; then
          echo -e "    ${RED}✗${NC} Bundle ID mismatch: Plist has $BUNDLE_ID, app has $APP_BUNDLE_ID"
        else
          echo -e "    ${GREEN}✓${NC} Bundle ID matches app bundle ID"
        fi
      else
        echo -e "    ${RED}✗${NC} Could not extract bundle ID"
      fi
    else
      echo -e "    ${RED}✗${NC} Missing required keys"
    fi
  else
    echo -e "  ${RED}✗${NC} Missing $env configuration: $plist"
  fi
  
  echo ""
}

check_plist "$DEV_PLIST" "Development"
check_plist "$STAGING_PLIST" "Staging"
check_plist "$PROD_PLIST" "Production"

# Check for Firebase SDK initialization code
echo -e "${YELLOW}Checking Firebase initialization code:${NC}"

if grep -q "FirebaseApp.configure" "Growth/Core/Networking/FirebaseClient.swift"; then
  echo -e "  ${GREEN}✓${NC} Found FirebaseApp.configure() in FirebaseClient.swift"
else
  echo -e "  ${RED}✗${NC} FirebaseApp.configure() not found in FirebaseClient.swift"
fi

if grep -q "configure(for: .development)" "Growth/Application/AppDelegate.swift"; then
  echo -e "  ${GREEN}✓${NC} Found Firebase configuration call in AppDelegate.swift"
else
  echo -e "  ${RED}✗${NC} Firebase configuration call not found in AppDelegate.swift"
fi

if grep -q "FirebaseClient.shared.configure" "Growth/Application/GrowthAppApp.swift"; then
  echo -e "  ${GREEN}✓${NC} Found Firebase configuration call in GrowthAppApp.swift"
else
  echo -e "  ${RED}✗${NC} Firebase configuration call not found in GrowthAppApp.swift"
fi

echo ""
echo -e "${YELLOW}Firebase initialization diagnostics complete.${NC}"
echo -e "${YELLOW}If you continue to experience issues, check network connectivity and Firebase console configuration.${NC}" 