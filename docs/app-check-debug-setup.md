# App Check Debug Setup Guide

## Overview
This guide explains how to set up Firebase App Check debug tokens for development and testing environments.

## Current Error
The app is showing an App Check registration error:
```
Firebase App Check: Token verification error. <FIRAppCheckErrorInfo: 0x10c15cf40>. App not registered: 1:645068839446:ios:7782656347bee14bfc3337
```

## Development Setup

### 1. Enable Debug Logging
In Xcode:
1. Go to Product → Scheme → Edit Scheme
2. Select "Run" on the left
3. Select "Arguments" tab
4. Under "Arguments Passed On Launch", add: `-FIRDebugEnabled`
5. Click "Close"

### 2. Run the App
1. Build and run the app in the simulator
2. Look for the debug token in the console output:
   ```
   ========================================
   🔑 App Check Debug Token:
   [YOUR-DEBUG-TOKEN-HERE]
   ========================================
   ```

### 3. Register Debug Token in Firebase Console
1. Go to [Firebase Console App Check](https://console.firebase.google.com/project/growth-70a85/appcheck/apps)
2. Click on your iOS app
3. Click the three dots menu → "Manage debug tokens"
4. Click "Add debug token"
5. Paste your debug token
6. Give it a descriptive name (e.g., "Development Simulator - [Your Name]")
7. Click "Done"

### 4. Restart the App
After registering the token, restart your app. The App Check errors should be resolved.

## CI/Testing Environment Setup

### Using the Setup Script
We provide a script to help configure debug tokens for CI:

```bash
./scripts/setup-appcheck-debug.sh --token YOUR_DEBUG_TOKEN --env dev
```

### Manual CI Configuration

#### GitHub Actions
Add to your workflow:
```yaml
env:
  FIREBASE_APP_CHECK_DEBUG_TOKEN: ${{ secrets.FIREBASE_APP_CHECK_DEBUG_TOKEN }}
```

#### Fastlane
Add to your Fastfile:
```ruby
ENV['FIREBASE_APP_CHECK_DEBUG_TOKEN'] = ENV['FIREBASE_APP_CHECK_DEBUG_TOKEN']
```

#### Xcode Cloud
Add as environment variable in workflow settings.

## Security Best Practices

### ⚠️ Important Security Notes
1. **Never commit debug tokens to version control**
2. **Keep debug tokens private** - They bypass App Check protection
3. **Use different tokens for different environments**
4. **Rotate tokens regularly**
5. **Revoke compromised tokens immediately**

### Token Storage
- Store tokens in secure environment variables
- Use secret management systems for CI/CD
- Never hardcode tokens in your app

### Revoking Tokens
If a token is compromised:
1. Go to Firebase Console → App Check → Manage debug tokens
2. Find the compromised token
3. Click the delete icon
4. Generate and register a new token

## Implementation Details

### Current Configuration
The app uses different providers based on build configuration:

1. **Simulator**: Always uses debug provider
2. **Debug builds**: Uses debug provider on real devices
3. **Production**: Uses App Attest (iOS 14+) or Device Check

### Debug Provider Factory
```swift
class DebugAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppCheckDebugProvider(app: app)
    }
}
```

## Troubleshooting

### Token Not Appearing
1. Ensure `-FIRDebugEnabled` flag is set correctly
2. Check that you're using the debug provider factory
3. Token appears after `FirebaseApp.configure()` is called

### Token Not Working
1. Verify you registered the exact token (no extra spaces)
2. Ensure you're registering in the correct Firebase project
3. Check that bundle ID matches Firebase app configuration

### Different Devices/Simulators
- Each device/simulator generates its own debug token
- Register all tokens you use for development
- Tokens persist across app launches on the same device

## Token Persistence
Debug tokens are stored in UserDefaults under the key `FIRAAppCheckDebugToken`. They persist:
- Across app launches
- Until the app is deleted
- Or until a new token is generated

## Production Considerations
- Debug provider must NEVER be used in production
- Use conditional compilation (#if DEBUG) to ensure this
- Production builds should use App Attest or Device Check