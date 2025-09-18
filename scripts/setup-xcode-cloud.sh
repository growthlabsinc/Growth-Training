#!/bin/bash

# setup-xcode-cloud.sh
# Quick setup script for Xcode Cloud

echo "🚀 Xcode Cloud Setup Helper for Growth App"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "Growth.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Must run from project root directory"
    exit 1
fi

# Step 1: Ensure scheme is shared
echo "1️⃣ Checking Xcode scheme..."
SCHEME_PATH="Growth.xcodeproj/xcshareddata/xcschemes/Growth.xcscheme"
if [ -f "$SCHEME_PATH" ]; then
    echo "✅ Scheme 'Growth' is already shared"
else
    echo "⚠️  Scheme 'Growth' needs to be shared in Xcode:"
    echo "   1. Open Xcode"
    echo "   2. Go to Product → Scheme → Manage Schemes"
    echo "   3. Check 'Shared' for the Growth scheme"
fi

# Step 2: Check Package.resolved
echo -e "\n2️⃣ Checking Swift Package Manager..."
PACKAGE_RESOLVED="Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo "✅ Package.resolved exists"
else
    echo "⚠️  Package.resolved missing - will be created on first build"
fi

# Step 3: Verify CI scripts
echo -e "\n3️⃣ Checking CI scripts..."
CI_SCRIPTS=("ci_post_clone.sh" "ci_pre_xcodebuild.sh" "ci_post_xcodebuild.sh")
for script in "${CI_SCRIPTS[@]}"; do
    if [ -f "ci_scripts/$script" ] && [ -x "ci_scripts/$script" ]; then
        echo "✅ $script is present and executable"
    else
        echo "❌ Missing or not executable: ci_scripts/$script"
    fi
done

# Step 4: Check Firebase configuration
echo -e "\n4️⃣ Checking Firebase configuration..."
FIREBASE_CONFIGS=(
    "Growth/Resources/Plist/GoogleService-Info.plist"
    "Growth/Resources/Plist/dev.GoogleService-Info.plist"
    "Growth/Resources/Plist/staging.GoogleService-Info.plist"
)
for config in "${FIREBASE_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ Found: $config"
    else
        echo "⚠️  Missing: $config"
    fi
done

# Step 5: Generate workflow recommendations
echo -e "\n5️⃣ Recommended Xcode Cloud Workflows:"
echo ""
echo "📱 Development Workflow:"
echo "   - Name: 'Dev - Continuous Integration'"
echo "   - Start: Push to 'develop' branch"
echo "   - Actions: Build, Test, Archive"
echo "   - Post-Actions: Deploy to TestFlight (Internal)"
echo ""
echo "🚀 Production Workflow:"
echo "   - Name: 'Prod - Release'"
echo "   - Start: Push to 'main' branch"
echo "   - Actions: Build, Test, Archive"
echo "   - Post-Actions: Deploy to TestFlight (External)"
echo ""
echo "🔍 Pull Request Workflow:"
echo "   - Name: 'PR - Validation'"
echo "   - Start: Pull Request to 'main' or 'develop'"
echo "   - Actions: Build, Test"
echo "   - Post-Actions: Comment on PR"

# Step 6: Next steps
echo -e "\n📋 Next Steps:"
echo "1. Open project in Xcode"
echo "2. Select Product → Xcode Cloud → Create Workflow"
echo "3. Sign in with your Apple ID"
echo "4. Grant access to your GitHub repository"
echo "5. Configure your first workflow using recommendations above"
echo ""
echo "📚 For detailed instructions, see: docs/xcode-cloud-setup.md"
echo ""
echo "✅ Setup check complete!"