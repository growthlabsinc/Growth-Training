# Xcode Cloud Setup Guide for Growth App

## Overview
Xcode Cloud is Apple's continuous integration and delivery (CI/CD) service built into Xcode. It automatically builds, tests, and distributes your app when you push changes to your repository.

## Prerequisites

1. **Apple Developer Account**: You need an active Apple Developer Program membership
2. **Xcode 13+**: Xcode Cloud requires Xcode 13 or later
3. **GitHub Repository**: Your project is already hosted on GitHub
4. **App Store Connect Access**: Admin or App Manager role

## Initial Setup Steps

### 1. Enable Xcode Cloud in App Store Connect

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app (Growth)
3. Click on "Xcode Cloud" in the sidebar
4. Click "Get Started" to enable Xcode Cloud for your app

### 2. Connect Xcode to Your Repository

1. Open the Growth project in Xcode
2. Navigate to **Product > Xcode Cloud > Create Workflow**
3. Select your project and click "Next"
4. Choose your source control provider (GitHub)
5. Authenticate with GitHub if prompted
6. Select the repository: `growthlabsinc/GrowthMethod`

### 3. Configure Your First Workflow

Create a basic CI workflow that builds and tests on every push:

1. **Workflow Name**: "CI - Main Branch"
2. **Start Conditions**:
   - Branch Changes: `main`
   - Pull Request Changes: Enabled
3. **Environment**:
   - Xcode Version: Latest Release
   - macOS Version: Latest
4. **Actions**:
   - Build
   - Run Tests
   - Create Archive (for main branch only)

## Project Configuration

### 1. Create Xcode Cloud Configuration File

Create `ci_scripts/ci_post_clone.sh`:

```bash
#!/bin/sh

# ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository

echo "🔧 Running post-clone setup..."

# Set up environment
export LANG=en_US.UTF-8

# Install Firebase CLI if needed for cloud functions
if [ -d "functions" ]; then
    echo "📦 Installing Firebase Functions dependencies..."
    cd functions
    npm ci --prefer-offline --no-audit
    cd ..
fi

# Copy production Firebase config
echo "📋 Setting up Firebase configuration..."
if [ -f "Growth/Resources/Plist/GoogleService-Info.plist" ]; then
    echo "✅ Firebase config already exists"
else
    echo "❌ Warning: GoogleService-Info.plist not found"
    # You may want to copy from a secure location or use environment variables
fi

# Ensure proper permissions
chmod +x scripts/*.sh || true

echo "✅ Post-clone setup complete"
```

Make it executable:
```bash
chmod +x ci_scripts/ci_post_clone.sh
```

### 2. Handle Dependencies

Since you're using Swift Package Manager (SPM), dependencies are automatically resolved. However, ensure your `Package.resolved` file is committed:

```bash
git add Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "Add Package.resolved for Xcode Cloud"
git push
```

### 3. Environment Variables and Secrets

For sensitive data like API keys:

1. In Xcode Cloud workflow settings, add environment variables:
   - `FIREBASE_API_KEY`
   - `APP_STORE_CONNECT_API_KEY`
   - `APP_STORE_CONNECT_API_ISSUER_ID`

2. Create `ci_scripts/ci_pre_xcodebuild.sh`:

```bash
#!/bin/sh

# ci_pre_xcodebuild.sh
# This script runs before the build phase

echo "🔐 Setting up environment variables..."

# Example: Set up Firebase configuration from environment
if [ ! -z "$FIREBASE_CONFIG_BASE64" ]; then
    echo "$FIREBASE_CONFIG_BASE64" | base64 -d > Growth/Resources/Plist/GoogleService-Info.plist
    echo "✅ Firebase configuration created from environment"
fi

# Set build number based on Xcode Cloud build number
if [ ! -z "$CI_BUILD_NUMBER" ]; then
    echo "📝 Setting build number to $CI_BUILD_NUMBER"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" Growth/Resources/Plist/App/Info.plist
fi

echo "✅ Pre-build setup complete"
```

