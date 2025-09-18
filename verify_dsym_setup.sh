#!/bin/bash

echo "🔍 Verifying dSYM Upload Setup"
echo "=============================="

# Check if upload-symbols exists
UPLOAD_SCRIPT="${HOME}/Library/Developer/Xcode/DerivedData/Growth-*/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

if ls $UPLOAD_SCRIPT 1> /dev/null 2>&1; then
    echo "✅ Upload script found at SPM location"
else
    echo "⚠️  Upload script not found at SPM location"
    echo "   This is normal if you haven't built recently"
fi

# Check GoogleService-Info.plist
if [ -f "Growth/Resources/Plist/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "❌ GoogleService-Info.plist not found"
fi

# Check current project settings
echo ""
echo "📋 Current Build Settings to Verify:"
echo "-------------------------------------"
echo "1. Debug Information Format: Should be 'DWARF with dSYM File'"
echo "2. Generate Debug Symbols: Should be 'YES'"
echo "3. Enable Bitcode: Should be 'NO' (or you'll need manual downloads)"
echo ""
echo "To check these:"
echo "  Xcode → Project → Build Settings → Search for each setting"

# Check if there are any recent dSYMs
echo ""
echo "📦 Recent dSYMs in DerivedData:"
find ~/Library/Developer/Xcode/DerivedData -name "*.dSYM" -type d -mtime -1 2>/dev/null | head -5

echo ""
echo "=============================="
echo "Next Steps:"
echo "1. Add the build phase in Xcode (see setup_automatic_dsym_xcode.md)"
echo "2. Archive and upload a new build"
echo "3. Check Firebase Console after upload"