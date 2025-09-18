#!/bin/bash

# Script to fix Firebase integration issues in the Growth iOS project
echo "🔥 Firebase Integration Fixer 🔥"
echo "================================================================================"
echo "This script will help fix common Firebase integration issues."
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Xcode is installed
if ! command_exists xcodebuild; then
    echo "❌ Xcode command-line tools not found. Please install Xcode first."
    exit 1
fi

# Path to the Xcode project file
PROJECT_PATH="Growth.xcodeproj"

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Error: Xcode project not found at $PROJECT_PATH"
    exit 1
fi

echo "Checking dependency management setup..."

# Check for SPM vs CocoaPods setup
if [ -f "Package.swift" ]; then
    echo "✅ Using Swift Package Manager for dependencies."
    DEPENDENCY_MANAGER="SPM"
    
    echo "Fixing SPM integration issues..."
    
    # Create a new Package.swift file with correct configuration
    echo "Updating Package.swift file..."
    cat > Package.swift << EOL
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Growth",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Growth",
            targets: ["Growth"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Growth",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
            ],
            path: "Growth"
        ),
        .testTarget(
            name: "GrowthTests",
            dependencies: ["Growth"],
            path: "GrowthTests"
        )
    ]
)
EOL
    
    # Close Xcode if it's open
    echo "Closing Xcode if it's open (this may require authentication)..."
    killall Xcode 2>/dev/null || true
    
    # Remove SPM cache
    echo "Cleaning SPM cache..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    
    # Force Xcode to resolve dependencies
    echo "Resolving package dependencies..."
    xcodebuild -resolvePackageDependencies -project "$PROJECT_PATH"
    
    # Check import in AppDelegate.swift
    APPDELEGATE="Growth/Application/AppDelegate.swift"
    if [ -f "$APPDELEGATE" ]; then
        echo "Checking AppDelegate.swift for proper imports..."
        if ! grep -q "import Firebase" "$APPDELEGATE"; then
            echo "Adding Firebase import to AppDelegate.swift..."
            # Create a temporary file with the import
            sed -i '' '1s/^/import Firebase\n/' "$APPDELEGATE"
            echo "✅ Fixed import in AppDelegate.swift"
        else
            echo "✅ Firebase import already present in AppDelegate.swift"
        fi
    else
        echo "❌ AppDelegate.swift not found at expected location: $APPDELEGATE"
    fi
    
    echo ""
    echo "✅ Fixed Swift Package Manager integration issues."
    echo ""
    echo "Please try the following steps:"
    echo "1. Open the project in Xcode: open $PROJECT_PATH"
    echo "2. In Xcode, go to File > Packages > Reset Package Caches"
    echo "3. In Xcode, go to File > Packages > Resolve Package Versions"
    echo "4. Clean the build folder: Cmd+Shift+K"
    echo "5. Build the project: Cmd+B"
    
elif [ -f "Podfile" ]; then
    echo "✅ Using CocoaPods for dependencies."
    DEPENDENCY_MANAGER="PODS"
    
    echo "Fixing CocoaPods integration issues..."
    
    # Check if CocoaPods is installed
    if ! command_exists pod; then
        echo "❌ CocoaPods not found. Would you like to install it now? (requires RubyGems)"
        read -p "Install CocoaPods? (y/n): " install_pods
        
        if [[ $install_pods == "y" || $install_pods == "Y" ]]; then
            echo "Installing CocoaPods..."
            sudo gem install cocoapods
            
            if [ $? -ne 0 ]; then
                echo "❌ Failed to install CocoaPods. Please install it manually and run this script again."
                exit 1
            fi
        else
            echo "Please install CocoaPods manually and run this script again."
            exit 1
        fi
    fi
    
    # Close Xcode if it's open
    echo "Closing Xcode if it's open (this may require authentication)..."
    killall Xcode 2>/dev/null || true
    
    # Remove Pods directory and Podfile.lock to force reinstallation
    echo "Removing Pods directory and Podfile.lock..."
    rm -rf Pods
    rm -f Podfile.lock
    
    # Run pod install
    echo "Installing pods (this might take a while)..."
    pod install --repo-update
    
    if [ $? -eq 0 ]; then
        echo "✅ Fixed CocoaPods integration issues!"
        echo ""
        echo "Please try the following steps:"
        echo "1. Make sure Xcode is closed"
        echo "2. Open Growth.xcworkspace (NOT .xcodeproj) with: open Growth.xcworkspace"
        echo "3. Wait for Xcode to fully load"
        echo "4. Clean the build folder: Cmd+Shift+K"
        echo "5. Build the project: Cmd+B"
    else
        echo "❌ Error fixing CocoaPods integration. Check the error messages above."
        exit 1
    fi
else
    echo "❌ No dependency management files found (Package.swift or Podfile)."
    echo ""
    echo "Would you like to set up Firebase dependencies now?"
    read -p "Set up Firebase dependencies? (y/n): " setup_deps
    
    if [[ $setup_deps == "y" || $setup_deps == "Y" ]]; then
        echo "Running setup-dependencies.sh..."
        bash scripts/setup-dependencies.sh
    else
        echo "Please run scripts/setup-dependencies.sh manually to set up Firebase."
        exit 1
    fi
fi

echo ""
echo "================================================================================"
echo "🔥 Firebase Integration Fix Completed 🔥"
echo ""
echo "If you're still experiencing issues, please try manual integration:"
echo ""
echo "1. Check if you have correct GoogleService-Info.plist files in place:"
echo "   - Development: Growth/Resources/Plist/dev.GoogleService-Info.plist"
echo "   - Staging: Growth/Resources/Plist/staging.GoogleService-Info.plist"
echo "   - Production: Growth/Resources/Plist/GoogleService-Info.plist"
echo ""
echo "2. Ensure FirebaseClient.swift correctly initializes Firebase"
echo ""
echo "3. If you're using SPM, try manually adding Firebase packages in Xcode:"
echo "   - Go to File > Add Packages"
echo "   - Enter URL: https://github.com/firebase/firebase-ios-sdk.git"
echo "   - Select the required Firebase products"
echo ""
echo "4. Verify that the app has the correct capabilities enabled in Xcode"
echo "================================================================================" 