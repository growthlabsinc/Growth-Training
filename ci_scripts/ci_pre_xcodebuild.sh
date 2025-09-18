#!/bin/sh

# ci_pre_xcodebuild.sh
# This script runs before the build phase
# It configures build settings and environment variables

set -e  # Exit on error

echo "🏗️ Running pre-build setup for Growth app..."

# Set build number from Xcode Cloud
if [ ! -z "$CI_BUILD_NUMBER" ]; then
    echo "📝 Setting build number to $CI_BUILD_NUMBER"
    
    # Update the main Info.plist
    INFO_PLIST="Growth/Resources/Plist/App/Info.plist"
    if [ -f "$INFO_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$INFO_PLIST"
        echo "✅ Updated CFBundleVersion in Info.plist"
    else
        echo "⚠️  Warning: Info.plist not found at $INFO_PLIST"
    fi
    
    # Also update the widget extension Info.plist if it exists
    WIDGET_INFO_PLIST="GrowthTimerWidget/Info.plist"
    if [ -f "$WIDGET_INFO_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$WIDGET_INFO_PLIST"
        echo "✅ Updated CFBundleVersion in Widget Info.plist"
    fi
fi

# Set up Firebase configuration from environment if provided
if [ ! -z "$FIREBASE_CONFIG_BASE64" ]; then
    echo "🔐 Creating Firebase configuration from environment..."
    echo "$FIREBASE_CONFIG_BASE64" | base64 -d > Growth/Resources/Plist/GoogleService-Info.plist
    echo "✅ Firebase configuration created"
fi

# Configure environment-specific settings
echo "🌍 Configuring for environment: ${CI_XCODE_SCHEME:-Unknown}"
case "$CI_XCODE_SCHEME" in
    "Growth Dev")
        echo "📱 Building for Development environment"
        # Dev-specific configurations
        ;;
    "Growth Staging")
        echo "🧪 Building for Staging environment"
        # Staging-specific configurations
        ;;
    "Growth")
        echo "🚀 Building for Production environment"
        # Production-specific configurations
        ;;
    *)
        echo "⚠️  Unknown scheme: $CI_XCODE_SCHEME"
        ;;
esac

# Set up code signing (Xcode Cloud handles this automatically)
echo "🔐 Code signing will be handled by Xcode Cloud automatic signing"

# Verify required files exist
echo "🔍 Verifying required files..."
required_files=(
    "Growth.xcodeproj/project.pbxproj"
    "Growth/Resources/Plist/App/Info.plist"
    "Growth/Application/GrowthAppApp.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing required file: $file"
        exit 1
    fi
done

# Set custom build settings if needed
if [ ! -z "$CI_WORKFLOW" ]; then
    echo "🔧 Applying workflow-specific settings for: $CI_WORKFLOW"
    
    # Example: Different settings for different workflows
    case "$CI_WORKFLOW" in
        *"Release"*)
            echo "📦 Configuring for Release build"
            # Add any release-specific settings
            ;;
        *"TestFlight"*)
            echo "✈️ Configuring for TestFlight distribution"
            # Add any TestFlight-specific settings
            ;;
    esac
fi

# Log environment for debugging
echo "📊 Build environment:"
echo "   - Xcode: $CI_XCODE_VERSION"
echo "   - macOS: $CI_MACOS_VERSION"
echo "   - Scheme: $CI_XCODE_SCHEME"
echo "   - Configuration: ${CI_XCODE_CONFIGURATION:-Default}"

echo "✅ Pre-build setup complete!"