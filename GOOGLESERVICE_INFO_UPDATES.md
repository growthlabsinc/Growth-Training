# GoogleService-Info.plist Updates

## Changes Made

### 1. **Development Environment** (`dev.GoogleService-Info.plist`)
- **Changed**: Bundle ID from `com.growthtraining.Growth` → `com.growthlabs.growthmethod.dev`
- Now matches what `EnvironmentDetector.swift` expects

### 2. **Staging Environment** (`staging.GoogleService-Info.plist`)
- **Changed**: Bundle ID from `com.growthtraining.Growth` → `com.growthlabs.growthmethod.staging`
- Now matches what `EnvironmentDetector.swift` expects

### 3. **Production Environment** (`GoogleService-Info.plist`)
- **No changes needed** - Already has correct bundle ID: `com.growthlabs.growthmethod`

## ⚠️ Important Notes

### Bundle ID Alignment
The plist files now have bundle IDs that match what your code expects:
- Dev: `com.growthlabs.growthmethod.dev`
- Staging: `com.growthlabs.growthmethod.staging`
- Prod: `com.growthlabs.growthmethod`

### Firebase Configuration Issues
**WARNING**: The dev and staging plist files still have identical Firebase configurations:
- Same Client ID: `645068839446-e2hieedodcgv06djtr02adbiv7cmv2ub`
- Same Google App ID: `1:645068839446:ios:7782656347bee14bfc3337`
- Same API Key: `AIzaSyAG_6EUgBI75ICsMqNwZJGKOHH9y3Q8-To`

This means both environments are pointing to the same Firebase app/project.

## Next Steps

### Option 1: Create Separate Firebase Apps (Recommended)
1. Go to Firebase Console
2. Create separate iOS apps for:
   - Development with bundle ID: `com.growthlabs.growthmethod.dev`
   - Staging with bundle ID: `com.growthlabs.growthmethod.staging`
3. Download the new GoogleService-Info.plist files
4. Replace the current dev and staging plist files

### Option 2: Use Single Firebase Project
If you want to use the same Firebase project for all environments:
1. Add the dev and staging bundle IDs to your existing Firebase iOS app
2. In Firebase Console → Project Settings → Your iOS app → Add bundle ID
3. Add both:
   - `com.growthlabs.growthmethod.dev`
   - `com.growthlabs.growthmethod.staging`

### Option 3: Update Xcode Build Settings
To actually use different environments, update your Xcode project:
1. Create different build configurations for Dev, Staging, and Production
2. Set different bundle identifiers for each configuration
3. Use different schemes to build with different configurations

## Testing Different Environments

To test if the environment detection is working:
1. Change your app's bundle identifier in Xcode to one of:
   - `com.growthlabs.growthmethod.dev`
   - `com.growthlabs.growthmethod.staging`
   - `com.growthlabs.growthmethod`
2. Run the app and check the console logs for "Firebase configured for environment: [dev/staging/prod]"

## Current Status
- ✅ Bundle IDs in plist files now match EnvironmentDetector expectations
- ⚠️ Dev and staging still point to the same Firebase backend
- ✅ Production configuration is correct and working