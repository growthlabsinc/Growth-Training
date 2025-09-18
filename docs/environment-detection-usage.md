# Firebase Environment Detection

The app now automatically detects which Firebase environment to use based on the bundle identifier.

## How It Works

1. **Bundle ID Mapping**:
   - `com.growth.dev` → Development environment
   - `com.growth.staging` → Staging environment
   - `com.growth` → Production environment

2. **Automatic Detection**:
   - On app launch, `EnvironmentDetector.detectEnvironment()` determines the environment
   - Firebase is configured with the appropriate GoogleService-Info.plist file
   - Falls back to production if bundle ID is unrecognized (in release builds)

## Usage Examples

### Check Current Environment
```swift
// Get the current environment
let environment = EnvironmentDetector.detectEnvironment()
print("Running in \(environment.rawValue) environment")

// Use convenience properties
if EnvironmentDetector.isDevelopment {
    // Enable debug features
    print("Debug mode enabled")
}

// Get full description with bundle ID
print(EnvironmentDetector.currentEnvironmentDescription)
// Output: "dev (Bundle ID: com.growth.dev)"
```

### Access Firebase Environment
```swift
// Get the Firebase client's current environment
let firebaseEnv = FirebaseClient.shared.currentEnvironment

// Check environment on Firebase types
if firebaseEnv.isDevelopment {
    // Use development-specific features
}
```

### Conditional Logic Based on Environment
```swift
// Example: Different API endpoints per environment
var apiBaseURL: String {
    switch EnvironmentDetector.detectEnvironment() {
    case .development:
        return "https://dev-api.growth.com"
    case .staging:
        return "https://staging-api.growth.com"
    case .production:
        return "https://api.growth.com"
    }
}

// Example: Enable/disable features
var isDebugMenuEnabled: Bool {
    return EnvironmentDetector.isDevelopment || EnvironmentDetector.isStaging
}
```

## Development Tools Integration

The Development Tools view (accessible in Settings when in DEBUG mode) now shows:
- Current detected environment
- Firebase configured environment
- Bundle identifier
- Color-coded environment indicator (orange=dev, blue=staging, green=production)

## Configuration Requirements

1. Ensure the correct bundle identifier is set in Xcode for each scheme:
   - Growth Dev scheme → `com.growth.dev`
   - Growth Staging scheme → `com.growth.staging`
   - Growth scheme → `com.growth`

2. Corresponding Firebase configuration files must exist:
   - `Growth/Resources/Plist/dev.GoogleService-Info.plist`
   - `Growth/Resources/Plist/staging.GoogleService-Info.plist`
   - `Growth/Resources/Plist/GoogleService-Info.plist`

## Troubleshooting

If the wrong environment is detected:
1. Check `Bundle.main.bundleIdentifier` in the debugger
2. Verify the scheme's bundle identifier in Xcode project settings
3. Ensure the corresponding GoogleService-Info.plist file exists
4. Check the console logs for environment detection messages