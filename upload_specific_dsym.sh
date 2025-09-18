#!/bin/bash

# Upload a specific dSYM file to Firebase Crashlytics

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_dsym_or_folder>"
    echo "Example: $0 ~/Downloads/dSYMs"
    exit 1
fi

DSYM_PATH="$1"

echo "📤 Uploading specific dSYM to Firebase Crashlytics"
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
    exit 1
fi

# Path to GoogleService-Info.plist (production)
GOOGLE_PLIST="./Growth/Resources/Plist/GoogleService-Info.plist"

# Check if path exists
if [ ! -e "$DSYM_PATH" ]; then
    echo "❌ Path not found: $DSYM_PATH"
    exit 1
fi

# If it's a directory containing dSYMs
if [ -d "$DSYM_PATH" ]; then
    # Look for .dSYM files in the directory
    for dsym in "$DSYM_PATH"/*.dSYM; do
        if [ -d "$dsym" ]; then
            echo "📤 Uploading: $(basename "$dsym")"
            "$UPLOAD_SCRIPT" -gsp "$GOOGLE_PLIST" -p ios "$dsym"
            echo "✅ Uploaded: $(basename "$dsym")"
        fi
    done
    
    # Also check if the directory itself is a dSYM
    if [[ "$DSYM_PATH" == *.dSYM ]]; then
        echo "📤 Uploading: $(basename "$DSYM_PATH")"
        "$UPLOAD_SCRIPT" -gsp "$GOOGLE_PLIST" -p ios "$DSYM_PATH"
        echo "✅ Uploaded: $(basename "$DSYM_PATH")"
    fi
else
    echo "❌ Not a directory: $DSYM_PATH"
    exit 1
fi

echo ""
echo "=================================================="
echo "🎉 Upload complete! Check Firebase Console."
echo "   https://console.firebase.google.com/project/growth-70a85/crashlytics"
echo ""
echo "The 7 crashes from version 1.1.0 should now be processed."