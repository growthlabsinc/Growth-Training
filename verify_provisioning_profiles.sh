#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying Provisioning Profiles and Certificates${NC}\n"

# Check for Apple Distribution certificate
echo -e "${BLUE}Checking for Apple Distribution certificate...${NC}"
if security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
    echo -e "${GREEN}✓ Apple Distribution certificate found:${NC}"
    security find-identity -v -p codesigning | grep "Apple Distribution"
else
    echo -e "${RED}✗ No Apple Distribution certificate found${NC}"
    echo "  You need to install your distribution certificate from the Apple Developer portal"
fi

echo ""

# Check installed provisioning profiles
echo -e "${BLUE}Checking installed provisioning profiles...${NC}"
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

if [ -d "$PROFILES_DIR" ]; then
    echo "Profile directory exists at: $PROFILES_DIR"
    
    # Count profiles
    PROFILE_COUNT=$(ls -1 "$PROFILES_DIR"/*.mobileprovision 2>/dev/null | wc -l)
    echo "Found $PROFILE_COUNT provisioning profile(s)"
    
    if [ $PROFILE_COUNT -gt 0 ]; then
        echo -e "\n${BLUE}Analyzing profiles...${NC}"
        
        # Look for our specific profiles
        MAIN_FOUND=false
        WIDGET_FOUND=false
        
        for profile in "$PROFILES_DIR"/*.mobileprovision; do
            # Extract profile info
            PROFILE_INFO=$(security cms -D -i "$profile" 2>/dev/null)
            
            # Get profile name
            PROFILE_NAME=$(echo "$PROFILE_INFO" | awk -F'<string>|</string>' '/<key>Name<\/key>/{getline; print $2}')
            
            # Get app ID
            APP_ID=$(echo "$PROFILE_INFO" | awk -F'<string>|</string>' '/<key>application-identifier<\/key>/{getline; print $2}')
            
            # Get expiration date
            EXPIRY=$(echo "$PROFILE_INFO" | awk -F'<date>|</date>' '/<key>ExpirationDate<\/key>/{getline; print $2}')
            
            # Check if it's App Store distribution
            if echo "$PROFILE_INFO" | grep -q "<key>ProvisionsAllDevices</key>"; then
                PROFILE_TYPE="App Store"
            else
                PROFILE_TYPE="Development/Ad Hoc"
            fi
            
            # Check for our profiles
            if [[ "$PROFILE_NAME" == "Growth App Store Distribution" ]] || [[ "$APP_ID" == *"com.growthlabs.growthmethod" ]]; then
                if [[ "$PROFILE_TYPE" == "App Store" ]]; then
                    MAIN_FOUND=true
                    echo -e "${GREEN}✓ Found main app profile:${NC}"
                    echo "  Name: $PROFILE_NAME"
                    echo "  Type: $PROFILE_TYPE"
                    echo "  App ID: $APP_ID"
                    echo "  Expires: $EXPIRY"
                fi
            fi
            
            if [[ "$PROFILE_NAME" == "Growth Timer Widget App Store" ]] || [[ "$APP_ID" == *"GrowthTimerWidget" ]]; then
                if [[ "$PROFILE_TYPE" == "App Store" ]]; then
                    WIDGET_FOUND=true
                    echo -e "${GREEN}✓ Found widget profile:${NC}"
                    echo "  Name: $PROFILE_NAME"
                    echo "  Type: $PROFILE_TYPE"
                    echo "  App ID: $APP_ID"
                    echo "  Expires: $EXPIRY"
                fi
            fi
        done
        
        echo -e "\n${BLUE}Summary:${NC}"
        if [ "$MAIN_FOUND" = true ]; then
            echo -e "${GREEN}✓ Main app provisioning profile found${NC}"
        else
            echo -e "${RED}✗ Main app provisioning profile NOT FOUND${NC}"
            echo "  Need: 'Growth App Store Distribution' for com.growthlabs.growthmethod"
        fi
        
        if [ "$WIDGET_FOUND" = true ]; then
            echo -e "${GREEN}✓ Widget provisioning profile found${NC}"
        else
            echo -e "${YELLOW}⚠ Widget provisioning profile NOT FOUND${NC}"
            echo "  Need: 'Growth Timer Widget App Store' for com.growthlabs.growthmethod.GrowthTimerWidget"
        fi
    fi
else
    echo -e "${RED}✗ Provisioning profiles directory not found${NC}"
    mkdir -p "$PROFILES_DIR"
    echo "  Created directory: $PROFILES_DIR"
fi

echo -e "\n${BLUE}Quick Actions:${NC}"
echo "1. Download missing profiles from:"
echo "   https://developer.apple.com/account/resources/profiles/list"
echo ""
echo "2. To refresh all profiles:"
echo "   rm -rf ~/Library/MobileDevice/Provisioning\\ Profiles/*"
echo "   Then re-download from Developer Portal"
echo ""
echo "3. To see detailed certificate info:"
echo "   security find-identity -v -p codesigning"