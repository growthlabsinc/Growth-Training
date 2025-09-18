#!/bin/bash

# Script to verify Firebase configuration
# This script checks if the Firebase configuration files are properly set up
# It verifies the GoogleService-Info.plist files and bundle identifiers

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Verifying Firebase Configuration...${NC}"

# Check if GoogleService-Info.plist files exist
echo -e "\n${YELLOW}Checking GoogleService-Info.plist files:${NC}"

DEV_PLIST="Growth/Resources/Plist/dev.GoogleService-Info.plist"
STAGING_PLIST="Growth/Resources/Plist/staging.GoogleService-Info.plist"
PROD_PLIST="Growth/Resources/Plist/GoogleService-Info.plist"

# Function to check plist files
check_plist() {
    local plist_path=$1
    local env_name=$2
    
    if [ -f "$plist_path" ]; then
        echo -e "  ${GREEN}✓${NC} $env_name GoogleService-Info.plist found at: $plist_path"
        
        # Check for required keys
        local required_keys=("API_KEY" "GOOGLE_APP_ID" "PROJECT_ID" "BUNDLE_ID" "GCM_SENDER_ID")
        local missing_keys=()
        
        for key in "${required_keys[@]}"; do
            if ! /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path" &>/dev/null; then
                missing_keys+=("$key")
            fi
        done
        
        if [ ${#missing_keys[@]} -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} All required keys found in $env_name plist"
            
            # Get the bundle ID from the plist
            local bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$plist_path" 2>/dev/null)
            echo -e "  ${GREEN}ℹ${NC} $env_name Bundle ID: $bundle_id"
            
            return 0
        else
            echo -e "  ${RED}✗${NC} Missing required keys in $env_name plist: ${missing_keys[*]}"
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} $env_name GoogleService-Info.plist NOT found at: $plist_path"
        return 1
    fi
}

# Check each environment plist
dev_ok=0
staging_ok=0
prod_ok=0

check_plist "$DEV_PLIST" "Development" && dev_ok=1
check_plist "$STAGING_PLIST" "Staging" && staging_ok=1
check_plist "$PROD_PLIST" "Production" && prod_ok=1

# Check bundle identifier in Xcode project
echo -e "\n${YELLOW}Checking Bundle Identifier in Xcode project:${NC}"

# Get bundle ID from Xcode project settings
PROJECT_BUNDLE_ID=$(xcodebuild -project Growth.xcodeproj -target Growth -configuration Debug -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | sed 's/.*= //')

if [ -n "$PROJECT_BUNDLE_ID" ]; then
    echo -e "  ${GREEN}✓${NC} Found Bundle ID in Xcode project: $PROJECT_BUNDLE_ID"
    
    # Compare with Firebase plists
    if [ $dev_ok -eq 1 ]; then
        dev_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$DEV_PLIST" 2>/dev/null)
        if [ "$dev_bundle_id" = "$PROJECT_BUNDLE_ID" ]; then
            echo -e "  ${GREEN}✓${NC} Development Bundle ID matches Xcode project"
        else
            echo -e "  ${RED}✗${NC} Development Bundle ID ($dev_bundle_id) does NOT match Xcode project ($PROJECT_BUNDLE_ID)"
        fi
    fi
    
    if [ $staging_ok -eq 1 ]; then
        staging_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$STAGING_PLIST" 2>/dev/null)
        if [ "$staging_bundle_id" = "$PROJECT_BUNDLE_ID" ]; then
            echo -e "  ${GREEN}✓${NC} Staging Bundle ID matches Xcode project"
        else
            echo -e "  ${RED}✗${NC} Staging Bundle ID ($staging_bundle_id) does NOT match Xcode project ($PROJECT_BUNDLE_ID)"
        fi
    fi
    
    if [ $prod_ok -eq 1 ]; then
        prod_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$PROD_PLIST" 2>/dev/null)
        if [ "$prod_bundle_id" = "$PROJECT_BUNDLE_ID" ]; then
            echo -e "  ${GREEN}✓${NC} Production Bundle ID matches Xcode project"
        else
            echo -e "  ${RED}✗${NC} Production Bundle ID ($prod_bundle_id) does NOT match Xcode project ($PROJECT_BUNDLE_ID)"
        fi
    fi
else
    echo -e "  ${RED}✗${NC} Could not determine Bundle ID from Xcode project"
fi

# Check Info.plist configuration
echo -e "\n${YELLOW}Checking Info.plist configuration:${NC}"
INFO_PLIST="Growth/Info.plist"
ALT_INFO_PLIST="Growth/Resources/Plist/App/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    echo -e "  ${GREEN}✓${NC} Found main Info.plist at: $INFO_PLIST"
    
    # Check for Firebase App Delegate Proxy setting
    if grep -q "FirebaseAppDelegateProxyEnabled" "$INFO_PLIST"; then
        echo -e "  ${GREEN}✓${NC} FirebaseAppDelegateProxyEnabled is configured in Info.plist"
    else
        echo -e "  ${RED}✗${NC} FirebaseAppDelegateProxyEnabled is NOT configured in Info.plist"
    fi
else
    echo -e "  ${RED}✗${NC} Main Info.plist NOT found at: $INFO_PLIST"
fi

if [ -f "$ALT_INFO_PLIST" ]; then
    echo -e "  ${GREEN}✓${NC} Found alternative Info.plist at: $ALT_INFO_PLIST"
fi

# Check for Firebase initialization in code
echo -e "\n${YELLOW}Checking Firebase initialization in code:${NC}"

APP_DELEGATE="Growth/Application/AppDelegate.swift"
FIREBASE_CLIENT="Growth/Core/Networking/FirebaseClient.swift"

if grep -q "FirebaseApp.configure" "$FIREBASE_CLIENT"; then
    echo -e "  ${GREEN}✓${NC} Found FirebaseApp.configure in FirebaseClient.swift"
else
    echo -e "  ${RED}✗${NC} Could NOT find FirebaseApp.configure in FirebaseClient.swift"
fi

if grep -q "FirebaseClient.shared.configure" "$APP_DELEGATE"; then
    echo -e "  ${GREEN}✓${NC} Found Firebase initialization in AppDelegate.swift"
else
    echo -e "  ${RED}✗${NC} Could NOT find Firebase initialization in AppDelegate.swift"
fi

# Check for Firebase import statements
echo -e "\n${YELLOW}Checking Firebase import statements:${NC}"

REQUIRED_IMPORTS=("Firebase" "FirebaseAuth" "FirebaseFirestore" "FirebaseAnalytics" "FirebaseCrashlytics" "FirebaseFunctions" "FirebaseRemoteConfig" "FirebaseInAppMessaging")
MISSING_IMPORTS=()

for import in "${REQUIRED_IMPORTS[@]}"; do
    if grep -q "import $import" "$FIREBASE_CLIENT"; then
        echo -e "  ${GREEN}✓${NC} Found import for $import"
    else
        echo -e "  ${RED}✗${NC} Missing import for $import"
        MISSING_IMPORTS+=("$import")
    fi
done

# Check for Firebase entitlements
echo -e "\n${YELLOW}Checking Firebase entitlements:${NC}"

ENTITLEMENTS_FILE="Growth/Growth.entitlements"

if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} Found entitlements file at: $ENTITLEMENTS_FILE"
    
    if grep -q "aps-environment" "$ENTITLEMENTS_FILE"; then
        echo -e "  ${GREEN}✓${NC} Found aps-environment in entitlements file"
    else
        echo -e "  ${RED}✗${NC} Missing aps-environment in entitlements file"
    fi
else
    echo -e "  ${RED}✗${NC} Entitlements file NOT found at: $ENTITLEMENTS_FILE"
fi

# Summary
echo -e "\n${YELLOW}Firebase Verification Summary:${NC}"

if [ $dev_ok -eq 1 ] && [ $staging_ok -eq 1 ] && [ $prod_ok -eq 1 ] && [ ${#MISSING_IMPORTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Firebase configuration looks good! All required files and settings are in place.${NC}"
else
    echo -e "${RED}⚠ Firebase configuration has issues that need to be addressed.${NC}"
    
    if [ $dev_ok -eq 0 ] || [ $staging_ok -eq 0 ] || [ $prod_ok -eq 0 ]; then
        echo -e "  - Fix the GoogleService-Info.plist files"
    fi
    
    if [ ${#MISSING_IMPORTS[@]} -gt 0 ]; then
        echo -e "  - Add missing import statements: ${MISSING_IMPORTS[*]}"
    fi
fi

echo -e "\n${YELLOW}Firebase Verification Complete${NC}" 