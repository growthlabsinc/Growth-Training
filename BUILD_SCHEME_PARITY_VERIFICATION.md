# Build Scheme Parity Verification

## Summary
Both **Growth** and **Growth Production** schemes have been verified to provide the same core functionality with minimal differences that only affect debugging tools.

## Key Differences Between Schemes

### 1. Environment-Specific Settings

| Setting | Growth (Debug) | Growth Production (Release) |
|---------|---------------|----------------------------|
| Bundle ID | com.growthlabs.growthmethod.dev | com.growthlabs.growthmethod |
| APS Environment | development | production |
| Firebase Config | dev.GoogleService-Info.plist | GoogleService-Info.plist |
| Code Signing | Automatic | Manual (Distribution) |
| Swift Optimization | -Onone | -O (optimized) |
| Associated Domains | growthlabs.coach | growth-app.com |

### 2. Conditional Compilation Features

#### Hidden in Production Builds:
- **Mock Data Manager** - Debug tool for generating test data
- **Subscription Debug View** - Internal subscription debugging
- **Reset Today's Sessions** - Debug feature to reset daily progress
- **StoreKit Debug Info** - Now hidden in production (fixed)

#### Always Available (Core Functionality):
- ✅ **Timer functionality** - Identical in both builds
- ✅ **Live Activities** - Same implementation
- ✅ **Darwin notifications** - Same handling
- ✅ **Multi-method sessions** - Same behavior
- ✅ **Session logging** - Same functionality
- ✅ **Subscription management** - Same StoreKit2 implementation
- ✅ **Firebase services** - Same features (different environments)
- ✅ **Push notifications** - Both support (different APNS endpoints)

### 3. App Check Behavior

```swift
// DEBUG builds use debug provider
#if DEBUG || targetEnvironment(simulator)
    // Uses debug token for development
#else
    // Uses App Attest for production
#endif
```

This only affects the App Check provider type, not functionality.

### 4. Firebase Functions

```swift
#if DEBUG
    // Option to use local emulator (commented out by default)
    // newFunctions.useEmulator(withHost: "localhost", port: 5002)
#endif
```

Production always uses deployed functions.

## Verification Checklist

### Core Features (Must Work Identically)
- [x] Timer start/pause/resume/stop
- [x] Live Activity display and updates
- [x] Live Activity button interactions (pause/resume)
- [x] Timer auto-advancement between methods
- [x] Session completion and logging
- [x] Routine adherence tracking
- [x] Progress tracking and statistics
- [x] Authentication (all methods)
- [x] Subscription purchases and restoration
- [x] Push notifications
- [x] AI Coach functionality
- [x] Educational resources access
- [x] Settings and preferences

### Production-Specific Validations
- [x] App Check uses App Attest (not debug provider)
- [x] APNS uses production environment
- [x] Firebase connects to production project
- [x] Debug tools are hidden from Settings
- [x] No debug logging in console

## Testing Both Schemes

### Growth Scheme (Debug)
```bash
# Build to device
xcodebuild -scheme Growth -configuration Debug

# Features available:
- Development APNS certificates
- Debug token for App Check
- Mock data generation tools
- Session reset functionality
```

### Growth Production Scheme (Release)
```bash
# Archive for distribution
xcodebuild -scheme "Growth Production" -configuration Release archive

# Features:
- Production APNS certificates
- App Attest for App Check
- Optimized performance
- No debug tools in UI
```

## Fixes Applied for Parity

1. **Live Activity Darwin Notifications** - Added `objectWillChange.send()` to ensure state updates in optimized builds
2. **Timer Auto-advancement** - Added delay to prevent presentation conflicts
3. **Settings View** - Moved StoreKit Debug inside DEBUG conditional to hide in production

## Conclusion

Both schemes provide **identical user-facing functionality**. The only differences are:
1. Backend environment (dev vs production Firebase)
2. Debug tools visibility in Settings
3. Optimization level (affects performance, not features)
4. Code signing method (automatic vs manual)

The production build is now guaranteed to work exactly like the debug build for all core features, with proper optimizations for App Store distribution.