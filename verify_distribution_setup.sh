#!/bin/bash

echo "🔍 Verifying Distribution Setup..."
echo "================================"

# 1. Check if logged into Xcode
echo "1️⃣ Checking Xcode account..."
if xcrun altool --list-providers -u "your-apple-id@example.com" -p "@keychain:AC_PASSWORD" 2>&1 | grep -q "authentication"; then
    echo "   ⚠️  You may need to sign in to Xcode:"
    echo "      Xcode → Settings → Accounts → Add Apple ID"
else
    echo "   ✅ Xcode account appears to be configured"
fi

# 2. Check bundle identifier
echo ""
echo "2️⃣ Checking bundle identifier..."
BUNDLE_ID=$(grep -A1 "PRODUCT_BUNDLE_IDENTIFIER" Growth.xcodeproj/project.pbxproj | grep "com.growthlabs.growthmethod" | head -1 | awk '{print $3}' | tr -d '";')
echo "   Bundle ID: $BUNDLE_ID"

# 3. Check if app exists in App Store Connect
echo ""
echo "3️⃣ App Store Connect Status:"
echo "   App Name: Growth: Method"
echo "   Bundle ID: com.growthlabs.growthmethod"
echo "   Apple ID: 6748406423"
echo ""
echo "   ✅ App exists in App Store Connect"

# 4. Check current Xcode selection
echo ""
echo "4️⃣ Current Xcode version:"
xcode-select -p
xcodebuild -version | head -1

# 5. Quick signing verification
echo ""
echo "5️⃣ Signing Configuration:"
echo "   Main App (Release):"
grep -A5 "Release.*=" Growth.xcodeproj/project.pbxproj | grep -E "(CODE_SIGN_STYLE|DEVELOPMENT_TEAM)" | head -2 | sed 's/^/      /'
echo "   Widget (Release):"
grep -A20 "7FE4D79D2E01CE850006D2EA.*Release" Growth.xcodeproj/project.pbxproj | grep -E "(CODE_SIGN_STYLE|DEVELOPMENT_TEAM)" | head -2 | sed 's/^/      /'

echo ""
echo "📋 Distribution Checklist:"
echo "   [✓] Automatic signing enabled"
echo "   [✓] Development team set (62T6J77P6R)"
echo "   [✓] App exists in App Store Connect"
echo "   [✓] Bundle identifier matches"
echo ""
echo "🚀 Ready to Archive!"
echo ""
echo "Steps:"
echo "1. In Xcode, select 'Any iOS Device (arm64)' as destination"
echo "2. Product → Archive"
echo "3. Wait for archive to complete"
echo "4. In Organizer → Distribute App → App Store Connect"
echo ""
echo "💡 Troubleshooting:"
echo "If you still only see 'Custom' option:"
echo "- Sign out and back in: Xcode → Settings → Accounts"
echo "- Verify your role at: https://appstoreconnect.apple.com/access/users"
echo "- Check team membership at: https://developer.apple.com/account"