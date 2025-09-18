#!/bin/bash

# Script to set up Firebase dependencies for the Growth iOS project
# Supports both Swift Package Manager (SPM) and CocoaPods

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section divider
print_divider() {
    echo "================================================================================"
}

# Print header
print_divider
echo "🔥 Firebase Dependencies Setup Script for Growth iOS App 🔥"
print_divider
echo ""

# Ask user which dependency manager to use
echo "How would you like to add Firebase dependencies?"
echo "1) Swift Package Manager (recommended)"
echo "2) CocoaPods"
echo ""
read -p "Enter your choice (1/2): " dep_manager_choice

case $dep_manager_choice in
    1)
        echo ""
        echo "Setting up Firebase dependencies using Swift Package Manager..."
        
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
        
        # The Firebase iOS SDK GitHub URL
        FIREBASE_URL="https://github.com/firebase/firebase-ios-sdk.git"
        
        echo "This will add Firebase dependencies to your project using SPM."
        echo "Note: This process might take several minutes."
        echo ""
        echo "Adding the following Firebase products:"
        echo "- FirebaseAuth"
        echo "- FirebaseFirestore"
        echo "- FirebaseFunctions"
        echo "- FirebaseAnalytics" 
        echo "- FirebaseCrashlytics"
        echo "- FirebaseRemoteConfig"
        echo ""
        
        read -p "Press Enter to continue or Ctrl+C to cancel..."
        
        echo ""
        echo "📦 Adding Firebase package from $FIREBASE_URL..."
        
        # Create or verify Package.swift file exists
        if [ ! -f "Package.swift" ]; then
            echo "Creating Package.swift file..."
            cat > Package.swift << EOL
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Growth",
    platforms: [.iOS(.v16)],
    products: [],
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
        else
            echo "Package.swift file already exists. Using existing file."
        fi
        
        echo "Resolving dependencies (this might take a while)..."
        xcodebuild -resolvePackageDependencies -project "$PROJECT_PATH" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ Firebase dependencies added successfully using Swift Package Manager!"
            echo ""
            echo "Next steps:"
            echo "1. Open your Xcode project"
            echo "2. Wait for SPM to fetch and resolve dependencies"
            echo "3. Build and run your project"
        else
            echo "❌ Error adding Firebase dependencies with Swift Package Manager."
            echo ""
            echo "You can try the following manual steps instead:"
            echo "1. Open $PROJECT_PATH in Xcode"
            echo "2. Go to File > Add Packages..."
            echo "3. Enter URL: $FIREBASE_URL"
            echo "4. Select the required Firebase products"
            echo "5. Click 'Add Package'"
        fi
        ;;
        
    2)
        echo ""
        echo "Setting up Firebase dependencies using CocoaPods..."
        
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
        
        # Check if Podfile exists, create if not
        if [ ! -f "Podfile" ]; then
            echo "Creating Podfile..."
            cat > Podfile << EOL
# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'Growth' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Firebase pods
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'
  
  target 'GrowthTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'GrowthUITests' do
    # Pods for UI testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # For Firebase Crashlytics
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    end
  end
end
EOL
        else
            echo "Podfile already exists. Using existing file."
        fi
        
        echo "Installing pods (this might take a while)..."
        pod install
        
        if [ $? -eq 0 ]; then
            echo "✅ Firebase dependencies added successfully using CocoaPods!"
            echo ""
            echo "Next steps:"
            echo "1. Close Xcode if it's open"
            echo "2. Open Growth.xcworkspace (not the .xcodeproj file)"
            echo "3. Build and run your project"
        else
            echo "❌ Error installing Firebase dependencies with CocoaPods."
            echo "Check the error messages above for more information."
        fi
        ;;
    *)
        echo "Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac

# Final setup instructions
print_divider
echo "🔥 Firebase Configuration Setup 🔥"
print_divider
echo "Don't forget to add your Firebase configuration files:"
echo ""
echo "1. Create Firebase projects for each environment (Dev, Staging, Prod)"
echo "2. Download the GoogleService-Info.plist files"
echo "3. Add them to your project at the following locations:"
echo "   - Development: Growth/Resources/Plist/dev.GoogleService-Info.plist"
echo "   - Staging: Growth/Resources/Plist/staging.GoogleService-Info.plist"
echo "   - Production: Growth/Resources/Plist/GoogleService-Info.plist"
echo ""
echo "The FirebaseClient class is already set up to use these configuration files."
print_divider

echo "Setup completed! 🎉" 