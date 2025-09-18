#!/bin/bash

echo "=========================================="
echo "StoreKit Configuration Verification Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Products.storekit exists
echo -e "\n${YELLOW}1. Checking for Products.storekit file...${NC}"
if [ -f "Products.storekit" ]; then
    echo -e "${GREEN}✅ Products.storekit found in project root${NC}"
    
    # Extract product IDs
    echo -e "\n${YELLOW}2. Product IDs in Products.storekit:${NC}"
    grep -o '"productID"[[:space:]]*:[[:space:]]*"[^"]*"' Products.storekit | sed 's/"productID"[[:space:]]*:[[:space:]]*"/  - /' | sed 's/"$//'
    
    # Check subscription group
    echo -e "\n${YELLOW}3. Subscription Group:${NC}"
    grep -o '"name"[[:space:]]*:[[:space:]]*"Growth: Method Pro"' Products.storekit > /dev/null && echo -e "${GREEN}✅ Growth: Method Pro group found${NC}"
    
else
    echo -e "${RED}❌ Products.storekit not found${NC}"
fi

# Check Xcode project for StoreKit configuration
echo -e "\n${YELLOW}4. Checking Xcode project for StoreKit references...${NC}"
if [ -f "Growth.xcodeproj/project.pbxproj" ]; then
    if grep -q "Products.storekit" Growth.xcodeproj/project.pbxproj; then
        echo -e "${GREEN}✅ Products.storekit is referenced in Xcode project${NC}"
    else
        echo -e "${RED}❌ Products.storekit is NOT referenced in Xcode project${NC}"
        echo "   You need to add it to the project in Xcode"
    fi
fi

# Check for scheme configuration
echo -e "\n${YELLOW}5. Checking for scheme StoreKit configuration...${NC}"
SCHEME_DIR="Growth.xcodeproj/xcshareddata/xcschemes"
if [ -d "$SCHEME_DIR" ]; then
    for scheme in "$SCHEME_DIR"/*.xcscheme; do
        if [ -f "$scheme" ]; then
            SCHEME_NAME=$(basename "$scheme" .xcscheme)
            if grep -q "storeKitConfigurationFileReference" "$scheme"; then
                echo -e "${GREEN}✅ Scheme '$SCHEME_NAME' has StoreKit configuration${NC}"
                # Extract the referenced file
                grep "storeKitConfigurationFileReference" "$scheme" | head -1
            else
                echo -e "${YELLOW}⚠️  Scheme '$SCHEME_NAME' does NOT have StoreKit configuration${NC}"
            fi
        fi
    done
else
    echo -e "${RED}❌ No shared schemes found${NC}"
fi

# Check Bundle ID
echo -e "\n${YELLOW}6. Checking Bundle ID...${NC}"
PLIST_FILE="Growth/Resources/Plist/Info.plist"
if [ -f "$PLIST_FILE" ]; then
    BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$PLIST_FILE" 2>/dev/null || grep -A1 "CFBundleIdentifier" "$PLIST_FILE" | tail -1 | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//')
    echo "Bundle ID: $BUNDLE_ID"
    if [ "$BUNDLE_ID" = "com.growthlabs.growthmethod" ]; then
        echo -e "${GREEN}✅ Bundle ID matches App Store Connect${NC}"
    else
        echo -e "${RED}❌ Bundle ID mismatch! Expected: com.growthlabs.growthmethod${NC}"
    fi
fi

# Check for required capabilities
echo -e "\n${YELLOW}7. Checking for In-App Purchase capability...${NC}"
ENTITLEMENTS_FILE="Growth/Growth.entitlements"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    if grep -q "com.apple.developer.in-app-payments" "$ENTITLEMENTS_FILE"; then
        echo -e "${GREEN}✅ In-App Purchase capability found in entitlements${NC}"
    else
        echo -e "${YELLOW}⚠️  In-App Purchase capability not explicitly in entitlements${NC}"
        echo "   (This might be handled by Xcode automatically)"
    fi
fi

# Check product IDs in code match StoreKit file
echo -e "\n${YELLOW}8. Verifying product IDs match between code and StoreKit file...${NC}"
CODE_FILE="Growth/Core/Models/SubscriptionProduct.swift"
if [ -f "$CODE_FILE" ]; then
    echo "Product IDs in code:"
    grep -o 'premiumWeekly = "[^"]*"' "$CODE_FILE" | sed 's/premiumWeekly = /  - /'
    grep -o 'premiumQuarterly = "[^"]*"' "$CODE_FILE" | sed 's/premiumQuarterly = /  - /'
    grep -o 'premiumYearly = "[^"]*"' "$CODE_FILE" | sed 's/premiumYearly = /  - /'
    
    # Cross-check
    WEEKLY="com.growthlabs.growthmethod.subscription.premium.weekly"
    QUARTERLY="com.growthlabs.growthmethod.subscription.premium.quarterly"
    YEARLY="com.growthlabs.growthmethod.subscription.premium.yearly"
    
    ALL_MATCH=true
    for PRODUCT in "$WEEKLY" "$QUARTERLY" "$YEARLY"; do
        if grep -q "\"$PRODUCT\"" Products.storekit && grep -q "\"$PRODUCT\"" "$CODE_FILE"; then
            echo -e "${GREEN}✅ $PRODUCT matches${NC}"
        else
            echo -e "${RED}❌ $PRODUCT mismatch${NC}"
            ALL_MATCH=false
        fi
    done
    
    if [ "$ALL_MATCH" = true ]; then
        echo -e "${GREEN}✅ All product IDs match perfectly!${NC}"
    fi
fi

echo -e "\n${YELLOW}=========================================="
echo "Verification Summary"
echo "==========================================${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Make sure you're signed into a Sandbox Account:"
echo "   Settings > App Store > Sandbox Account"
echo ""
echo "2. In Xcode, ensure Products.storekit is selected in your scheme:"
echo "   Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration"
echo ""
echo "3. For TestFlight builds, products must be in 'Ready to Submit' state in App Store Connect"
echo ""
echo "4. Try running the app with the enhanced debugging to see detailed logs"