### 4. Test Configuration

Create `ci_scripts/ci_post_xcodebuild.sh`:

```bash
#!/bin/sh

# ci_post_xcodebuild.sh
# This script runs after the build phase

echo "🧪 Running post-build tasks..."

# Upload debug symbols to Firebase Crashlytics
if [ -f "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}" ]; then
    echo "📤 Uploading dSYMs to Crashlytics..."
    # Add Crashlytics upload script here if needed
fi

echo "✅ Post-build tasks complete"
```

## Workflow Examples

### 1. Development Workflow

**File**: `.github/xcode-cloud/workflows/development.yml` (conceptual - configured in Xcode)

- **Trigger**: Push to `develop` branch
- **Actions**:
  1. Build Debug configuration
  2. Run unit tests
  3. Run UI tests on iPhone 15 simulator
  4. Upload to TestFlight (internal testing)

### 2. Release Workflow

**File**: `.github/xcode-cloud/workflows/release.yml` (conceptual - configured in Xcode)

- **Trigger**: Push to `main` branch with version tag
- **Actions**:
  1. Build Release configuration
  2. Run full test suite
  3. Create archive
  4. Upload to App Store Connect
  5. Submit for App Store review (manual)

### 3. Pull Request Workflow

- **Trigger**: Pull request to `main` or `develop`
- **Actions**:
  1. Build
  2. Run tests
  3. Post results to PR

## Firebase Functions Deployment

Since Xcode Cloud only handles iOS builds, you'll need a separate CI/CD for Firebase:

Create `.github/workflows/firebase-deploy.yml`:

```yaml
name: Deploy Firebase Functions

on:
  push:
    branches: [ main ]
    paths:
      - 'functions/**'
      - 'firebase.json'
      - '.firebaserc'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd functions && npm ci
      - name: Deploy to Firebase
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: |
          npm install -g firebase-tools
          firebase deploy --only functions --token "$FIREBASE_TOKEN"
```

## Best Practices

1. **Build Numbers**: Use Xcode Cloud's `CI_BUILD_NUMBER` for automatic versioning
2. **Branches**: 
   - `develop` → TestFlight (internal)
   - `main` → App Store release
3. **Testing**: Run tests on multiple device types
4. **Notifications**: Set up Slack/email notifications for build status

## Troubleshooting

### Common Issues

1. **"No Scheme Found"**
   - Ensure your scheme is shared: Product → Scheme → Manage Schemes → Check "Shared"

2. **"Dependencies Not Found"**
   - Commit `Package.resolved`
   - Ensure all packages are accessible

3. **"Code Signing Failed"**
   - Xcode Cloud handles signing automatically
   - Ensure your Bundle ID matches App Store Connect

4. **"Build Failed - Missing File"**
   - Check that all required files are committed
   - GoogleService-Info.plist should be in the repository or created via environment variables

## Next Steps

1. **Create your first workflow** in Xcode:
   ```
   Product → Xcode Cloud → Create Workflow
   ```

2. **Test the workflow** by pushing a commit:
   ```bash
   git commit --allow-empty -m "Test Xcode Cloud build"
   git push
   ```

3. **Monitor builds** in:
   - Xcode (Report Navigator)
   - App Store Connect (Xcode Cloud section)

4. **Set up TestFlight** for automatic distribution to testers

## Security Considerations

1. Never commit sensitive keys to the repository
2. Use Xcode Cloud environment variables for secrets
3. Restrict workflow triggers to protected branches
4. Enable two-factor authentication on all accounts

## Cost

Xcode Cloud includes:
- 25 compute hours/month (free tier)
- Additional hours available for purchase
- Parallel testing counts against compute time

## Resources

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [WWDC Videos on Xcode Cloud](https://developer.apple.com/videos/xcode-cloud)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)