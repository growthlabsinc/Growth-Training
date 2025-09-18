#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing Provisioning Profiles${NC}\n"

# Create profiles directory if it doesn't exist
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_DIR"

echo -e "${BLUE}Looking for downloaded profiles...${NC}"

# Common download locations
DOWNLOAD_DIRS=(
    "$HOME/Downloads"
    "$HOME/Desktop"
    "."
)

FOUND_PROFILES=false

for dir in "${DOWNLOAD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Look for mobileprovision files
        for profile in "$dir"/*.mobileprovision; do
            if [ -f "$profile" ]; then
                FOUND_PROFILES=true
                echo -e "${GREEN}✓ Found: $(basename "$profile")${NC}"
                
                # Copy to provisioning profiles directory
                cp "$profile" "$PROFILES_DIR/"
                
                # Also open with Xcode to ensure it's registered
                open -a Xcode "$profile" 2>/dev/null || true
            fi
        done
    fi
done

if [ "$FOUND_PROFILES" = false ]; then
    echo -e "${YELLOW}⚠️  No .mobileprovision files found in Downloads or Desktop${NC}"
    echo -e "${YELLOW}Please download your profiles from:${NC}"
    echo "https://developer.apple.com/account/resources/profiles/list"
else
    echo -e "\n${GREEN}✅ Profiles installed!${NC}"
    
    # Force Xcode to recognize them
    echo -e "\n${BLUE}Refreshing Xcode...${NC}"
    killall Xcode 2>/dev/null || true
    
    echo -e "\n${GREEN}✅ Done! Next steps:${NC}"
    echo "1. Open Xcode"
    echo "2. Your project should now recognize the profiles"
    echo "3. Try archiving again"
fi