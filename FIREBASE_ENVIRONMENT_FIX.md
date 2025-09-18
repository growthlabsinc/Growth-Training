# Firebase Environment Configuration Fix

## Issue
When building from Xcode with a production bundle ID (`com.growthlabs.growthmethod`), the app was trying to use production Firebase configuration but needed development APNs tokens and settings.

## Root Cause
- Xcode debug builds always generate development APNs tokens
- The app was selecting Firebase environment based on bundle ID alone
- This caused a mismatch where production Firebase configuration was used with development APNs tokens

## Solution

### 1. Force Development Environment for DEBUG Builds
Modified `EnvironmentDetector.swift` to always use development environment when building in DEBUG mode:

```swift
static func detectEnvironment() -> FirebaseEnvironment {
    // Check debug configuration first - this ensures Xcode builds use development
    #if DEBUG
    print("Running in DEBUG configuration, using development environment")
    return .development
    #else
    // ... production logic for release builds
    #endif
}
```

### 2. Add Development URL Scheme
Added the development Google Sign-In URL scheme to Info.plist:
```xml
<array>
    <string>com.googleusercontent.apps.645068839446-ornmecs6mg94okaqlp11oj6ouu1af74r</string>
    <string>com.googleusercontent.apps.645068839446-e2hieedodcgv06djtr02adbiv7cmv2ub</string>
</array>
```

### 3. Firebase Function Configuration
The `updateLiveActivitySimplified.js` function uses development APNs endpoint:
```javascript
const APNS_HOST = process.env.APNS_HOST || 'api.development.push.apple.com';
const KEY_ID = process.env.APNS_KEY_ID?.trim() || '55LZB28UY2'; // Development key
```

## Key Findings
1. **Xcode builds always use development APNs tokens** regardless of bundle ID
2. Development and production APNs environments are completely separate
3. Firebase configuration must match the APNs environment being used
4. DEBUG builds should always use development Firebase configuration

## Testing
When running from Xcode, you should now see:
- "Running in DEBUG configuration, using development environment"
- Correct loading of `dev.GoogleService-Info.plist`
- APNs tokens working with development endpoint
- No bundle ID mismatch warnings

## Production Builds
Release builds (TestFlight, App Store) will:
- Use the `#else` branch in EnvironmentDetector
- Select environment based on bundle ID
- Use production APNs endpoints and keys