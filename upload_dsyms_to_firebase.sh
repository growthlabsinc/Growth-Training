#!/bin/bash

# Upload dSYMs to Firebase Crashlytics
# This script finds and uploads missing dSYM files

echo "🔍 Finding and uploading dSYMs to Firebase Crashlytics..."
echo "=================================================="

# Path to Firebase upload script
UPLOAD_SCRIPT="${HOME}/Library/Developer/Xcode/DerivedData/Growth-adkrbxoexjakjgdutkjorzolwbvt/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

# Alternative path if not found
if [ ! -f "$UPLOAD_SCRIPT" ]; then
    UPLOAD_SCRIPT="./Pods/FirebaseCrashlytics/upload-symbols"
fi

# Check if upload script exists
if [ ! -f "$UPLOAD_SCRIPT" ]; then
    echo "❌ Firebase upload-symbols script not found!"
    echo "   Try running: pod install"
    exit 1
fi

# Path to GoogleService-Info.plist (production)
GOOGLE_PLIST="./Growth/Resources/Plist/GoogleService-Info.plist"

# Find the most recent archive dSYMs
ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Growth.app.dSYM" -type d 2>/dev/null | grep -i archive | head -1)
WIDGET_DSYM=$(find ~/Library/Developer/Xcode/DerivedData -name "GrowthTimerWidgetExtension.app.dSYM" -type d 2>/dev/null | grep -i archive | head -1)

if [ -z "$ARCHIVE_PATH" ]; then
    echo "⚠️  No archive dSYMs found. Looking for build dSYMs..."
    ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Growth.app.dSYM" -type d 2>/dev/null | head -1)
    WIDGET_DSYM=$(find ~/Library/Developer/Xcode/DerivedData -name "GrowthTimerWidgetExtension.app.dSYM" -type d 2>/dev/null | head -1)
fi

# Upload main app dSYM
if [ -d "$ARCHIVE_PATH" ]; then
    echo "📤 Uploading main app dSYM..."
    echo "   Path: $ARCHIVE_PATH"
    "$UPLOAD_SCRIPT" -gsp "$GOOGLE_PLIST" -p ios "$ARCHIVE_PATH"
    echo "✅ Main app dSYM uploaded"
else
    echo "❌ Main app dSYM not found"
fi

# Upload widget extension dSYM
if [ -d "$WIDGET_DSYM" ]; then
    echo "📤 Uploading widget extension dSYM..."
    echo "   Path: $WIDGET_DSYM"
    "$UPLOAD_SCRIPT" -gsp "$GOOGLE_PLIST" -p ios "$WIDGET_DSYM"
    echo "✅ Widget extension dSYM uploaded"
else
    echo "⚠️  Widget extension dSYM not found (this is okay if not using widgets)"
fi

echo ""
echo "=================================================="
echo "🎉 Upload complete! Check Firebase Console in a few minutes."
echo "   https://console.firebase.google.com/project/growth-70a85/crashlytics"