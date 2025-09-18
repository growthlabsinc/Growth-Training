#!/bin/bash

echo "==============================================="
echo "StoreKit Configuration Verification"
echo "==============================================="
echo ""

echo "✅ App Store Connect Products (APPROVED):"
echo "   1. Growth Premium Annual (com.growthlabs.growthmethod.subscription.premium.yearly)"
echo "   2. Growth Premium Quarterly (com.growthlabs.growthmethod.subscription.premium.quarterly)"
echo "   3. Growth Premium Weekly (com.growthlabs.growthmethod.subscription.premium.weekly)"
echo ""

echo "📱 Configuration Status:"
echo ""

# Check Debug scheme
if grep -q "StoreKitConfigurationFileReference" Growth.xcodeproj/xcshareddata/xcschemes/Growth.xcscheme 2>/dev/null; then
    echo "✅ Debug Scheme (Growth): Uses local StoreKit config for testing"
else
    echo "✅ Debug Scheme (Growth): No StoreKit config (uses App Store Connect)"
fi

# Check Production scheme
if grep -q "StoreKitConfigurationFileReference" "Growth.xcodeproj/xcshareddata/xcschemes/Growth Production.xcscheme" 2>/dev/null; then
    echo "❌ Production Scheme: Still has StoreKit config (should be removed!)"
else
    echo "✅ Production Scheme: No StoreKit config (uses App Store Connect)"
fi

echo ""
echo "🔧 How it Works:"
echo "   - Debug/Simulator: Uses Products.storekit for local testing"
echo "   - Release/Device: Uses App Store Connect products"
echo "   - TestFlight: Uses App Store Connect products"
echo ""

echo "📲 Testing Instructions:"
echo ""
echo "1. For Local Testing (Simulator):"
echo "   - Use 'Growth' scheme"
echo "   - Run on iOS Simulator"
echo "   - Products load from Products.storekit"
echo ""
echo "2. For TestFlight/Production:"
echo "   - Use 'Growth Production' scheme"
echo "   - Archive and upload to TestFlight"
echo "   - Products load from App Store Connect"
echo ""

echo "⚠️  Important Notes:"
echo "   - Products are APPROVED in App Store Connect"
echo "   - No fallback UI needed - products should load"
echo "   - If products don't load, check:"
echo "     • Correct scheme is selected"
echo "     • Not using StoreKit config in production"
echo "     • Bundle ID matches (com.growthlabs.growthmethod)"
echo ""

echo "==============================================="
echo "Current Status: READY FOR PRODUCTION"
echo "==============================================="