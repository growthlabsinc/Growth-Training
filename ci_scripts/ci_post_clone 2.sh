#!/bin/sh

# ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository
# It sets up the environment and prepares dependencies

set -e  # Exit on error

echo "🔧 Running post-clone setup for Growth app..."

# Set up environment
export LANG=en_US.UTF-8

# Log environment info
echo "📍 Current directory: $(pwd)"
echo "📦 Xcode version: $CI_XCODE_VERSION"
echo "🔢 Build number: $CI_BUILD_NUMBER"

# Install Firebase Functions dependencies if needed
if [ -d "functions" ]; then
    echo "📦 Installing Firebase Functions dependencies..."
    cd functions
    npm ci --prefer-offline --no-audit --no-fund
    cd ..
    echo "✅ Firebase dependencies installed"
fi

# Verify Firebase configuration files exist
echo "🔍 Checking Firebase configuration..."
for env in "dev" "staging" "prod"; do
    if [ "$env" = "prod" ]; then
        config_file="Growth/Resources/Plist/GoogleService-Info.plist"
    else
        config_file="Growth/Resources/Plist/${env}.GoogleService-Info.plist"
    fi
    
    if [ -f "$config_file" ]; then
        echo "✅ Found $env Firebase config"
    else
        echo "⚠️  Warning: $config_file not found"
    fi
done

# Ensure build scripts are executable
echo "🔐 Setting script permissions..."
find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Clean any previous build artifacts
echo "🧹 Cleaning previous artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-* 2>/dev/null || true

# Verify Swift Package Dependencies
echo "📦 Verifying Swift Package Manager setup..."
if [ -f "Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ Package.resolved found"
else
    echo "⚠️  Warning: Package.resolved not found - SPM will resolve dependencies"
fi

# Create required directories if they don't exist
echo "📁 Ensuring required directories exist..."
mkdir -p Growth/Resources/Plist/App
mkdir -p Growth/Resources/Fonts

# Log completion
echo "✅ Post-clone setup complete!"
echo "📊 Setup summary:"
echo "   - Environment: $CI_XCODE_SCHEME"
echo "   - Branch: $CI_BRANCH"
echo "   - Workflow: $CI_WORKFLOW"