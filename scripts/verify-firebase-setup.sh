#!/bin/bash

# Script to verify Firebase configuration is correct

# Function to print section divider
print_divider() {
    echo "================================================================================"
}

# Print header
print_divider
echo "🔥 Firebase Setup Verification Script 🔥"
print_divider
echo ""

# Check for Firebase configuration files
echo "Checking Firebase configuration files..."
DEV_CONFIG="Growth/Resources/Plist/dev.GoogleService-Info.plist"
STAGING_CONFIG="Growth/Resources/Plist/staging.GoogleService-Info.plist"
PROD_CONFIG="Growth/Resources/Plist/GoogleService-Info.plist"

CONFIG_STATUS="✅"

# Array to hold missing configuration files
MISSING_FILES=()

if [ ! -f "$DEV_CONFIG" ]; then
    MISSING_FILES+=("$DEV_CONFIG")
    CONFIG_STATUS="❌"
fi

if [ ! -f "$STAGING_CONFIG" ]; then
    MISSING_FILES+=("$STAGING_CONFIG")
    CONFIG_STATUS="❌"
fi

if [ ! -f "$PROD_CONFIG" ]; then
    MISSING_FILES+=("$PROD_CONFIG")
    CONFIG_STATUS="❌"
fi

echo -n "Firebase configuration files: $CONFIG_STATUS "

if [ "$CONFIG_STATUS" = "✅" ]; then
    echo "All configuration files are present."
else
    echo "Missing configuration files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Please create the necessary Firebase projects and download the configuration files."
    echo "Refer to the README.md for more information."
fi

echo ""

# Check for Package.swift or Podfile
echo "Checking dependency management setup..."
DEPENDENCY_STATUS="✅"

if [ -f "Package.swift" ]; then
    echo "✅ Package.swift found. Swift Package Manager is set up."
    
    # Look for Firebase dependencies in Package.swift
    if grep -q "firebase-ios-sdk" "Package.swift"; then
        echo "✅ Firebase dependencies are specified in Package.swift."
    else
        DEPENDENCY_STATUS="❌"
        echo "❌ Firebase dependencies not found in Package.swift."
        echo "   Run ./scripts/setup-dependencies.sh to set up Firebase properly."
    fi
elif [ -f "Podfile" ]; then
    echo "✅ Podfile found. CocoaPods is set up."
    
    # Look for Firebase dependencies in Podfile
    if grep -q "Firebase" "Podfile"; then
        echo "✅ Firebase dependencies are specified in Podfile."
        
        # Check if pods are installed
        if [ -d "Pods" ]; then
            echo "✅ Pods directory found. CocoaPods dependencies are installed."
        else
            DEPENDENCY_STATUS="❌"
            echo "❌ Pods directory not found. Run 'pod install' to install dependencies."
        fi
    else
        DEPENDENCY_STATUS="❌"
        echo "❌ Firebase dependencies not found in Podfile."
        echo "   Run ./scripts/setup-dependencies.sh to set up Firebase properly."
    fi
else
    DEPENDENCY_STATUS="❌"
    echo "❌ Neither Package.swift nor Podfile found."
    echo "   Run ./scripts/setup-dependencies.sh to set up Firebase."
fi

echo ""

# Check FirebaseClient.swift
echo "Checking FirebaseClient implementation..."
FIREBASE_CLIENT="Growth/Core/Networking/FirebaseClient.swift"

if [ -f "$FIREBASE_CLIENT" ]; then
    echo "✅ FirebaseClient.swift found."
    
    # Look for essential Firebase imports
    IMPORTS_FOUND=true
    MISSING_IMPORTS=()
    
    for import in "Firebase" "FirebaseAuth" "FirebaseFirestore" "FirebaseFunctions" "FirebaseRemoteConfig"; do
        if ! grep -q "import $import" "$FIREBASE_CLIENT"; then
            IMPORTS_FOUND=false
            MISSING_IMPORTS+=("$import")
        fi
    done
    
    if [ "$IMPORTS_FOUND" = true ]; then
        echo "✅ All essential Firebase imports found in FirebaseClient.swift."
    else
        echo "❌ Missing Firebase imports in FirebaseClient.swift:"
        for import in "${MISSING_IMPORTS[@]}"; do
            echo "  - $import"
        done
    fi
else
    echo "❌ FirebaseClient.swift not found at expected location: $FIREBASE_CLIENT"
    echo "   This file is essential for Firebase integration."
fi

echo ""
print_divider
echo "🔥 Verification Summary 🔥"
print_divider

if [ "$CONFIG_STATUS" = "✅" ] && [ "$DEPENDENCY_STATUS" = "✅" ] && [ -f "$FIREBASE_CLIENT" ]; then
    echo "✅ Firebase setup appears to be complete and correct."
    echo ""
    echo "Next steps:"
    echo "1. Open the Xcode project/workspace"
    echo "2. Build and run the app"
    echo "3. Check the console logs for Firebase initialization messages"
else
    echo "❌ Firebase setup is incomplete or incorrect."
    echo ""
    echo "Please address the issues mentioned above."
    echo "Run ./scripts/setup-dependencies.sh to properly set up Firebase dependencies."
fi

print_divider 