#!/bin/bash

# Script to add all required Firebase dependencies to the Growth iOS project
echo "Adding Firebase dependencies to the Growth iOS project..."

# Path to the Xcode project file
PROJECT_PATH="Growth.xcodeproj"

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Xcode project not found at $PROJECT_PATH"
    exit 1
fi

# Add Firebase dependencies using Swift Package Manager
echo "Adding Firebase dependencies using Swift Package Manager..."

# The Firebase iOS SDK GitHub URL
FIREBASE_URL="https://github.com/firebase/firebase-ios-sdk.git"

# Use xcodebuild to add the package (prints a lot of output, so we redirect to a log file)
echo "This might take a few minutes. Adding Firebase package from $FIREBASE_URL..."
xcodebuild -project "$PROJECT_PATH" -scheme "Growth" -resolvePackageDependencies -packageDirectory ./SPM > add-dependencies.log 2>&1

# Edit the Package.swift file to include the specific Firebase products we need
echo "Adding specific Firebase products..."
cat > ./SPM/Package.swift << EOL
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "GrowthDependencies",
    platforms: [.iOS(.v16)],
    products: [],
    dependencies: [
        .package(url: "$FIREBASE_URL", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .target(
            name: "GrowthDependencies",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
            ]
        )
    ]
)
EOL

# Resolve dependencies again to ensure everything is properly added
echo "Resolving dependencies..."
xcodebuild -project "$PROJECT_PATH" -scheme "Growth" -resolvePackageDependencies -packageDirectory ./SPM >> add-dependencies.log 2>&1

# Check if the operation was successful
if [ $? -eq 0 ]; then
    echo "✅ Firebase dependencies added successfully!"
    echo "The following Firebase products have been added:"
    echo "- FirebaseAuth"
    echo "- FirebaseFirestore"
    echo "- FirebaseFunctions"
    echo "- FirebaseAnalytics" 
    echo "- FirebaseCrashlytics"
    echo "- FirebaseRemoteConfig"
    echo ""
    echo "You can now build and run your project."
else
    echo "❌ Error adding Firebase dependencies. Check add-dependencies.log for details."
    exit 1
fi

# Alternative manual instructions
echo ""
echo "If the automated installation didn't work, you can add dependencies manually:"
echo "1. Open $PROJECT_PATH in Xcode"
echo "2. Go to File > Add Packages..."
echo "3. Enter URL: $FIREBASE_URL"
echo "4. Select the following Firebase products:"
echo "   - FirebaseAuth"
echo "   - FirebaseFirestore"
echo "   - FirebaseFunctions"
echo "   - FirebaseAnalytics"
echo "   - FirebaseCrashlytics"
echo "   - FirebaseRemoteConfig"
echo "5. Click 'Add Package'" 