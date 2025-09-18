#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 App Store Upload Script${NC}\n"

# Find the latest archive
LATEST_ARCHIVE=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d | sort -r | head -n 1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo -e "${RED}❌ No archive found. Please archive your app first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found archive: $(basename "$LATEST_ARCHIVE")${NC}"

# Create export directory
EXPORT_DIR="$HOME/Desktop/GrowthExport_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EXPORT_DIR"

echo -e "\n${BLUE}Step 1: Exporting IPA...${NC}"
xcodebuild -exportArchive \
    -archivePath "$LATEST_ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Export successful!${NC}"
    IPA_PATH="$EXPORT_DIR/Growth.ipa"
    
    if [ -f "$IPA_PATH" ]; then
        echo -e "\n${BLUE}Step 2: Choose upload method:${NC}"
        echo "1) Upload directly using xcrun altool"
        echo "2) Save IPA for manual upload via Transporter"
        echo -n "Enter choice (1 or 2): "
        read choice
        
        if [ "$choice" = "1" ]; then
            echo -e "\n${BLUE}Uploading to App Store Connect...${NC}"
            echo -e "${YELLOW}You'll be prompted for your Apple ID password${NC}"
            
            xcrun altool --upload-app \
                -f "$IPA_PATH" \
                -t ios \
                -u jon@growthlabs.coach \
                --apiKey 66LQV834DU \
                --apiIssuer 69a6de94-30e9-47e3-e053-5b8c7c11a4d1
                
            if [ $? -eq 0 ]; then
                echo -e "\n${GREEN}✅ Upload successful!${NC}"
                echo -e "Check App Store Connect for processing status."
            else
                echo -e "\n${YELLOW}If upload failed, try:${NC}"
                echo "1. Download Transporter from Mac App Store"
                echo "2. Open Transporter and sign in"
                echo "3. Drag the IPA file: $IPA_PATH"
            fi
        else
            echo -e "\n${GREEN}✓ IPA saved to: $IPA_PATH${NC}"
            echo -e "\n${BLUE}To upload manually:${NC}"
            echo "1. Download 'Transporter' from Mac App Store"
            echo "2. Open Transporter and sign in with Apple ID"
            echo "3. Drag this file to Transporter: $IPA_PATH"
            open "$EXPORT_DIR"
        fi
    else
        echo -e "${RED}❌ IPA file not found in export${NC}"
        ls -la "$EXPORT_DIR"
    fi
else
    echo -e "${RED}❌ Export failed. Check the error messages above.${NC}"
    echo -e "\n${YELLOW}Common fixes:${NC}"
    echo "- Ensure provisioning profiles are installed"
    echo "- Check that bundle IDs match"
    echo "- Verify certificate is valid"
fi