#!/bin/bash

echo "StoreKit Diagnostic Report"
echo "=========================="
echo ""

# Check bundle IDs
echo "1. Bundle ID Configuration:"
echo "Debug Bundle ID:"
grep PRODUCT_BUNDLE_IDENTIFIER Debug.xcconfig | head -1
echo "Release Bundle ID:"
grep PRODUCT_BUNDLE_IDENTIFIER Release.xcconfig | head -1
echo ""

# Check Products.storekit
echo "2. Products in StoreKit Configuration:"
if [ -f "Products.storekit" ]; then
    echo "Products.storekit found ✓"
    echo "Product IDs configured:"
    grep -o '"productID"[[:space:]]*:[[:space:]]*"[^"]*"' Products.storekit | sed 's/"productID"[[:space:]]*:[[:space:]]*"/  - /'
    echo ""
    echo "App Store Connect App ID:"
    grep "_applicationInternalID" Products.storekit | head -1
    echo "Team ID:"
    grep "_developerTeamID" Products.storekit | head -1
else
    echo "Products.storekit not found ✗"
fi
echo ""

# Check code implementation
echo "3. Product IDs in Code:"
grep -h "premiumWeekly\|premiumQuarterly\|premiumYearly" Growth/Core/Models/SubscriptionProduct.swift | grep "static let" | head -3
echo ""

# Check scheme configuration
echo "4. Scheme Configuration:"
if [ -f "Growth.xcodeproj/xcshareddata/xcschemes/Growth.xcscheme" ]; then
    echo "Debug Scheme StoreKit Configuration:"
    grep -A1 "StoreKitConfigurationFileReference" Growth.xcodeproj/xcshareddata/xcschemes/Growth.xcscheme | head -2
fi
echo ""

echo "5. Recommendations:"
echo "-------------------"
echo "• For testing with local products: Use iOS Simulator"
echo "• For device testing: Products must exist in App Store Connect"
echo "• Bundle ID in debug (*.dev) doesn't match product IDs"
echo "• Consider creating test products with .dev suffix for debug builds"
echo ""
echo "To test immediately:"
echo "1. Open Xcode: open Growth.xcodeproj"
echo "2. Select an iPhone Simulator (not a physical device)"
echo "3. Run the app (Cmd+R)"
echo "4. Products should load from Products.storekit file"